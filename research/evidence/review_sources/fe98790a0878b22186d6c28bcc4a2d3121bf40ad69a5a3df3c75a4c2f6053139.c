/* Incremental framed-protocol decoder, bounded buffering and CRC32 integrity.
 * C17, no external dependencies. Wire: BE32 payload length, byte type (1..3),
 * payload, BE32 IEEE CRC32 over type+payload. At most 256 payload bytes.
 * Decoder accepts arbitrary chunk boundaries. A malformed frame poisons the
 * stream until explicit reset; it never attempts unsafe heuristic resync.
 */
#include <assert.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

enum { MAX_PAYLOAD = 256, MAX_FRAME = 265 };
typedef enum {
  FRAME_OK,
  FRAME_LENGTH,
  FRAME_TYPE,
  FRAME_CHECKSUM,
  FRAME_CALLBACK,
  FRAME_ARGUMENT,
  FRAME_POISONED
} Status;
typedef bool (*Consumer)(void *context, uint8_t type, const uint8_t *payload,
                         size_t length);
typedef struct {
  uint8_t bytes[MAX_FRAME];
  size_t used, expected;
  bool poisoned;
} Decoder;

static uint32_t crc32(const uint8_t *bytes, size_t length) {
  uint32_t crc = UINT32_MAX;
  for (size_t i = 0; i < length; ++i) {
    crc ^= bytes[i];
    for (unsigned bit = 0; bit < 8; ++bit)
      crc = (crc >> 1) ^ (UINT32_C(0xedb88320) & (0u - (crc & 1u)));
  }
  return ~crc;
}
static uint32_t read32(const uint8_t *p) {
  return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
         ((uint32_t)p[2] << 8) | (uint32_t)p[3];
}
static void write32(uint8_t *p, uint32_t value) {
  p[0] = (uint8_t)(value >> 24);
  p[1] = (uint8_t)(value >> 16);
  p[2] = (uint8_t)(value >> 8);
  p[3] = (uint8_t)value;
}
static size_t encode(uint8_t *output, size_t capacity, uint8_t type,
                     const uint8_t *payload, size_t length) {
  if (length > MAX_PAYLOAD || capacity < length + 9 || type < 1 || type > 3 ||
      !output || (!payload && length))
    return 0;
  write32(output, (uint32_t)length);
  output[4] = type;
  if (length)
    memcpy(output + 5, payload, length);
  write32(output + 5 + length, crc32(output + 4, length + 1));
  return length + 9;
}
static Status poison(Decoder *decoder, Status error) {
  decoder->poisoned = true;
  return error;
}
static Status feed(Decoder *decoder, const uint8_t *input, size_t length,
                   Consumer consumer, void *context) {
  if (decoder->poisoned)
    return FRAME_POISONED;
  if ((!input && length) || !consumer)
    return poison(decoder, FRAME_ARGUMENT);
  while (length) {
    size_t target = decoder->expected ? decoder->expected : 4;
    size_t take = target - decoder->used;
    if (take > length)
      take = length;
    memcpy(decoder->bytes + decoder->used, input, take);
    decoder->used += take;
    input += take;
    length -= take;
    if (decoder->used == 4 && decoder->expected == 0) {
      uint32_t payload = read32(decoder->bytes);
      if (payload > MAX_PAYLOAD)
        return poison(decoder, FRAME_LENGTH);
      decoder->expected = (size_t)payload + 9;
    }
    if (decoder->expected && decoder->used == decoder->expected) {
      size_t payload = decoder->expected - 9;
      uint8_t type = decoder->bytes[4];
      if (type < 1 || type > 3)
        return poison(decoder, FRAME_TYPE);
      if (read32(decoder->bytes + 5 + payload) !=
          crc32(decoder->bytes + 4, payload + 1))
        return poison(decoder, FRAME_CHECKSUM);
      /* Consumer must not reenter this decoder. View lifetime ends on
       * callback return; copy payload bytes to retain them. */
      if (!consumer(context, type, decoder->bytes + 5, payload))
        return poison(decoder, FRAME_CALLBACK);
      decoder->used = decoder->expected = 0;
    }
  }
  return FRAME_OK;
}
static bool complete(const Decoder *decoder) {
  return !decoder->poisoned && decoder->used == 0;
}
typedef struct {
  size_t count, bytes;
  uint64_t fingerprint;
  bool reject;
} Sink;
static bool consume(void *context, uint8_t type, const uint8_t *payload,
                    size_t length) {
  Sink *sink = context;
  if (sink->reject)
    return false;
  ++sink->count;
  sink->bytes += length;
  sink->fingerprint = sink->fingerprint * 257 + type;
  for (size_t i = 0; i < length; ++i)
    sink->fingerprint = sink->fingerprint * 257 + payload[i];
  return true;
}
int main(void) {
  assert(crc32((const uint8_t *)"123456789", 9) == UINT32_C(0xcbf43926));
  uint8_t wire[1024], payload[MAX_PAYLOAD];
  for (size_t i = 0; i < MAX_PAYLOAD; ++i)
    payload[i] = (uint8_t)i;
  size_t length = encode(wire, sizeof(wire), 1, NULL, 0);
  length += encode(wire + length, sizeof(wire) - length, 2,
                   (const uint8_t *)"hello", 5);
  length +=
      encode(wire + length, sizeof(wire) - length, 3, payload, sizeof(payload));
  Decoder whole = {0};
  Sink expected = {0};
  assert(feed(&whole, wire, length, consume, &expected) == FRAME_OK);
  assert(complete(&whole) && expected.count == 3 && expected.bytes == 261);
  for (size_t split = 0; split <= length; ++split) {
    Decoder decoder = {0};
    Sink sink = {0};
    assert(feed(&decoder, wire, split, consume, &sink) == FRAME_OK);
    assert(feed(&decoder, wire + split, length - split, consume, &sink) ==
           FRAME_OK);
    assert(complete(&decoder) && sink.count == expected.count &&
           sink.fingerprint == expected.fingerprint);
  }
  Decoder one = {0};
  Sink sink = {0};
  for (size_t i = 0; i < length; ++i)
    assert(feed(&one, wire + i, 1, consume, &sink) == FRAME_OK);
  assert(complete(&one) && sink.fingerprint == expected.fingerprint);
  uint8_t corrupt[MAX_FRAME];
  size_t size = encode(corrupt, sizeof(corrupt), 2, payload, 10);
  corrupt[7] ^= 1;
  Decoder bad = {0};
  sink = (Sink){0};
  assert(feed(&bad, corrupt, size, consume, &sink) == FRAME_CHECKSUM &&
         sink.count == 0);
  assert(feed(&bad, NULL, 0, consume, &sink) == FRAME_POISONED);
  bad = (Decoder){0};
  write32(corrupt, MAX_PAYLOAD + 1);
  assert(feed(&bad, corrupt, 4, consume, &sink) == FRAME_LENGTH);
  bad = (Decoder){0};
  sink.reject = true;
  assert(feed(&bad, wire, 9, consume, &sink) == FRAME_CALLBACK);
  for (size_t cut = 1; cut < 9; ++cut) {
    Decoder partial = {0};
    Sink output = {0};
    assert(feed(&partial, wire, cut, consume, &output) == FRAME_OK);
    assert(!complete(&partial) && output.count == 0);
  }
  uint8_t sentinel[4] = {1, 2, 3, 4};
  assert(encode(sentinel, 4, 1, NULL, 0) == 0 && sentinel[0] == 1);
  /* Type rejection must be distinguished from checksum failure: recompute a
   * valid checksum after changing the type to an unsupported value. */
  size = encode(corrupt, sizeof(corrupt), 2, payload, 10);
  corrupt[4] = 99;
  write32(corrupt + size - 4, crc32(corrupt + 4, 11));
  bad = (Decoder){0}; sink = (Sink){0};
  assert(feed(&bad, corrupt, size, consume, &sink) == FRAME_TYPE && sink.count == 0);
  bad = (Decoder){0};
  assert(feed(&bad, NULL, 1, consume, &sink) == FRAME_ARGUMENT);
  bad = (Decoder){0};
  assert(feed(&bad, wire, 9, NULL, &sink) == FRAME_ARGUMENT);
  bad = (Decoder){0};
  assert(feed(&bad, NULL, 0, consume, &sink) == FRAME_OK && complete(&bad));
  bad = (Decoder){0}; /* Explicit reset restores usability after a poison. */
  assert(feed(&bad, wire, 9, consume, &sink) == FRAME_OK && sink.count == 1);
  puts("Frame decoder: every two-chunk split, byte-at-a-time delivery, "
       "truncation and poison states passed");
  return 0;
}
