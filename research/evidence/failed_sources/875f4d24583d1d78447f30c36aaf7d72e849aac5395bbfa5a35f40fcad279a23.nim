# Nim 1.6+: module API using sequences, options, a generic iterator and tables.
import std/[json, options, tables, strutils]
type Reading* = object
  name*: string
  amount*: Option[int]

iterator present*[T](values: openArray[Option[T]]): T =
  for value in values:
    if value.isSome: yield value.get()

iterator readings*(text: string): Reading =
  var lineNumber=0
  for line in text.splitLines():
    inc lineNumber
    if line.strip().len==0: continue
    var node: JsonNode
    try: node=parseJson(line)
    except JsonParsingError: raise newException(ValueError,"JSON line " & $lineNumber)
    if node.kind!=JObject or node.len!=2 or not node.hasKey("name") or not node.hasKey("amount"):
      raise newException(ValueError,"record fields")
    if node["name"].kind!=JString or node["name"].getStr().len==0:
      raise newException(ValueError,"record name")
    var amount=none(int)
    if node["amount"].kind==JInt:
      let value=node["amount"].getBiggestInt()
      if value<0 or value>1000: raise newException(ValueError,"amount range")
      amount=some(int(value))
    elif node["amount"].kind!=JNull: raise newException(ValueError,"amount type")
    yield Reading(name: node["name"].getStr(),amount: amount)

proc totals*(text: string): Table[string,int] =
  result=initTable[string,int]()
  var count=0
  for row in readings(text):
    inc count
    if count>1000: raise newException(ValueError,"record limit")
    if row.amount.isSome: result[row.name]=result.getOrDefault(row.name)+row.amount.get()
