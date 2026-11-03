# Research pass 6: partial progress and deterministic ownership

Continuation of the unchanged approximately 2B-token goal, under
`provenance/research-pass-6.txt`. Exact model build remains unknown. No
standardized benchmark statements/solutions were intentionally used.

The retained `sql/13_audit_triggers.sql` source remains unchanged. New harness
checks verify exact initial history pairs and task row, insert-without-history,
multirow transitions, no-op/missing updates, unrelated title changes and final
states. Four isolated rejections check exact extended errors and immediate
persistent state equality. Three mutants remove reopening protection, remove
logging, or remove no-op suppression. Each fails for its intended reason.
The existing legacy provenance/coverage hold stays in place; this is not a
blanket promotion or independent benchmark-origin proof.

`curated/rust/vectored_cursor.rs` borrows discontiguous slices and keeps exact
progress across short writes, repeated WouldBlock/errors and retries. Fixtures
include zero progress, Interrupted, contract-violating overreport, a default
scalar fallback, a real standard-library capacity-limited writer, 16-entry
windowing, empty/high-bit/NUL payloads and 1820 segmentation/quota cases using
original flat bytes as the oracle. Error boundaries at each prefix are tested.
No atomic record, flushing, readiness or durability guarantee is made.
Rust contract reference: [Write](https://doc.rust-lang.org/std/io/trait.Write.html).

`curated/cpp/owned_stream.cpp` adopts a C FILE stream with move-only ownership.
It tests borrowed byte I/O, move construction/assignment and self-move,
moved-from reuse, release/adoption, same-pointer reset, close-failure
invalidation, context transfer, exception unwinding and vector relocation.
Actual temporary streams are always closed, including the fixture that then
reports a synthetic close failure. This tests ownership after a reported error,
not the probability or platform-specific causes of real fclose failures.
Adoption precedes container allocation to avoid a raw-handle argument leak.
The close-audit context must outlive owners; flush durability is not claimed.

`curated/lua/closing_iterator.lua` adds Lua 5.4 syntax/runtime coverage. The
fourth generic-for result owns cleanup on exhaustion, break, return or error.
Checks distinguish nil/false payloads, empty input, reader failures and close
failures, nested close-error propagation, manual adoption, idempotent invalidation
and malformed arguments before acquisition. This related lifecycle example
shares a task-family ID with the PHP/Ruby variants.
Reference: [Lua 5.4 manual](https://lua.org/manual/5.4/manual.html#3.3.8).

Local Lua runs use the actual native Lua interpreter in lupa.lua54, with Python,
lupa, implementation version and binary module SHA256 recorded. They do not
claim a standalone CLI. The official source archive download timed out twice;
a first pip attempt failed on sandbox TEMP access. All setup results are
preserved; the retry used an owned workspace TEMP and installed lupa 2.6.
Third-party runtimes/source are outside the training allowlist. Linux CI installs
and explicitly requires standalone lua5.4; unsupported runtimes stay not_tested.

All sample source runs so far passed locally. Source-bound logs remain the
source of truth for exact commands, hashes and versions. Reports, setup records,
harnesses, snapshots and repeated execution add no training tokens. Counts and
CI results will be appended after the batch is published and executed.
