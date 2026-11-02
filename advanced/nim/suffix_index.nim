# Byte-oriented suffix array, Kasai LCP, binary-search occurrence indexing.
# nim c -r suffix_index.nim; no third-party packages. O(n log^2 n) construction.
import std/[algorithm, sequtils]

type SuffixIndex = object
  text: string
  suffixes, lcp: seq[int]

proc build(text: string): SuffixIndex =
  if text.len > 4096: raise newException(ValueError, "demo size limit")
  result.text = text
  let n = text.len
  result.suffixes = toSeq(0..<n)
  result.lcp = newSeq[int](max(0, n-1))
  if n == 0: return
  var ranks = newSeq[int](n)
  for i in 0..<n: ranks[i] = ord(text[i])
  var width = 1
  while width < n:
    proc compare(a, b: int): int =
      if ranks[a] != ranks[b]: return cmp(ranks[a], ranks[b])
      let ar = if a+width < n: ranks[a+width] else: -1
      let br = if b+width < n: ranks[b+width] else: -1
      cmp(ar, br)
    result.suffixes.sort(compare)
    var next = newSeq[int](n)
    for i in 1..<n:
      next[result.suffixes[i]] = next[result.suffixes[i-1]]
      if compare(result.suffixes[i-1], result.suffixes[i]) != 0:
        inc next[result.suffixes[i]]
    ranks = next
    if ranks[result.suffixes[^1]] == n-1: break
    width *= 2
  var inverse = newSeq[int](n)
  for position, index in result.suffixes: inverse[index] = position
  var shared = 0
  for index in 0..<n:
    let position = inverse[index]
    if position == n-1: shared = 0; continue
    let other = result.suffixes[position+1]
    while index+shared < n and other+shared < n and text[index+shared] == text[
        other+shared]: inc shared
    result.lcp[position] = shared
    if shared > 0: dec shared

proc comparePrefix(index: SuffixIndex; start: int; pattern: string): int =
  for i in 0..<pattern.len:
    if start+i >= index.text.len: return -1
    let order = cmp(ord(index.text[start+i]), ord(pattern[i]))
    if order != 0: return order
  0

proc occurrences(index: SuffixIndex; pattern: string): seq[int] =
  if pattern.len == 0: return toSeq(0..index.text.len)
  var low = 0
  var high = index.suffixes.len
  while low < high:
    let middle = low+(high-low) div 2
    if index.comparePrefix(index.suffixes[middle], pattern) < 0: low = middle+1
    else: high = middle
  let first = low
  high = index.suffixes.len
  while low < high:
    let middle = low+(high-low) div 2
    if index.comparePrefix(index.suffixes[middle], pattern) <= 0: low = middle+1
    else: high = middle
  for i in first..<low: result.add(index.suffixes[i])
  result.sort()

proc naive(text, pattern: string): seq[int] =
  for start in 0..text.len:
    if start+pattern.len > text.len: continue
    var matches = true
    for i in 0..<pattern.len:
      if text[start+i] != pattern[i]: matches = false; break
    if matches: result.add(start)

when isMainModule:
  let banana = build("banana")
  doAssert banana.suffixes == @[5, 3, 1, 0, 4, 2]
  doAssert banana.lcp == @[1, 3, 0, 0, 2]
  doAssert banana.occurrences("ana") == @[1, 3]
  var seed = 107
  for trial in 0..<200:
    var text = ""
    for i in 0..<(trial mod 61):
      seed = (seed*251+17) mod 10007
      text.add(char(seed mod 4)) # Includes embedded NUL bytes.
    let index = build(text)
    var expected = toSeq(0..<text.len)
    expected.sort(proc(a, b: int): int = cmp(text[a..^1], text[b..^1]))
    doAssert index.suffixes == expected
    for i in 0..<index.lcp.len:
      var common = 0
      let a = index.suffixes[i]
      let b = index.suffixes[i+1]
      while a+common < text.len and b+common < text.len and text[a+common] ==
          text[b+common]: inc common
      doAssert common == index.lcp[i]
    for length in 0..5:
      var pattern = ""
      for i in 0..<length:
        seed = (seed*251+17) mod 10007; pattern.add(char(seed mod 4))
      doAssert index.occurrences(pattern) == naive(text, pattern)
  echo "Suffix index: 200 naive-array/LCP comparisons and 1200 pattern searches passed"
