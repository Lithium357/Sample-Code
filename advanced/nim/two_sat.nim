# 2-SAT via iterative Kosaraju SCCs with a concrete satisfying assignment.
# nim c -r two_sat.nim. Literals are +/- one-based variable numbers.
# This solves clauses of at most two literals, not general SAT.
import std/[options]

type Clause = tuple[a, b: int]

proc solve(variables: int; clauses: seq[Clause]): Option[seq[bool]] =
  if variables < 0 or variables > 10000: raise newException(ValueError, "variable limit")
  let n = variables*2
  var graph = newSeq[seq[int]](n)
  var reverse = newSeq[seq[int]](n)
  proc vertex(literal: int): int =
    if literal == 0 or literal < -variables or literal >
        variables: raise newException(ValueError, "invalid literal")
    (abs(literal)-1)*2 + (if literal < 0: 1 else: 0)
  proc edge(a, b: int) =
    graph[a].add(b); reverse[b].add(a)
  for clause in clauses:
    let a = vertex(clause.a)
    let b = vertex(clause.b)
    edge(a xor 1, b); edge(b xor 1, a)
  var seen = newSeq[bool](n)
  var order: seq[int]
  # Explicit next-edge stack produces true DFS postorder without recursion.
  for start in 0..<n:
    if seen[start]: continue
    var stack: seq[tuple[u, next: int]] = @[(start, 0)]
    seen[start] = true
    while stack.len > 0:
      let u = stack[^1].u
      if stack[^1].next < graph[u].len:
        let next = graph[u][stack[^1].next]; inc stack[^1].next
        if not seen[next]: seen[next] = true; stack.add((next, 0))
      else:
        order.add(u); stack.setLen(stack.len-1)
  var component = newSeq[int](n)
  for i in 0..<n: component[i] = -1
  var count = 0
  for i in countdown(order.len-1, 0):
    let start = order[i]
    if component[start] >= 0: continue
    var stack = @[start]; component[start] = count
    while stack.len > 0:
      let u = stack.pop()
      for next in reverse[u]:
        if component[next] < 0: component[next] = count; stack.add(next)
    inc count
  var assignment = newSeq[bool](variables)
  for variable in 0..<variables:
    if component[2*variable] == component[2*variable+1]: return none(seq[bool])
    assignment[variable] = component[2*variable] > component[2*variable+1]
  some(assignment)

proc satisfies(clauses: seq[Clause]; values: seq[bool]): bool =
  proc value(lit: int): bool = values[abs(lit)-1] == (lit > 0)
  for clause in clauses:
    if not (value(clause.a) or value(clause.b)): return false
  true

when isMainModule:
  doAssert solve(0, @[]).get().len == 0
  doAssert solve(1, @[(1, 1), (-1, -1)]).isNone
  doAssert solve(2, @[(1, 2), (-1, 2), (1, -2)]).isSome
  var seed = 127
  for trial in 0..<1000:
    let variables = 1+trial mod 7
    var clauses: seq[Clause]
    for i in 0..<(trial mod 25):
      seed = (seed*251+17) mod 10007
      var a = 1+seed mod variables
      if seed mod 2 == 0: a = -a
      seed = (seed*251+17) mod 10007
      var b = 1+seed mod variables
      if seed mod 2 == 0: b = -b
      clauses.add((a, b))
    var possible = false
    for mask in 0..<(1 shl variables):
      var values = newSeq[bool](variables)
      for i in 0..<variables: values[i] = (mask and (1 shl i)) != 0
      if satisfies(clauses, values): possible = true; break
    let answer = solve(variables, clauses)
    doAssert answer.isSome == possible
    if answer.isSome: doAssert satisfies(clauses, answer.get())
  # Long implication chain exercises the nonrecursive DFS implementation.
  var chain: seq[Clause] = @[(1, 1)]
  for i in 1..<2000: chain.add((-i, i+1))
  let result = solve(2000, chain).get()
  for value in result: doAssert value
  echo "2-SAT: 1000 exhaustive model comparisons, contradiction and 2000-variable chain passed"
