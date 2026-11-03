// Go 1.20+: coalesce concurrent work by key; cancellation affects only a waiter.
// Work must eventually return and must not recursively wait on its own key.
// No caching: after completion, a later caller starts a new operation.
package main

import (
	"context"
	"errors"
	"fmt"
	"runtime"
	"sync"
	"sync/atomic"
)

type outcome struct {
	value int
	err   error
}
type flight struct {
	done    chan struct{}
	result  outcome
	waiters int
}
type Group struct {
	mu     sync.Mutex
	active map[string]*flight
}

func (g *Group) Do(ctx context.Context, key string, work func() (int, error)) (int, error) {
	if err := ctx.Err(); err != nil {
		return 0, err
	}
	g.mu.Lock()
	if g.active == nil {
		g.active = make(map[string]*flight)
	}
	call := g.active[key]
	if call == nil {
		call = &flight{done: make(chan struct{})}
		g.active[key] = call
		go func() {
			result := outcome{}
			func() {
				completed := false
				defer func() {
					if !completed {
						result.err = fmt.Errorf("work panicked: %v", recover())
					}
				}()
				result.value, result.err = work()
				completed = true
			}()
			g.mu.Lock()
			call.result = result
			delete(g.active, key)
			close(call.done)
			g.mu.Unlock()
		}()
	}
	call.waiters++
	g.mu.Unlock()
	select {
	case <-ctx.Done():
		return 0, ctx.Err()
	case <-call.done:
		return call.result.value, call.result.err
	}
}
func (g *Group) waitFor(key string, n int) {
	// A condition-free test barrier using the same mutex: no sleeps/deadlines
	// are used to infer whether callers have joined the in-flight operation.
	for {
		g.mu.Lock()
		c := g.active[key]
		ready := c != nil && c.waiters == n
		g.mu.Unlock()
		if ready {
			return
		}
		yield()
	}
}
func yield() { runtime.Gosched() }
func check(value bool) {
	if !value {
		panic("assertion failed")
	}
}
func main() {
	var group Group
	var count atomic.Int32
	release := make(chan struct{})
	entered := make(chan struct{})
	work := func() (int, error) { count.Add(1); close(entered); <-release; return 42, nil }
	results := make(chan outcome, 9)
	go func() { v, e := group.Do(context.Background(), "same", work); results <- outcome{v, e} }()
	<-entered
	// A blocked operation on one key must not hold the mutex during its work.
	other, otherErr := group.Do(context.Background(), "different", func() (int, error) { return 17, nil })
	check(other == 17 && otherErr == nil)
	for i := 0; i < 7; i++ {
		go func() { v, e := group.Do(context.Background(), "same", work); results <- outcome{v, e} }()
	}
	cancelled, cancel := context.WithCancel(context.Background())
	go func() { v, e := group.Do(cancelled, "same", work); results <- outcome{v, e} }()
	group.waitFor("same", 9)
	cancel()
	first := <-results
	check(errors.Is(first.err, context.Canceled))
	close(release)
	for i := 0; i < 8; i++ {
		r := <-results
		check(r.value == 42 && r.err == nil)
	}
	check(count.Load() == 1)
	value, err := group.Do(context.Background(), "same", func() (int, error) { return 99, nil })
	check(value == 99 && err == nil)
	boom := errors.New("fixture failure")
	_, err = group.Do(context.Background(), "bad", func() (int, error) { return 0, boom })
	check(errors.Is(err, boom))
	_, err = group.Do(context.Background(), "panic", func() (int, error) { panic("fixture panic") })
	check(err != nil)
	_, err = group.Do(context.Background(), "nil-panic", func() (int, error) { panic(nil) })
	check(err != nil)
	value, err = group.Do(context.Background(), "panic", func() (int, error) { return 3, nil })
	check(value == 3 && err == nil)
	stop, cancelStop := context.WithCancel(context.Background())
	cancelStop()
	_, err = group.Do(stop, "unused", func() (int, error) { panic("must not start") })
	check(errors.Is(err, context.Canceled))
	group.mu.Lock()
	check(len(group.active) == 0)
	group.mu.Unlock()
	fmt.Println("Keyed work: one leader, independent cancellation, fresh runs, errors and panic cleanup passed")
}
