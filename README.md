# Sample Code

## Imported vx-underground collection

The upstream collection is sorted into language folders such as
[`assembly/vxunderground/`](assembly/vxunderground/),
[`c/vxunderground/`](c/vxunderground/),
[`php/vxunderground/`](php/vxunderground/), and
[`python/vxunderground/`](python/vxunderground/).
See the [complete category index and provenance](imports/vxunderground.md)
and [per-file location map](imports/vxunderground-files.json).

Retained code/build/archive bytes, filenames and file modes are preserved. Imported
documentation, images, standalone compiled artifacts and opaque non-source files
were removed at the user's request. Packed archives with
no established implementation language are in [`unknown/vxunderground/`](unknown/vxunderground/).
Source projects keep their required build support together. Existing validation
results and token counts below cover the original Sample-Code examples;
imported samples have not been executed or included in the training-candidate export.

<!-- current-inventory:start -->
## Original example language inventory and token counts

The original example snapshot contains **20 programming/query languages plus JSON fixture data**,
represented by **27 inventory categories** when SQL dialects, assembly targets
and the two SQLite collection labels are kept separate. The complete language
list is: **Assembly, AWK (GNU gawk), Bash, C, C++, C#, CMD/batch, F#, Go,
JavaScript, Lua, Nim, Perl, PHP, PowerShell, Python, Ruby, Rust, SQL and Tcl**.
SQL covers **SQLite, PostgreSQL and Microsoft SQL Server/T-SQL**. Assembly covers
**x86-64, AArch64, ARMv7 and RV64**; exact ISA subsets, ABI, syntax and execution
assumptions are stated in each source and its evidence. Category membership
does not imply native execution on every architecture or cross-platform support.

Counts below use **`cl100k_base`, tiktoken 0.14.0**, independently tokenizing each
UTF-8 source/support file with normalized newlines. These are **not Morderca
tokenizer counts**. Files can be modules, drivers or fixtures rather than
standalone programs. Comments and inline self-checks are included.

| Language / dialect / target | Files | Generated tokens | Execution-validated tokens | Training-candidate tokens |
| --- | ---: | ---: | ---: | ---: |
| Assembly — x86-64, NASM, Linux / System V AMD64 | 21 | 19,419 | 19,419 | 2,998 |
| Assembly — AArch64, GNU syntax / AAPCS64 | 2 | 1,526 | 1,526 | 1,526 |
| Assembly — ARMv7, GNU syntax / AAPCS | 1 | 309 | 309 | 309 |
| Assembly — RV64, GNU syntax / RISC-V calling convention | 2 | 1,116 | 1,116 | 1,116 |
| AWK — GNU gawk | 1 | 1,471 | 1,471 | 1,471 |
| Bash | 29 | 18,767 | 18,767 | 4,567 |
| C | 5 | 9,830 | 9,830 | 3,817 |
| Windows CMD / batch | 24 | 15,515 | 15,515 | 1,383 |
| C++ | 7 | 12,167 | 12,167 | 7,638 |
| C# | 1 | 1,776 | 1,776 | 1,776 |
| F# | 2 | 3,385 | 3,385 | 3,385 |
| Go | 38 | 25,668 | 25,668 | 7,102 |
| JavaScript | 1 | 1,071 | 1,071 | 1,071 |
| JSON — fixture data format | 1 | 105 | 105 | 105 |
| Lua | 1 | 1,902 | 1,902 | 1,902 |
| Nim | 45 | 24,337 | 24,337 | 6,544 |
| Perl | 2 | 3,144 | 3,144 | 3,144 |
| PHP | 39 | 20,586 | 20,586 | 5,316 |
| PowerShell | 37 | 22,862 | 22,862 | 7,583 |
| Python | 2 | 1,857 | 1,857 | 1,857 |
| Ruby | 45 | 20,124 | 20,124 | 5,647 |
| Rust | 39 | 24,449 | 24,449 | 9,253 |
| SQL — SQLite, original / advanced collection | 26 | 13,719 | 13,719 | 564 |
| SQL — PostgreSQL | 2 | 1,523 | 1,523 | 1,523 |
| SQL — SQLite, curated collection | 1 | 153 | 153 | 153 |
| SQL — Microsoft SQL Server / T-SQL | 1 | 1,964 | 1,964 | 1,964 |
| Tcl | 2 | 3,048 | 3,048 | 3,048 |
| **Total** | **377** | **251,793** | **251,793** | **86,762** |

**Training candidates: 68 files / 86,762 tokens.** **Legacy files held for review: 309 files / 165,031 tokens.**

Execution-validated means current source hashes have successful recorded
execution in their stated mode: host-native, managed runtime, transpiled
JavaScript or emulation. Syntax-only checks and missing tools do not qualify.
This is accumulated source-bound evidence, not a claim that every file was
rerun during this README update. Candidate status is a selection gate, not
independent certification of correctness, provenance or evaluation-set absence.

