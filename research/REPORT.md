# Research pass 1

## Changes

Retained the original collection. Repaired selected missing failure paths in
bookings, task history, constraints, upserts, Sudoku, scheduler validation and
frame decoding. The booking suite checks seven exact rejections, database state
before cleanup, positive boundaries, and detection of either dropped trigger.
See `coverage-review.md` for the scope and residual audit limitations.

Added 14 source/support files in 13 curated units: language-specific PHP, Go,
Ruby, Rust, Bash, PowerShell, CMD and Nim examples, two SQL dialect fixtures and
three related ISA function modules. They use local strings, files, in-memory
SQLite, httptest or an opted-in disposable PostgreSQL database. No real
credentials, standardized benchmark items or model-performance claims were used.

## Validation and observed failures

The current inventory records commands, source/support hashes, harness hashes,
runtime/compiler version probes, results and modes. Native execution, Nim JS
execution, function-body emulation and syntax-only assembly remain distinct.
The retained examples are rerun through the detailed recorder; passing their
embedded checks does not establish exhaustive feature coverage.

Six observed failed records are retained with failed-source snapshots and
resolution links: Ruby helper scope; PowerShell's directory parameter and
scalar-type handling; Nim backend selection and JSON exception behavior; and
the WSL/Git Bash selection mismatch. Missing Ruby initially produced
`not_tested`, not a pass. See `fixes.md`, `changes.jsonl`, the raw history and
`evidence/corrections.jsonl`. No failed result was overwritten and no expected
answer was weakened to obtain a pass.

Representative commands (exact expanded per-file commands/cwds are in JSONL):

```text
python tools/research_validate.py --suite repairs --require-tools
python tools/research_validate.py --suite legacy --skip-language cmd --require-tools
python tools/research_validate.py --suite legacy --only-language cmd --require-tools
python tools/research_validate.py --suite curated
python tools/research_validate.py --path curated/nim/test_record_stream.nim --native-nim --require-tools
python tools/research_validate.py --path curated/go/local_http.go --go-race --require-tools
```

PostgreSQL uses the opt-in localhost CI fixture and records client/server
versions. CI imports are linked to workflow commits and verified artifact ZIP
digests. Historical unbound aggregates remain separately preserved as legacy.

## Counts and provenance

`volume.json` is the machine-readable current result: 327 source/support files,
174,302 `cl100k_base` tokens, of which 173,313 tokens across 325 files have a
qualifying source-bound execution check. This includes emulation/transpilation
where labeled; it is not a native-portability certificate. Syntax-only success
does not enter that execution total. These are not Morderca-tokenizer counts.

The 14 new files contain 9,089 tokens. File roles identify a separate Nim fixture
and support module; inline comments/self-checks in other files are not falsely
reported as lexically separated code-only volume. Evidence, prompts, failed
snapshots and harness copies are control material, excluded from source volume.

Exact generation model build and server thread IDs are unknown and remain null.
Visible prompts, reported model family, local task identifiers, source edits
and conservative task families are recorded. Related records, request examples,
shell fixtures, dialect counterparts and ISA variants stay grouped for splits.
Legacy origins are not exhaustively audited and remain flagged for review.

## Remaining gaps

* SQL Server/T-SQL: no engine-backed or syntax validation yet; held for validation.
* RV64I: no execution yet. Clang cross-assembly, if successful, is syntax-only.
* ARMv7/AArch64: 404 vectors each under Keystone/Unicorn, with bounds, canaries,
  termination and saved-register checks. GNU directives, ELF linking and native
  OS execution remain unchecked.
* No broad portability claim across other SQL versions, OSes, ABIs or ISAs.
* Legacy feature coverage and evaluation-origin review remain incomplete.
  Self-check success is evidence about examples, not Morderca's capabilities.
