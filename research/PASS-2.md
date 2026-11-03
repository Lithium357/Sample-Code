# Research pass 2: useful variety with local contracts

Task ID: `research-pass-2`. The visible request is recorded in
`provenance/research-pass-2.txt`; inherited research requirements remain active.
Exact generation model version and server thread ID remain unknown, not inferred.
Ten new units are listed in `../curated/README.md`. Existing examples are retained.
Related record readers remain grouped in `records.validated-stream`; new task
families cover independent contracts rather than arbitrary per-file split IDs.

All new examples contain their own deterministic checks. Comments and embedded
fixtures remain included in full-file `cl100k_base` counts; lexical separation
is not implemented. `volume.json` and `lineage.jsonl` contain the current exact
inventory and source-bound validated subset. No Morderca tokenizer or performance
evaluation is used. No standardized benchmark problems/solutions were intentionally
used to generate this batch; the inherited origin audit remains incomplete.

## Validation and failures

Local Windows tests passed for C17/MSVC, C++20/MSVC, Go, Rust, PHP and Ruby.
Bash passed using Git Bash; Nim passed both JS/Node and native C/MSVC backends.
NASM passed flat-image Unicorn execution and ELF64 object assembly; this is
emulation, not Windows-native execution of a Linux binary. PostgreSQL is
explicitly `not_tested` locally because no disposable database was opted in.
GitHub CI adds native Linux execution, sanitizer builds for C/C++, Go's race
detector, native Nim, and the disposable PostgreSQL 16 fixture. Consult the
source hashes and exact commands in the append-only history for each mode.

The PHP CSV fixture initially failed at `tempnam`, both with the host temporary
directory and with an explicitly supplied owned working directory. A retry
outside the restricted sandbox failed too; the underlying host cause is not
established. The fixture now creates a randomly named file exclusively with
`fopen(...,'xb')` inside its owned working directory and cleans it in `finally`.
The CSV expectations were unchanged. All three failed invocations, both source
revisions and the passing result remain recorded. Exclusive creation passed.

Review also strengthened the new checks before final publication: C wire-value
boundaries/null output arguments; C++ all six ASCII whitespace characters,
exact error offsets and small-string copy/move; Go unrelated-key progress while
another key is blocked; Ruby invalid delay bounds and zero-delay retries; Nim
independent copies for input immutability assertions. These were source edits,
not observed failing tests; the ledger must not describe them as failures.

## Coverage still missing

SQL Server/T-SQL execution is still unavailable. RISC-V still has only a
cross-object syntax check. ARM/AArch64 still use function-body emulation rather
than native execution/ELF loading. PostgreSQL checks cover a single session,
not concurrency/isolation stress. Go coalescing deliberately has no work-level
cancellation, persistence or cache; work must eventually return and cannot
recursively wait on its own key. PHP delegates CSV lexical permissiveness to
`fgetcsv`. Full Unicode/shell grammars are outside the C++ lexer contract.
The retained examples' comprehensive feature and origin audit remains unfinished.

## Final source-bound results

Both code batches passed CI. The final code commit is
`def47c3281aeb4cf9219db4c8ce7bc784fe58161` and its
[passing Linux, Windows and PostgreSQL run](https://github.com/Lithium357/Sample-Code/actions/runs/41586669093)
is the cross-platform validation reference. The first batch also passed in
[run 41586184236](https://github.com/Lithium357/Sample-Code/actions/runs/41586184236).
All six research-evidence archives from those two runs were downloaded and
verified against GitHub's SHA-256 artifact digests before importing their raw
history records. `evidence/ci-imports.jsonl` binds artifact IDs, digests and
workflow commit identities. Subsequent publication contains documentation,
inventory and imported evidence; the example source bytes are unchanged.

| New example | cl100k_base tokens | Passing execution modes |
| --- | ---: | --- |
| C canonical varint codec | 1,257 | Native Windows/MSVC and Linux/GCC; Linux ASan/UBSan |
| C++ command lexer | 1,167 | Native Windows/MSVC and Linux/GCC; Linux ASan/UBSan |
| Go keyed work | 1,065 | Native Windows and Linux; Linux race detector |
| Rust query decoder | 864 | Native Windows and Linux |
| PHP CSV stream | 650 | Native Windows and Linux |
| Ruby retry policy | 772 | Native Windows and Linux |
| Nim stable merge | 910 | JS/Node and native C backends on Windows/Linux |
| Bash transactional options | 764 | Native Linux Bash and Windows Git Bash |
| PostgreSQL window events | 918 | Native PostgreSQL 16.15 local CI service |
| NASM decimal buffer | 1,174 | Native Linux ELF64 and Windows-hosted Unicorn emulation |
| **Total added** | **9,541** | **10/10 new units have passing execution evidence** |

The refreshed collection contains **337 source/support files and 183,843
cl100k_base tokens**. Of these, **335 files / 182,854 tokens** have passing
execution records for the current source bundles. The excluded 989 tokens are
T-SQL (647; untested) and RISC-V (342; syntax-only). These counts are full-file
source/support counts with normalized text newlines, not Morderca-tokenizer
counts, and exclude documentation, harnesses, history and failed snapshots.

Whole-file roles total 174,754 tokens labeled source-with-inline-fixtures,
8,369 source, 293 separate fixture and 427 support-source tokens. Source files
can still contain comments/tests; these labels do not establish a lexical split.
All 9,541 new tokens are in files with embedded comments and fixtures.

Exact compiler/runtime outputs, command arguments, working directories, source
and harness hashes are retained per record. For example, the new C/C++ units
passed with MSVC 19.51.36257 and GCC 13.3.0; the PostgreSQL fixture records both
client and server 16.15. A pass establishes the recorded checks and platform,
not exhaustive correctness or portability to untested platforms. The three
failed PHP invocations remain in the history alongside the later successes.
