# Native fixture driver. Imports the public module; privateAccess is explicitly
# test-only for handle observation and deterministic byte-reader fault injection.
# Compile with C backend, ARC: nim c --gc:arc -r test_scoped_lines.nim
import std/[options, os, tempfiles, strutils, importutils]
import scoped_lines
when defined(windows):
  import winlean
else:
  import std/posix
privateAccess(LineReader)

var checks = 0
proc check(condition: bool, label: string) =
  if not condition: raise newException(ValueError, "failed: " & label)
  inc checks

proc nativeAlive(handle: FileHandle): bool =
  when defined(windows):
    stderr.writeLine("handle probe begin " & $handle)
    stderr.flushFile()
    var flags: DWORD
    result = getHandleInformation(Handle(handle), addr flags) != 0
    stderr.writeLine("handle probe result " & $result)
    stderr.flushFile()
  else:
    result = posix.fcntl(handle, F_GETFD) != -1

proc reference(text: string): seq[string] =
  if text.len == 0: return @[]
  result = text.split('\n')
  if text[^1] == '\n': result.setLen(result.len - 1)

let base = getCurrentDir().absolutePath.normalizedPath
let directory = createTempDir("scoped lines ", "", base).absolutePath.normalizedPath
check(directory.parentDir == base, "owned temporary path")
let path = directory / "bytes with spaces.bin"
let absent = directory / "absent.bin"

try:
  var binary = ""
  for value in 0..255:
    if value != 10: binary.add char(value)
  let texts = @["", "\n", "\n\n", "a", "a\n", "a\n\nz", "a\r\n", "\x00\xff\n",
                binary, repeat('x', 1024), repeat('x', 1025), "ok\n" & repeat('z', 1025)]
  for text in texts:
    writeFile(path, text)
    for limit in [1, 2, 3, 255, 1024]:
      var expected: seq[string] = @[]
      var oversized = false
      for line in reference(text):
        if line.len > limit:
          oversized = true
          break
        expected.add line
      var actual: seq[string] = @[]
      var rejected = false
      var native: FileHandle
      var escaped: LineReader
      try:
        withLines[void](path, limit, proc(reader: LineReader) =
          escaped = reader
          native = getOsFileHandle(reader.file)
          check(nativeAlive(native), "native handle starts open")
          while true:
            let line = reader.nextLine()
            if line.isNone: break
            actual.add line.get()
          let before = reader.readCalls
          let again = reader.nextLine()
          check(again.isNone and reader.readCalls == before, "cached EOF performs no read")
        )
      except LineTooLong:
        rejected = true
      check(not nativeAlive(native), "native file closed")
      check(not escaped.isOpen, "logical reader closed")
      check(actual == expected and rejected == oversized, "independent LF prefix oracle")
      var closed = false
      try: discard escaped.nextLine()
      except ReaderClosed: closed = true
      check(closed, "escaped reader rejects reads")

  writeFile(path, "abc\n")
  var native: FileHandle
  withLines[void](path, 2, proc(reader: LineReader) =
    native = getOsFileHandle(reader.file)
    var tooLong = false
    try: discard reader.nextLine()
    except LineTooLong: tooLong = true
    let before = reader.readCalls
    var poisoned = false
    try: discard reader.nextLine()
    except ReaderPoisoned: poisoned = true
    check(tooLong and poisoned and before == 3 and reader.readCalls == before, "oversize poisons without retry")
  )
  check(not nativeAlive(native), "caught oversize still closes file")

  writeFile(path, "a\nz")
  let ioFault = newException(IOError, "owned injected read failure")
  var prefix = ""
  withLines[void](path, 10, proc(reader: LineReader) =
    native = getOsFileHandle(reader.file)
    let original = reader.readByte
    var calls = 0
    reader.readByte = proc(): char =
      inc calls
      if calls == 3: raise ioFault
      original()
    prefix = reader.nextLine().get()
    var same = false
    try: discard reader.nextLine()
    except IOError as error: same = cast[pointer](error) == cast[pointer](ioFault)
    let before = reader.readCalls
    var poisoned = false
    try: discard reader.nextLine()
    except ReaderPoisoned: poisoned = true
    check(same and poisoned and calls == 3 and before == reader.readCalls, "I/O error identity and poison")
  )
  check(prefix == "a" and not nativeAlive(native), "published prefix survives read error and cleanup")

  let bodyFault = newException(ValueError, "owned callback failure")
  var bodySame = false
  try:
    discard withLines[int](path, 10, proc(reader: LineReader): int =
      native = getOsFileHandle(reader.file)
      discard reader.nextLine()
      raise bodyFault
    )
  except ValueError as error: bodySame = cast[pointer](error) == cast[pointer](bodyFault)
  check(bodySame and not nativeAlive(native), "callback exception identity and native cleanup")

  let escaped = withLines[LineReader](path, 10, proc(reader: LineReader): LineReader = reader)
  check(not escaped.isOpen, "generic ref result is closed")
  let total = withLines[int](path, 10, proc(reader: LineReader): int =
    while true:
      let line = reader.nextLine()
      if line.isNone: break
      result += line.get().len
  )
  check(total == 2, "generic integer result")

  var invoked = 0
  for limit in [0, 1025]:
    var rejected = false
    try:
      discard withLines[int](absent, limit, proc(reader: LineReader): int =
        inc invoked
        0
      )
    except ValueError: rejected = true
    check(rejected, "argument before open")
  let missingBody: proc(reader: LineReader): int {.closure.} = nil
  var badBody = false
  try: discard withLines[int](absent, 1, missingBody)
  except ValueError: badBody = true
  check(badBody, "nil body before open")
  var openFailed = false
  try:
    discard withLines[int](absent, 1, proc(reader: LineReader): int =
      inc invoked
      0
    )
  except IOError: openFailed = true
  check(openFailed and invoked == 0, "open failure never invokes body")
  var nilReader: LineReader
  var nilClosed = false
  try: discard nilReader.nextLine()
  except ReaderClosed: nilClosed = true
  check(nilClosed and not nilReader.isOpen, "nil reader contract")
finally:
  # Failed mutation processes may still hold a file until process teardown.
  # Never mask the primary assertion; Python's owned scratch cleans after exit.
  try:
    if fileExists(path): removeFile(path)
    if dirExists(directory): removeDir(directory)
  except OSError: discard
echo "scoped lines: ", checks, " checks passed"
