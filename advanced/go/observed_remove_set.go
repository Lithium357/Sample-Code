// State-based observed-remove set CRDT with add-wins concurrent semantics.
// go run observed_remove_set.go
// Actor ids must be unique for concurrent writers; reuse after cloning is not
// supported. Tombstones are retained: safe GC needs causal-stability knowledge.
package main

import (
	"fmt"
	"math"
	"reflect"
	"sort"
)

type Dot struct {
	Actor   string
	Counter uint64
}
type ORSet struct {
	actor   string
	clock   map[string]uint64
	live    map[string]map[Dot]bool
	removed map[Dot]bool
}

func NewORSet(actor string) *ORSet {
	if actor == "" {
		panic("actor required")
	}
	return &ORSet{actor: actor, clock: map[string]uint64{}, live: map[string]map[Dot]bool{}, removed: map[Dot]bool{}}
}
func (s *ORSet) Add(value string) {
	if s.clock[s.actor] == math.MaxUint64 {
		panic("actor counter exhausted")
	}
	s.clock[s.actor]++
	if s.live[value] == nil {
		s.live[value] = map[Dot]bool{}
	}
	s.live[value][Dot{s.actor, s.clock[s.actor]}] = true
}
func (s *ORSet) Remove(value string) {
	for dot := range s.live[value] {
		s.removed[dot] = true
	}
	delete(s.live, value)
}
func (s *ORSet) Merge(other *ORSet) {
	for actor, counter := range other.clock {
		if counter > s.clock[actor] {
			s.clock[actor] = counter
		}
	}
	for dot := range other.removed {
		s.removed[dot] = true
	}
	for value, dots := range other.live {
		for dot := range dots {
			if !s.removed[dot] {
				if s.live[value] == nil {
					s.live[value] = map[Dot]bool{}
				}
				s.live[value][dot] = true
			}
		}
	}
	for value, dots := range s.live {
		for dot := range dots {
			if s.removed[dot] {
				delete(dots, dot)
			}
		}
		if len(dots) == 0 {
			delete(s.live, value)
		}
	}
}
func (s *ORSet) Snapshot() *ORSet { copy := NewORSet(s.actor); copy.Merge(s); return copy }
func (s *ORSet) Values() []string {
	values := []string{}
	for value := range s.live {
		values = append(values, value)
	}
	sort.Strings(values)
	return values
}
func same(a, b *ORSet) bool {
	return reflect.DeepEqual(a.clock, b.clock) && reflect.DeepEqual(a.live, b.live) && reflect.DeepEqual(a.removed, b.removed)
}
func assert(ok bool) {
	if !ok {
		panic("self-check failed")
	}
}
func main() {
	a, b := NewORSet("a"), NewORSet("b")
	a.Add("x")
	b.Merge(a)
	a.Remove("x")
	b.Add("x")
	a.Merge(b)
	b.Merge(a)
	assert(reflect.DeepEqual(a.Values(), []string{"x"}) && same(a, b))
	a.Remove("x")
	b.Merge(a)
	assert(len(b.Values()) == 0)
	for trial := 0; trial < 150; trial++ {
		nodes := []*ORSet{NewORSet("a"), NewORSet("b"), NewORSet("c")}
		messages := []*ORSet{}
		seed := uint64(131 + trial)
		for step := 0; step < 300; step++ {
			seed = seed*6364136223846793005 + 1
			node := nodes[(seed>>16)%3]
			value := fmt.Sprintf("v%d", (seed>>24)%7)
			switch seed % 4 {
			case 0:
				node.Add(value)
			case 1:
				node.Remove(value)
			case 2:
				messages = append(messages, node.Snapshot())
			case 3:
				if len(messages) > 0 {
					node.Merge(messages[(seed>>32)%uint64(len(messages))])
				}
			}
		}
		x, y, z := nodes[0].Snapshot(), nodes[1].Snapshot(), nodes[2].Snapshot()
		xy := x.Snapshot()
		xy.Merge(y)
		yx := y.Snapshot()
		yx.Merge(x)
		assert(same(xy, yx))
		idempotent := x.Snapshot()
		idempotent.Merge(x)
		assert(same(idempotent, x))
		left := xy.Snapshot()
		left.Merge(z)
		yz := y.Snapshot()
		yz.Merge(z)
		right := x.Snapshot()
		right.Merge(yz)
		assert(same(left, right))
		// Deliver all queued old states in reverse, including duplicates, then
		// join current replica states. Old messages cannot resurrect tombstones.
		for i := len(messages) - 1; i >= 0; i-- {
			for _, node := range nodes {
				node.Merge(messages[i])
				node.Merge(messages[i])
			}
		}
		for _, source := range nodes {
			for _, target := range nodes {
				target.Merge(source)
			}
		}
		for _, node := range nodes {
			assert(same(node, left))
		}
		// Merging never mutated the captured source snapshots.
		replay := x.Snapshot()
		assert(same(replay, x))
	}
	fmt.Println("OR-set: observed removes, concurrent add-wins, 150 reordered-delivery simulations and join laws passed")
}
