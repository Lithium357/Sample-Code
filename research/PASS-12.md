# Research pass 12: A64 packed samples and callback frames

New module curated/assembly/aarch64/packed_s24.s contains related decoder and
visitor entry points in one binary.signed24-decoder-visitor family. Exact target:
Armv8-A A64, little endian, GNU syntax, AAPCS64 LP64, no OS calls or unwind
metadata. A two-uint64 aggregate returns status and consumed bytes in x0/x1.
The contract specifies 0..32 samples, disjoint valid ranges, any source byte
alignment and 4-byte-aligned int32 output. Count errors precede size errors.
The accompanying JSON file contains four literal independent wire/value fixtures.

unpack_s24le sign-extends three-byte little-endian samples into 32-bit words.
Rejected count/size performs no input access or output writes. visit_s24le calls
an AAPCS64 callback with opaque context, signed 64-bit value and index. Any
nonzero 64-bit result stops, including high-bit-only results; consumed includes
that sample. Earlier callback effects persist. The visitor saves its frame/link
and callee registers. Callbacks must return normally and leave input unchanged.

## Execution evidence

Command: Python work/run_native.py --research --path
curated/assembly/aarch64/packed_s24.s --require-tools. Final source-bound run:
367e4a8fe4a14b3383574614e4651b2d. Mode: emulation, Keystone 0.9.2 assembly of
marked bodies and Unicorn 2.1.4 execution, not hardware, ELF loading or OS
emulation. Actual Python/platform versions, source/support/harness hashes,
invocation, image hash and observed results are in immutable history.

947 configurations run both entry points: 1894 executions. Cases cover every
supported count, short/exact/extra sizes, unsigned register-domain boundaries,
four source alignments, signed extrema, NUL/high bytes, and callback stop at
first/middle/last samples with low/high-only results. Empty/error cases pass null
pointers to catch unintended dereferences. Independent Python signed-byte
decoding and literal anchors supply expected output.

Memory hooks reject reads beyond consumed input and writes beyond valid output
or the owned 64-byte frame. Full output/canary and source snapshots are checked.
Callbacks verify context/value/index and 16-byte SP alignment, then poison
x0..x17 and caller-saved SIMD registers. Return checks cover x18..x29, low 64
bits of v8..v15, restored SP, return PC, status and consumed count. This finite
instrumentation is not exhaustive platform ABI certification.

Five deliberate bodies must fail: zero-extension, ignoring high callback result
bits, clobbering x19, a signed count guard, and an omitted short-source guard.
The last produces read address zero. An initial probe observation failure is
preserved with its source/harness snapshots; see fixes.md. The ordinary source
and expected answers were unchanged by that observation fix.

## GNU/native distinction and remaining scope

Explicit local --aarch64-linked --require-tools run
6222197d14b64cd38c950a16f4fcfb54 is not_tested: GNU cross-as is missing. New
Linux CI requires binutils-aarch64-linux-gnu, assembles full source with
-march=armv8-a, links at 0x100000, checks ELF64 LE/AArch64/entry metadata,
extracts .text, requires byte identity with Keystone and executes that text under
Unicorn. That new CI result remains pending until observed. Linking is not
native execution. Neither mode checks a loader, C compiler interoperability,
unwinding, hardware alignment faults or callbacks violating their contract.
ARMv7 remains limited to its prior folded-buffer example.

Task/provenance: provenance/research-pass-12.txt and session.json. Model family
GPT-6; exact build unknown. ABI reference consulted, no example copied:
https://github.com/ARM-software/abi-aa/blob/main/aapcs64/aapcs64.rst . No
standardized benchmark/evaluation source was intentionally imported. These
checks validate related synthetic examples, not Morderca performance.

Source and fixture tokens are separated by file role in refreshed volume/lineage.
Probe code, mutants, snapshots, logs and reports add no source volume. The 309
legacy holds remain. The completed prior Rust CI checkpoint is in PASS-11.md.

Volume checkpoint: new assembly source 1200 cl100k_base tokens and literal JSON
fixtures 105 tokens, 1305 total in two files belonging to one module/task family.
Generated and execution-validated totals are 244029 tokens / 373 files. Candidate
volume is 78998 tokens / 64 files. Legacy holds stay 165031 tokens / 309 files.
Whole-file counts include source comments; no lexical code/comment separation or
Morderca tokenizer is claimed. Emulated execution remains labeled emulation.

Subsequent CI observation: workflow42067176616 for source
e697052bdfbd6db4e847c88544878a722a180482 ended cancelled overall. Five jobs,
including the Linux job with the required GNU-link step, succeeded. A separate
Linux breadth job cancelled after repeated artifact-finalization retries; its
test steps completed and its artifact finalized. Exact cancellation cause is not
established. Raw log/hash and job conclusions are preserved in evidence/ci-status;
the whole workflow is not reported as passed.

Six digest-verified research artifacts contributed seventeen new history files.
Current-source Linux runs 4be94fb2fec04780affcb6adf1f7b46c and
7bc75469431946e3b3bee25b19cd01ac passed 1894 executions and five controls using
GNU-assembled/linked text. Object, ELF and raw-text hashes are recorded; raw text
matches the Keystone image. This verifies GNU assembly/linking plus emulated
execution, not native hardware or ELF loading. The original local missing-tool
record remains not_tested and is not overwritten by this separate Linux result.
