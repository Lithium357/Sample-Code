# Nim 1.6+ syntax; nim c -r wire_schema.nim or nim js -r wire_schema.nim.
# A compile-time DSL produces enum-specific parsers and serializers. Wire values
# are exact 1..8 visible ASCII bytes. Names differing only by case/underscores
# are conservatively rejected. No textual source concatenation or runtime eval.
# Definitions must be literal (identifier, ordinary string literal) tuples.
import std/[macros, options, strutils]

macro defineTokens(name, definitions: untyped): untyped =
  expectKind(name, nnkIdent)
  expectKind(definitions, nnkBracket)
  if definitions.len == 0: error("schema must be nonempty", definitions)
  var names, wires: seq[string]
  let enumeration = newTree(nnkEnumTy, newEmptyNode())
  let input = genSym(nskParam, "text")
  let value = genSym(nskParam, "value")
  let parseBody = newStmtList()
  let wireBody = newTree(nnkCaseStmt, value)
  for entry in definitions:
    expectKind(entry, nnkTupleConstr)
    expectLen(entry, 2)
    expectKind(entry[0], nnkIdent)
    expectKind(entry[1], nnkStrLit)
    let normalized = entry[0].strVal.replace("_", "").toLowerAscii
    let spelling = entry[1].strVal
    if normalized in names: error("normalized enum name collision", entry[0])
    if spelling in wires: error("duplicate wire value", entry[1])
    if spelling.len < 1 or spelling.len > 8: error("wire length outside 1..8", entry[1])
    for c in spelling:
      if ord(c) < 33 or ord(c) > 126: error("wire value must use visible ASCII", entry[1])
    names.add normalized
    wires.add spelling
    let symbol = entry[0].copyNimTree
    let literal = newLit(spelling)
    enumeration.add symbol
    parseBody.add quote do:
      if `input` == `literal`: return some(`symbol`)
    wireBody.add newTree(nnkOfBranch, symbol, newStmtList(newTree(nnkReturnStmt, literal)))
  parseBody.add quote do:
    return none(`name`)
  let parseName = ident("parse" & name.strVal)
  let wireName = ident("wire" & name.strVal)
  result = newStmtList(newTree(nnkTypeSection,
    newTree(nnkTypeDef, name, newEmptyNode(), enumeration)))
  result.add quote do:
    proc `parseName`(`input`: string): Option[`name`] =
      `parseBody`
    proc `wireName`(`value`: `name`): string =
      `wireBody`

defineTokens JobState, [(queued, "Q"), (running, "RUN"), (finished, "DONE")]
defineTokens Direction, [(north, "N"), (east, "E"), (south, "S"), (west, "W")]
defineTokens LiteralToken, [(quoteMark, "\""), (slashMark, "\\"), (metaMark, "[x]")]
defineTokens BoundaryToken, [(eightMarker, "12345678")]

doAssert parseJobState("Q") == some(queued)
doAssert parseJobState("RUN") == some(running)
doAssert parseJobState("DONE") == some(finished)
doAssert wireJobState(queued) == "Q"
doAssert wireJobState(running) == "RUN"
doAssert wireJobState(finished) == "DONE"
for state in JobState: doAssert parseJobState(wireJobState(state)) == some(state)
for direction in Direction: doAssert parseDirection(wireDirection(direction)) == some(direction)
for bad in ["", "q", "Q ", " Q", "Q\0", "RUN\n", "unknown"]:
  doAssert parseJobState(bad).isNone
doAssert parseLiteralToken("\"") == some(quoteMark)
doAssert parseLiteralToken("\\") == some(slashMark)
doAssert wireLiteralToken(metaMark) == "[x]"
doAssert parseDirection("N") == some(north)
doAssert wireDirection(west) == "W"
doAssert parseBoundaryToken("12345678") == some(eightMarker)
doAssert wireBoundaryToken(eightMarker) == "12345678"

static:
  # Rejection checks are compiler semantic checks, not runtime exceptions.
  doAssert not compiles(block:
    defineTokens Empty, [])
  doAssert not compiles(block:
    defineTokens Names, [(someName, "A"), (some_name, "B")])
  doAssert not compiles(block:
    defineTokens Wires, [(one, "A"), (two, "A")])
  doAssert not compiles(block:
    defineTokens Blank, [(one, "")])
  doAssert not compiles(block:
    defineTokens Space, [(one, "a b")])
  doAssert not compiles(block:
    defineTokens Long, [(one, "123456789")])
  doAssert not compiles(block:
    defineTokens Shape, [("notAnIdentifier", "A")])
  doAssert not compiles(block:
    defineTokens ValueType, [(one, 123)])
  doAssert not compiles(block:
    defineTokens NonAscii, [(one, "é")])
  doAssert not compiles(wireJobState(north))
echo "Nim schema: generated typed parsers, exhaustive serializers, escaped literals, nine schema rejections and one typed API rejection passed"
