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
requires matching family, accepted outcome, unchanged document, unchanged source
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
