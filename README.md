# Sample Code

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
arithmetic over language-specific libraries. There are no vendored dependencies
or copied third-party source files.

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
