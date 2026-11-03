// Go 1.20+: an all-or-error bounded reader. No goroutines/files/network.
// Handles legal n>0,err!=nil returns and bounded consecutive empty reads.
// Limit 0..1MiB; over-limit takes precedence over a same-read upstream error.
// It may consume one byte beyond the limit to establish overflow. Reader must
// obey the io.Reader contract; invalid n values are diagnosed defensively.
package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
)

var ErrLimit = errors.New("input exceeds limit")
var ErrReadCount = errors.New("reader returned invalid byte count")
var ErrArgument = errors.New("invalid limit or nil reader")

func ReadBounded(reader io.Reader, limit int) ([]byte, error) {
	if reader == nil || limit < 0 || limit > 1<<20 {
		return nil, ErrArgument
	}
	result := make([]byte, 0)
	var scratch [4096]byte
	empty := 0
	for {
		width := limit - len(result) + 1
		if width > len(scratch) {
			width = len(scratch)
		}
		n, err := reader.Read(scratch[:width])
		if n < 0 || n > width {
			return nil, ErrReadCount
		}
		if n > 0 {
			empty = 0
			if n > limit-len(result) {
				return nil, ErrLimit
			}
			result = append(result, scratch[:n]...)
		}
		if err != nil {
			if errors.Is(err, io.EOF) {
				return result, nil
			}
			return nil, err
		}
		if n == 0 {
			empty++
			if empty == 100 {
				return nil, io.ErrNoProgress
			}
		}
	}
}

type chunk struct {
	data string
	err  error
}
type scripted struct {
	steps []chunk
	calls int
}

func (s *scripted) Read(p []byte) (int, error) {
	s.calls++
	if len(s.steps) == 0 {
		return 0, io.EOF
	}
	step := &s.steps[0]
	n := copy(p, step.data)
	step.data = step.data[n:]
	if len(step.data) != 0 {
		return n, nil
	}
	err := step.err
	s.steps = s.steps[1:]
	return n, err
}

type invalid struct{ n int }

func (i invalid) Read([]byte) (int, error) { return i.n, nil }
func check(truth bool) {
	if !truth {
		panic("assertion failed")
	}
}
func main() {
	for length := 0; length <= 128; length++ {
		input := bytes.Repeat([]byte{byte(length)}, length)
		for limit := 0; limit <= 130; limit++ {
			got, err := ReadBounded(bytes.NewReader(input), limit)
			if length > limit {
				check(errors.Is(err, ErrLimit) && got == nil)
			} else {
				reference, referenceErr := io.ReadAll(bytes.NewReader(input))
				check(referenceErr == nil && err == nil && bytes.Equal(got, reference))
			}
		}
	}
	// EOF accompanying bytes must not cause those bytes to be dropped.
	s := &scripted{steps: []chunk{{"ab", nil}, {"cd", io.EOF}}}
	got, err := ReadBounded(s, 4)
	check(err == nil && string(got) == "abcd" && s.calls == 2)
	failure := errors.New("fixture source error")
	s = &scripted{steps: []chunk{{"prefix", failure}}}
	got, err = ReadBounded(s, 20)
	check(got == nil && err == failure && s.calls == 1)
	s = &scripted{steps: []chunk{{"abc", failure}}}
	got, err = ReadBounded(s, 2)
	check(got == nil && errors.Is(err, ErrLimit))
	for _, limit := range []int{-1, 1<<20 + 1} {
		got, err = ReadBounded(bytes.NewReader(nil), limit)
		check(got == nil && errors.Is(err, ErrArgument))
	}
	got, err = ReadBounded(nil, 0)
	check(got == nil && errors.Is(err, ErrArgument))
	for _, n := range []int{-1, 4097} {
		got, err = ReadBounded(invalid{n}, 5000)
		check(got == nil && errors.Is(err, ErrReadCount))
	}
	s = &scripted{steps: make([]chunk, 100)}
	got, err = ReadBounded(s, 1)
	check(got == nil && errors.Is(err, io.ErrNoProgress) && s.calls == 100)
	// Progress resets the consecutive-empty counter; total empty reads can exceed 100.
	s = &scripted{}
	for i := 0; i < 3; i++ {
		s.steps = append(s.steps, make([]chunk, 99)...)
		s.steps = append(s.steps, chunk{"x", nil})
	}
	got, err = ReadBounded(s, 3)
	check(err == nil && string(got) == "xxx" && s.calls == 301)
	max := bytes.Repeat([]byte{'z'}, 1<<20)
	got, err = ReadBounded(bytes.NewReader(max), len(max))
	check(err == nil && bytes.Equal(got, max))
	fmt.Println("Bounded reader: 16899 size cases, EOF-with-data, error identity, bad counts, no-progress reset and 1MiB boundary passed")
}
