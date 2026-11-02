// Checksummed write-ahead log with explicit torn-tail recovery.
// go run wal_recovery.go
// Format: LE32 payload length, LE64 monotonically increasing sequence, payload,
// CRC32C. Recovery tolerates only incomplete final frames. Complete corrupt
// frames are rejected. Sync/rename durability depends on the host filesystem.
package main

import (
	"bytes"
	"encoding/binary"
	"errors"
	"fmt"
	"hash/crc32"
	"io"
	"os"
	"path/filepath"
)

var castagnoli = crc32.MakeTable(crc32.Castagnoli)
var ErrCorrupt = errors.New("corrupt WAL")

const payloadLimit = 4096

type Entry struct {
	Sequence uint64
	Payload  []byte
}
type WAL struct {
	file *os.File
	next uint64
}

func Recover(reader io.Reader) ([]Entry, int64, error) {
	entries := []Entry{}
	var offset int64
	var expected uint64 = 1
	for {
		var header [12]byte
		n, err := io.ReadFull(reader, header[:])
		if err == io.EOF && n == 0 {
			return entries, offset, nil
		}
		if err == io.ErrUnexpectedEOF {
			return entries, offset, nil
		}
		if err != nil {
			return nil, offset, err
		}
		length := binary.LittleEndian.Uint32(header[:4])
		sequence := binary.LittleEndian.Uint64(header[4:])
		if length > payloadLimit || sequence != expected {
			return nil, offset, ErrCorrupt
		}
		body := make([]byte, int(length)+4)
		if _, err = io.ReadFull(reader, body); err == io.EOF || err == io.ErrUnexpectedEOF {
			return entries, offset, nil
		}
		if err != nil {
			return nil, offset, err
		}
		checksum := crc32.New(castagnoli)
		_, _ = checksum.Write(header[:])
		_, _ = checksum.Write(body[:length])
		if checksum.Sum32() != binary.LittleEndian.Uint32(body[length:]) {
			return nil, offset, ErrCorrupt
		}
		entries = append(entries, Entry{sequence, bytes.Clone(body[:length])})
		offset += int64(16 + length)
		expected++
	}
}
func OpenWAL(path string) (*WAL, []Entry, error) {
	file, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return nil, nil, err
	}
	entries, valid, err := Recover(file)
	if err != nil {
		_ = file.Close()
		return nil, nil, err
	}
	if err = file.Truncate(valid); err != nil {
		_ = file.Close()
		return nil, nil, err
	}
	if _, err = file.Seek(valid, io.SeekStart); err != nil {
		_ = file.Close()
		return nil, nil, err
	}
	return &WAL{file: file, next: uint64(len(entries)) + 1}, entries, nil
}
func (w *WAL) Append(payload []byte) error {
	if len(payload) > payloadLimit {
		return errors.New("payload too large")
	}
	if w.file == nil {
		return errors.New("closed WAL")
	}
	frame := make([]byte, 12+len(payload)+4)
	binary.LittleEndian.PutUint32(frame, uint32(len(payload)))
	binary.LittleEndian.PutUint64(frame[4:], w.next)
	copy(frame[12:], payload)
	binary.LittleEndian.PutUint32(frame[len(frame)-4:], crc32.Checksum(frame[:len(frame)-4], castagnoli))
	// A failed write leaves a potentially torn log. Close this handle so later
	// appends cannot accidentally continue after the partial frame.
	for remaining := frame; len(remaining) > 0; {
		n, err := w.file.Write(remaining)
		if err != nil || n == 0 {
			_ = w.Close()
			if err == nil {
				err = io.ErrShortWrite
			}
			return err
		}
		remaining = remaining[n:]
	}
	if err := w.file.Sync(); err != nil {
		_ = w.Close()
		return err
	}
	w.next++
	return nil
}
func (w *WAL) Close() error {
	if w.file == nil {
		return nil
	}
	file := w.file
	w.file = nil
	return file.Close()
}
func check(ok bool) {
	if !ok {
		panic("self-check failed")
	}
}

type brokenReader struct{}

func (brokenReader) Read([]byte) (int, error) { return 0, errors.New("device error") }
func main() {
	directory, err := os.MkdirTemp("", "sample-wal-")
	check(err == nil)
	defer os.RemoveAll(directory)
	path := filepath.Join(directory, "events.wal")
	wal, entries, err := OpenWAL(path)
	check(err == nil && len(entries) == 0)
	messages := [][]byte{[]byte("first"), nil, bytes.Repeat([]byte{0, 255}, 31), []byte("last")}
	for _, message := range messages {
		check(wal.Append(message) == nil)
	}
	check(wal.Close() == nil)
	image, err := os.ReadFile(path)
	check(err == nil)
	boundaries := []int{0}
	position := 0
	for _, message := range messages {
		position += 16 + len(message)
		boundaries = append(boundaries, position)
	}
	for cut := 0; cut <= len(image); cut++ {
		recovered, valid, err := Recover(bytes.NewReader(image[:cut]))
		check(err == nil)
		count := 0
		for _, boundary := range boundaries[1:] {
			if boundary <= cut {
				count++
			}
		}
		check(len(recovered) == count && valid == int64(boundaries[count]))
		for i, entry := range recovered {
			check(entry.Sequence == uint64(i+1) && bytes.Equal(entry.Payload, messages[i]))
		}
	}
	corrupt := bytes.Clone(image)
	corrupt[12] ^= 1
	_, _, err = Recover(bytes.NewReader(corrupt))
	check(errors.Is(err, ErrCorrupt))
	_, _, err = Recover(brokenReader{})
	check(err != nil && !errors.Is(err, ErrCorrupt))
	check(os.WriteFile(path, image[:len(image)-2], 0600) == nil)
	wal, entries, err = OpenWAL(path)
	check(err == nil && len(entries) == 3)
	check(wal.Append([]byte("replacement")) == nil)
	check(wal.Close() == nil)
	wal, entries, err = OpenWAL(path)
	check(err == nil && len(entries) == 4 && string(entries[3].Payload) == "replacement")
	check(wal.Close() == nil)
	fmt.Println("WAL: every torn-tail boundary, corruption, reader errors and reopen/append recovery passed")
}
