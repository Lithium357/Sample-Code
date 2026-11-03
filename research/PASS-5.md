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
