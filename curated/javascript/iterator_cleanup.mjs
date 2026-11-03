// Node.js 18+ ES modules: owned async iteration and deterministic IteratorClose.
// Run: node iterator_cleanup.mjs. No network, timers or dependencies.
// Source is finite. Cancellation is checked between pulls; this adapter cannot
// interrupt a source whose next() is blocked forever. Output is per iteration.
import assert from 'node:assert/strict';

async function* select(source, predicate, signal) {
  if (signal?.aborted) throw signal.reason;
  let index = 0;
  for await (const value of source) {
    // Cancellation can happen while the upstream next() is pending.
    if (signal?.aborted) throw signal.reason;
    const accepted = await predicate(value, index++);
    if (signal?.aborted) throw signal.reason;
    if (accepted) yield value;
    // Also check after resumption: no second pull following cancellation.
    if (signal?.aborted) throw signal.reason;
  }
}

function tracked(values, {failAt = -1, failure = new Error('upstream')} = {}) {
  const state = {pulls: 0, closes: 0, active: false};
  async function* generate() {
    state.active = true;
    try {
      for (let i = 0; i < values.length; i++) {
        state.pulls++;
        if (i === failAt) throw failure;
        yield values[i];
      }
    } finally {
      state.closes++;
      state.active = false;
    }
  }
  return {source: generate(), state};
}

async function collect(source) {
  const result = [];
  for await (const value of source) result.push(value);
  return result;
}

const all = tracked([1, 2, 3, 4]);
const seen = [];
assert.deepEqual(await collect(select(all.source, async (n, i) => {
  seen.push(i);
  return n % 2 === 0;
})), [2, 4]);
assert.deepEqual(seen, [0, 1, 2, 3]);
assert.deepEqual(all.state, {pulls: 4, closes: 1, active: false});

// Consumers can stop without exhausting the input; both generators must close.
const early = tracked([10, 20, 30]);
for await (const value of select(early.source, () => true)) {
  assert.equal(value, 10);
  break;
}
assert.deepEqual(early.state, {pulls: 1, closes: 1, active: false});

const boom = new Error('predicate failure');
const badPredicate = tracked([1, 2]);
await assert.rejects(collect(select(badPredicate.source, () => { throw boom; })),
  error => error === boom);
assert.deepEqual(badPredicate.state, {pulls: 1, closes: 1, active: false});

const upstreamFailure = new Error('fixture input failure');
const upstream = tracked([1, 2], {failAt: 1, failure: upstreamFailure});
await assert.rejects(collect(select(upstream.source, () => true)),
  error => error === upstreamFailure);
assert.deepEqual(upstream.state, {pulls: 2, closes: 1, active: false});

const control = new AbortController();
const reason = new Error('fixture abort');
const cancellable = tracked([5, 6]);
const iterator = select(cancellable.source, () => true, control.signal);
assert.deepEqual(await iterator.next(), {value: 5, done: false});
control.abort(reason);
await assert.rejects(iterator.next(), error => error === reason);
assert.deepEqual(cancellable.state, {pulls: 1, closes: 1, active: false});

const empty = tracked([]);
assert.deepEqual(await collect(select(empty.source, () => { throw boom; })), []);
assert.deepEqual(empty.state, {pulls: 0, closes: 1, active: false});

const preAborted = tracked([1]);
await assert.rejects(collect(select(preAborted.source, () => true, control.signal)),
  error => error === reason);
assert.deepEqual(preAborted.state, {pulls: 0, closes: 0, active: false});
const during = new AbortController();
const duringPredicate = tracked([1, 2]);
await assert.rejects(collect(select(duringPredicate.source, async () => {
  await Promise.resolve();
  during.abort(reason);
  return true;
}, during.signal)), error => error === reason);
assert.deepEqual(duringPredicate.state, {pulls: 1, closes: 1, active: false});

// Pulling the adapter should never eagerly drain the source.
const lazy = tracked([7, 8, 9]);
const lazyIterator = select(lazy.source, () => true);
assert.equal(lazy.state.pulls, 0);
await lazyIterator.next();
assert.equal(lazy.state.pulls, 1);
await lazyIterator.return();
assert.deepEqual(lazy.state, {pulls: 1, closes: 1, active: false});
console.log('Async iteration: laziness, index order, early close, errors and between-pull cancellation passed');
