# Available-lineage and contract review: three retained GCD variants

Reviewer: the Codex assistant in research-pass-5; exact model build unknown.
Scope: go/01_gcd.go, rust/01_gcd.rs and ruby/01_gcd.rb only. Each accepted
review is separately bound to the current source hash and this document's hash
in reviews.jsonl. Related implementations retain parallel.integer.gcd, including
the six unreviewed variants; this is not approval of the whole family.

## Available origin evidence

The original visible generation request and language-list transcription are in
provenance/session.json, conversation-round-1. The collection labels these as
related synthetic parallel examples. Inspection found a generic Euclidean
algorithm, local mathematical fixtures and standard-library facilities; no
external problem statement, benchmark identifier, imported solution or remote
fixture was identified. No standardized benchmark material was consulted for
this review. This is an available-lineage review, not an independent corpus-wide
near-duplicate search or proof that no external benchmark has a similar GCD task.
Missing original model/build information remains unknown.

## Inspected contract and implementation

Go and Rust accept nonnegative signed-64-bit inputs. Ruby accepts nonnegative
Integer inputs, including arbitrary precision. The caller enforces the input
precondition; negative, floating-point and malformed Ruby inputs are outside
the contract, and these functions do not promise rejection diagnostics for them.
All three define gcd(0,0)=0, return the other input when one is zero, and have
no I/O or stateful side effects in the computation.

The loop divides only when b is nonzero. For nonnegative inputs the remainder
is nonnegative and less than b; assigning (b, remainder) therefore decreases
the nonzero second argument and preserves the set of common divisors. The
implementation performs no multiplication/addition that could overflow; the
signed MIN/-1 division case is excluded by the nonnegative precondition.
When b becomes zero the returned a is the specified greatest common divisor.

## Coverage gap and subsequent checks

The original five small fixtures tested basic zero cases and a coprime pair but
not native-width boundaries, narrowing regressions or broad small-input behavior.
They remain unchanged. Added fixed cases cover signed-64-bit maximum/equality,
maximum/zero, adjacent large integers, values beyond signed-32-bit range, and a
longer remainder chain. Ruby additionally checks a 200-bit common factor.
Each source now compares all 1089 pairs in [0,32] squared with an independent
enumeration of positive common divisors. The reference is not another Euclid
implementation and does not call the function under test to construct answers.

Go/Rust have 10 fixed fixtures plus the oracle grid; Ruby has 11 plus the grid.
The successful local source-bound run is f66fb77c580a4dfaba4d38960f073c8b;
its raw history records include hashes, runtime versions and exact commands.
Linux CI replay must still be inspected separately; the local native run is
the current execution basis, not a claim of unobserved cross-platform results.

## Outcome and limits

Candidate with the stated scope, conditional on a matching execution pass.
The review does not clear other family members, validate out-of-contract input,
establish model performance, or certify evaluation-set independence. A source
edit or document edit invalidates this acceptance until a new bound review.
This document is immutable for these review records; later evidence belongs in
the pass report or a new review revision, not an unrecorded edit here.
