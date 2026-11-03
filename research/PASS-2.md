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

Execution evidence and exact final counts are finalized after CI import; that
import adds records without replacing earlier results.
