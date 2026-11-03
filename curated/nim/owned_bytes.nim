# Nim native C backend with ARC, not JavaScript. Example build:
# nim c --mm:arc -r owned_bytes.nim
# A move-only owned allocation with destructor hooks and lexical borrows.
# Index access copies a byte, never exposes a pointer that could outlive its
# owner. Audit refs keep counters alive across moves; there is no shared mutable
# buffer ownership or multithreaded access contract. Zero length owns no storage.
type
  Audit = ref object
    allocations, releases: int
  OwnedBytes = object
    data: ptr UncheckedArray[byte]
    count: int
    audit: Audit

proc `=destroy`(buffer: var OwnedBytes) =
  if buffer.data != nil:
    dealloc(buffer.data)
    buffer.data = nil
    inc buffer.audit.releases
  buffer.count = 0
  buffer.audit = nil

proc `=copy`(dest: var OwnedBytes; source: OwnedBytes) {.error:
  "OwnedBytes is move-only; use move or borrow".}

proc `=sink`(dest: var OwnedBytes; source: OwnedBytes) =
  `=destroy`(dest)
  dest.data = source.data
  dest.count = source.count
  dest.audit = source.audit
  # The compiler marks the source moved; do not destroy the transferred pointer.

proc owned(count: int; audit: Audit): OwnedBytes =
  if count < 0 or count > 65536:
    raise newException(ValueError, "byte count outside 0..65536")
  if audit.isNil:
    raise newException(ValueError, "audit required")
  result.audit = audit
  result.count = count
  if count > 0:
    result.data = cast[ptr UncheckedArray[byte]](alloc0(count))
    inc audit.allocations

proc len(buffer: OwnedBytes): int = buffer.count

proc at(buffer: OwnedBytes; index: int): byte =
  if index < 0 or index >= buffer.count:
    raise newException(IndexDefect, "byte index outside owned allocation")
  buffer.data[index]

proc put(buffer: var OwnedBytes; index: int; value: byte) =
  if index < 0 or index >= buffer.count:
    raise newException(IndexDefect, "byte index outside owned allocation")
  buffer.data[index] = value

proc checksum(buffer: OwnedBytes): int =
  # Borrowing parameters do not invoke the forbidden copy hook.
  for i in 0..<buffer.len:
    result += int(buffer.at(i))

proc transfer(buffer: sink OwnedBytes): OwnedBytes =
  result = move(buffer)

proc expectIndex(buffer: OwnedBytes; index: int) =
  var caught = false
  try: discard buffer.at(index)
  except IndexDefect: caught = true
  doAssert caught

when isMainModule:
  let audit = Audit()
  block:
    var source = owned(4, audit)
    doAssert source.len == 4 and checksum(source) == 0
    source.put(0, 0)
    source.put(1, 255)
    source.put(2, 65)
    source.put(3, 10)
    doAssert checksum(source) == 330
    expectIndex(source, -1)
    expectIndex(source, 4)
    var target = transfer(move(source))
    doAssert source.len == 0 and target.len == 4
    expectIndex(source, 0)
    doAssert checksum(target) == 330
    doAssert audit.allocations == 1 and audit.releases == 0
    var replacement = owned(2, audit)
    replacement.put(0, 7)
    replacement = move(target) # release old allocation before adoption
    doAssert target.len == 0 and checksum(replacement) == 330
    doAssert audit.allocations == 2 and audit.releases == 1
    # Reuse moved-from values instead of letting accidental copies look valid.
    target = owned(1, audit)
    target.put(0, 99)
    doAssert checksum(target) == 99
    var empty = owned(0, audit)
    doAssert empty.len == 0 and checksum(empty) == 0
    expectIndex(empty, 0)
    empty = move(replacement)
    doAssert checksum(empty) == 330 and replacement.len == 0
  doAssert audit.allocations == 3 and audit.releases == 3

  for bad in [-1, 65537]:
    var rejected = false
    try: discard owned(bad, audit)
    except ValueError: rejected = true
    doAssert rejected
  var rejected = false
  try: discard owned(1, nil)
  except ValueError: rejected = true
  doAssert rejected and audit.allocations == 3

  try:
    var exceptional = owned(3, audit)
    exceptional.put(2, 41)
    doAssert checksum(exceptional) == 41
    raise newException(ValueError, "fixture unwind")
  except ValueError as error:
    doAssert error.msg == "fixture unwind"
  doAssert audit.allocations == 4 and audit.releases == 4

  block:
    var buffers: seq[OwnedBytes] = @[]
    for i in 0..<40:
      var buffer = owned(i mod 5, audit)
      if buffer.len > 0: buffer.put(0, byte(i))
      buffers.add(move(buffer))
      doAssert buffer.len == 0
    for i in 0..<buffers.len:
      let expected = if i mod 5 == 0: 0 else: i
      doAssert checksum(buffers[i]) == expected
    doAssert audit.releases == 4
    buffers.setLen(3)
    doAssert audit.releases == 34 # only two nonempty of the retained three
  doAssert audit.allocations == 36 and audit.releases == 36
  echo "owned bytes: borrows, moves, bounds, shrinking and unwind passed"
