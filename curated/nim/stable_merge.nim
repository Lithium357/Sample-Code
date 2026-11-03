# Nim 1.6+; nim c -r stable_merge.nim or nim js -r stable_merge.nim.
# Finite, already-sorted sequences; comparator must define a consistent order.
# Inputs are validated before output. Equal keys from the left input come first.
import std/[algorithm, sequtils]

proc mergeSorted*[T](left, right: openArray[T],
    compare: proc(a, b: T): int {.closure.}): seq[T] =
  for values in [@left, @right]:
    for i in 1 ..< values.len:
      if compare(values[i-1], values[i]) > 0:
        raise newException(ValueError, "input is not sorted")
  var i, j = 0
  while i < left.len and j < right.len:
    if compare(left[i], right[j]) <= 0:
      result.add left[i]
      inc i
    else:
      result.add right[j]
      inc j
  while i < left.len:
    result.add left[i]
    inc i
  while j < right.len:
    result.add right[j]
    inc j

iterator runsOf*[T](values: openArray[T]): tuple[value: T, count: int] =
  ## Adjacent equality runs, including one run when all elements are equal.
  var i = 0
  while i < values.len:
    var stop = i+1
    while stop < values.len and values[stop] == values[i]: inc stop
    yield (values[i], stop-i)
    i = stop

when isMainModule:
  proc order(a, b: int): int = cmp(a, b)
  doAssert mergeSorted[int]([], [], order) == newSeq[int]()
  doAssert mergeSorted[int]([], [1, 2], order) == @[1, 2]
  doAssert mergeSorted[int]([1, 2], [], order) == @[1, 2]
  doAssert toSeq(runsOf(newSeq[int]())).len == 0
  doAssert toSeq(runsOf(@[2, 2, 3, 2])) == @[(2, 2), (3, 1), (2, 1)]
  doAssert toSeq(runsOf(@["x", "x"])) == @[("x", 2)]
  for bad in [@[2, 1], @[0, 1, 0]]:
    for side in 0..1:
      var rejected = false
      try:
        if side == 0: discard mergeSorted(bad, @[1], order)
        else: discard mergeSorted(@[1], bad, order)
      except ValueError: rejected = true
      doAssert rejected
  # Independent oracle: concatenate then sort, rather than another merge.
  for n in 0..30:
    for m in 0..30:
      var left, right: seq[int]
      for i in 0..<n: left.add (i*17+n) mod 11 - 5
      for j in 0..<m: right.add (j*13+m) mod 11 - 5
      left.sort(); right.sort()
      let savedLeft = left.mapIt(it)
      let savedRight = right.mapIt(it)
      var expected = left & right
      expected.sort()
      doAssert mergeSorted(left, right, order) == expected
      doAssert left == savedLeft and right == savedRight
  type Entry = tuple[key: int, label: string]
  proc byKey(a, b: Entry): int = cmp(a.key, b.key)
  let left: seq[Entry] = @[(1, "L1"), (1, "L2"), (3, "L3")]
  let right: seq[Entry] = @[(1, "R1"), (2, "R2"), (3, "R3")]
  doAssert mergeSorted(left, right, byKey) == @[
    (1, "L1"), (1, "L2"), (1, "R1"), (2, "R2"), (3, "L3"), (3, "R3")]
  echo "Nim merge: 961 sort-oracle comparisons, stable ties, generic runs and rejected unsorted inputs passed"
