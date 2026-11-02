// Optimistic serializable MVCC store with tombstones and snapshot-aware GC.
// go run -race mvcc_store.go
// Transactions are confined to one goroutine. The Store supports concurrency.
// Full-map scans conservatively conflict with every commit after their snapshot.
package main

import (
	"errors"
	"fmt"
	"sort"
	"strconv"
	"sync"
)

var ErrConflict = errors.New("transaction conflict")
var ErrClosed = errors.New("transaction closed")

type version struct {
	revision uint64
	value    string
	deleted  bool
}
type Store struct {
	mu       sync.Mutex
	revision uint64
	data     map[string][]version
	active   map[*Tx]uint64
}
type Tx struct {
	store           *Store
	snapshot        uint64
	reads           map[string]bool
	writes          map[string]*string
	scanned, closed bool
}

func NewStore() *Store { return &Store{data: make(map[string][]version), active: make(map[*Tx]uint64)} }
func (s *Store) Begin() *Tx {
	s.mu.Lock()
	defer s.mu.Unlock()
	tx := &Tx{store: s, snapshot: s.revision, reads: make(map[string]bool), writes: make(map[string]*string)}
	s.active[tx] = tx.snapshot
	return tx
}
func visible(history []version, snapshot uint64) (string, bool) {
	i := sort.Search(len(history), func(i int) bool { return history[i].revision > snapshot }) - 1
	if i < 0 || history[i].deleted {
		return "", false
	}
	return history[i].value, true
}
func (tx *Tx) Get(key string) (string, bool, error) {
	if tx.closed {
		return "", false, ErrClosed
	}
	if value, exists := tx.writes[key]; exists {
		if value == nil {
			return "", false, nil
		}
		return *value, true, nil
	}
	tx.store.mu.Lock()
	defer tx.store.mu.Unlock()
	tx.reads[key] = true
	value, exists := visible(tx.store.data[key], tx.snapshot)
	return value, exists, nil
}
func (tx *Tx) Put(key, value string) error {
	if tx.closed {
		return ErrClosed
	}
	copy := value
	tx.writes[key] = &copy
	return nil
}
func (tx *Tx) Delete(key string) error {
	if tx.closed {
		return ErrClosed
	}
	tx.writes[key] = nil
	return nil
}
func (tx *Tx) Scan() (map[string]string, error) {
	if tx.closed {
		return nil, ErrClosed
	}
	tx.store.mu.Lock()
	defer tx.store.mu.Unlock()
	tx.scanned = true
	result := make(map[string]string)
	for key, history := range tx.store.data {
		if value, ok := visible(history, tx.snapshot); ok {
			result[key] = value
		}
	}
	for key, value := range tx.writes {
		if value == nil {
			delete(result, key)
		} else {
			result[key] = *value
		}
	}
	return result, nil
}
func (tx *Tx) Abort() {
	tx.store.mu.Lock()
	defer tx.store.mu.Unlock()
	tx.closed = true
	delete(tx.store.active, tx)
}
func (tx *Tx) Commit() error {
	s := tx.store
	s.mu.Lock()
	defer s.mu.Unlock()
	if tx.closed {
		return ErrClosed
	}
	defer func() { tx.closed = true; delete(s.active, tx) }()
	if tx.scanned && s.revision != tx.snapshot {
		return ErrConflict
	}
	changed := func(key string) bool { h := s.data[key]; return len(h) > 0 && h[len(h)-1].revision > tx.snapshot }
	for key := range tx.reads {
		if changed(key) {
			return ErrConflict
		}
	}
	for key := range tx.writes {
		if changed(key) {
			return ErrConflict
		}
	}
	if len(tx.writes) == 0 {
		return nil
	}
	s.revision++
	for key, value := range tx.writes {
		event := version{revision: s.revision, deleted: value == nil}
		if value != nil {
			event.value = *value
		}
		s.data[key] = append(s.data[key], event)
	}
	return nil
}
func (s *Store) Compact() {
	s.mu.Lock()
	defer s.mu.Unlock()
	cutoff := s.revision
	for _, snapshot := range s.active {
		if snapshot < cutoff {
			cutoff = snapshot
		}
	}
	for key, history := range s.data {
		// Retain the newest version at/before the oldest active snapshot, plus
		// every later version. Tombstones remain so absent-key reads conflict.
		firstLater := sort.Search(len(history), func(i int) bool { return history[i].revision > cutoff })
		if firstLater > 1 {
			s.data[key] = append([]version(nil), history[firstLater-1:]...)
		}
	}
}
func must(ok bool) {
	if !ok {
		panic("self-check failed")
	}
}
func main() {
	s := NewStore()
	tx := s.Begin()
	_ = tx.Put("counter", "0")
	must(tx.Commit() == nil)
	old := s.Begin()
	first, second := s.Begin(), s.Begin()
	_, _, _ = first.Get("counter")
	_, _, _ = second.Get("counter")
	_ = first.Put("counter", "1")
	_ = second.Put("counter", "2")
	must(first.Commit() == nil)
	must(second.Commit() == ErrConflict)
	s.Compact()
	value, ok, err := old.Get("counter")
	must(err == nil && ok && value == "0")
	old.Abort()
	s.Compact()
	// Phantom: a transaction that scanned an empty namespace cannot commit
	// on the assumption that it is still empty after another writer inserts.
	reader := s.Begin()
	_, _ = reader.Scan()
	writer := s.Begin()
	_ = writer.Put("new", "value")
	must(writer.Commit() == nil)
	must(reader.Commit() == ErrConflict)
	absent := s.Begin()
	_, ok, _ = absent.Get("missing")
	must(!ok)
	writer = s.Begin()
	_ = writer.Put("missing", "x")
	must(writer.Commit() == nil)
	writer = s.Begin()
	_ = writer.Delete("missing")
	must(writer.Commit() == nil)
	s.Compact()
	must(absent.Commit() == ErrConflict)
	own := s.Begin()
	_ = own.Put("self", "yes")
	value, ok, _ = own.Get("self")
	must(ok && value == "yes")
	_ = own.Delete("self")
	_, ok, _ = own.Get("self")
	must(!ok)
	own.Abort()
	must(own.Commit() == ErrClosed)
	var group sync.WaitGroup
	for worker := 0; worker < 8; worker++ {
		group.Add(1)
		go func() {
			defer group.Done()
			for i := 0; i < 100; i++ {
				for {
					tx := s.Begin()
					value, _, _ := tx.Get("counter")
					n, err := strconv.Atoi(value)
					must(err == nil)
					_ = tx.Put("counter", strconv.Itoa(n+1))
					err = tx.Commit()
					if err == nil {
						break
					}
					must(err == ErrConflict)
				}
			}
		}()
	}
	group.Wait()
	final := s.Begin()
	value, _, _ = final.Get("counter")
	final.Abort()
	must(value == "801")
	s.Compact()
	must(len(s.active) == 0)
	fmt.Println("MVCC: snapshots, conflicts, tombstones, phantoms, GC and 800 concurrent increments passed")
}
