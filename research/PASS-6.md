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

## PowerShell providers and Nim ownership

`curated/powershell/provider_bytes.ps1` resolves literal session-state paths
before invoking .NET. It tests a FileSystem PSDrive whose location differs from
process cwd, bracket filenames versus wildcard matching, provider-qualified
paths, one byte-array output for empty/singleton/binary input, a bounded sentinel
read, non-filesystem providers, directory/missing files, parameter bounds and
exclusive reopen after twenty failed reads. Exact owned fixtures are deleted
nonrecursively. This is not a security sandbox or atomic snapshot guarantee.

Its first source run dd9909ffbed4495581c71c7d299b9423 failed because the test used
an internal ParameterBindingValidationException as a PowerShell type literal.
A diagnostic confirmed the actual class and exact FullyQualifiedErrorId. The
fixed assertion requires public ParameterBindingException plus the exact
ParameterArgumentValidationError,Read-LiteralBytes ID. It does not accept an
arbitrary error. The original failure/snapshot remains; final local run
 d02951a858f044a897789aa20d3390bd passed.

`curated/nim/owned_bytes.nim` adds native C/ARC destructor, forbidden-copy and
sink hooks. Bounds, zero initialization, moved-from reuse, transfer over an
existing allocation, exception unwinding and sequence growth/shrink release
counts are checked. A generated compile-only control attempts to copy a live
source, and must fail with the unavailable =copy diagnostic for OwnedBytes and
the specific still-live source variable. The control is not training volume.
C++ stream/Nim allocation examples share resource.move-only-owner for splitting;
they retain distinct resource contracts, not independent project provenance.

The first Nim source-bound run ba98d300b0e44f4fafebfd0322ba5f62 ran all runtime
checks successfully, but its negative-control assertion failed because Nim emits
its own unavailable-copy diagnostic instead of the hook's custom error text.
The raw failed result and snapshots remain. Inspection showed compile failure
code 1 naming =copy, OwnedBytes and the non-last read of first. The fixed
harness requires that specific rejection; it does not count unrelated compiler
failures. Final local run 38dbc0ec5f704fe387768dc4f7765813 passed runtime and
negative compile checks. Reference: [Nim move semantics](https://nim-lang.org/docs/destructors.html).
