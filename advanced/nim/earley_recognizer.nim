# Earley CFG recognition with nullable productions and left recursion.
# nim c -r earley_recognizer.nim; no parse forest is constructed.
# Symbols >=0 are nonterminals; negative symbols encode -(byte+1).
# General CFG recognition has cubic worst-case time. Demo caps input and states.
import std/[sets]

type
  Rule = object
    lhs: int
    rhs: seq[int]
  Item = tuple[rule, dot, origin: int]

proc terminal(c: char): int = -ord(c)-1

proc accepts(input: string; grammar: seq[Rule]; start: int): bool =
  if input.len > 80 or grammar.len > 100: raise newException(ValueError, "demo limits")
  var defined = initHashSet[int]()
  var largest = start
  for rule in grammar:
    if rule.lhs < 0: raise newException(ValueError, "negative nonterminal")
    defined.incl(rule.lhs); largest = max(largest, rule.lhs)
  if start notin defined: raise newException(ValueError, "missing start rule")
  for rule in grammar:
    for symbol in rule.rhs:
      if symbol >= 0 and symbol notin defined: raise newException(ValueError, "undefined nonterminal")
      if symbol < -256: raise newException(ValueError, "invalid byte terminal")
  var rules = grammar
  rules.add(Rule(lhs: largest+1, rhs: @[start]))
  let augmented = rules.len-1
  var chart = newSeq[seq[Item]](input.len+1)
  var seen = newSeq[HashSet[Item]](input.len+1)
  var total = 0
  proc add(position: int; item: Item) =
    if item notin seen[position]:
      if total >= 200000: raise newException(ValueError, "state limit")
      seen[position].incl(item); chart[position].add(item); inc total
  add(0, (augmented, 0, 0))
  for position in 0..input.len:
    var cursor = 0
    while cursor < chart[position].len:
      let item = chart[position][cursor]; inc cursor
      let production = rules[item.rule]
      if item.dot == production.rhs.len:
        let count = chart[item.origin].len
        for j in 0..<count:
          let parent = chart[item.origin][j]
          let rule = rules[parent.rule]
          if parent.dot < rule.rhs.len and rule.rhs[parent.dot] ==
              production.lhs:
            add(position, (parent.rule, parent.dot+1, parent.origin))
      else:
        let symbol = production.rhs[item.dot]
        if symbol < 0:
          if position < input.len and terminal(input[position]) == symbol:
            add(position+1, (item.rule, item.dot+1, item.origin))
        else:
          for id, rule in rules:
            if rule.lhs == symbol: add(position, (id, 0, position))
          # A nullable completion may already have been processed before this
          # waiting item was discovered. Pair it immediately to reach a fixed
          # point regardless of production ordering.
          let count = chart[position].len
          for j in 0..<count:
            let completed = chart[position][j]
            let rule = rules[completed.rule]
            if completed.origin == position and completed.dot ==
                rule.rhs.len and rule.lhs == symbol:
              add(position, (item.rule, item.dot+1, item.origin))
  (augmented, 1, 0) in seen[input.len]

when isMainModule:
  let open = terminal('(')
  let close = terminal(')')
  # S -> S S | '(' S ')' | epsilon (ambiguous, left recursive and nullable).
  let balanced = @[Rule(lhs: 0, rhs: @[0, 0]), Rule(lhs: 0, rhs: @[open, 0,
      close]), Rule(lhs: 0, rhs: @[])]
  for length in 0..10:
    for bits in 0..<(1 shl length):
      var text = ""; var depth = 0; var valid = true
      for i in 0..<length:
        if (bits and (1 shl i)) == 0: text.add('('); inc depth
        else: text.add(')'); dec depth
        if depth < 0: valid = false
      valid = valid and depth == 0
      doAssert accepts(text, balanced, 0) == valid
  # Indirect nullable cycle: S->A A, A->B, B->A | epsilon | 'x'.
  let cyclic = @[Rule(lhs: 0, rhs: @[1, 1]), Rule(lhs: 1, rhs: @[2]),
    Rule(lhs: 2, rhs: @[1]), Rule(lhs: 2, rhs: @[]), Rule(lhs: 2, rhs: @[
        terminal('x')])]
  for text in ["", "x", "xx"]: doAssert accepts(text, cyclic, 0)
  doAssert not accepts("xxx", cyclic, 0)
  # Left-recursive expression grammar: E->E+T|T, T->T*F|F, F->n|(E).
  let expr = @[Rule(lhs: 0, rhs: @[0, terminal('+'), 1]), Rule(lhs: 0, rhs: @[1]),
    Rule(lhs: 1, rhs: @[1, terminal('*'), 2]), Rule(lhs: 1, rhs: @[2]),
    Rule(lhs: 2, rhs: @[terminal('n')]), Rule(lhs: 2, rhs: @[open, 0, close])]
  for text in ["n", "n+n*n", "(n+n)*n"]: doAssert accepts(text, expr, 0)
  for text in ["", "n+", "*n", "n(n)", "(n"]: doAssert not accepts(text, expr, 0)
  echo "Earley: 2047 balanced-language oracle strings, nullable cycles and left recursion passed"
