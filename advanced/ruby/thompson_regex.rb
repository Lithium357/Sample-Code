# Regex compiler and epsilon-NFA simulation, avoiding exponential backtracking.
# ruby thompson_regex.rb
# Supports literals, escapes, ., grouping, alternation, *, +, ?. Full-string
# matching; dot includes newlines. No character classes, anchors or captures.
require 'set'

class RegexSyntax < StandardError; end
class TinyRegex
  ANY = Object.new.freeze

  def initialize(pattern)
    raise RegexSyntax, 'pattern too long' if pattern.length > 512
    @chars = pattern.chars
    @cursor = 0
    @edges = []
    tree = alternative(0)
    raise RegexSyntax, 'unexpected closing parenthesis' unless peek.nil?
    @start, @finish = compile(tree)
  end

  def match?(text)
    current = closure(Set[@start])
    text.each_char do |character|
      following = Set.new
      current.each do |state|
        @edges[state].each do |label, target|
          following.add(target) if label.equal?(ANY) || label == character
        end
      end
      current = closure(following)
      return false if current.empty?
    end
    current.include?(@finish)
  end

  private

  def peek = @chars[@cursor]
  def take
    character = peek
    @cursor += 1
    character
  end

  def alternative(depth)
    raise RegexSyntax, 'nesting limit' if depth > 64
    left = concatenation(depth)
    while peek == '|'
      take
      left = [:or, left, concatenation(depth)]
    end
    left
  end

  def concatenation(depth)
    pieces = []
    until peek.nil? || peek == ')' || peek == '|'
      node = atom(depth)
      if ['*', '+', '?'].include?(peek)
        node = [take, node]
        raise RegexSyntax, 'stacked quantifiers' if ['*', '+', '?'].include?(peek)
      end
      pieces << node
    end
    pieces.reduce([:empty]) { |left, right| [:concat, left, right] }
  end

  def atom(depth)
    character = take
    case character
    when '('
      node = alternative(depth + 1)
      raise RegexSyntax, 'unclosed group' unless take == ')'
      node
    when '\\'
      literal = take
      raise RegexSyntax, 'dangling escape' if literal.nil?
      [:literal, literal]
    when '.' then [:literal, ANY]
    when '*', '+', '?' then raise RegexSyntax, 'quantifier lacks an operand'
    else [:literal, character]
    end
  end

  def state
    @edges << []
    @edges.length - 1
  end

  def compile(node)
    start = state
    finish = state
    case node[0]
    when :empty then @edges[start] << [nil, finish]
    when :literal then @edges[start] << [node[1], finish]
    when :concat
      a, b = compile(node[1]); c, d = compile(node[2])
      @edges[start] << [nil, a]; @edges[b] << [nil, c]; @edges[d] << [nil, finish]
    when :or
      a, b = compile(node[1]); c, d = compile(node[2])
      @edges[start].concat([[nil, a], [nil, c]])
      @edges[b] << [nil, finish]; @edges[d] << [nil, finish]
    when '*', '+', '?'
      a, b = compile(node[1])
      @edges[start] << [nil, a]; @edges[b] << [nil, finish]
      @edges[start] << [nil, finish] unless node[0] == '+'
      @edges[b] << [nil, a] unless node[0] == '?'
    else raise 'unknown AST node'
    end
    [start, finish]
  end

  def closure(states)
    pending = states.to_a
    until pending.empty?
      @edges[pending.pop].each do |label, target|
        pending << target if label.nil? && states.add?(target)
      end
    end
    states
  end
end

def check(condition, message)
  raise message unless condition
end
patterns = ['', 'a', '.', 'a*', '(a|b)+', '(ab|a)*b?', '(a?)*', 'a|', '(a|)b',
            'a+b?', '(a|b)*abb', '\\*', 'a\\.b', '((ab)?c)+']
texts = ['', 'a', 'b', "\n", '*', 'a.b']
(0..6).each { |length| ['a', 'b'].repeated_permutation(length) { |chars| texts << chars.join } }
patterns.each do |pattern|
  implementation = TinyRegex.new(pattern)
  # Ruby's native regex engine is an independent oracle only, not part of the
  # implementation. MULTILINE makes dot match newline, agreeing with our grammar.
  oracle = Regexp.new("\\A(?:#{pattern})\\z", Regexp::MULTILINE)
  texts.each do |text|
    check(implementation.match?(text) == oracle.match?(text), "mismatch: #{pattern.inspect}, #{text.inspect}")
  end
end
['(', ')', '*a', 'a**', 'a+?', '\\'].each do |pattern|
  rejected = false
  begin TinyRegex.new(pattern); rescue RegexSyntax; rejected = true; end
  check(rejected, "accepted bad pattern #{pattern.inspect}")
end
check(!TinyRegex.new('(a|aa)*b').match?('a' * 2000), 'adversarial non-match')
puts 'Thompson NFA: native-regex differential checks, epsilon cycles and adversarial input passed'
