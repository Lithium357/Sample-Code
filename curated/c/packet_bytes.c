/* C17, 8-bit bytes. A purpose-written binary record, not a standard protocol.
 * Header: "SC", version=1, flags (bit 0 only), payload u16 BE, sequence u32 BE,
 * checksum u16 BE. Payload <=1024 bytes. Checksum complements the sum of the
 * first ten header bytes and payload bytes; it is not cryptographic integrity.
 * Parse requires exactly one record. Output fields/counts and destination bytes
 * are unchanged on failure. Parsed payload is borrowed from the input buffer.
 * Encode source/destination ranges must be disjoint; pointers name valid
 * ranges. NULL input/payload/destination is permitted only with its
 * corresponding zero length/capacity. No struct packing, unaligned loads, or
 * type-punned pointers.
 */
#include <assert.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
_Static_assert(CHAR_BIT == 8, "requires 8-bit bytes");
enum { HEADER = 12, MAX_PAYLOAD = 1024 };
typedef enum {
  OK,
  ARGUMENT,
  TRUNCATED,
  LENGTH,
  INVALID,
  CHECKSUM,
  CAPACITY
} Status;
typedef struct {
  uint32_t sequence;
  uint8_t flags;
  const uint8_t *payload;
  size_t length;
} Packet;
static uint16_t be16(const uint8_t *p) {
  return (uint16_t)((uint16_t)p[0] << 8 | (uint16_t)p[1]);
}
static uint32_t be32(const uint8_t *p) {
  return (uint32_t)p[0] << 24 | (uint32_t)p[1] << 16 | (uint32_t)p[2] << 8 |
         (uint32_t)p[3];
}
static uint16_t checksum(const uint8_t *header, const uint8_t *payload,
                         size_t n) {
  uint32_t sum = 0;
  for (size_t i = 0; i < 10; ++i)
    sum += header[i];
  for (size_t i = 0; i < n; ++i)
    sum += payload[i];
  return (uint16_t)~sum;
}
static Status encode(const Packet *packet, uint8_t *output, size_t capacity,
                     size_t *written) {
  if (!packet || !written || (!output && capacity) ||
      (!packet->payload && packet->length))
    return ARGUMENT;
  if (packet->flags > 1)
    return INVALID;
  if (packet->length > MAX_PAYLOAD)
    return LENGTH;
  size_t required = HEADER + packet->length; /* bounded before addition */
  if (capacity < required)
    return CAPACITY;
  uint8_t header[HEADER] = {0x53, 0x43, 1, packet->flags, 0, 0, 0, 0, 0,
                            0,    0,    0};
  header[4] = (uint8_t)(packet->length >> 8);
  header[5] = (uint8_t)packet->length;
  header[6] = (uint8_t)(packet->sequence >> 24);
  header[7] = (uint8_t)(packet->sequence >> 16);
  header[8] = (uint8_t)(packet->sequence >> 8);
  header[9] = (uint8_t)packet->sequence;
  uint16_t check = checksum(header, packet->payload, packet->length);
  header[10] = (uint8_t)(check >> 8);
  header[11] = (uint8_t)check;
  memcpy(output, header, HEADER);
  if (packet->length)
    memcpy(output + HEADER, packet->payload, packet->length);
  *written = required;
  return OK;
}
static Status parse(const uint8_t *input, size_t length, Packet *output) {
  if (!output || (!input && length))
    return ARGUMENT;
  if (length < HEADER)
    return TRUNCATED;
  if (input[0] != 0x53 || input[1] != 0x43 || input[2] != 1 || input[3] > 1)
    return INVALID;
  size_t payload_length = be16(input + 4);
  if (payload_length > MAX_PAYLOAD || length != HEADER + payload_length)
    return LENGTH;
  if (be16(input + 10) != checksum(input, input + HEADER, payload_length))
    return CHECKSUM;
  Packet candidate = {be32(input + 6), input[3], input + HEADER,
                      payload_length};
  *output = candidate;
  return OK;
}
static void reject_parse(const uint8_t *bytes, size_t length, Status expected) {
  static const uint8_t sentinel[] = {9};
  Packet output = {77, 1, sentinel, 1};
  assert(parse(bytes, length, &output) == expected);
  assert(output.sequence == 77 && output.flags == 1 &&
         output.payload == sentinel && output.length == 1);
}
int main(void) {
  /* Independent fixed wire fixtures: sums are 539, 151 and 1427 respectively.
   */
  const uint8_t wire[] = {0x53, 0x43, 1,    1,    0,    2,    1,
                          0x23, 0x45, 0x67, 0xfd, 0xe4, 0x48, 0x69};
  const uint8_t empty[] = {0x53, 0x43, 1, 0, 0, 0, 0, 0, 0, 0, 0xff, 0x68};
  const uint8_t maximum[] = {0x53, 0x43, 1,   0,    0,    1,  255,
                             255,  255,  255, 0xfa, 0x6c, 255};
  Packet output;
  assert(parse(wire, sizeof wire, &output) == OK &&
         output.sequence == UINT32_C(0x01234567));
  assert(output.flags == 1 && output.length == 2 &&
         output.payload == wire + HEADER);
  assert(memcmp(output.payload, "Hi", 2) == 0);
  assert(parse(empty, sizeof empty, &output) == OK && output.length == 0 &&
         output.sequence == 0);
  assert(parse(maximum, sizeof maximum, &output) == OK &&
         output.sequence == UINT32_MAX && output.payload[0] == 255);
  uint8_t encoded[HEADER + MAX_PAYLOAD + 2];
  size_t written = 77;
  Packet input = {UINT32_C(0x01234567), 1, wire + HEADER, 2};
  _Alignas(4) uint8_t shifted[sizeof wire + 2];
  memset(shifted, 0xa5, sizeof shifted);
  assert(encode(&input, shifted + 1, sizeof wire, &written) == OK);
  assert(shifted[0] == 0xa5 && shifted[sizeof shifted - 1] == 0xa5);
  assert(memcmp(shifted + 1, wire, sizeof wire) == 0);
  assert(parse(shifted + 1, sizeof wire, &output) == OK);
  assert(output.sequence == input.sequence &&
         output.payload == shifted + 1 + HEADER);
  for (size_t capacity = 0; capacity < sizeof wire; ++capacity) {
    memset(encoded, 0xa5, sizeof encoded);
    written = 77;
    assert(encode(&input, encoded, capacity, &written) == CAPACITY &&
           written == 77);
    for (size_t i = 0; i < sizeof encoded; ++i)
      assert(encoded[i] == 0xa5);
  }
  assert(encode(&input, encoded, sizeof encoded, &written) == OK &&
         written == sizeof wire);
  assert(memcmp(encoded, wire, sizeof wire) == 0 &&
         encoded[sizeof wire] == 0xa5);
  Packet zero = {0, 0, NULL, 0};
  assert(encode(&zero, encoded, sizeof encoded, &written) == OK &&
         written == sizeof empty);
  assert(memcmp(encoded, empty, sizeof empty) == 0);
  for (size_t prefix = 0; prefix < sizeof wire; ++prefix)
    reject_parse(wire, prefix, prefix < HEADER ? TRUNCATED : LENGTH);
  reject_parse(NULL, 0, TRUNCATED);
  reject_parse(NULL, 1, ARGUMENT);
  assert(parse(wire, sizeof wire, NULL) == ARGUMENT);
  uint8_t bad[sizeof wire + 1];
  memcpy(bad, wire, sizeof wire);
  bad[sizeof wire] = 0;
  reject_parse(bad, sizeof bad, LENGTH);
  for (size_t field = 0; field < 4; ++field) {
    memcpy(bad, wire, sizeof wire);
    bad[field] = field == 3 ? 2 : 0xff;
    reject_parse(bad, sizeof wire, INVALID);
  }
  memcpy(bad, wire, sizeof wire);
  bad[HEADER] ^= 1;
  reject_parse(bad, sizeof wire, CHECKSUM);
  memcpy(bad, wire, sizeof wire);
  bad[10] ^= 1;
  reject_parse(bad, sizeof wire, CHECKSUM);
  memcpy(bad, wire, sizeof wire);
  bad[4] = 255;
  bad[5] = 255;
  reject_parse(bad, sizeof wire, LENGTH);
  memset(encoded, 0xa5, sizeof encoded);
  written = 77;
  Packet invalid = input;
  invalid.flags = 2;
  assert(encode(&invalid, encoded, sizeof encoded, &written) == INVALID);
  invalid = input;
  invalid.length = MAX_PAYLOAD + 1;
  assert(encode(&invalid, encoded, sizeof encoded, &written) == LENGTH);
  invalid = input;
  invalid.payload = NULL;
  assert(encode(&invalid, encoded, sizeof encoded, &written) == ARGUMENT);
  assert(encode(NULL, encoded, sizeof encoded, &written) == ARGUMENT);
  assert(encode(&input, encoded, sizeof encoded, NULL) == ARGUMENT);
  assert(encode(&input, NULL, 1, &written) == ARGUMENT);
  assert(encode(&input, NULL, 0, &written) == CAPACITY);
  assert(written == 77);
  for (size_t i = 0; i < sizeof encoded; ++i)
    assert(encoded[i] == 0xa5);
  uint8_t payload[MAX_PAYLOAD];
  for (size_t i = 0; i < sizeof payload; ++i)
    payload[i] = (uint8_t)i;
  for (size_t length = 0; length <= MAX_PAYLOAD; ++length) {
    input = (Packet){UINT32_MAX, (uint8_t)(length % 2), payload, length};
    memset(encoded, 0xa5, sizeof encoded);
    assert(encode(&input, encoded, sizeof encoded, &written) == OK &&
           written == HEADER + length);
    assert(parse(encoded, written, &output) == OK);
    assert(output.sequence == input.sequence && output.flags == input.flags &&
           output.length == length);
    assert(memcmp(output.payload, payload, length) == 0 &&
           encoded[written] == 0xa5);
  }
  puts("Packet bytes: fixed wire vectors, every payload size, endian/sign "
       "boundaries, malformed inputs and failure atomicity passed");
}
