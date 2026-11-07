# Curated, language-specific local examples

These synthetic examples were added in research passes 1 through 7. They are not benchmark
items and their checks do not measure Morderca. The registry in
`research/cases.json` defines task families, runtime assumptions and support
files; results are in append-only `research/evidence/history/` records.

Pass 3 broadens the language rotation with Python task-local scopes, JavaScript
async-iterator cleanup and F# typed stock transitions, plus Go's unusual Reader
return/progress cases. Further batches add C# pooled-buffer ownership, Python/
SQLite deferred constraints and Tcl versioned dictionary patches. See
`research/PASS-3.md` for contracts and checks.

Pass 4 adds C++ polymorphic-allocation failure guarantees and Rust streaming
UTF-8 state transitions, plus GNU-linked emulation checks for the retained
RISC-V function. It also adds Nim schema generation, PowerShell ShouldProcess
byte invariants and PHP generator delegation. See `research/PASS-4.md` for the
exact validated scope.
The same pass adds Perl tied hashes and GNU AWK transactional aggregation with
explicit dialect/runtime labels and Linux/Windows checks.

Pass 5 adds C packet byte contracts, Ruby Fiber lifecycle, Bash borrowed
descriptors and CMD literal expansion. Four retained examples also receive
scoped reviews and stronger tests. See `research/PASS-5.md`.

Pass 6 adds Rust vectored-write progress, C++ stream moves, Lua 5.4 closing
iterators, PowerShell provider/literal paths, Nim ARC ownership and Tcl command
prefix snapshots. The retained T-SQL fixture now executes against a disposable
SQL Server engine, with source hash, image/version and cleanup evidence. See
`research/PASS-6.md` for failures, fixes and the exact validation scope.

Pass 7 adds Go conditional/range HTTP snapshots, PHP user stream filters,
Bash producer-status collection and canonical ULEB32 decoders in NASM/RV64I.
It strengthens retained T-SQL defaults/transaction behavior and requires five
intended schema/binding mutations to fail. See `research/PASS-7.md`.

Pass 2 adds ten standalone units, each with embedded local fixtures:

| Example | Contract and checks |
| --- | --- |
| `c/varint_codec.c` | Canonical unsigned LEB128, portable ZigZag, fixed wire vectors, 10,000 round trips, every proper truncation and transactional decoder outputs |
| `cpp/command_lexer.cpp` | Owned storage and offset spans, quoting, exact malformed-input offsets, copy/move including small strings, independent literal encoder |
| `go/keyed_work.go` | One operation per concurrent key, independent waiter cancellation, unrelated-key progress, fresh runs, errors and recovered panics; CI race detector |
| `rust/query_decode.rs` | Ordered duplicate query keys, one-pass percent decoding, UTF-8, limits, malformed escapes and independent encoding round trips |
| `php/csv_stream.php` | Lazy CSV generator, quoted commas/newlines, numeric/schema failures and early-stop file cleanup |
| `ruby/retry_policy.rb` | Injected sleeper, bounded attempts, saturating delays, retry predicate and exception identity; no real sleeps |
| `nim/stable_merge.nim` | Generic stable merge and run iterator; 961 concatenate/sort oracle comparisons, invalid ordering and unchanged inputs |
| `bash/transactional_options.sh` | Exact argument vectors, empty/space/wildcard values, option terminator, status 64 and atomic publication after validation |
| `sql/postgresql/window_events.sql` | Explicit ROWS frames, deterministic timestamp ties, partitioning, NULL values, retry RETURNING, rejected updates and empty lateral joins |
| `assembly/x86_64/decimal_buffer.asm` | NASM x86-64, SysV AMD64, Linux ELF64; unsigned decimal bytes, capacities 0..12, unchanged short buffers, guards and saved registers |

The NASM case runs natively on Linux and as a flat executable image under
Unicorn on other hosts. The latter also cross-assembles ELF64 but does not test
the Linux loader/kernel. Native and emulation results are recorded separately.
See `research/PASS-2.md` for the pass-specific evidence and limitations.

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
  instructions or linker relaxation. GNU cross-as/ld/objcopy plus Unicorn
  exercise linked .text when available. Local cross-tools are unavailable;
  CI has passed linked-text emulation for the current source hash. Native
  hardware and ELF-loader behavior remain untested. Older syntax-only results
  stay syntax-only in the history.

The three ISA files are close variants in task family `buffer.bounded-ascii-fold`.
ARMv7/AArch64 tests assemble only the marked function bodies with Keystone and
execute them with Unicorn. They check 404 vectors each, including all byte
values, zero-capacity null pointers, access bounds, canaries and saved registers.
That does not establish GNU-directive correctness, ELF linking, native OS
execution, or performance. Existing x86 files remain NASM/Linux x86-64 targets.

Cases with close variants share a task-family ID. Keep their source and support
files together when splitting training data. See `research/README.md` for
provenance limits, historical evidence qualifications and tokenizer accounting.

The current complete language/token inventory is in the root README and
`research/volume.json`; older availability notes above describe their original
checkpoints. Later source-bound CI and local evidence supersede those checkpoints
only for the exact recorded hashes and modes.

`nim/scoped_lines.nim` and `nim/test_scoped_lines.nim` form the native scoped
binary line-reader unit in family `io.scoped-binary-line-reader`. They exercise
generic callbacks, ARC closures, options, byte limits, exceptions, poison state
and actual native file cleanup. Windows validation uses Nim 2.4.0 with MSVC;
the test observer requires MSVC SEH. See `research/PASS-15.md` for control
results, preserved failures and untested POSIX/other-compiler scope.
