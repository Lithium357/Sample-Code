# Research pass 7: migration behavior, streams and protocol boundaries

Continuation of the unchanged approximately 2B-token goal under
`provenance/research-pass-7.txt`. Exact generation build is unavailable. No
standardized benchmark problems/solutions are intentionally used. All counts
exclude harnesses, prompts, failure snapshots, logs and archive duplicates.

## Retained T-SQL coverage first

The existing constraint/migration fixture now checks the backfilled default
before any explicit update, a new-row default, NULL updates, accepted lower/
upper bounds, six pre-migration rejection paths and one migration rejection,
failed multirow statement atomicity, immediate rows/transaction state, an empty
update, savepoint restoration and outer rollback of temporary schema. Its
parameterized text comparison uses binary conversion to avoid collation or
trailing-space equivalence hiding changed bytes. Original behavior is retained.

Five generated negative controls remove the CHECK/UNIQUE, omit savepoint
rollback, change the default, or change the bound note. Each must exit 1 with
its specific SQL error number and identifying message. Controls are not extra
training source. A temporary validation branch was necessary because the local
host has no SQL Server engine; native-engine source-bound run
2547ee0894f644589a56e8b299551246 passed all five controls. Full workflow
41661352324 passed, then tested commit 94bc9e5a65c1862e7ae2785368c8aefbb81def6b
was promoted to main with an expected-head check. No local engine pass is claimed.
The original task-family/generation task are retained; this edit is task 7.

## Go immutable conditional snapshots

`curated/go/conditional_snapshot.go` snapshots a bounded Reader, publishes no
partial result on input error, uses a digest ETag, and delegates conditional
HTTP/range rules to net/http.ServeContent with a fresh seek cursor per request.
Fixtures use direct httptest calls, fixed independent hash/date/body references,
HEAD and method rejection, strong/weak validators and precedence, single/suffix/
clamped/multipart ranges, malformed/unsatisfiable ranges, binary/empty input,
reader failures, an owned temporary file and 320 concurrent range requests.
No listener/DNS/external service is used. Source version-specific error text or
error-header stripping is not asserted as a universal HTTP guarantee.

Local native run 6f7145255f91499cbb955c589c80b3b0 passed. The initial -race run
a4e3ed8171714b409e3ab3700d5e3336 failed before compilation because CGO was
disabled. That original failure/snapshot remains. A preflight now records the
Go configuration and marks the unavailable local race setup not_tested
(d17b5ea861a04d738c2a9e5e2ea15c79). Native uninstrumented execution is separate;
Linux CI explicitly performs the race check. No race pass is claimed locally.

The ledger previously linked a later success solely by source path. It now
requires matching platform, execution mode AND instrumentation before making a
resolution link. Historical links with mismatched scopes receive append-only
corrections rather than deletion. In particular, a normal native pass cannot
resolve the unavailable local race configuration.

## PHP user stream filter

