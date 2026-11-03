// Bounded concurrent DAG execution with validation and cooperative cancellation.
// go run -race dag_scheduler.go
// Task functions must return when their context is cancelled. The scheduler
// cannot forcibly stop an arbitrary Go function. Dependencies are read-only.
package main

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"sync"
	"sync/atomic"
	"time"
)

type Task struct {
	Dependencies []string
	Run          func(context.Context, map[string]int) (int, error)
}
type completion struct {
	name  string
	value int
	err   error
}

func validate(tasks map[string]Task) (map[string]int, map[string][]string, error) {
	remaining := make(map[string]int)
	children := make(map[string][]string)
	for name, task := range tasks {
		if name == "" || task.Run == nil {
			return nil, nil, fmt.Errorf("invalid task %q", name)
		}
		seen := make(map[string]bool)
		for _, dependency := range task.Dependencies {
			if _, exists := tasks[dependency]; !exists {
				return nil, nil, fmt.Errorf("%s: missing %s", name, dependency)
			}
			if seen[dependency] {
				return nil, nil, fmt.Errorf("%s: duplicate dependency", name)
			}
			seen[dependency] = true
			children[dependency] = append(children[dependency], name)
		}
		remaining[name] = len(task.Dependencies)
	}
	// Reject cycles before any task can produce side effects.
	degrees := make(map[string]int)
	queue := []string{}
	for name, degree := range remaining {
		degrees[name] = degree
		if degree == 0 {
			queue = append(queue, name)
		}
	}
	visited := 0
	for len(queue) > 0 {
		current := queue[0]
		queue = queue[1:]
		visited++
		for _, child := range children[current] {
			degrees[child]--
			if degrees[child] == 0 {
				queue = append(queue, child)
			}
		}
	}
	if visited != len(tasks) {
		return nil, nil, errors.New("dependency cycle")
	}
	return remaining, children, nil
}

func Execute(parent context.Context, tasks map[string]Task, workers int) (map[string]int, error) {
	if workers < 1 {
		return nil, errors.New("workers must be positive")
	}
	remaining, children, err := validate(tasks)
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithCancel(parent)
	defer cancel()
	var group sync.WaitGroup
	// Every started task sends exactly once. Capacity prevents abandoned sends
	// from blocking during cancellation; waiting joins all started goroutines.
	events := make(chan completion, len(tasks))
	defer func() { cancel(); group.Wait() }()
	results := make(map[string]int)
	ready := []string{}
	for name, degree := range remaining {
		if degree == 0 {
			ready = append(ready, name)
		}
	}
	running := 0
	for len(results) < len(tasks) {
		if err := ctx.Err(); err != nil {
			return nil, err
		}
		sort.Strings(ready)
		for running < workers && len(ready) > 0 {
			name := ready[0]
			ready = ready[1:]
			task := tasks[name]
			inputs := make(map[string]int)
			for _, dependency := range task.Dependencies {
				inputs[dependency] = results[dependency]
			}
			running++
			group.Add(1)
			go func(name string, task Task, inputs map[string]int) {
				defer group.Done()
				value, taskErr := task.Run(ctx, inputs)
				events <- completion{name, value, taskErr}
			}(name, task, inputs)
		}
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		case event := <-events:
			running--
			if event.err != nil {
				return nil, fmt.Errorf("task %s: %w", event.name, event.err)
			}
			results[event.name] = event.value
			for _, child := range children[event.name] {
				remaining[child]--
				if remaining[child] == 0 {
					ready = append(ready, child)
				}
			}
		}
	}
	return results, nil
}

func must(condition bool) {
	if !condition {
		panic("self-check failed")
	}
}
func main() {
	var active, peak atomic.Int32
	work := func(ctx context.Context, inputs map[string]int) (int, error) {
		count := active.Add(1)
		defer active.Add(-1)
		for old := peak.Load(); count > old; old = peak.Load() {
			if peak.CompareAndSwap(old, count) {
				break
			}
		}
		select {
		case <-ctx.Done():
			return 0, ctx.Err()
		case <-time.After(time.Millisecond):
		}
		sum := 1
		for _, n := range inputs {
			sum += n
		}
		return sum, nil
	}
	tasks := map[string]Task{
		"a": {nil, work}, "b": {nil, work},
		"c": {[]string{"a", "b"}, work}, "d": {[]string{"c"}, work},
	}
	result, err := Execute(context.Background(), tasks, 2)
	must(err == nil && result["d"] == 4 && active.Load() == 0 && peak.Load() <= 2)
	for _, invalid := range []map[string]Task{
		{"a": {[]string{"missing"}, work}},
		{"a": {[]string{"b"}, work}, "b": {[]string{"a"}, work}},
		{"a": {nil, work}, "b": {[]string{"a", "a"}, work}},
	} {
		_, err = Execute(context.Background(), invalid, 2)
		must(err != nil)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	_, err = Execute(ctx, tasks, 2)
	must(errors.Is(err, context.Canceled))
	boom := errors.New("boom")
	_, err = Execute(context.Background(), map[string]Task{
		"bad":  {nil, func(context.Context, map[string]int) (int, error) { return 0, boom }},
		"wait": {nil, func(ctx context.Context, _ map[string]int) (int, error) { <-ctx.Done(); return 0, ctx.Err() }},
	}, 2)
	must(errors.Is(err, boom))
	empty, err := Execute(context.Background(), nil, 1)
	must(err == nil && len(empty) == 0)
	_, err = Execute(context.Background(), tasks, 0)
	must(err != nil)
	var invoked atomic.Int32
	for _, invalid := range []map[string]Task{
		{"": {nil, work}}, {"bad": {nil, nil}},
		{"good": {nil, func(context.Context, map[string]int) (int, error) { invoked.Add(1); return 1, nil }}, "bad": {[]string{"missing"}, work}},
	} {
		_, err = Execute(context.Background(), invalid, 2)
		must(err != nil && invoked.Load() == 0)
	}
	fmt.Println("DAG scheduler: ordering, bounds, validation, failure and cancellation passed")
}
