# Hindley-Milner inference with let-polymorphism and destructive unification
# (Algorithm J style). ruby hindley_milner.rb
# ASTs are explicit arrays: no parser and no annotations to hide inference work.
# Supports integers, booleans, lambdas, application, let, if and pairs; no let-rec.
require 'set'

class TypeErrorHM < StandardError; end
Variable = Struct.new(:id, :link)
Constructor = Struct.new(:name, :arguments)
Scheme = Struct.new(:quantified, :body)

class Inferencer
  def initialize
    @next_id = 0
  end
  def fresh
    variable = Variable.new(@next_id, nil)
    @next_id += 1
    variable
  end
  def con(name, *arguments) = Constructor.new(name, arguments)
  def arrow(a, b) = con(:arrow, a, b)
  def prune(type)
    if type.is_a?(Variable) && type.link
      type.link = prune(type.link)
      return type.link
    end
    type
  end
  def free(type)
    type = prune(type)
    return Set[type.id] if type.is_a?(Variable)
    type.arguments.reduce(Set.new) { |all, argument| all | free(argument) }
  end
  def free_scheme(scheme) = free(scheme.body) - scheme.quantified
  def generalize(type, environment)
    environment_free = environment.values.reduce(Set.new) { |all, scheme| all | free_scheme(scheme) }
    Scheme.new(free(type) - environment_free, type)
  end
  def instantiate(scheme)
    replacements = scheme.quantified.to_h { |id| [id, fresh] }
    copy = lambda do |type|
      type = prune(type)
      if type.is_a?(Variable)
        replacements.fetch(type.id, type)
      else
        Constructor.new(type.name, type.arguments.map { |argument| copy.call(argument) })
      end
    end
    copy.call(scheme.body)
  end
  def unify(left, right)
    left = prune(left); right = prune(right)
    return if left.equal?(right)
    if left.is_a?(Variable)
      raise TypeErrorHM, 'infinite type (occurs check)' if free(right).include?(left.id)
      left.link = right
    elsif right.is_a?(Variable)
      unify(right, left)
    else
      unless left.name == right.name && left.arguments.length == right.arguments.length
        raise TypeErrorHM, "cannot unify #{left.name} with #{right.name}"
      end
      left.arguments.zip(right.arguments).each { |a, b| unify(a, b) }
    end
  end
  def infer(expression, environment = {})
    case expression[0]
    when :int then con(:int)
    when :bool then con(:bool)
    when :var
      scheme = environment.fetch(expression[1]) { raise TypeErrorHM, "unbound #{expression[1]}" }
      instantiate(scheme)
    when :lambda
      parameter = fresh
      local = environment.merge(expression[1] => Scheme.new(Set.new, parameter))
      arrow(parameter, infer(expression[2], local))
    when :apply
      function = infer(expression[1], environment)
      argument = infer(expression[2], environment)
      result = fresh
      unify(function, arrow(argument, result))
      prune(result)
    when :let
      value = infer(expression[2], environment)
      scheme = generalize(value, environment)
      infer(expression[3], environment.merge(expression[1] => scheme))
    when :if
      unify(infer(expression[1], environment), con(:bool))
      yes = infer(expression[2], environment)
      no = infer(expression[3], environment)
      unify(yes, no)
      prune(yes)
    when :pair
      con(:pair, infer(expression[1], environment), infer(expression[2], environment))
    else raise TypeErrorHM, 'unknown AST expression'
    end
  end
  def render(type)
    names = {}
    format = lambda do |value|
      value = prune(value)
      if value.is_a?(Variable)
        names[value.id] ||= "'#{('a'.ord + names.length).chr}"
      elsif value.name == :arrow
        "(#{format.call(value.arguments[0])} -> #{format.call(value.arguments[1])})"
      elsif value.name == :pair
        "(#{format.call(value.arguments[0])} * #{format.call(value.arguments[1])})"
      else
        value.name.to_s
      end
    end
    format.call(type)
  end
end

def type_of(expression)
  inference = Inferencer.new
  inference.render(inference.infer(expression))
end
def check(expression, expected)
  actual = type_of(expression)
  raise "expected #{expected}, got #{actual}" unless actual == expected
end
identity = [:lambda, :x, [:var, :x]]
check(identity, "('a -> 'a)")
check([:lambda, :x, [:lambda, :y, [:var, :x]]], "('a -> ('b -> 'a))")
composition = [:lambda, :f, [:lambda, :g, [:lambda, :x,
  [:apply, [:var, :f], [:apply, [:var, :g], [:var, :x]]]]]]
check(composition, "(('a -> 'b) -> (('c -> 'a) -> ('c -> 'b)))")
# One let-bound identity may be independently instantiated at int and bool.
check([:let, :id, identity, [:pair,
  [:apply, [:var, :id], [:int, 3]], [:apply, [:var, :id], [:bool, true]]]], '(int * bool)')
check([:if, [:bool, true], [:int, 1], [:int, 2]], 'int')
check([:let, :id, identity, [:apply, [:var, :id], [:var, :id]]], "('a -> 'a)")
invalid = [
  [:lambda, :x, [:apply, [:var, :x], [:var, :x]]], # occurs check
  [:apply, [:int, 1], [:int, 2]],
  [:if, [:int, 1], [:int, 2], [:int, 3]],
  [:if, [:bool, true], [:int, 2], [:bool, false]],
  [:var, :missing],
  # Lambda parameters are monomorphic, unlike let-bound identity above.
  [:lambda, :f, [:pair, [:apply, [:var, :f], [:int, 1]], [:apply, [:var, :f], [:bool, true]]]],
  # Generalization must not quantify variables that belong to the environment.
  [:lambda, :x, [:let, :alias, [:var, :x], [:pair,
    [:apply, [:var, :alias], [:int, 1]], [:apply, [:var, :alias], [:bool, true]]]]]
]
invalid.each do |expression|
  rejected = false
  begin type_of(expression); rescue TypeErrorHM; rejected = true; end
  raise "accepted ill-typed expression #{expression.inspect}" unless rejected
end
puts 'HM inference: principal types, instantiation, monomorphism and occurs checks passed'
