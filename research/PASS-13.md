# Research pass 13: C++ object lifetimes and generational handles

curated/cpp/generational_pool.cpp is an original C++20 standalone example in
lifetime.generational-slot-pool. It owns fixed aligned byte storage for 1..64
objects, uses construct_at/launder/destroy_at, and never relocates live objects.
It publishes occupancy only after successful construction. Constructor exceptions
preserve logical pool state; external constructor side effects are not rolled
back. The element must have noexcept destruction; calls are nonconcurrent and
constructors/destructors must not reenter the pool.

Handles include owner, slot and generation. Erased/cleared handles cannot revive;
a slot retires permanently at its generation limit. Pool copy/move are disabled.
Raw borrows end at erase/clear/destruction. Handles are valid for queries only
while the originating pool remains alive: this is not an across-lifetime address
reuse/ABA mechanism or a concurrent reclamation scheme.

## Checks and meaningful limits

Local fixture covers constructor rollback while another object stays live,
member cleanup after failed complete-object construction, no destruction of the
failed complete object, unchanged generation on failure, full-before-constructor
precedence, wrong-owner and invalid handles, duplicate erase, stale reuse, clear
and repeated clear, scope-exit cleanup, immovable elements and 64-byte alignment.
The maximum capacity 64 is filled and destroyed. Separate lifetime/token counters
must balance, including constructor exceptions. Pool mutations and PRNG state
updates are outside assertion expressions; NDEBUG builds reject explicitly.

10000 deterministic model steps maintain an independent logical collection of
requested live values and stale handles. Values are not generated from pool
lookups. Each step checks live size, reusable capacity, element self-address,
values and lifetime counters; sampled/final stale handles must reject. This
is a finite model/invariant check, not exhaustive object-pool correctness.

End-to-end retirement uses policy limits 1 and 3, including failed constructors
before successful generation use. The exact production epoch-step helper is
also checked with literal uint64 max-1/max expectations, permitting the real
integer boundary without simulating 2^64 object lifetimes. No full-lifetime
uint64 stress run, ambient OOM, throwing destructor runtime, thread/race or
post-pool-lifetime handle guarantee is claimed.

Five execution mutants must fail: early occupancy publication, omitted generation
change, disabled retirement, omitted owner check and generation consumed by a
failed constructor. Five compile gates reject copy, throwing destructor, capacity
0/65 and generation limit 0. Negative variants are excluded control material.
Windows fixture failures route CRT diagnostics to stderr rather than a dialog.
The assertion-disabled controller also compiles/runs all twelve present C/C++
fixtures normally, then requires explicit NDEBUG rejection. This is a controller
rerun, not a new exhaustive audit of those twelve implementations.

## Evidence scope and lineage

Commands: Python work/run_native.py --research --path
curated/cpp/generational_pool.cpp --require-tools; and Python work/run_native.py
--correction --phase after --temp-root work. Exact absolute commands, runtime
versions, source/harness hashes and observed results are in immutable history.
Local execution is MSVC native Windows; Linux ASan/UBSan flags are preserved in
the dedicated adapter, but new-source Linux results remain pending until observed.
No ordinary implementation failure was observed during this batch.

Available provenance, human excerpts and labeled agent-selected task are in
provenance/research-pass-13.txt and session.json. Model family GPT-6, exact build
unavailable. C++ draft references were consulted without copying examples:
https://eel.is/c++draft/specialized.construct and https://eel.is/c++draft/ptr.launder .
No standardized benchmark/evaluation material was intentionally imported. These
self-checks do not measure Morderca. Counts include source comments/inline fixtures;
controllers, mutants, logs and reports contribute no source-token volume. Legacy
holds remain unchanged. Prior AArch64 CI cancellation and successful GNU-linked
checks are recorded separately in PASS-12.md and evidence/ci-status.

Complete local source run: 9f6bdf38de6042feaa1c4848716fabe5, MSVC 19.51.36257 x64.
It passes ordinary execution, five execution mutants and five compile gates.
Current-source NDEBUG controller: 65f2290ce75c478ead2baaed330eeb57, twelve normal
executions and twelve guard-specific build rejections. Earlier positive revisions
remain recorded. No failed ordinary or controller run occurred in this new batch.

Volume checkpoint: one new file / 3153 cl100k_base tokens. Generated and
execution-validated totals are 247182 tokens / 374 files; candidate volume is
82151 tokens / 65 files. Legacy holds stay 165031 tokens / 309 files. Full-file
counts include comments and inline fixtures, not a lexical component split or
Morderca-tokenizer count. Repeated builds and negative fixtures add no volume.

Final controller refinement: original disabled-retirement mutant produced MSVC
C4100 for its deliberately unused limit parameter. Linux uses -Werror, so the
mutant now explicitly discards limit before the same false guard. Ordinary source,
compiler flags and expected assertion are unchanged; no Linux failure is inferred
from the Windows warning. Final local controller run
37f39ad17b0d47e9be938b4564cfde2c passes all ten controls with that refinement.

Publication integrity check stopped the first attempt before main advanced:
TextDecoder removed the raw CI log's leading UTF-8 BOM. The decoder now preserves
it and its cache was cleared; raw evidence/digest stay unchanged. The mismatch
and fix are in evidence/ci-status/publication-events.jsonl. This is publication
control evidence, not a working C++ implementation failure.

Resumed publication/CI checkpoint: source
6e1d58b85f5849a31c0349e11d2c7326133eb426 was published after confirming main
had not advanced, preserving original BOM bytes and verifying all 1146 blobs.
Workflow42311224062 completed successfully in all six jobs. Six digest-verified
research artifacts contributed seventeen new immutable history files. Current
pool Linux run a45e3e50eec04241af6461b5cc17015e passes native execution under
-fsanitize=address,undefined, all five execution mutants and all five compile
gates. This adds actual Linux sanitizer evidence to the earlier Windows results.
The prior AArch64 workflow cancellation remains recorded, not overwritten.
