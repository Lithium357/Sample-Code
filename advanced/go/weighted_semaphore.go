// FIFO weighted semaphore with cancellation-safe ownership transfer.
// go run -race weighted_semaphore.go
// Strict FIFO can leave capacity idle behind a large head waiter. This is an
// intentional fairness policy. Release must match successful acquisitions.
package main

import (
	"container/list"
	"context"
	"errors"
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

type request struct {
	weight  int64
	ready   chan struct{}
	granted bool
}
type Weighted struct {
	mu             sync.Mutex
	capacity, used int64
	queue          list.List
}

func NewWeighted(capacity int64) (*Weighted, error) {
	if capacity <= 0 {
		return nil, errors.New("capacity must be positive")
	}
	return &Weighted{capacity: capacity}, nil
}
func (s *Weighted) wake() {
	for s.queue.Len() > 0 {
		front := s.queue.Front()
		waiting := front.Value.(*request)
		if waiting.weight > s.capacity-s.used {
			return
		}
		s.queue.Remove(front)
		s.used += waiting.weight
		waiting.granted = true
		close(waiting.ready)
	}
}
func (s *Weighted) Acquire(ctx context.Context, weight int64) error {
	if weight <= 0 || weight > s.capacity {
		return errors.New("weight outside capacity")
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	s.mu.Lock()
	if s.queue.Len() == 0 && weight <= s.capacity-s.used {
		s.used += weight
		s.mu.Unlock()
		return nil
	}
	waiting := &request{weight: weight, ready: make(chan struct{})}
	element := s.queue.PushBack(waiting)
	s.mu.Unlock()
	select {
	case <-waiting.ready:
		// Once granted, the caller owns capacity even if cancellation happens
		// simultaneously. The successful return obligates it to Release.
		return nil
	case <-ctx.Done():
		s.mu.Lock()
		if waiting.granted {
			// The cancellation branch won select after a concurrent grant.
			// Return the grant internally before reporting cancellation.
			s.used -= weight
		} else {
			s.queue.Remove(element)
		}
		s.wake()
		s.mu.Unlock()
		return ctx.Err()
	}
}
func (s *Weighted) Release(weight int64) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if weight <= 0 || weight > s.used {
		return errors.New("invalid release")
	}
	s.used -= weight
	s.wake()
	return nil
}
func (s *Weighted) state() (int64, int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.used, s.queue.Len()
}
func must(ok bool) {
	if !ok {
		panic("self-check failed")
	}
}
func waitQueued(s *Weighted, count int) {
	timeout := time.NewTimer(5 * time.Second)
	defer timeout.Stop()
	for {
		_, n := s.state()
		if n == count {
			return
		}
		select {
		case <-timeout.C:
			panic("queue did not reach expected state")
		default:
			time.Sleep(time.Millisecond)
		}
	}
}
func main() {
	s, err := NewWeighted(3)
	must(err == nil)
	must(s.Acquire(context.Background(), 2) == nil)
	large := make(chan error, 1)
	small := make(chan error, 1)
	ctx, cancel := context.WithCancel(context.Background())
	go func() { large <- s.Acquire(ctx, 3) }()
	waitQueued(s, 1)
	go func() { small <- s.Acquire(context.Background(), 1) }()
	waitQueued(s, 2)
	select {
	case <-small:
		panic("FIFO bypass")
	default:
	}
	cancel()
	must(errors.Is(<-large, context.Canceled))
	must(<-small == nil)
	must(s.Release(3) == nil)
	used, queued := s.state()
	must(used == 0 && queued == 0)
	must(s.Release(1) != nil)
	must(s.Acquire(context.Background(), 4) != nil)
	// Repeated grants race with cancellation. Each successful acquisition must
	// release exactly once; every cancelled acquisition must leak zero permits.
	var group sync.WaitGroup
	var active, peak atomic.Int64
	for worker := 0; worker < 12; worker++ {
		group.Add(1)
		go func(worker int) {
			defer group.Done()
			for i := 0; i < 100; i++ {
				ctx, cancel := context.WithCancel(context.Background())
				if (worker+i)%3 == 0 {
					go cancel()
				}
				err := s.Acquire(ctx, 1)
				if err == nil {
					count := active.Add(1)
					for old := peak.Load(); count > old; old = peak.Load() {
						if peak.CompareAndSwap(old, count) {
							break
						}
					}
					time.Sleep(time.Microsecond)
					active.Add(-1)
					must(s.Release(1) == nil)
				} else {
					must(errors.Is(err, context.Canceled))
				}
				cancel()
			}
		}(worker)
	}
	group.Wait()
	used, queued = s.state()
	must(used == 0 && queued == 0 && active.Load() == 0 && peak.Load() <= 3)
	fmt.Println("Weighted semaphore: FIFO, head cancellation, invalid releases and 1200 cancellation races passed")
}
