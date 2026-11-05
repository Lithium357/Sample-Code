# Ruby 3.1+ standard library. Raw UTF-16LE chunks -> UTF-8 or US-ASCII.
# Finite, trusted Enumerable of Strings; tags on input strings are ignored.
# No BOM detection/removal, newline conversion, normalization or replacement.
# At most 65536 admitted source bytes, 0..65536 output bytes, buffer 1..64.
# Only a fully converted String is returned. Failed calls publish no prefix;
# enumerator side effects and consumption are not rolled back. Caller strings
# are never mutated. Input chunks are copied; no streaming output API is claimed.
# API semantics: https://docs.ruby-lang.org/en/3.4/Encoding/Converter.html
module StrictTranscode
  class Rejected < StandardError
    attr_reader :reason, :admitted_bytes

    def initialize(reason, admitted_bytes)
      @reason, @admitted_bytes = reason, admitted_bytes
      super("#{reason} after admitting #{admitted_bytes} source bytes")
    end
  end

  def self.call(chunks, destination: 'UTF-8', limit: 65_536, buffer: 7)
    unless limit.is_a?(Integer) && (0..65_536).cover?(limit)
      raise ArgumentError, 'limit must be an Integer in 0..65536'
    end
    unless buffer.is_a?(Integer) && (1..64).cover?(buffer)
      raise ArgumentError, 'buffer must be an Integer in 1..64'
    end
    unless ['UTF-8', 'US-ASCII'].include?(destination)
      raise ArgumentError, 'destination must be UTF-8 or US-ASCII'
    end
    converter = Encoding::Converter.new('UTF-16LE', destination)
    result = String.new(encoding: Encoding::BINARY)
    admitted = 0
    pump = lambda do |source, partial|
      loop do
        fragment = String.new(encoding: Encoding::BINARY)
        status = converter.primitive_convert(source, fragment, nil, buffer,
                                             partial_input: partial)
        if fragment.bytesize > limit - result.bytesize
          raise Rejected.new(:output_limit, admitted)
        end
        result << fragment.b
        case status
        when :destination_buffer_full
          # Even one encoded character may need several calls with buffer=1.
          next
        when :source_buffer_empty
          raise 'unexpected partial completion' unless partial
          break
        when :finished
          raise 'unexpected early finish' if partial
          break
        when :invalid_byte_sequence, :incomplete_input, :undefined_conversion
          raise Rejected.new(status, admitted), cause: converter.last_error
        else
          raise "unexpected converter status #{status.inspect}"
        end
      end
    end
    chunks.each do |chunk|
      raise TypeError, 'each chunk must be a String' unless chunk.is_a?(String)
      if chunk.bytesize > 65_536 - admitted
        raise Rejected.new(:input_limit, admitted)
      end
      admitted += chunk.bytesize
      pump.call(chunk.b, true) # String#b makes a binary copy, including frozen input.
    end
    pump.call(''.b, false) # EOF must flush/reject an incomplete code unit/pair.
    result.force_encoding(destination)
  end
end

