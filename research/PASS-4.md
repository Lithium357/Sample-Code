# Research pass 4: allocation, streaming text and RISC-V execution

Automatic continuation of the active broad-language quality-gated volume goal.
Prompts and inherited human steering: `provenance/research-pass-4.txt`.
Exact generation model build remains unknown. No standardized benchmark or
evaluation material was intentionally used. All new fixtures are local.

## First batch

C++20 `pmr_catalog.cpp` implements transactional replacement using polymorphic
allocators. It validates names before allocation, builds using the existing
resource identity, and commits by swapping equal-allocator containers. Tests
inject failure at successive allocation requests until the operation completes,
checking unchanged contents and complete cleanup on each failure. They also
cover aliased input views, duplicate/empty/oversized names, NUL bytes and exact
limits. Long-string allocation assertions target the tested MSVC/libstdc++
implementations, not an unverified universal small-string-storage threshold.

Rust `incremental_utf8.rs` wraps the standard-library UTF-8 validator with a
streaming tail, byte offsets, sticky malformed-input errors, explicit finish/
reset transitions and recoverable size-limit errors. Tests partition valid
inputs at every pair of byte boundaries, compare buffered decoding against
whole-input std validation, and use literal malformed-byte/error fixtures.
This is an independent check of buffering/state behavior, not a claim of two
independent Unicode validation algorithms. Both examples passed locally.

## Retained RISC-V example

The bounded ASCII-fold source remains in the shared ISA task family
`buffer.bounded-ascii-fold`. Its original generation task remains pass 1;
pass-4 edits and validation are subsequent work, not a new independent example.
The source now disables linker relaxation and describes validation modes rather
than carrying a permanently hardcoded untested label.

The new adapter uses real GNU RV64 cross-as/ld/objcopy, links .text at a known
address, checks the ELF machine/type/entry, and executes the resulting .text in
Unicorn. It does not patch unresolved branch relocations itself. Checks cover
411 vectors, high-bit unsigned length/capacity values, all byte values, null
zero-copy pointers, source immutability, exact memory access bounds, destination
canaries, stack and preserved integer registers. Two valid-code negative
controls must fail their intended assertions: disabled folding and clobbered s0.

