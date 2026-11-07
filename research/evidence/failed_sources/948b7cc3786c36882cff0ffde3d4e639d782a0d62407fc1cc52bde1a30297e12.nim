# Native Nim 1.6+ C backend, stdio regular-file reader. No JavaScript target.
# LF terminates records; CR, NUL and all other bytes are data, not Unicode text.
# A final nonempty unterminated record is returned; trailing LF adds no record.
# Limit 1..1024 counts data bytes. Oversize/read failure poisons this reader:
# no partial current record is returned, prior callback effects remain visible.
# withLines owns the file; references may escape but reject reads after closure.
# Synchronous/nonconcurrent only. No rollback, file snapshot, fatal-process
# cleanup or close-failure exception-priority guarantee.
import std/options

type
  ReaderClosed* = object of IOError
  ReaderPoisoned* = object of IOError
  LineTooLong* = object of IOError
  LineReader* = ref object
    file: File
    opened, poisoned, ended: bool
    limit, readCalls: int
    readByte: proc(): char {.closure.}

proc isOpen*(reader: LineReader): bool =
  not reader.isNil and reader.opened

proc nextLine*(reader: LineReader): Option[string] =
  if not reader.isOpen:
    raise newException(ReaderClosed, "reader is closed")
  if reader.poisoned:
    raise newException(ReaderPoisoned, "reader is poisoned")
  if reader.ended: return none(string)
  var line = ""
  while true:
    var value: char
    try:
      inc reader.readCalls
      value = reader.readByte()
    except EOFError:
      reader.ended = true
      return if line.len == 0: none(string) else: some(line)
    except IOError:
      reader.poisoned = true
      raise
    if value == '\n': return some(line)
    if line.len == reader.limit:
      reader.poisoned = true
      raise newException(LineTooLong, "line exceeds byte limit")
    line.add value

proc withLines*[T](path: string, limit: int,
                   body: proc(reader: LineReader): T {.closure.}): T =
  if limit < 1 or limit > 1024:
    raise newException(ValueError, "limit must be 1..1024")
  if body == nil:
    raise newException(ValueError, "body must not be nil")
  let reader = LineReader(limit: limit)
  if not open(reader.file, path, fmRead):
    raise newException(IOError, "cannot open fixture input")
  reader.opened = true
  defer:
    try:
      close(reader.file)
    finally:
      reader.opened = false
      reader.file = nil
      reader.readByte = nil
  let openedFile = reader.file
  reader.readByte = proc(): char = readChar(openedFile)
  when T is void:
    body(reader)
  else:
    result = body(reader)