Whole-file roles separate dedicated fixtures where practical:

| File role | Tokens |
| --- | ---: |
| `source_with_inline_fixtures` | 236,804 |
| `source` | 12,274 |
| `fixture` | 2,135 |
| `support_source` | 580 |

Comments and inline fixtures have not been lexically split out; these file-role
totals must not be described as code-only token counts. The complete per-file
counts, SHA-256 hashes, task families, provenance and eligibility are in
[`research/lineage.jsonl`](research/lineage.jsonl); machine-readable totals are in
[`research/volume.json`](research/volume.json). Validation commands, tool versions,
source/harness hashes, failures and execution modes remain in
[`research/evidence/history/`](research/evidence/history/).

For a separate **whole-repository text count**, including documentation,
controllers, provenance, historical evidence and deliberate broken controls,
see [`research/repository-token-inventory.json`](research/repository-token-inventory.json).
That report lists every counted file and hash, category subtotals and exclusions;
it excludes itself to avoid self-reference. Repository text is not training-code
volume. Broken controls remain evidence and are excluded from the ordinary
working-code candidate export.

Generation remains paused at the user's request. The pending Nim scoped-reader
batch and its native validation are documented in
[`research/PASS-15.md`](research/PASS-15.md). The older table below is retained
solely as a historical record of the initial ten-language collection.
<!-- current-inventory:end -->


**Research-quality records:** see [`research/README.md`](research/README.md),
[`research/volume.json`](research/volume.json), and the source-bound evidence history.
The [second research pass](research/PASS-2.md) adds ten varied units, including
binary codecs, command/query parsing, keyed concurrency, streaming CSV, retries,
generic sequences, argument parsing, PostgreSQL windows and NASM buffers.
The [third pass](research/PASS-3.md) expands language breadth and uncommon
runtime contracts toward the user's long-running quality-gated volume goal.
The [fourth pass](research/PASS-4.md) adds allocation-failure, streaming,
compile-time schema, ShouldProcess and generator-lifecycle checks, and executes
the retained RISC-V function under explicitly labeled emulation.
The [fifth pass](research/PASS-5.md) adds byte-safe C packets, Ruby Fiber lifecycle,
Bash descriptor scope and CMD literal expansion, fixes SQLite storage-type
validation, and reviews four retained files under hash-bound acceptance.
The [sixth pass](research/PASS-6.md) adds resumable Rust vectored output, C++
stream ownership, Lua closing iterators, PowerShell provider reads, Nim ARC
ownership and Tcl snapshot events. It also adds native SQL Server CI evidence
for the retained T-SQL fixture.
The [seventh pass](research/PASS-7.md) strengthens T-SQL migration checks and
adds conditional Go snapshots, PHP stream filters, waited Bash process sources,
and related NASM/RV64I protocol decoders with distinct execution modes.
The [focused correction audit](research/AUDIT-8.md) reproduces unchecked SQL
outputs and assertion-disabled false passes, then strengthens exact outputs,
build gates and sampled independent prime oracles.
The [ninth pass](research/PASS-9.md) adds strict Ruby chunked transcoding and
Perl dynamically scoped binary records with independent byte/partition oracles.
The [tenth pass](research/PASS-10.md) adds PowerShell owned pipeline streams,
cleanup across early stop/errors, cancellation and fresh output buffers.
The [eleventh pass](research/PASS-11.md) adds exclusive borrowed Rust scatter
input with retained progress, independent prefix checks and an alias rejection
control, grouped with its related output example for dataset splitting.
The [twelfth pass](research/PASS-12.md) adds AArch64 packed signed samples and
callback frames, with access/ABI instrumentation and distinct linked-text
emulation versus native-hardware claims.
The [thirteenth pass](research/PASS-13.md) adds C++ aligned in-place object
lifetimes, constructor rollback and stale-handle retirement with model and
compile-time contract checks.
The [fourteenth pass](research/PASS-14.md) adds F# applicative error accumulation,
dependent measured validation and an independent grammar oracle, preserving its
initial compiler failures and excluding ill-typed controls from training export.
The original token table below is a historical generation snapshot, not current
source-bound validated volume. Its tokenizer is `cl100k_base`, not Morderca's.

**Additional, separately authored advanced programs live in [`advanced/`](advanced/README.md).**
They have their own catalog and verification runner; the counts below describe
the original parallel algorithm collection.

The original collection contains 268 standalone examples across ten languages, approximately 10,000 BPE tokens
per language. The folders below follow the requested bottom-to-top order.

