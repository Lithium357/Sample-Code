/* Robin Hood hash map with backward-shift deletion and transactional resizing.
 * C17: cc -std=c17 -Wall -Wextra -Wpedantic robin_hood_map.c -o map && ./map
 * Keys are uint64_t; values are int64_t. Single-threaded, no sentinel keys.
 * Allocation failure leaves existing contents unchanged, including during grow.
 */
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  uint64_t key, hash;
  int64_t value;
  bool used;
} Slot;
typedef struct {
  Slot *slots;
  size_t capacity, length;
} Map;
static int allocation_budget = -1;
static void *allocate(size_t count, size_t width) {
  if (allocation_budget == 0)
    return NULL;
  if (allocation_budget > 0)
    --allocation_budget;
  return calloc(count, width);
}
static uint64_t hash_key(uint64_t x) {
  x += UINT64_C(0x9e3779b97f4a7c15);
  x = (x ^ (x >> 30)) * UINT64_C(0xbf58476d1ce4e5b9);
  x = (x ^ (x >> 27)) * UINT64_C(0x94d049bb133111eb);
  return x ^ (x >> 31);
}
static size_t distance_at(const Map *map, size_t index, uint64_t hash) {
  return (index - ((size_t)hash & (map->capacity - 1))) & (map->capacity - 1);
}
static bool locate(const Map *map, uint64_t key, size_t *where) {
  if (map->capacity == 0)
    return false;
  uint64_t hash = hash_key(key);
  size_t index = (size_t)hash & (map->capacity - 1);
  for (size_t distance = 0; distance < map->capacity; ++distance) {
    const Slot *slot = &map->slots[index];
    if (!slot->used || distance_at(map, index, slot->hash) < distance)
      return false;
    if (slot->hash == hash && slot->key == key) {
      *where = index;
      return true;
    }
    index = (index + 1) & (map->capacity - 1);
  }
  return false;
}
static void insert_absent(Map *map, Slot incoming) {
  size_t index = (size_t)incoming.hash & (map->capacity - 1), distance = 0;
  for (;;) {
    Slot *slot = &map->slots[index];
    if (!slot->used) {
      *slot = incoming;
      ++map->length;
      return;
    }
    size_t resident_distance = distance_at(map, index, slot->hash);
    if (resident_distance < distance) {
      Slot displaced = *slot;
      *slot = incoming;
      incoming = displaced;
      distance = resident_distance;
    }
    index = (index + 1) & (map->capacity - 1);
    ++distance;
  }
}
static bool grow(Map *map) {
  size_t capacity = map->capacity == 0 ? 8 : map->capacity * 2;
  if (capacity < map->capacity || capacity > SIZE_MAX / sizeof(Slot))
    return false;
  Slot *slots = allocate(capacity, sizeof(*slots));
  if (!slots)
    return false;
  Map replacement = {slots, capacity, 0};
  for (size_t i = 0; i < map->capacity; ++i)
    if (map->slots[i].used)
      insert_absent(&replacement, map->slots[i]);
  free(map->slots);
  *map = replacement;
  return true;
}
static bool map_put(Map *map, uint64_t key, int64_t value) {
  size_t index;
  if (locate(map, key, &index)) {
    map->slots[index].value = value;
    return true;
  }
  if (map->capacity == 0 || map->length >= map->capacity - map->capacity / 4)
    if (!grow(map))
      return false;
  Slot incoming = {key, hash_key(key), value, true};
  insert_absent(map, incoming);
  return true;
}
static bool map_get(const Map *map, uint64_t key, int64_t *value) {
  size_t index;
  if (!locate(map, key, &index))
    return false;
  *value = map->slots[index].value;
  return true;
}
static bool map_erase(Map *map, uint64_t key) {
  size_t hole;
  if (!locate(map, key, &hole))
    return false;
  size_t next = (hole + 1) & (map->capacity - 1);
  while (map->slots[next].used &&
         distance_at(map, next, map->slots[next].hash) > 0) {
    map->slots[hole] = map->slots[next];
    hole = next;
    next = (next + 1) & (map->capacity - 1);
  }
  memset(&map->slots[hole], 0, sizeof(Slot));
  --map->length;
  return true;
}
static void audit(const Map *map) {
  size_t count = 0;
  for (size_t i = 0; i < map->capacity; ++i)
    if (map->slots[i].used) {
      int64_t value = 0;
      ++count;
      assert(map_get(map, map->slots[i].key, &value));
      assert(value == map->slots[i].value);
    }
  assert(count == map->length);
}
int main(void) {
  Map map = {0};
  int64_t value;
  allocation_budget = 0;
  assert(!map_put(&map, 0, 1) && map.capacity == 0);
  allocation_budget = -1;
  for (uint64_t i = 0; i < 6; ++i)
    assert(map_put(&map, i, (int64_t)i));
  Slot *before = map.slots;
  allocation_budget = 0;
  assert(map_put(&map, 0, 99)); /* Updating does not need capacity. */
  assert(!map_put(&map, 6, 6) && map.slots == before && map.length == 6);
  assert(map_get(&map, 0, &value) && value == 99);
  allocation_budget = -1;
  free(map.slots);
  map = (Map){0};
  bool present[257] = {false};
  int64_t reference[257] = {0};
  uint64_t seed = 97;
  for (size_t step = 0; step < 40000; ++step) {
    seed = seed * UINT64_C(6364136223846793005) + 1;
    size_t key = (size_t)(seed >> 24) % 257;
    if (seed % 3 == 0) {
      assert(map_erase(&map, key) == present[key]);
      present[key] = false;
    } else {
      reference[key] = (int64_t)step - 20000;
      present[key] = true;
      assert(map_put(&map, key, reference[key]));
    }
    if (step % 79 == 0) {
      audit(&map);
      for (size_t k = 0; k < 257; ++k) {
        bool found = map_get(&map, k, &value);
        assert(found == present[k]);
        if (found)
          assert(value == reference[k]);
      }
    }
  }
  assert(map_put(&map, UINT64_MAX, INT64_MIN));
  assert(map_get(&map, UINT64_MAX, &value) && value == INT64_MIN);
  audit(&map);
  free(map.slots);
  puts("Robin Hood map: 40000 reference operations, deletion chains and "
       "allocation-failure atomicity passed");
  return 0;
}