The LP64 saved-register contract was checked against the
[RISC-V psABI specification](https://riscv-non-isa.github.io/riscv-elf-psabi-doc/).
The tested scope is linked-text emulation: not native hardware, an ELF loader,
OS behavior, timing, or relaxed-link optimization behavior. The local Windows
host has Unicorn but lacks the GNU cross-tools; its attempt is recorded as
not_tested. CI installs the cross-tools and records the actual result. A prior
syntax-only pass is not promoted retroactively into execution evidence.

Current counts and source-bound results are in `volume.json` and
`evidence/history/`. Native/managed execution and emulation remain distinguished.
The long-run target remains active; documentation/harnesses/logs are not source
volume, and a rerun adds no tokens by itself.

## Second batch

PowerShell `should_process_markers.ps1` buffers pipeline records before writing,
uses terminating structured validation errors, and honors WhatIf/Confirm through
ShouldProcess. Its owned-file fixtures check dry-run creation and replacement,
unchanged bytes, strict UTF-8 without BOM, canonical replacement of UTF-16 files,
case-insensitive duplicate detection, Windows device stems on every host, scalar
types, invalid surrogates, byte-count limits and path-safe directory cleanup.
Prevalidation is batch-wide; I/O application is deliberately per-file, not a
claim of an atomic filesystem transaction. The root must be owned, free of
concurrent writers and symlink tricks. The minimum runtime is PowerShell 7.2.

Nim `wire_schema.nim` generates typed enums, parsers and exhaustive serializers
from a literal schema using AST nodes, fresh parameter symbols and escaped
string literals. Tests cover exact values and unknowns, metacharacter literals,
the eight-byte wire boundary, nine compile-time invalid-schema checks and one
cross-enum type rejection. These are actual compiler semantic checks through
compiles, not runtime rejections. Macro APIs and semantic-check behavior were
checked against [std/macros](https://nim-lang.org/docs/macros.html) and
[system.compiles](https://nim-lang.org/docs/system.html#compiles%2Cuntyped).
The example passed local JS/Node and native C/MSVC backends. CI adds the
distribution Nim compiler and the Linux native backend.

The first batch passed [CI run 41592825399](https://github.com/Lithium357/Sample-Code/actions/runs/41592825399).
Its five research artifacts were SHA-256 verified before ten new raw history
files were imported. The RISC-V record confirms emulation success for the
current source hash, all 411 vectors and both intended negative-control failures.
This is new execution evidence, not a relabeling of prior syntax-only results.

## Third batch

PHP `delegated_cleanup.php` exercises yield-from forwarding of keys, values,
return counts and injected exceptions. Its fixture contract acknowledges a row
only after its yield resumes normally; an injected SkipRow skips acknowledgment.
Tests assert exact source/delegate finally order, retained references after
foreach break, cleanup after unset, unstarted generators, duplicate stream keys,
getReturn before/after completion, exception identity and lazy validation errors.
The schema intentionally requires ordered id/value array keys and integer values
0..99; already emitted values cannot be rolled back. It passed locally without
I/O or external packages. CI supplies the second PHP runtime on Linux.

## Fourth batch: two more language families

Perl `folded_tie.pl` implements a tied hash with canonical ASCII keys, correct
undef-versus-absence behavior, scalar counts, and one sorted key-snapshot
iterator. Tests modify values, delete keys and insert keys during iteration,
check live values versus snapshot keys, verify reference aliasing, reject bad
accesses without mutation and exercise key-length limits and clear/assignment.
The interpreter's tie hooks are checked against the
[Perl tie contract](https://perldoc.perl.org/perltie); this is a purpose-written
implementation, not a copied tutorial or benchmark solution.

GNU AWK `transactional_totals.awk` uses nested arrays and an asorti comparator to
merge LF/tab chunks with deterministic numeric/tie ordering. A temporary nested
array holds the whole candidate update before publication. Fixtures assert
literal summaries, exact line/kind errors, rollback after a valid prefix, empty
chunks, 16-zone limits, 1000-row limits and the exact 1-billion integer total.
Quantities are bounded so all arithmetic remains within exact binary64 integers.
The dialect is explicitly GNU AWK, not POSIX awk; LC_ALL=C is recorded per run.

Git's bundled Perl 5.42.3 and GNU AWK 5.4.1 passed local self-checks. Their first
capability probes inside the restricted Windows sandbox failed while creating
an MSYS shared-memory object, before any sample source was executed. Version
probes and formal source-bound tests succeeded outside that restriction. CI
selects the same bundled executables on Windows and distribution Perl/gawk on
Linux, without CPAN packages or remote services.

## Final checkpoint and evidence

All four source batches passed CI:

* `cb68552c710af8ea27ca667da703e88ed5cf39b5`:
  [run 41592825399](https://github.com/Lithium357/Sample-Code/actions/runs/41592825399).
* `8c2039f54589207e1164bc60dc2973688ef2b9d1`:
  [run 41593940314](https://github.com/Lithium357/Sample-Code/actions/runs/41593940314).
* `ef6b085484f6589124629d3a5fa83a7d355c74cd`:
  [run 41594174256](https://github.com/Lithium357/Sample-Code/actions/runs/41594174256).
* `5d022c0bbcbd2c36b5564541b4f0a03d85ec6975`:
  [run 41595985540](https://github.com/Lithium357/Sample-Code/actions/runs/41595985540).

The last run passed Linux, Windows, PostgreSQL and both language-breadth jobs.
All twenty research artifacts were SHA-256 verified before forty new raw history
files were imported; artifact identities and workflow commits are recorded in
`evidence/ci-imports.jsonl`. Current source hashes were checked against passing
Linux and Windows records for every new file. Later publication adds evidence,
documentation and reporting updates; the tested example bytes are unchanged.

| New source | cl100k_base tokens | Passing scope |
| --- | ---: | --- |
| C++ PMR catalog | 1,499 | Windows/MSVC; Linux/GCC with ASan/UBSan |
| Rust incremental UTF-8 | 1,496 | Windows and Linux Rust |
| Nim wire schema | 1,177 | Windows/Linux, JS and native C backends |
| PowerShell marker writer | 2,226 | Windows and Linux PowerShell |
| PHP delegated cleanup | 1,194 | Windows and Linux PHP |
| Perl tied hash | 1,228 | Windows Git-bundled Perl and Linux Perl |
| GNU AWK totals | 1,471 | Windows Git-bundled GNU AWK and Linux gawk |
| **Seven new source files** | **10,291** | **All have current-source execution evidence** |

The retained RISC-V source is 363 tokens, compared with 342 before its directive/
comment update. It now has new linked-text emulation evidence. Generated volume
therefore increased by 10,312 tokens, while execution-validated volume increased
by 10,654 tokens. The 363-token retained file is not counted as a new example.

| Collection metric | Files | cl100k_base tokens |
| --- | ---: | ---: |
| Generated source/support | 352 | 203,051 |
| Current-source passing execution | 351 | 202,404 |
| Curated training candidates under the lineage policy | 38 | 37,191 |
| Legacy origin/coverage review still required | 313 | 165,213 |
| T-SQL without execution evidence | 1 | 647 |

### Quality-goal counting clarification

The older execution total is preserved as a technical metric. It does not clear
the existing legacy origin/coverage hold. The approximately 2B-token goal now
uses the separately reported training_candidate_tokens field: 37,191 tokens,
or 0.00185955% of the target. The target and full task scope are unchanged.
Earlier percentages described execution volume only; this clarification is
append-only in `evidence/corrections.jsonl`, and original reports are retained.
Candidate status records available provenance and meaningful checks, not an
independent proof of benchmark absence or exhaustive correctness. Legacy files
can qualify only after a documented source-bound review, not a blanket relabel.

Whole-file roles total 193,788 source-with-inline-fixture tokens, 8,390 source,
293 separate fixture and 580 support-source. These are file roles, not a lexical
code/comment/test split. Control, prompts, snapshots, reports and repeated runs
add no source tokens. No Morderca tokenizer or performance evaluation was used.

There were no unexpected sample-test failures in these new source cases.
The local missing RISC-V toolchain is explicitly not_tested; MSYS capability
probe startup failures and their resolution are in `evidence/setup-probes.jsonl`.
Older failed results/snapshots remain intact. Native ARM/AArch64/RISC-V hardware,
ELF loading, T-SQL execution and the retained legacy audit remain outstanding.
The long-running goal remains active.
