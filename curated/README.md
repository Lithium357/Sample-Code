# Curated, language-specific local examples

These synthetic examples were added for research pass 1. They are not benchmark
items and their checks do not measure Morderca. The registry in
`research/cases.json` defines task families, runtime assumptions and support
files; results are in append-only `research/evidence/history/` records.

| Example | Language-specific behavior | Fixture and failure checks |
| --- | --- | --- |
| `php/local_orders.php` | JSON request validation, PDO binding, exceptions, generators | SQLite in memory; invalid JSON/types/ranges, duplicate and FK rollback, literal SQL-like text |
| `go/local_http.go` | Interfaces, request contexts, HTTP and files | httptest without a listener; strict/body-limited JSON, duplicate concurrent creates, cancellation and unchanged filesystem |
| `ruby/record_stream.rb` | Enumerators, blocks, structured records, exception causes | StringIO; lazy consumption, malformed records, immutable outputs |
| `rust/borrowed_records.rs` | Borrowed slices, fallible iterators, enums and typed errors | Owned local string; line offsets, malformed amounts and u32 overflow |
| `bash/local_files.sh` | Quoting, NUL-delimited paths, pipelines, statuses, traps | Owned temp directory; spaces/newlines/exclamation names, upstream failure and failure-path cleanup |
| `powershell/object_pipeline.ps1` | Objects/pipelines, validation, terminating errors, JSON/CSV | Owned CSV directory; invalid parameters/records and round-trip values |
| `cmd/paths_and_status.cmd` | Quoting, delayed expansion, subroutines, ERRORLEVEL | Owned temp directory with spaces/`!`; missing file, nonzero return and cleanup |
| `nim/test_record_stream.nim` + `record_stream.nim` | Modules, sequences, generic iterators, options, tables and exceptions | JSON-line strings; empty/nullable values, malformed inputs and record-count boundary |

Run `python tools/research_validate.py --suite curated`. Runtime availability
is checked and recorded; absence is not success. PHP needs PDO SQLite. Nim's
local JS checks are labeled `transpiled_js`, not native C-backend execution.
The Go HTTP fixture starts no listener, and the PHP fixture starts no server.

## Explicitly separated dialect and ISA targets

* `sql/tsql/constraint_migration.sql`: SQL Server 2019+ T-SQL. Uses a local
  engine, `#temp` tables, exact constraint error numbers, savepoints and bound
  dynamic SQL after a migration. No SQL Server engine is available locally;
  the source is held as **not tested**, not syntax-validated by SQLite.
* `sql/postgresql/constraint_migration.sql`: PostgreSQL 16+ with PL/pgSQL.
  Uses TEMP tables, exception subtransactions, joins and prepared statements.
  The CI job supplies a disposable localhost PostgreSQL 16 database without
  real credentials. The opt-in runner records client/server versions.
* `assembly/armv7/`: ARMv7-A A32 little-endian, GNU unified syntax, AAPCS32.
* `assembly/aarch64/`: Armv8-A AArch64 little-endian, GNU syntax, AAPCS64.
* `assembly/riscv64/`: RV64I little-endian, GNU syntax, LP64, no compressed
  instructions. Local tools are unavailable. CI attempts a Clang cross-object
  build labeled **syntax_only**; execution remains untested, and the file is
  held out of execution-validated volume even if cross-assembly succeeds.

The three ISA files are close variants in task family `buffer.bounded-ascii-fold`.
ARMv7/AArch64 tests assemble only the marked function bodies with Keystone and
execute them with Unicorn. They check 404 vectors each, including all byte
values, zero-capacity null pointers, access bounds, canaries and saved registers.
That does not establish GNU-directive correctness, ELF linking, native OS
execution, or performance. Existing x86 files remain NASM/Linux x86-64 targets.

Cases with close variants share a task-family ID. Keep their source and support
files together when splitting training data. See `research/README.md` for
provenance limits, historical evidence qualifications and tokenizer accounting.
