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

## Tcl command-prefix snapshots and SQL Server validation infrastructure

`curated/tcl/snapshot_events.tcl` uses TclOO and word-list command prefixes,
registration-order snapshots, first-error propagation and finally-based busy
restoration. Tests include literal script-like words, empty dispatch/value,
registration changes during dispatch, exact Tcl error codes/errorinfo, rejected
recursion and deferred command lookup failure. Callbacks cannot yield or destroy
the emitter. It uses core Tcl only. Its first run failed for a missing test
bracket; after that fix all assertions ran, but the embedded-driver completion
check failed because puts returns an empty string. The source now prints AND
returns its success value, as the existing Tcl adapter requires. Both failures
and source snapshots remain; no behavior expectation was relaxed. Final local
run 77007943e7fc4ca6bb843f63a5804561 passed using native embedded Tcl.

The retained T-SQL source has not changed. A separate CI job now supplies an
owned SQL Server 2022 Linux container and bundled sqlcmd, with no host port and
a public disposable fixture password. The adapter connects only to localhost
INSIDE that explicitly opted-in container. It records Docker/server/sqlcmd
versions and image digest, verifies the copied SQL SHA256, runs sqlcmd with -b,
requires the fixture completion text and deletes its exact temporary SQL copy.
The source still contains only #temp tables and transaction rollback. Local
engine absence remains not_tested (run 70833902ae394faaa1c127d641a782de); no
execution or candidate promotion is claimed until actual engine evidence arrives.
Container-backed native_sqlserver results are eligible only after source-bound
success, separately labeled from SQLite/PostgreSQL. Infrastructure follows
[Microsoft's container guidance](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker).


SQL Server CI run 41656069870 / source-bound run
d93d3468774a40e0802eb24bfc308331 executed the original T-SQL successfully on
SQL Server 2022 16.0.4305.5 (RTM-CU27-GDR), then failed cleanup. Docker cp made
the file root-owned directly in sticky /tmp; the normal mssql user could read
but not delete it. The failed result is imported unchanged, with copied source
hash, sqlcmd success and rm failure; it is not counted as a successful validation.
Fix: create a uniquely named private directory as the normal container user,
copy into it, then remove the exact file and nonrecursively rmdir the owned
folder as that same user. No privileged Docker exec is introduced. Cleanup
errors are recorded without masking an original test error. The source itself
is unchanged; a clean CI rerun is required for promotion.


SQL Server run 1afa527a0f184d8fbdaa1dfce1f8ccf9 (workflow 41656604474)
confirmed the private-directory cleanup fix, but failed the completion sentinel:
-b -r 1 correctly routes PRINT to stderr, while the adapter inspected stdout
alone. Both command streams, code 0 SQL execution and successful file/directory
cleanup are preserved in the failed result. The original run also had this
sentinel error, masked by its cleanup exception. Fix: retain the exact same
completion text requirement and -b failure behavior, checking the recorded
stdout AND stderr as documented for sqlcmd -r 1. No SQL expectation or expected
output text is changed. The unchanged T-SQL still requires a wholly successful
new validation run before qualification.
