# Research pass 5: retained-family review and resource/byte contracts

Automatic continuation of the active approximately 2B good-token goal. The
target, broad language rotation and quality gate remain unchanged. Governing
requests are in `provenance/research-pass-5.txt`; model build remains unknown.
No standardized benchmark/evaluation material was intentionally used.

## Retained GCD family: three scoped reviews

Go/Rust/Ruby retained their original five fixed fixtures and implementations.
Tests now include signed-width boundaries and all 1089 pairs in [0,32] squared
against a divisor-enumeration oracle. Ruby additionally checks a 200-bit common
factor and explicitly states its Integer precondition. There are 10 fixed
fixtures in Go/Rust and 11 in Ruby. Negative/type-invalid inputs remain outside
the documented computation contract; no rejection behavior is invented.

The review is in `reviews/pass-5-gcd.md` and each acceptance is bound to that
document's hash and the exact source hash in `reviews.jsonl`. The inventory
requires matching family/generation task, accepted outcome, unchanged document, unchanged source
and a source-bound execution pass. A later edit invalidates acceptance. The
other six members of parallel.integer.gcd remain held; no family-wide or
collection-wide review is inferred. Original generation task IDs stay intact.

The outcome is an available-lineage/contract candidate review, not independent
proof that no evaluation corpus contains a similar mathematical task. The review
document records inspected source, available prompts, semantic reasoning,
failure/boundary coverage, current evidence and explicit limits.

## C fixed packet codec

`curated/c/packet_bytes.c` defines a purpose-written 12-byte header with bounded
payload, explicit big-endian fields and a simple noncryptographic checksum.
No packed structs, unaligned integer loads or type-punned pointers are used.
Parsed payload is borrowed; encoding requires disjoint source/destination ranges.
Tests use three independent fixed wire vectors, all 1025 payload lengths,
deliberately unaligned buffers, short capacities, truncation, trailing data,
malformed fields, checksum corruption and unchanged outputs on rejection.
It passed locally under native C17/MSVC; Linux sanitizer scope is recorded
separately after CI execution. It does not claim to implement a standard protocol.

All counts use cl100k_base full-file source/support text with comments/fixtures.
Control, reports, review documents, harnesses, snapshots and repeated runs are
excluded. Training-candidate volume and technical execution volume remain
separate; raw append-only evidence is authoritative. The long-run goal is active.

## Ruby Fiber lifecycle

