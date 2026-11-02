# Dinic maximum flow with residual reverse edges and a minimum-cut certificate.
# nim c -r dinic_flow.nim; also supports the JS backend for bounded capacities.
import std/[deques]

type
  Edge = object
    target, reverse, capacity: int
  Network = object
    adjacency: seq[seq[Edge]]
    level, cursor: seq[int]

proc initNetwork(vertices: int): Network =
  if vertices < 2: raise newException(ValueError,"at least two vertices")
  result.adjacency = newSeq[seq[Edge]](vertices)
  result.level = newSeq[int](vertices)
  result.cursor = newSeq[int](vertices)

proc add(network: var Network; source, target, capacity: int) =
  let size = network.adjacency.len
  if source < 0 or target < 0 or source >= size or target >= size or source == target or capacity < 0:
    raise newException(ValueError,"invalid arc")
  let forward = Edge(target: target, reverse: network.adjacency[target].len, capacity: capacity)
  let backward = Edge(target: source, reverse: network.adjacency[source].len, capacity: 0)
  network.adjacency[source].add(forward)
  network.adjacency[target].add(backward)

proc layers(network: var Network; source, sink: int): bool =
  for i in 0..<network.level.len: network.level[i] = -1
  network.level[source] = 0
  var queue = initDeque[int]()
  queue.addLast(source)
  while queue.len > 0:
    let u = queue.popFirst()
    for edge in network.adjacency[u]:
      if edge.capacity > 0 and network.level[edge.target] < 0:
        network.level[edge.target] = network.level[u] + 1
        queue.addLast(edge.target)
  network.level[sink] >= 0

proc send(network: var Network; u, sink, available: int): int =
  if u == sink: return available
  while network.cursor[u] < network.adjacency[u].len:
    let index = network.cursor[u]
    let edge = network.adjacency[u][index] # copy before recursive mutation
    if edge.capacity > 0 and network.level[edge.target] == network.level[u]+1:
      let amount = network.send(edge.target,sink,min(available,edge.capacity))
      if amount > 0:
        network.adjacency[u][index].capacity -= amount
        network.adjacency[edge.target][edge.reverse].capacity += amount
        return amount
    inc network.cursor[u]
  0

proc maxFlow(network: var Network; source,sink: int): int =
  let n = network.adjacency.len
  if source < 0 or sink < 0 or source >= n or sink >= n or source == sink:
    raise newException(ValueError,"invalid terminals")
  while network.layers(source,sink):
    for i in 0..<n: network.cursor[i] = 0
    while true:
      let sent = network.send(source,sink,100000000)
      if sent == 0: break
      result += sent

proc reachable(network: Network; source: int): seq[bool] =
  result = newSeq[bool](network.adjacency.len)
  var queue = initDeque[int]()
  result[source] = true; queue.addLast(source)
  while queue.len > 0:
    let u = queue.popFirst()
    for edge in network.adjacency[u]:
      if edge.capacity > 0 and not result[edge.target]:
        result[edge.target] = true; queue.addLast(edge.target)

when isMainModule:
  type Arc = tuple[u,v,capacity:int]
  var seed = 79
  for trial in 0..<250:
    let n = 2 + trial mod 6
    var network = initNetwork(n)
    var arcs: seq[Arc]
    for u in 0..<n:
      for v in 0..<n:
        seed = (seed*251+17) mod 10007
        if u != v and seed mod 4 == 0:
          let capacity = seed mod 10
          network.add(u,v,capacity)
          arcs.add((u,v,capacity))
    # Independent max-flow/min-cut oracle enumerates every source/sink cut.
    var best = 100000000
    for mask in 0..<(1 shl n):
      if (mask and 1) == 0 or (mask and (1 shl (n-1))) != 0: continue
      var capacity = 0
      for arc in arcs:
        if (mask and (1 shl arc.u)) != 0 and (mask and (1 shl arc.v)) == 0:
          capacity += arc.capacity
      best = min(best,capacity)
    let answer = network.maxFlow(0,n-1)
    doAssert answer == best
    let cut = network.reachable(0)
    doAssert not cut[n-1]
    var certificate = 0
    for arc in arcs:
      if cut[arc.u] and not cut[arc.v]: certificate += arc.capacity
    doAssert certificate == answer
    doAssert network.maxFlow(0,n-1) == 0 # no additional augmenting flow
  var parallel = initNetwork(3)
  parallel.add(0,1,2); parallel.add(0,1,3); parallel.add(1,0,7); parallel.add(1,2,4)
  doAssert parallel.maxFlow(0,2) == 4
  echo "Dinic: 250 exhaustive cut oracles, certificates, parallel and reverse arcs passed"
