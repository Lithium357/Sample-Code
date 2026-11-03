# Ruby 3+: a small lazy JSON-lines library with blocks and structured exceptions.
# ruby record_stream.rb. The caller owns the IO; enumeration never closes it.
require 'json'
require 'stringio'
Record = Struct.new(:name, :quantity, keyword_init: true)
class RecordError < StandardError
  attr_reader :line
  def initialize(line, message)
    @line = line
    super("line #{line}: #{message}")
  end
end
module RecordStream
  def self.each_record(io)
    return enum_for(__method__, io) unless block_given?
    io.each_line.with_index(1) do |line, number|
      next if line.strip.empty?
      begin
        value = JSON.parse(line)
      rescue JSON::ParserError => error
        raise RecordError.new(number, 'invalid JSON'), cause: error
      end
      unless value.is_a?(Hash) && value.keys.sort == %w[name quantity] &&
             value['name'].is_a?(String) && !value['name'].empty? &&
             value['quantity'].is_a?(Integer) && value['quantity'].between?(0, 1000)
        raise RecordError.new(number, 'invalid record')
      end
      yield Record.new(name: value['name'].dup.freeze, quantity: value['quantity']).freeze
    end
  end
end
def check(condition)
  raise 'assertion failed' unless condition
end
input = StringIO.new("{\"name\":\"pen\",\"quantity\":2}\n\n{\"name\":\"pen\",\"quantity\":3}\n")
totals = Hash.new(0)
RecordStream.each_record(input) { |record| totals[record.name] += record.quantity }
check(totals == {'pen' => 5} && !input.closed?)
check(RecordStream.each_record(StringIO.new('')).to_a.empty?)
lazy_input = StringIO.new("{\"name\":\"ok\",\"quantity\":1}\n{bad\n")
enumerator = RecordStream.each_record(lazy_input)
first = enumerator.next
check(first.name == 'ok' && first.frozen? && first.name.frozen?)
begin
  enumerator.next
  raise 'missing parse failure'
rescue RecordError => error
  check(error.line == 2 && error.cause.is_a?(JSON::ParserError))
end
['[]', '{}', '{"name":"x","quantity":1.5}', '{"name":"x","quantity":-1}'].each do |bad|
  rejected = false
  begin RecordStream.each_record(StringIO.new(bad)).to_a; rescue RecordError; rejected = true; end
  check(rejected)
end
prefix = RecordStream.each_record(StringIO.new("{\"name\":\"x\",\"quantity\":4}\n{bad\n")).lazy.take(1).map(&:quantity).force
check(prefix == [4]) # Lazy take never parses the malformed second record.
puts 'Record stream: lazy enumeration, blocks, typed validation and exception causes passed'
