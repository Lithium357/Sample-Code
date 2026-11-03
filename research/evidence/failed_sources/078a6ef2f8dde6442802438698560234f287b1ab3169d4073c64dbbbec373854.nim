# Run: nim c -r test_record_stream.nim (or compile with the JS backend).
import std/[options, tables, sequtils, strutils]
import record_stream
let result=totals("{\"name\": \"pen\",\"amount\": 2}\n\n{\"name\": \"pen\",\"amount\": 3}\n{\"name\": \"ink\",\"amount\": null}\n")
doAssert result.len==1 and result["pen"]==5
doAssert totals("").len==0
let line="{\"name\": \"x\",\"amount\": 1}\n"
doAssert totals(line.repeat(1000))["x"]==1000
var tooMany=false
try: discard totals(line.repeat(1001))
except ValueError: tooMany=true
doAssert tooMany
doAssert toSeq(present(@[some(1),none(int),some(3)]))== @[1,3]
doAssert toSeq(present(@[some("a"),none(string),some("b")]))== @["a","b"]
for malformed in ["{bad","[]","{}","{\"name\": \"x\",\"amount\": 1.5}","{\"name\": \"x\",\"amount\": -1}"]:
  var rejected=false
  try: discard totals(malformed)
  except ValueError: rejected=true
  doAssert rejected
echo "Nim records: module boundaries, generic iterator, options, totals and malformed input passed"
