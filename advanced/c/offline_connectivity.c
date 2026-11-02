/* Offline dynamic connectivity: segment tree of edge lifetimes + rollback DSU.
 * C17, at most 12 vertices and 160 events. Adds/removes are strict (no parallel
 * edge multiplicity). Queries may use the same endpoint twice. No path
 * compression: union-by-size keeps roots shallow while preserving rollback.
 */
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

enum { V = 12, T = 160, LINKS = T * 16 };
typedef enum { ADD, REMOVE, QUERY } Kind;
typedef struct {
  Kind kind;
  int u, v;
} Event;
typedef struct {
  int child, parent, old_size;
} Change;
typedef struct {
  int parent[V], size[V], used;
  Change changes[V];
} DSU;
typedef struct {
  int u, v, next;
} Link;
typedef struct {
  int heads[4 * T], used;
  Link links[LINKS];
} Work;
static int root(const DSU *dsu, int vertex) {
  while (dsu->parent[vertex] != vertex)
    vertex = dsu->parent[vertex];
  return vertex;
}
static void unite(DSU *dsu, int a, int b) {
  a = root(dsu, a);
  b = root(dsu, b);
  if (a == b)
    return;
  if (dsu->size[a] < dsu->size[b]) {
    int swap = a;
    a = b;
    b = swap;
  }
  assert(dsu->used < V);
  dsu->changes[dsu->used++] = (Change){b, a, dsu->size[a]};
  dsu->parent[b] = a;
  dsu->size[a] += dsu->size[b];
}
static void rollback(DSU *dsu, int checkpoint) {
  while (dsu->used > checkpoint) {
    Change old = dsu->changes[--dsu->used];
    dsu->parent[old.child] = old.child;
    dsu->size[old.parent] = old.old_size;
  }
}
static bool attach(Work *work, int node, int low, int high, int begin, int end,
                   int u, int v) {
  if (end <= low || high <= begin)
    return true;
  if (begin <= low && high <= end) {
    if (work->used == LINKS)
      return false;
    work->links[work->used] = (Link){u, v, work->heads[node]};
    work->heads[node] = work->used++;
    return true;
  }
  int middle = low + (high - low) / 2;
  return attach(work, node * 2, low, middle, begin, end, u, v) &&
         attach(work, node * 2 + 1, middle, high, begin, end, u, v);
}
static void visit(const Work *work, int node, int low, int high, DSU *dsu,
                  const Event *events, int *answers) {
  int checkpoint = dsu->used;
  for (int edge = work->heads[node]; edge != -1; edge = work->links[edge].next)
    unite(dsu, work->links[edge].u, work->links[edge].v);
  if (high - low == 1) {
    answers[low] = events[low].kind == QUERY
                       ? (root(dsu, events[low].u) == root(dsu, events[low].v))
                       : -1;
  } else {
    int middle = low + (high - low) / 2;
    visit(work, node * 2, low, middle, dsu, events, answers);
    visit(work, node * 2 + 1, middle, high, dsu, events, answers);
  }
  rollback(dsu, checkpoint);
}
static bool solve(int vertices, const Event *events, int count, int *output) {
  if (vertices < 1 || vertices > V || count < 0 || count > T ||
      (!events && count) || (!output && count))
    return false;
  if (count == 0)
    return true;
  Work *work = calloc(1, sizeof(*work));
  if (!work)
    return false;
  for (int i = 0; i < 4 * T; ++i)
    work->heads[i] = -1;
  int starts[V][V];
  for (int u = 0; u < V; ++u)
    for (int v = 0; v < V; ++v)
      starts[u][v] = -1;
  bool valid = true;
  for (int time = 0; time < count && valid; ++time) {
    Event event = events[time];
    int u = event.u, v = event.v;
    if (u < 0 || v < 0 || u >= vertices || v >= vertices) {
      valid = false;
      break;
    }
    if (u > v) {
      int swap = u;
      u = v;
      v = swap;
    }
    switch (event.kind) {
    case ADD:
      if (u == v || starts[u][v] != -1)
        valid = false;
      else
        starts[u][v] = time;
      break;
    case REMOVE:
      if (u == v || starts[u][v] == -1)
        valid = false;
      else {
        valid = attach(work, 1, 0, count, starts[u][v], time, u, v);
        starts[u][v] = -1;
      }
      break;
    case QUERY:
      break;
    default:
      valid = false;
    }
  }
  for (int u = 0; u < vertices && valid; ++u)
    for (int v = u + 1; v < vertices && valid; ++v)
      if (starts[u][v] != -1)
        valid = attach(work, 1, 0, count, starts[u][v], count, u, v);
  if (valid) {
    DSU dsu = {0};
    for (int i = 0; i < vertices; ++i) {
      dsu.parent[i] = i;
      dsu.size[i] = 1;
    }
    int answers[T];
    visit(work, 1, 0, count, &dsu, events, answers);
    for (int i = 0; i < count; ++i)
      output[i] = answers[i];
    assert(dsu.used == 0);
    for (int i = 0; i < vertices; ++i)
      assert(dsu.parent[i] == i && dsu.size[i] == 1);
  }
  free(work);
  return valid;
}
static bool bfs(bool graph[V][V], int vertices, int source, int target) {
  bool seen[V] = {false};
  int queue[V], head = 0, tail = 0;
  queue[tail++] = source;
  seen[source] = true;
  while (head < tail) {
    int u = queue[head++];
    for (int v = 0; v < vertices; ++v)
      if (graph[u][v] && !seen[v]) {
        seen[v] = true;
        queue[tail++] = v;
      }
  }
  return seen[target];
}
int main(void) {
  uint32_t seed = 113;
  for (int trial = 0; trial < 200; ++trial) {
    bool graph[V][V] = {{false}};
    Event events[80];
    int expected[80], actual[80];
    for (int time = 0; time < 80; ++time) {
      seed = seed * UINT32_C(1664525) + UINT32_C(1013904223);
      int u = (int)((seed >> 8) % 8);
      seed = seed * UINT32_C(1664525) + UINT32_C(1013904223);
      int v = (int)((seed >> 8) % 8);
      if (seed % 3 == 0 || u == v) {
        events[time] = (Event){QUERY, u, v};
        expected[time] = bfs(graph, 8, u, v);
      } else {
        events[time] = (Event){graph[u][v] ? REMOVE : ADD, u, v};
        graph[u][v] = graph[v][u] = !graph[u][v];
        expected[time] = -1;
      }
    }
    assert(solve(8, events, 80, actual));
    for (int i = 0; i < 80; ++i)
      assert(expected[i] == actual[i]);
  }
  Event invalid[] = {{REMOVE, 0, 1}};
  int unchanged = 123;
  assert(!solve(2, invalid, 1, &unchanged) && unchanged == 123);
  Event duplicate[] = {{ADD, 0, 1}, {ADD, 1, 0}};
  int outputs[2] = {7, 8};
  assert(!solve(2, duplicate, 2, outputs) && outputs[0] == 7 &&
         outputs[1] == 8);
  assert(solve(1, NULL, 0, NULL));
  puts("Offline connectivity: 200 BFS-oracle event streams, rollback "
       "invariants and atomic rejection passed");
  return 0;
}
