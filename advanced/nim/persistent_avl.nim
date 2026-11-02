# Immutable AVL map with path copying, deletion and historical snapshots.
# nim c -r persistent_avl.nim (or nim js then node persistent_avl.js)
import std/[options, tables, algorithm]

type
  Node = ref object
    key, value, height: int
    left, right: Node
  Pair = tuple[key, value: int]

proc height(n: Node): int =
  if n.isNil: 0 else: n.height

proc make(key, value: int; left, right: Node): Node =
  Node(key: key, value: value, left: left, right: right,
       height: 1 + max(height(left), height(right)))

proc rotateLeft(n: Node): Node =
  let top = n.right
  make(top.key, top.value,
       make(n.key, n.value, n.left, top.left), top.right)

proc rotateRight(n: Node): Node =
  let top = n.left
  make(top.key, top.value, top.left,
       make(n.key, n.value, top.right, n.right))

proc balance(n: Node): Node =
  let difference = height(n.left) - height(n.right)
  if difference > 1:
    if height(n.left.left) < height(n.left.right):
      return rotateRight(make(n.key, n.value, rotateLeft(n.left), n.right))
    return rotateRight(n)
  if difference < -1:
    if height(n.right.right) < height(n.right.left):
      return rotateLeft(make(n.key, n.value, n.left, rotateRight(n.right)))
    return rotateLeft(n)
  n

proc put(n: Node; key, value: int): Node =
  if n.isNil: return make(key, value, nil, nil)
  if key < n.key:
    return balance(make(n.key, n.value, put(n.left, key, value), n.right))
  if key > n.key:
    return balance(make(n.key, n.value, n.left, put(n.right, key, value)))
  make(key, value, n.left, n.right)

proc erase(n: Node; key: int): Node =
  if n.isNil: return nil
  if key < n.key:
    return balance(make(n.key, n.value, erase(n.left, key), n.right))
  if key > n.key:
    return balance(make(n.key, n.value, n.left, erase(n.right, key)))
  if n.left.isNil: return n.right
  if n.right.isNil: return n.left
  var successor = n.right
  while not successor.left.isNil: successor = successor.left
  balance(make(successor.key, successor.value, n.left,
               erase(n.right, successor.key)))

proc lookup(n: Node; key: int): Option[int] =
  var current = n
  while not current.isNil:
    if key == current.key: return some(current.value)
    current = if key < current.key: current.left else: current.right
  none(int)

proc entries(n: Node; output: var seq[Pair]) =
  if n.isNil: return
  entries(n.left, output)
  output.add((n.key, n.value))
  entries(n.right, output)

proc audit(n: Node): int =
  if n.isNil: return 0
  let lh = audit(n.left)
  let rh = audit(n.right)
  doAssert abs(lh - rh) <= 1, "unbalanced subtree"
  doAssert n.height == 1 + max(lh, rh), "stale height"
  if not n.left.isNil: doAssert n.left.key < n.key
  if not n.right.isNil: doAssert n.right.key > n.key
  n.height

proc referenceEntries(reference: Table[int, int]): seq[Pair] =
  for key, value in reference: result.add((key, value))
  result.sort(proc(a, b: Pair): int = cmp(a.key, b.key))

proc check(n: Node; expected: seq[Pair]) =
  discard audit(n)
  var actual: seq[Pair]
  entries(n, actual)
  doAssert actual == expected, "inorder contents differ from reference map"
  for pair in expected: doAssert lookup(n, pair.key) == some(pair.value)

when isMainModule:
  var root: Node
  var reference = initTable[int, int]()
  var snapshots: seq[tuple[root: Node, expected: seq[Pair]]]
  var seed = 23
  for step in 0..<1200:
    seed = (seed * 251 + 17) mod 10007
    let key = seed mod 101 - 50
    if step mod 3 == 0:
      root = erase(root, key)
      reference.del(key)
    else:
      root = put(root, key, step)
      reference[key] = step
    check(root, referenceEntries(reference))
    if step mod 37 == 0: snapshots.add((root, referenceEntries(reference)))
  for snapshot in snapshots: check(snapshot.root, snapshot.expected)
  # Force each rotation shape, then delete every key while retaining the old root.
  for order in [@[3, 2, 1], @[1, 2, 3], @[3, 1, 2], @[1, 3, 2]]:
    var tree: Node
    for key in order: tree = put(tree, key, key * 10)
    let historical = tree
    for key in order:
      tree = erase(tree, key)
      discard audit(tree)
    doAssert tree.isNil
    check(historical, @[(1, 10), (2, 20), (3, 30)])
  doAssert lookup(root, 10000).isNone
  echo "Persistent AVL: 1200 reference-checked mutations and immutable snapshots passed"
