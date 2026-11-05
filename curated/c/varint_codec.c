/* C17: canonical unsigned LEB128 and portable signed ZigZag coding.
 * Decoder outputs are transactional: neither output changes on failure.
 * No allocation; NULL is permitted only with zero input length.
 */
#include <assert.h>
#ifdef NDEBUG
#error "This executable fixture requires assertions enabled; NDEBUG is unsupported"
#endif
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
typedef enum { OK, TRUNCATED, OVERFLOW, NONCANONICAL, ARGUMENT } Status;
static size_t encode(uint64_t value, uint8_t output[10]) {
  size_t count = 0;
  do {
    uint8_t byte = (uint8_t)(value & 127);
    value >>= 7;
    output[count++] = (uint8_t)(byte | (value ? 128 : 0));
  } while (value);
  return count;
}
static Status decode(const uint8_t *input, size_t length, size_t *used,
                     uint64_t *output) {
  if (!used || !output || (!input && length))
    return ARGUMENT;
  uint64_t value = 0;
  for (size_t i = 0; i < 10; ++i) {
    if (i >= length)
      return TRUNCATED;
    uint8_t byte = input[i];
    if (i == 9 && byte > 1)
      return OVERFLOW;
    value |= (uint64_t)(byte & 127) << (7 * i);
    if (!(byte & 128)) {
      if (i > 0 && byte == 0)
        return NONCANONICAL;
      *used = i + 1;
      *output = value;
      return OK;
    }
  }
  return OVERFLOW;
}
static uint64_t zigzag(int64_t value) {
  return value >= 0 ? (uint64_t)value * 2 : (uint64_t)(-(value + 1)) * 2 + 1;
}
static int64_t unzigzag(uint64_t value) {
  return value & 1 ? -1 - (int64_t)(value >> 1) : (int64_t)(value >> 1);
}
static void failure(const uint8_t *bytes, size_t length, Status expected) {
  size_t used = 77;
  uint64_t value = 99;
  assert(decode(bytes, length, &used, &value) == expected);
  assert(used == 77 && value == 99);
}
int main(void) {
  const uint8_t three_hundred[] = {0xac, 0x02};
  size_t used = 0;
  uint64_t value = 0;
  assert(decode(three_hundred, 2, &used, &value) == OK && used == 2 &&
         value == 300);
  uint8_t bytes[10];
  const uint64_t small_values[] = {0, 1, 127, 128};
  const uint8_t small_wire[][2] = {{0, 0}, {1, 0}, {127, 0}, {128, 1}};
  for (size_t i = 0; i < 4; ++i) {
    size_t width = i == 3 ? 2 : 1;
    assert(encode(small_values[i], bytes) == width);
    assert(memcmp(bytes, small_wire[i], width) == 0);
    assert(decode(small_wire[i], width, &used, &value) == OK);
    assert(used == width && value == small_values[i]);
  }
  assert(encode(300, bytes) == 2 && memcmp(bytes, three_hundred, 2) == 0);
  const uint8_t maximum[] = {255, 255, 255, 255, 255, 255, 255, 255, 255, 1};
  assert(decode(maximum, 10, &used, &value) == OK && value == UINT64_MAX);
  assert(encode(UINT64_MAX, bytes) == 10 && memcmp(bytes, maximum, 10) == 0);
  const uint8_t overlong[] = {0x80, 0};
  failure(overlong, 2, NONCANONICAL);
  const uint8_t overflow[] = {255, 255, 255, 255, 255, 255, 255, 255, 255, 2};
  failure(overflow, 10, OVERFLOW);
  failure(NULL, 0, TRUNCATED);
  failure(NULL, 1, ARGUMENT);
  used = 77;
  value = 99;
  assert(decode(three_hundred, 2, NULL, &value) == ARGUMENT && value == 99);
  assert(decode(three_hundred, 2, &used, NULL) == ARGUMENT && used == 77);
  assert(zigzag(0) == 0 && zigzag(-1) == 1 && zigzag(1) == 2);
  assert(zigzag(INT64_MIN) == UINT64_MAX && unzigzag(UINT64_MAX) == INT64_MIN);
  assert(unzigzag(zigzag(INT64_MAX)) == INT64_MAX);
  uint64_t seed = 149;
  for (size_t trial = 0; trial < 10000; ++trial) {
    seed = seed * UINT64_C(6364136223846793005) + 1;
    size_t count = encode(seed, bytes);
    for (size_t prefix = 0; prefix < count; ++prefix)
      failure(bytes, prefix, TRUNCATED);
    assert(decode(bytes, count, &used, &value) == OK && used == count &&
           value == seed);
  }
  puts("Varints: fixed wire vectors, canonicality, overflow, every truncation "
       "and 10000 round trips passed");
}