if $PROGRAM_NAME == __FILE__
  checks = 0
  check = lambda do |condition, label|
    raise "failed: #{label}" unless condition
    checks += 1
  end
  rejected = lambda do |reason, &operation|
    begin
      operation.call
    rescue StrictTranscode::Rejected => error
      check.call(error.reason == reason, "reason #{reason}: #{error.reason}")
      error
    else
      raise "missing rejection: #{reason}"
    end
  end
  raises = lambda do |type, &operation|
    begin
      operation.call
    rescue type => error
      checks += 1
      error
    else
      raise "missing exception: #{type}"
    end
  end

  # Independent scalar -> bytes construction, no String#encode or Converter.
  utf16le = lambda do |points|
    units = points.flat_map do |cp|
      cp < 0x10000 ? [cp] : [0xd800 + ((cp - 0x10000) >> 10),
                            0xdc00 + ((cp - 0x10000) & 1023)]
    end
    units.pack('v*')
  end
  utf8 = lambda do |points|
    points.flat_map do |cp|
      if cp < 0x80
        [cp]
      elsif cp < 0x800
        [0xc0 | (cp >> 6), 0x80 | (cp & 63)]
      elsif cp < 0x10000
        [0xe0 | (cp >> 12), 0x80 | ((cp >> 6) & 63), 0x80 | (cp & 63)]
      else
        [0xf0 | (cp >> 18), 0x80 | ((cp >> 12) & 63),
         0x80 | ((cp >> 6) & 63), 0x80 | (cp & 63)]
      end
    end.pack('C*').force_encoding('UTF-8')
  end
  # Literal anchors prevent a shared mistake in both byte constructors hiding.
  check.call(utf16le.call([0x1f642]).bytes == [0x3d, 0xd8, 0x42, 0xde], 'UTF16 anchor')
  check.call(utf8.call([0x1f642]).bytes == [0xf0, 0x9f, 0x99, 0x82], 'UTF8 anchor')
  boundary = [0, 10, 13, 0x7f, 0x80, 0x7ff, 0x800, 0xd7ff,
              0xe000, 0xfeff, 0xffff, 0x10000, 0x10ffff]
  random = Random.new(0x9a17)
  examples = [[], boundary, [0x1f642, 0x1f642]]
  150.times do
    examples << Array.new(random.rand(0..30)) do
      # Uniform mapping onto all Unicode scalar values; exclude surrogates.
      cp = random.rand(0...(0x110000 - 0x800))
      cp >= 0xd800 ? cp + 0x800 : cp
    end
  end
  examples.each do |points|
    bytes, expected = utf16le.call(points), utf8.call(points)
    [1, 2, 3, 7, 64].each do |capacity|
      # Every byte split includes odd code-unit splits and split surrogate pairs.
      (0..bytes.bytesize).each do |split|
        chunks = [bytes.byteslice(0, split).freeze, ''.b.freeze,
                  bytes.byteslice(split..).freeze]
        original = chunks.map(&:dup)
        actual = StrictTranscode.call(chunks.each, buffer: capacity, limit: expected.bytesize)
        check.call(actual == expected && actual.encoding == Encoding::UTF_8 &&
                   actual.valid_encoding?, 'independent scalar oracle')
        check.call(chunks == original, 'source strings preserved')
      end
    end
  end
  check.call(StrictTranscode.call([]).empty?, 'empty enumeration')
  check.call(StrictTranscode.call(["A\x00\x00\x00".b], destination: 'US-ASCII') == "A\x00", 'ASCII NUL')
  # Invalid sequences are checked at every possible two-part split.
  malformed = [
    ["\x00".b, :incomplete_input],
    [[0xd800].pack('v'), :incomplete_input],
    [[0xdc00].pack('v'), :invalid_byte_sequence],
    [[0xd800, 65].pack('v*'), :invalid_byte_sequence],
    [[0xd800, 0xd800].pack('v*'), :invalid_byte_sequence],
    [[65, 0xdc00].pack('v*'), :invalid_byte_sequence]
  ]
  malformed.each do |bytes, reason|
    (0..bytes.bytesize).each do |split|
      error = rejected.call(reason) do
        StrictTranscode.call([bytes.byteslice(0, split), bytes.byteslice(split..)], buffer: 1)
      end
      check.call(error.cause.is_a?(Encoding::InvalidByteSequenceError), 'conversion cause retained')
    end
  end
  rejected.call(:undefined_conversion) do
    StrictTranscode.call([utf16le.call([65, 0x100])], destination: 'US-ASCII', buffer: 1)
  end
  rejected.call(:output_limit) { StrictTranscode.call([utf16le.call([65])], limit: 0) }
  rejected.call(:output_limit) { StrictTranscode.call([utf16le.call([0x10000])], limit: 3, buffer: 1) }
  at_output_cap = utf16le.call(([0x800] * 21845) + [65])
  check.call(StrictTranscode.call([at_output_cap], limit: 65536).bytesize == 65536,
             'output boundary 65536 bytes')
  rejected.call(:output_limit) { StrictTranscode.call([utf16le.call([0x800] * 21846)]) }
  check.call(StrictTranscode.call([utf16le.call([65] * 32768)], limit: 32768).bytesize == 32768,
             'input boundary 65536 bytes')
  error = rejected.call(:input_limit) { StrictTranscode.call(["\x00".b * 65537]) }
  check.call(error.admitted_bytes.zero?, 'oversize chunk not admitted')
  rejected.call(:input_limit) { StrictTranscode.call(["\x00".b * 65536, "\x00".b]) }
  [-1, 65537, 1.5, nil].each { |n| raises.call(ArgumentError) { StrictTranscode.call([], limit: n) } }
  [0, 65, 1.5, nil].each { |n| raises.call(ArgumentError) { StrictTranscode.call([], buffer: n) } }
  raises.call(ArgumentError) { StrictTranscode.call([], destination: 'UTF-16LE') }
  raises.call(TypeError) { StrictTranscode.call([65]) }
  boom = IOError.new('fixture source failed')
  source = Enumerator.new { |y| y << utf16le.call([65]); raise boom }
  published = :untouched
  error = raises.call(IOError) { published = StrictTranscode.call(source) }
  check.call(error.equal?(boom) && published == :untouched, 'upstream failure identity/no publication')
  # Failure creates no reusable poisoned converter: calls own their state.
  check.call(StrictTranscode.call([utf16le.call([66])]) == 'B', 'independent next call')
  puts "strict transcoding: #{checks} checks passed"
end
