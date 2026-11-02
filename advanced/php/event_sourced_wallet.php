<?php
declare(strict_types=1);
// In-memory event store: optimistic concurrency, replay and idempotent commands.
// php event_sourced_wallet.php
// This demonstrates transaction boundaries; it is not a durable database.
// PHP 8.0+; integer cents only, checked against overflow before addition.

final class Conflict extends RuntimeException {}
final class CommandRejected extends RuntimeException {}

final class EventStore {
    private array $streams = [];
    private array $receipts = [];

    public function load(string $stream): array {
        return $this->streams[$stream] ?? [];
    }

    public function receipt(string $stream, string $command): ?array {
        return $this->receipts[$stream][$command] ?? null;
    }

    public function append(string $stream, int $expectedVersion, string $command,
                           string $fingerprint, array $events): int {
        $receipt = $this->receipt($stream, $command);
        if ($receipt !== null) {
            if ($receipt['fingerprint'] !== $fingerprint) {
                throw new CommandRejected('command id reused with different content');
            }
            return $receipt['version'];
        }
        $existing = $this->load($stream);
        if (count($existing) !== $expectedVersion) {
            throw new Conflict('stream changed since it was read');
        }
        // All validation precedes mutation. A persistent implementation needs a
        // database transaction and a unique stream/version plus command-id key.
        $newVersion = $expectedVersion + count($events);
        $this->streams[$stream] = array_merge($existing, $events);
        $this->receipts[$stream][$command] = [
            'fingerprint' => $fingerprint, 'version' => $newVersion
        ];
        return $newVersion;
    }
}

final class Wallet {
    public bool $opened = false;
    public int $balance = 0;
    public int $version = 0;

    public static function replay(array $events): self {
        $wallet = new self();
        foreach ($events as $event) {
            switch ($event['type']) {
                case 'Opened':
                    if ($wallet->opened) throw new LogicException('duplicate open event');
                    $wallet->opened = true;
                    break;
                case 'Deposited':
                    if (!$wallet->opened || $event['cents'] <= 0 ||
                        $wallet->balance > PHP_INT_MAX - $event['cents']) {
                        throw new LogicException('invalid deposit event');
                    }
                    $wallet->balance += $event['cents'];
                    break;
                case 'Withdrawn':
                    if (!$wallet->opened || $event['cents'] <= 0 || $event['cents'] > $wallet->balance) {
                        throw new LogicException('invalid withdrawal event');
                    }
                    $wallet->balance -= $event['cents'];
                    break;
                default: throw new LogicException('unknown event type');
            }
            $wallet->version++;
        }
        return $wallet;
    }

    public function decide(string $operation, int $cents): array {
        if ($operation === 'open') {
            if ($this->opened || $cents !== 0) throw new CommandRejected('invalid open');
            return [['type' => 'Opened']];
        }
        if (!$this->opened || $cents <= 0) throw new CommandRejected('wallet closed or amount invalid');
        if ($operation === 'deposit') {
            if ($this->balance > PHP_INT_MAX - $cents) throw new CommandRejected('balance overflow');
            return [['type' => 'Deposited', 'cents' => $cents]];
        }
        if ($operation === 'withdraw') {
            if ($cents > $this->balance) throw new CommandRejected('insufficient funds');
            return [['type' => 'Withdrawn', 'cents' => $cents]];
        }
        throw new CommandRejected('unknown operation');
    }
}

function execute(EventStore $store, string $stream, string $command,
                 string $operation, int $cents, ?int $expected = null): int {
    if ($stream === '' || $command === '') throw new CommandRejected('identifiers required');
    $fingerprint = hash('sha256', json_encode([$operation, $cents], JSON_THROW_ON_ERROR));
    $receipt = $store->receipt($stream, $command);
    // Check receipts before revalidating against newer state: retries must return
    // their original outcome even if subsequent commands changed the balance.
    if ($receipt !== null) {
        if ($receipt['fingerprint'] !== $fingerprint) throw new CommandRejected('conflicting retry');
        return $receipt['version'];
    }
    $wallet = Wallet::replay($store->load($stream));
    if ($expected !== null && $expected !== $wallet->version) throw new Conflict('stale command');
    return $store->append($stream, $wallet->version, $command, $fingerprint,
                          $wallet->decide($operation, $cents));
}

function check(bool $condition): void {
    if (!$condition) throw new RuntimeException('self-check failed');
}
function rejects(string $class, callable $operation): void {
    try { $operation(); } catch (Throwable $error) {
        if ($error instanceof $class) return;
        throw $error;
    }
    throw new RuntimeException('expected rejection');
}
$store = new EventStore();
check(execute($store, 'alice', 'open', 'open', 0) === 1);
check(execute($store, 'alice', 'pay', 'deposit', 1000) === 2);
check(execute($store, 'alice', 'buy', 'withdraw', 300) === 3);
check(execute($store, 'alice', 'pay', 'deposit', 1000) === 2);
check(Wallet::replay($store->load('alice'))->balance === 700);
rejects(CommandRejected::class, fn() => execute($store, 'alice', 'pay', 'deposit', 1001));
rejects(CommandRejected::class, fn() => execute($store, 'alice', 'overdraft', 'withdraw', 701));
rejects(Conflict::class, fn() => execute($store, 'alice', 'stale', 'deposit', 1, 1));
check(count($store->load('alice')) === 3);
// A rejected command has no receipt; it can succeed after state changes.
execute($store, 'alice', 'fund', 'deposit', 100);
execute($store, 'alice', 'overdraft', 'withdraw', 701);
check(Wallet::replay($store->load('alice'))->balance === 99);
execute($store, 'bob', 'open', 'open', 0);
execute($store, 'bob', 'max', 'deposit', PHP_INT_MAX);
rejects(CommandRejected::class, fn() => execute($store, 'bob', 'overflow', 'deposit', 1));
rejects(LogicException::class, fn() => Wallet::replay([['type' => 'Withdrawn', 'cents' => 1]]));
echo "Event sourcing: replay, idempotency, conflicts, rejection and overflow passed\n";