`curated/php/bom_filter.php` strips exactly one initial UTF-8 BOM as bytes, with
at most three held prefix bytes. Short EOF prefixes, later BOMs, NUL/high bytes,
READ/WRITE paths, incremental/final flush, consumed-input accounting, filter
removal, isolated interleaved instances, close counts and invalid parameters
are checked. It creates new output buckets where bytes change, avoiding writes
to version-dependent bucket properties. Fixed expected bytes are tested across
all three-way write partitions of the small corpus and several read chunk sizes.
It is not UTF-8 validation. Local run bc0a0b0726154899b6500e7aaa7762f1 passed.
API reference: [PHP user filters](https://www.php.net/php-user-filter.filter.php)
and [filter removal](https://www.php.net/manual/en/function.stream-filter-remove.php).

Further results, exact current totals and remaining limitations are appended
after source-bound CI evidence is imported. The long-run goal remains active.


## Assembly protocol/ABI variants

NASM x86-64 and GNU RV64I implementations decode the first canonical ULEB32
value, writing a little-endian value/count pair only on success. Truncation,
overflow and noncanonical encodings leave output unchanged; aliases and
unaligned output are supported. They share binary.canonical-varint with the
related C codec for splitting, rather than being treated as independent projects.
The NASM source includes 16 native Linux ELF64 literal fixtures. A separate
function-body emulator checks required input access bounds, output/source guards,
transactional failure writes, aliases, NULL empty input, very large unsigned
available sizes, saved registers, stack and DF. Its reference uses division/
remainders and canonical re-encoding, independent from the assembly bit shifts.
Native execution and emulation are separate invocations/modes.

The first NASM run 1d6fd14590db44c1a540dc45ae0c5fe7 passed the primary vectors,
but the always-success negative control failed its harness check: the first
vector was a successful zero value, so the stub was caught for missing output,
not the specified wrong status. Put the already-existing empty vector first;
that preserves the complete vector set and every expected result, while making
the same stub fail its intended status assertion. Run
b7370dbebe8249f2b42cd926aa1df2d0 passed the current NASM function under Unicorn.
The original failure/source/harness remains. Local RISC-V GNU tools are absent
(run 107c61a343fd4bfc98425da776b67568 is not_tested); a CI validation branch is
required before that source is promoted to main. RV64I remains emulation-only.

A final Go boundary review added a real one-MiB accepted input and its one-byte
oversize neighbor; run a4c40d3aaca449abb11aadd1c7dbc793 passed. Large runtime
fixtures created by string repetition are not extra counted source tokens.


The assembly validation branch passed all jobs in workflow 41665793457; tested
commit 4938968522865b2403b4ec14d35d209fa76a663a was promoted to main. Native
NASM run 0d553e35c0e4463d870c9027ebadeae2 passed its 16 inline vectors. RV64I
runs 4f5e2ed0a6b24ee8b2ec55da6c9da4e2 and 75b4acf612aa4c4396e5f73666267165
passed 694 emulated vectors and three intended mutations (saved register,
always-success stub and signed size bound). x86-64 emulation has 694 vectors
and two controls; its native execution is separately recorded. RISC-V hardware,
ELF loading and OS execution remain untested.

## Waited Bash process source

`curated/bash/checked_process_source.sh` consumes a producer through process
substitution, closes its input before waiting, verifies the producer's exit
status, and publishes parsed output only after consumer AND producer success.
A consumer error takes precedence over the producer's resulting status. It
handles quoted argv, backslashes/empty values/unterminated records, unique keys,
exact 1000-record acceptance, 1001-record rejection, malformed/duplicate input,
a writer that would exceed pipe capacity after an invalid record, empty success,
partial/empty producer failure, destination-directory rejection and mktemp
failure. It uses owned same-parent temporary files and a subshell EXIT trap so
caller traps survive. Temporary files and finite producer processes are cleaned
up; trusted producers must not leave background stdout holders. GNU mv -T and
other coreutils are explicit dependencies. No NUL-line, POSIX-sh, durability or
universal rename-atomicity guarantee is made.

A generated control skips the producer wait and status; it must fail exactly
with expected producer status 23 versus actual 0. The original source passes.
The latest local test request on November 3 was not executed because automatic
approval review hit a usage limit; this was a review-availability failure, not a
safety finding or sample result. No alternate execution bypassed it. On November
5 account usage was available, the same escalated test path was approved, and
run 144c901139d34176a17dc842bea25274 passed both sample and negative control.
The initial simpler Bash source passed earlier, but that does not substitute
for evidence on this edited source. Its Linux CI execution remains pending
until this batch's workflow is imported.


The collector's ASCII identifier contract now explicitly sets LC_ALL=C inside
its subshell. Added fixtures reject a UTF-8 non-ASCII key while preserving
UTF-8/high bytes in an opaque value. Caller locale state is not changed by the
subshell. This avoids relying on host collation for range expressions; see the
[GNU Bash locale documentation](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html).