`curated/ruby/fiber_pull.rb` exposes tagged item/end results, explicit cooperative
close, cached failure identity, owner-thread checks and reentrancy rejection.
Tests distinguish nil/false/data resembling protocol tags, empty/unstarted
producers, normal completion, early close, producer/cleanup exceptions,
recursive calls and a genuinely different Thread. Resources are acquired inside
the producer and unfinished tasks must be closed. The producer contract forbids
intercepting private cancellation or yielding from cleanup; arbitrary-code
preemption is not claimed. It shares the related PHP generator-lifecycle family.
API behavior was checked against
[Ruby's Fiber documentation](https://docs.ruby-lang.org/en/3.2/Fiber.html#method-i-raise).

## Bash descriptors and preserved failure

`curated/bash/descriptor_scope.sh` owns a descriptor while forwarding an argv
vector to a borrowing callback. Tests cover literal space/bang/wildcard/newline
paths, independent offsets, empty/unterminated records, callback status 23,
missing/directory inputs, repeated closure and conditional-context errexit.
The callback must return normally and propagate failures explicitly; it cannot
close/rebind the borrowed descriptor or replace/exit the shell.

The first source-bound run failed at the leak assertion; its source snapshot
is preserved. A diagnostic trace showed the wrapper's close. The redirection
assertion could reuse the just-closed number for Bash's saved descriptors.
The revised /dev/fd assertion first verifies known-open state and has a known-open
negative control that must be rejected. Every callback checks its descriptor is
open while borrowed. The closure expectation is unchanged and the rerun passed.
Hosts lacking /dev/fd probe support exit 77 and are not_tested, not passes.

## CMD expansion phases

`curated/cmd/literal_expansion.cmd` creates files containing spaces, literal
!lit! and %PATH% text. Delayed expansion stays disabled around paths; data passes
through variables rather than reparsed CALL arguments. A nested numeric scope
enables delayed expansion then restores the outer state. Tests check exact
contents/counts, missing/corrupt statuses 7/8, fresh ERRORLEVEL capture, and
guarded unmatched wildcards. Cleanup uses exact owned files and nonrecursive RD.
The CRLF source passed native Windows CMD; POSIX/UNC portability is not claimed.

## Review-policy control tests

`tools/review_policy_probe.py` uses an owned scratch repository and real matching
execution records. It checks baseline acceptance, stale-document rejection,
family/task mismatches and later revocation. It genuinely compiles/runs a
comment-only Go revision before proving execution alone does not clear its
stale review. Exact commands and the genuine execution are recorded; no pass is
fabricated. Scratch copies, controls and logs add no training source tokens.
The probe passed locally and is included in Linux CI.

## SQLite booking type-affinity fix and scoped review

Inspection found that the retained booking schema could accept nonnumeric TEXT
and fractional REAL values despite INTEGER declarations. New tests were run
before the fix; run 9303a2b964354f458db92dc43fc98728 failed because the forbidden
text-valued insert was accepted. The original result and source are preserved.
The schema now enforces integer storage after affinity conversion using a named
CHECK, while still accepting numeric text that SQLite converts to integers.
It uses no STRICT-table requirement. See
[SQLite type affinity](https://www.sqlite.org/datatype3.html).

The source defines booking_totals once as a view. Tests query that view against
literal expected rows, avoiding an untested display query or a duplicated
aggregation expression that could hide a source-query regression. Final local
checks pass fifteen exact rejections, seven additional behaviors and three
intended negative controls (two triggers and the integer CHECK). Immediate state
hashes match before/after every rejected statement, before cleanup rollback.
The original two SQL checks remain. The hash-bound available-lineage/behavior
review is in `reviews/pass-5-bookings.md`; it does not clear other SQL cases or
claim concurrent-client, arbitrary-aggregate-overflow or server-dialect coverage.

## Publication and validation checkpoint

Three source commits were pushed directly to main with expected-head checks:
77b35c2e747069d5810f2ee084e81139da299452 (run 41601207987),
417cec7d7013a0a3d1a79a7d15e714085f7070c6 (run 41604071910), and
29d61f23815c6e05cdca6fe1be31725299f2c319 (run 41606283685).
All three workflow runs completed successfully. The fifteen research artifacts
were digest-verified and imported as 32 new immutable history files. Original
failed runs and snapshots remain. C, Ruby Fiber, Bash, three GCD variants and
SQLite have matching Windows-local/Linux evidence; CMD has native local/CI
Windows evidence. Linux C uses the workflow's sanitizers. These are specific
compiler/runtime and fixture results, not portability proofs.

Final local SQLite execution used Python 3.12.14 / SQLite 3.53.1. Its fifteen
rejections preserve identical immediate before/after state hashes; seven added
behaviors and three deliberately broken variants are checked. The review-policy
probe checks six scenarios including actual execution of a changed Go source
whose old review must remain invalid. It is control material, excluded from
training volume. Exact commands, versions, hashes and modes are in raw records.

Two formal failures occurred in this pass: Bash's misleading redirection probe
and the real SQLite text-storage bypass. The Bash diagnostic trace repeated its
failure outside the recorder. Both fixes, original results and snapshots are
retained. An artifact-download orchestration typo and a report-inspection typo
were corrected; they were not source validation passes or failures.

Current volume is 356 source/support files / 210,023 cl100k_base tokens:
355 files / 209,376 have source-bound execution evidence; 46 files / 45,551
qualify as training candidates under the documented policy. The remaining
309 executed legacy files / 163,825 tokens remain held for origin/coverage
review. One T-SQL file / 647 tokens is untested. Compared with pass 4, generated
and execution totals each rose by 6,972 tokens; candidate volume rose by 8,360
through four new files and four scoped retained-file reviews. New files alone
contain 6,159 tokens (C 2,542; Ruby 1,375; Bash 1,281; CMD 961). Remaining changes
in generated volume come from edits to retained source. These full-file counts
include comments/inline fixtures. Separate fixture-role files total 293 tokens;
lexical source/comment/inline-fixture separation is not implemented.

The approximately 2B-token goal remains active. SQL Server execution, native ARM/
AArch64/RISC-V hardware and broader runtime/dialect versions remain missing.
Emulation is labeled as such. Benchmark absence is not independently established
by these scoped reviews; candidate qualification retains that limitation. No
checks here measure Morderca performance. Future batches rotate all languages,
including niche practical contracts, rather than expanding a parallel algorithm
collection just to raise volume.
