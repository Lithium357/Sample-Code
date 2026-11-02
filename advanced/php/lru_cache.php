<?php
declare(strict_types=1);
// LRU cache: O(1) map/list operations; O(capacity) expiry sweep on full inserts.
// php lru_cache.php
// Expiry uses a caller-supplied monotonic integer clock. Expired entries are
// removed on access and before eviction; capacity counts currently live keys.

final class CacheNode {
    public ?self $previous = null;
    public ?self $next = null;
    public function __construct(public string $key, public mixed $value, public ?int $expires) {}
}
final class LruCache {
    private array $nodes = [];
    private ?CacheNode $head = null;
    private ?CacheNode $tail = null;
    private int $lastNow = 0;
    public function __construct(private int $capacity) {
        if ($capacity < 1) throw new InvalidArgumentException('positive capacity required');
    }
    private function clock(int $now): void {
        if ($now < $this->lastNow) throw new InvalidArgumentException('clock moved backwards');
        $this->lastNow = $now;
    }
    private function detach(CacheNode $node): void {
        if ($node->previous !== null) $node->previous->next = $node->next;
        else $this->head = $node->next;
        if ($node->next !== null) $node->next->previous = $node->previous;
        else $this->tail = $node->previous;
        $node->previous = null; $node->next = null;
    }
    private function front(CacheNode $node): void {
        $node->next = $this->head;
        if ($this->head !== null) $this->head->previous = $node;
        else $this->tail = $node;
        $this->head = $node;
    }
    private function remove(CacheNode $node): void {
        $this->detach($node); unset($this->nodes[$node->key]);
    }
    public function get(string $key, int $now): array {
        $this->clock($now);
        $node = $this->nodes[$key] ?? null;
        if ($node === null) return [false, null];
        if ($node->expires !== null && $node->expires <= $now) {
            $this->remove($node); return [false, null];
        }
        $this->detach($node); $this->front($node);
        return [true, $node->value]; // Found flag distinguishes cached null.
    }
    public function put(string $key, mixed $value, int $now, ?int $ttl = null): void {
        $this->clock($now);
        if ($ttl !== null && ($ttl < 0 || $now > PHP_INT_MAX - $ttl)) {
            throw new InvalidArgumentException('invalid TTL');
        }
        if (isset($this->nodes[$key])) $this->remove($this->nodes[$key]);
        if ($ttl === 0) return;
        // TTLs are unrelated to LRU order. Expiring only from the tail would
        // incorrectly evict a live key while an expired key exists elsewhere.
        // This sweep is O(capacity); individual map/list operations are O(1).
        if (count($this->nodes) >= $this->capacity) {
            foreach ($this->nodes as $node) {
                if ($node->expires !== null && $node->expires <= $now) $this->remove($node);
            }
        }
        if (count($this->nodes) >= $this->capacity) $this->remove($this->tail);
        $node = new CacheNode($key, $value, $ttl === null ? null : $now + $ttl);
        $this->nodes[$key] = $node; $this->front($node);
    }
    public function audit(): void {
        $seen = []; $previous = null;
        for ($node = $this->head; $node !== null; $node = $node->next) {
            if (isset($seen[$node->key]) || $node->previous !== $previous || ($this->nodes[$node->key] ?? null) !== $node) {
                throw new LogicException('list/map invariant failure');
            }
            $seen[$node->key] = true; $previous = $node;
        }
        if ($previous !== $this->tail || count($seen) !== count($this->nodes) || count($seen) > $this->capacity) {
            throw new LogicException('tail/capacity invariant failure');
        }
    }
}
function check(bool $ok): void { if (!$ok) throw new RuntimeException('self-check failed'); }
$cache = new LruCache(2);
$cache->put('a', null, 0); $cache->put('b', 2, 0, 1);
check($cache->get('a', 0) === [true, null]);
$cache->put('c', 3, 1);
check($cache->get('a', 1) === [true, null]);
check($cache->get('b', 1) === [false, null]);
$cache->put('d', 4, 1); check($cache->get('c', 1) === [false, null]);
$cache->put('a', 99, 1, 0); check($cache->get('a', 1) === [false, null]); $cache->audit();
// Differential test against a deliberately slow, timestamp-ranked reference.
$cache = new LruCache(5); $reference = []; $tick = 0; $seed = 7;
for ($now = 0; $now < 2000; $now++) {
    $seed = ($seed * 251 + 17) % 10007; $key = 'k' . ($seed % 9);
    foreach ($reference as $k => $entry) {
        if ($entry['expires'] !== null && $entry['expires'] <= $now) unset($reference[$k]);
    }
    if ($seed % 3 === 0) {
        $expected = isset($reference[$key]) ? [true, $reference[$key]['value']] : [false, null];
        check($cache->get($key, $now) === $expected);
        if ($expected[0]) $reference[$key]['rank'] = ++$tick;
    } else {
        $ttl = $seed % 2 === 0 ? null : $seed % 11;
        $cache->put($key, $now, $now, $ttl); unset($reference[$key]);
        if ($ttl !== 0) {
            if (count($reference) >= 5) {
                $oldest = array_key_first($reference);
                foreach ($reference as $k => $entry) if ($entry['rank'] < $reference[$oldest]['rank']) $oldest = $k;
                unset($reference[$oldest]);
            }
            $reference[$key] = ['value' => $now, 'expires' => $ttl === null ? null : $now + $ttl, 'rank' => ++$tick];
        }
    }
    $cache->audit();
}
echo "LRU: cached null, expiry order, eviction, list invariants and 2000 reference operations passed\n";