| Order | Language | Folder | Programs | Source tokens |
| --- | --- | --- | ---: | ---: |
| 1 | Nim | `nim/` | 32 | 10,241 |
| 2 | CMD / batch | `cmd/` | 19 | 10,590 |
| 3 | Assembly | `assembly/` | 13 | 10,614 |
| 4 | PowerShell | `powershell/` | 30 | 10,228 |
| 5 | SQL | `sql/` | 23 | 9,988 |
| 6 | Bash / shell | `bash/` | 22 | 10,269 |
| 7 | Rust | `rust/` | 31 | 10,377 |
| 8 | Ruby | `ruby/` | 38 | 10,227 |
| 9 | Go | `go/` | 28 | 10,020 |
| 10 | PHP | `php/` | 32 | 10,307 |
| | **Total** | | **268** | **102,861** |

Counts use the `cl100k_base` BPE encoding, summed independently for each UTF-8
source file. They include comments and executable fixtures. Documentation,
manifests, generator code, verification tools, and workflow files are excluded.
Other BPE vocabularies will produce different totals. CMD source preserves CRLF;
token counting reads normalized text, as documented by the counter script.

## What is included

The nine non-SQL folders contain original, generated parallel implementations
of a shared collection of bounded integer algorithms. Examples cover Euclid's
algorithm, exponentiation, primality and factorization, combinatorics, digit and
bit operations, modular arithmetic, calendar rules, and recurrence sequences.
Each program has explicit expected results and returns a failure status when a
fixture fails. Different syntactic overheads mean each language contains a
different-sized subset of the specifications.

SQL has separately authored relational scenarios: inventory ledgers, recursive
organization trees, calendar gap filling, event sessions, running balances,
cohort retention, deduplication, version-aware upserts, graph traversal, ranking,
consecutive-day streaks, effective-dated joins, audit triggers, booking overlap
prevention, relational division, keyset pagination, FIFO stock allocation,
proportional integer allocation, staging-data cleanup, pivots, quantiles,
reconciliation, and savepoint rollback.

This is a synthetic educational collection. Related algorithms are intentionally
shared across languages; the files are not samples from independent projects.
The implementations favor straightforward control flow and inspectable integer
arithmetic over language-specific libraries. The original example collection has no vendored dependencies
or copied third-party source files; the separately imported archive above retains
its own upstream provenance.

## Run individual examples

Run each source file independently. Multiple files in a folder have their own
entry points; for Go, select a single file rather than running the whole folder.
The programs need no application dependencies or external services.

```text
nim c -r nim/sample_01_gcd.nim
cmd /d /c cmd\01_gcd.cmd
pwsh -NoProfile -File powershell/01_gcd.ps1
sqlite3 :memory: ".bail on" ".read sql/01_inventory_ledger.sql"
bash bash/01_gcd.sh
rustc --edition=2021 rust/01_gcd.rs -o demo
ruby ruby/01_gcd.rb
go run go/01_gcd.go
php php/01_gcd.php
```

For Rust, run the compiled `demo` binary (`./demo` on Unix, `demo.exe` on Windows).
For assembly, use a Linux x86-64 host with NASM and the GNU linker:

```sh
nasm -f elf64 assembly/01_gcd.asm -o demo.o
ld demo.o -o demo
./demo
echo "$?"
```

Assembly uses NASM Intel syntax, ELF64, Linux system calls, and System V argument
registers. Exit status 0 means all fixtures passed; another status identifies
the failing fixture. SQL uses SQLite 3.25+ syntax. Shell examples require Bash
4+ and are not POSIX-sh scripts. CMD examples require Windows `cmd.exe` with
extensions and delayed expansion. PowerShell examples target PowerShell 7.
Nim examples target Nim 2.x; Rust uses edition 2021; Ruby targets 3.x;
Go targets 1.20+; PHP targets 8.x CLI.

Input contracts are stated in each file. These are small, bounded examples:
they do not provide general overflow protection or public-input validation.
Keep arithmetic within signed 32-bit range for portable comparison with CMD.
Sentinel results, such as -1 for a missing inverse, are explained where used.

## Verify and inspect

```sh
python tools/verify.py
python tools/verify.py --language sql --require-tools
python tools/verify.py --language nim --nim-backend js --require-tools
python -m pip install tiktoken
python tools/count_tokens.py --encoding cl100k_base
```

The verifier checks file hashes, compiles where applicable, and runs embedded
fixtures. It skips unavailable runtimes unless `--require-tools` is supplied.
Nim's optional JavaScript backend needs Node.js; its default C backend needs a
C compiler. Temporary compiler outputs stay outside the source folders.

`manifest.json` records each source path, language, token count, byte count,
SHA-256, and fixture count. `VALIDATION.md` describes the checks actually run.
The GitHub Actions workflow checks native Linux samples and Windows CMD samples.

## Regenerate

Install Python 3.10+, `tiktoken`, and Go (for `gofmt`). Then run:

```sh
python tools/build_corpus.py
python tools/build_sql.py
```

These scripts overwrite the generated source paths and manifest. Integer
specifications and their hand-specified expected results live in
`tools/algorithms.py`. The generator interleaves topics and stops near each
language's token budget; it does not repeat files to fill a size target.
