# Weighted A* search with an admissible heuristic and reconstructed paths.
# nim c -r astar_grid.nim; also compatible with the JavaScript backend.
# Entering a cell costs its value (1..9); zero means wall. Start costs zero.
import std/[heapqueue, options, algorithm]

type
  Point = tuple[x, y: int]
  State = object
    priority, cost, index: int
  Route = object
    cost: int
    path: seq[Point]

proc `<`(a, b: State): bool =
  if a.priority != b.priority: a.priority < b.priority
  elif a.cost != b.cost: a.cost < b.cost
  else: a.index < b.index

proc neighbors(index, width, height: int): seq[int] =
  let x = index mod width
  let y = index div width
  if x > 0: result.add(index - 1)
  if x + 1 < width: result.add(index + 1)
  if y > 0: result.add(index - width)
  if y + 1 < height: result.add(index + width)

proc search(grid: seq[seq[int]]; start, goal: Point): Option[Route] =
  if grid.len == 0 or grid[0].len == 0: raise newException(ValueError, "empty grid")
  let height = grid.len
  let width = grid[0].len
  var minimum = 10
  for row in grid:
    if row.len != width: raise newException(ValueError, "ragged grid")
    for value in row:
      if value < 0 or value > 9: raise newException(ValueError, "invalid cell")
      if value > 0: minimum = min(minimum, value)
  for p in [start, goal]:
    if p.x < 0 or p.x >= width or p.y < 0 or p.y >= height:
      raise newException(ValueError, "point outside grid")
  if grid[start.y][start.x] == 0 or grid[goal.y][goal.x] == 0: return none(Route)
  let source = start.y * width + start.x
  let target = goal.y * width + goal.x
  proc heuristic(index: int): int =
    (abs(index mod width - goal.x) + abs(index div width - goal.y)) * minimum
  var distance = newSeq[int](width * height)
  var previous = newSeq[int](width * height)
  for i in 0..<distance.len: distance[i] = 100000000; previous[i] = -1
  distance[source] = 0
  var queue = initHeapQueue[State]()
  queue.push(State(priority: heuristic(source), cost: 0, index: source))
  while queue.len > 0:
    let current = queue.pop()
    if current.cost != distance[current.index]: continue # stale heap entry
    if current.index == target:
      var path: seq[Point]
      var index = target
      while index != -1:
        path.add((index mod width, index div width))
        index = previous[index]
      path.reverse()
      return some(Route(cost: current.cost, path: path))
    for next in neighbors(current.index, width, height):
      let cell = grid[next div width][next mod width]
      if cell == 0: continue
      let candidate = current.cost + cell
      if candidate < distance[next]:
        distance[next] = candidate
        previous[next] = current.index
        queue.push(State(priority: candidate + heuristic(next), cost: candidate, index: next))
  none(Route)

proc oracle(grid: seq[seq[int]]): int =
  # Bellman-Ford relaxation, independent of the heap/heuristic implementation.
  let h = grid.len
  let w = grid[0].len
  var costs = newSeq[int](w*h)
  for i in 0..<costs.len: costs[i] = 100000000
  costs[0] = 0
  for pass in 0..<w*h:
    var changed = false
    for index in 0..<w*h:
      if grid[index div w][index mod w] == 0 or costs[index] == 100000000: continue
      for next in neighbors(index,w,h):
        let step = grid[next div w][next mod w]
        if step > 0 and costs[next] > costs[index] + step:
          costs[next] = costs[index] + step
          changed = true
    if not changed: break
  if costs[^1] == 100000000: -1 else: costs[^1]

when isMainModule:
  var seed = 41
  for trial in 0..<100:
    var grid = newSeq[seq[int]](8)
    for y in 0..<8:
      grid[y] = newSeq[int](9)
      for x in 0..<9:
        seed = (seed * 251 + 17) mod 10007
        grid[y][x] = seed mod 10
    grid[0][0] = 1; grid[^1][^1] = 1
    let route = search(grid,(0,0),(8,7))
    let expected = oracle(grid)
    doAssert route.isSome == (expected >= 0)
    if route.isSome:
      let answer = route.get()
      doAssert answer.cost == expected
      doAssert answer.path[0] == (0,0) and answer.path[^1] == (8,7)
      var measured = 0
      for i in 1..<answer.path.len:
        let a = answer.path[i-1]
        let b = answer.path[i]
        doAssert abs(a.x-b.x) + abs(a.y-b.y) == 1
        doAssert grid[b.y][b.x] > 0
        measured += grid[b.y][b.x]
      doAssert measured == answer.cost
  doAssert search(@[@[1]],(0,0),(0,0)).get().cost == 0
  doAssert search(@[@[1,0,1]],(0,0),(2,0)).isNone
  echo "A*: 100 Bellman-Ford comparisons, path validation and boundary cases passed"
