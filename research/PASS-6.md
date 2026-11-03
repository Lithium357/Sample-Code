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

The initial Rust/C++/Lua source runs passed locally; later failures and fixes
are recorded below. Source-bound logs remain the source of truth for exact commands, hashes and versions. Reports, setup records,
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


A final boundary review added the accepted maximum Nim allocation (65536),
first/last-byte writes, the next invalid index and exact release count; Lua now
also checks false-valued body/cleanup errors and capture of cleanup configuration
before a callback changes its options table. These checks passed locally in
run 9a56984d2da94c7a865452755dc64c8a. No implementation change or relaxed
expectation was needed. The first two publication batches passed all CI jobs.
SQL Server subsequently passed the complete fixture/copy/cleanup path in run
9e310ad7c33a4c6fadaaede86cd60b86, using engine 16.0.4305.5 and sqlcmd
18.7.0001.1. Its image digest is recorded in raw evidence. Other SQL Server
versions/platforms remain untested; native ARM/AArch64/RISC-V hardware and ELF
loading remain missing. The retained T-SQL migration default value is not yet
independently asserted before its explicit update; record that coverage gap
rather than equating a clean engine run with exhaustive SQL behavior coverage.

## Final source-bound checkpoint

Six new source files add 10,962 cl100k_base tokens (comments and inline fixtures
included): Rust 2,535; C++ 1,783; Lua 1,902; PowerShell 2,008; Nim 1,386; Tcl 1,348.
Their exact current source hashes have passing Linux and Windows execution
records. Local Lua uses native embedded Lua 5.4.8 via lupa 2.6; Linux CI uses
standalone Lua 5.4.6. Nim was checked under local 2.4.0 and Linux 1.6.14 with
native C/ARC, including the intended compile rejection. C++ Linux checks use
ASan/UBSan; local MSVC checks and managed PowerShell/Tcl embeddings are labeled
in their records. These are tested runtimes, not all-version portability claims.

The retained SQLite audit source is unchanged; its strengthened harness passed
four exact rejections with immediate state equality, eight additional behavior
checks and three intended schema mutants. Its legacy hold remains. The retained
647-token T-SQL source is also unchanged; it now has fully successful native
SQL Server execution. That promotion adds validation/candidate volume, not newly
generated source. No legacy origin/coverage holds were cleared in this pass.

Published source/infrastructure checkpoints:

* 9e19700bae15d139c188d140225d01f607642447 — first three new units;
  workflow 41653833395 passed.
* e2b96fc3f361175c83fc9a28afc11da81b97c784 — PowerShell/Nim;
  workflow 41655206694 passed.
* b916ea471b5da9b1bee68eda49bed2eeb3d8df09 — Tcl/SQL Server adapter;
  workflow 41656069870 failed its SQL Server adapter.
* 3ba43eb5ee36da5c57c573865ae61ca0b37c0e9b — cleanup fix;
  workflow 41656604474 exposed the stdout/stderr assertion error.
* 49a0606f49cd4311f763899fef90ee44a8446fc5 — completion-stream fix;
  workflow 41657297038 passed all six jobs.
* b21bf338d66dfc4fadcd44ab260abd26a06c332b — final Lua/Nim boundaries;
  workflow 41658450519 passed all six jobs.

Thirty-four digest-verified CI research artifacts yielded 76 new immutable
history files. Four local formal failures and two CI SQL Server adapter failures
are retained with their original source snapshots; the CI failure harness bytes
were recovered from their exact Git commits and verified against recorded
hashes. Later successes are additional records, not overwritten history. Lua
setup timeouts/TEMP-denied installation are separate setup failures. Diagnostics
and generated negative controls do not count as source volume.

| Collection metric | Files | cl100k_base tokens |
| --- | ---: | ---: |
| Generated source/support | 362 | 220,985 |
| At least one current-source passing execution mode | 362 | 220,985 |
| Training candidates under the documented quality policy | 53 | 57,160 |
| Executed legacy origin/coverage hold | 309 | 163,825 |
| Files with no accepted execution evidence | 0 | 0 |

Compared with pass 5: generated volume grew by 10,962; execution and candidate
volume each grew by 11,609, including the existing 647-token T-SQL promotion.
Whole-file roles are 211,722 source-with-inline-fixture, 8,390 source, 293 fixture
and 580 support-source tokens. No lexical code/comment/inline-fixture separation
or Morderca tokenizer count is claimed.

The local candidate-only archive contains only the 53 qualifying source/support
files; its separate manifest retains hashes, roles, provenance and actual
matching execution-record references. It groups ALL known current members of
exported task families, including held variants for future split handling. It
assigns no train/evaluation split and asserts no independent benchmark-absence
certification. The full snapshot also retains controls/evidence; it must not be
mistaken for a ready-to-ingest all-source training export.

The approximately 2B-token goal remains active. Native ARM/AArch64/RISC-V
hardware/ELF loading, more SQL Server versions and the explicit default-value
coverage gap above remain outstanding. Individual unavailable host/mode records
remain not_tested even when another mode passes. The 309 held legacy examples
still require scoped reviews. No self-check here is a Morderca performance result.


The final publication hash guard rejected a report-only byte mismatch before
updating main: the Windows default text encoding had written six em dashes as
CP1252 bytes, while the publication reader expected UTF-8. The report was
converted to UTF-8; source files, tests and token counts were unaffected.
