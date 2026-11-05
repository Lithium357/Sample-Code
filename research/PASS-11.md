# Research pass 11: borrowed resumable scatter input

curated/rust/vectored_fill.rs is an original Rust edition-2021 example using
standard-library Read and IoSliceMut::advance_slices (Rust 1.81+). It keeps an
exclusive borrow of caller-owned scatter destinations while tracking a committed
prefix. drive() fills capacity or returns the original read error plus cumulative
filled count. Interrupted is retried, WouldBlock is returned to the caller, and
Ok(0) reports UnexpectedEof. Retrying uses the same plan and logical source.
Earlier committed data survives failure; no atomicity, rollback or readiness wait.

The plan offers at most sixteen vectors per read, skips empty buffers and supports
Read's default scalar fallback. It never reads for an already complete/zero-capacity
plan. A reader reporting more than offered is rejected before cursor advancement;
illegal reader side effects cannot be undone. The implementation uses safe Rust.
API consulted without copying its example: https://doc.rust-lang.org/std/io/trait.Read.html

## Evidence

Command: Python work/run_native.py --research --path
curated/rust/vectored_fill.rs --require-tools. The source-bound controller compiles
with rustc --edition=2021 -D warnings, then again with -C opt-level=2 -C
debug-assertions=no. Both binaries must execute their always-on assertions and
print success. Exact argv, compiler version/host, hashes and output are recorded.
Final local run: 3ca1328048bf4adc8f1615feeaac6e9a.

Independent flat-prefix byte/canary oracles cover 208 layouts (including empty
buffers, more than sixteen buffers and thirty-three leading empties), five read
limits, both scripted vectored and scalar fallback readers, and three extra
error/cause contracts. Every possible early-EOF prefix of a nine-byte destination
is checked. Interrupted occurs both before and after progress; repeated WouldBlock
must return without a hidden readiness retry or lost prefix. Source bytes beyond
the destination remain unread. A custom error payload is downcast and compared,
then the same plan resumes. An overreporting reader is rejected after a valid
one-byte prefix. Only these finite injected transports are claimed, not socket
readiness, OS readv/syscall execution or exhaustive transport correctness.

Three deliberately broken variants must fail: overwrite cumulative progress,
omit slice advancement and return Interrupted instead of retrying it. A separate
compile control requires E0502 when external immutable access is attempted while
the plan's exclusive borrow remains live. Control material and failed snapshots
are excluded from ordinary working-code training exports. Two initial controller
diagnostic mismatches are preserved and explained in fixes.md; no original
implementation failure or changed expected byte answer is claimed.

## Family and remaining scope

Input and the retained vectored_cursor.rs output are close variants. Both now use
io.resumable-vectored-transfer for dataset split grouping; the output source,
generation task and original evidence are unchanged. Its former family name
io.resumable-vectored-output remains visible in historical documents. The family
metadata edit is recorded in changes.jsonl. These are related synthetic examples.

No realistic memory-allocation path can exercise the checked total-length overflow
guard within this small fixture, and no all-address-space proof is claimed.
No Miri, native syscall/readiness, endless-Interrupted liveness or every Rust
version claim. The source's minimum API version is distinguished from the actual
compiler probe. Prior-output/destination prefixes are observable on failure.

Available task/provenance: provenance/research-pass-11.txt and session.json.
Model family GPT-6, exact generation build unavailable. No benchmark/evaluation
problem or solution was intentionally imported, and these self-checks are not
Morderca performance measurements. Generated/executed/candidate volumes are
refreshed in volume.json; repeated builds and controls contribute no source volume.
The preceding PowerShell CI checkpoint is recorded in PASS-10.md; new Rust CI is
pending until its own workflow is observed terminal.

Local compiler actually observed: rustc 1.98.1, x86_64-pc-windows-msvc,
LLVM 22.1.8. Both builds report 2092 differential/error cases passed, followed
by three caught execution mutants and the expected E0502 compile rejection.
One new file contributes 2937 cl100k_base tokens. Refreshed generated and
execution-validated totals are 242724 tokens / 371 files; candidate volume is
77693 tokens / 62 files. Held legacy volume remains 165031 tokens / 309 files.
Counts are full files including comments/inline fixtures, not lexical code-only
or Morderca-tokenizer counts. Family regrouping adds no source volume.

Subsequent CI checkpoint: source d5deeec833ce37642964d8484d6512a17ae0fe0c,
workflow42064487667, all six jobs completed successfully. Six digest-verified
research artifacts contributed sixteen new immutable history files. Current
Rust source Linux run 63467a4612b7442283a7c66fa8061cab passes both builds,
three execution controls and the E0502 gate. Actual compiler probes are in that
record; this adds Linux evidence without claiming every supported compiler/host.
