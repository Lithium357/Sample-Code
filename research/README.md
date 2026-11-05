# Morderca synthetic training collection: evidence policy

The latest generation batch is [research pass 12](PASS-12.md), following
[research pass 11](PASS-11.md),
[research pass 10](PASS-10.md) and
[research pass 9](PASS-9.md); the preceding
correction batch is documented in [focused audit 8](AUDIT-8.md). The pass-1
report is historical; `volume.json` gives the refreshed collection totals.

This repository is training material. Passing its own checks is evidence about
these examples, not a measurement of Morderca's performance. No standardized
benchmark problem or solution is intentionally used for this pass. Legacy
material is retained; its origins have not been exhaustively audited.

`tools/research_validate.py` writes a new JSONL history file per invocation,
binding results to source/support hashes, harness hashes, exact commands, probe
outputs, runtime versions and validation mode. Missing tools produce
`not_tested`, not `passed`. In-process SQLite/emulator checks name their Python
entry point and command used to invoke the harness. Native, transpiled execution,
emulation, syntax-only and untested results must remain distinct.

Expected SQLite rejections are checked in `tools/sql_contracts.py`. The booking
tests require exact trigger errors, inspect the database before test rollback,
and verify acceptance of self-updates and touching intervals. Dropping either
overlap trigger must cause the rejection suite to fail. Run the companion
harness: the standalone SQL fixture cannot catch SQLite RAISE(ABORT) itself.

Historical aggregate reports remain historical: they lack command/version/hash
binding and cannot be upgraded retroactively. Imported raw logs are labeled
legacy; missing provenance stays null. Never replace a failed result with a
successful rerun. A fix is a new source hash and a new result, linked in the
change ledger. Do not interpret an old pass as validation of edited source.

Token counts use `cl100k_base`, not Morderca's tokenizer. Full-file counts include
inline comments and fixtures. They are not falsely split into additive code,
comment and fixture components: language-aware segmentation is not implemented,
and BPE boundaries can change when segments are concatenated. Separate fixture
files can be labeled separately in the case registry. Generated source volume
and source-bound successfully validated volume are reported separately.
The goal additionally uses `training_candidate_tokens`: passing execution does
not clear the existing legacy origin/coverage hold. The execution total remains
a separate technical metric. Candidate status records available provenance and
checks; it is not independent proof of benchmark absence or exhaustive quality.

Related translations/close variants share a task-family ID in the lineage
inventory. Split datasets by family, not by file. The exact model version is
unavailable. The server thread identifier was initially unknown; the goal tool
returned it during pass 3, recorded in provenance/session-updates.jsonl. Do not
infer identifiers from workspace paths. Prompts and task IDs have explicit sources.

Export training candidates by selecting `candidate_after_source_bound_checks`
from the `training_eligibility` field of the source/support allowlist in
`lineage.jsonl`, grouped by family. Held files remain separate until reviewed.
Evidence, failed snapshots, harness copies,
prompts and historical manifests are control material, not extra training
examples or additional generated source volume. Untested curated files are
held for validation. Legacy origin/coverage review remains incomplete even
where their current behavioral checks pass.

`--suite legacy` reruns retained examples through the detailed recorder.
Use `--skip-language cmd` on Linux and `--only-language cmd` on Windows. These
are embedded self-checks with recorded scope, not a comprehensive feature audit.
Go's `--go-race` records actual race-enabled build and run commands.
The research harness needs Python 3.11+ for SQLite extended error attributes.
`--native-nim` records a separate C-backend compilation/execution rather than
mislabeling the JavaScript backend. Syntax-only object generation is excluded
from the execution-validated token total.
