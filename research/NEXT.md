# Active goal continuation notes

This is planning/control material, not generated training volume or validation.
The user wants broad language coverage, uncommon practical contracts, and
approximately 2B useful code tokens. The active goal and counting rules are in
`long-run-goal.json`; exact current totals are in `volume.json`.

Use training_candidate_tokens for the quality goal and execution_validated_tokens
for technical execution volume. The existing legacy hold covers 313 files /
165,213 tokens at this checkpoint. Review available provenance and feature/
failure coverage in small source-bound batches before clearing any hold. A
rerun or blanket relabel is not an origin/coverage audit. Preserve review scope,
unresolved gaps, source hashes and task-family links when recording promotions.

Continue rotating through the established languages as well as adding others.
Avoid making Go/Python dominate just because their runners are convenient.
Pass 4 completed C++ PMR failure guarantees, Rust streaming UTF-8, Nim schema
generation, PHP delegation cleanup, PowerShell ShouldProcess and GNU-linked
RISC-V emulation, and added Perl/GNU AWK. Avoid regenerating these as new tasks.
Candidate next contracts (not yet implemented or validated):

* C portable binary layout without aliasing violations and checked integer field
  conversions; C++ move-only resource handles and documented ownership transfer.
* Rust vectored I/O with borrowed buffers and exact partial-read/write errors.
* Nim sink/copy hooks or module-level resource cleanup.
* Ruby Enumerator/Fiber failure boundaries and scoped resource libraries.
* CMD expansion phases and literal exclamation/percent characters in safe local
  path handling; PowerShell provider/literal-path differences in owned fixtures.
* Bash descriptor ownership, process substitution and upstream failure status.
* RISC-V beyond the single folded-buffer function; native hardware/ELF loading is
  still untested. ARM/AArch64 remain emulation-only and must not acquire native
  labels by inference. T-SQL still lacks an execution fixture.
* Additional executable functional and niche language runtimes, with exact
  versions/dialects and local fixtures; missing runtimes stay not_tested.

Do not count planned contracts, repeated executions, archives or failed snapshots.
Preserve failures, exact commands, modes and source/support hashes. Publish small
validated batches to main using a checked expected branch SHA. Append CI imports
only after verifying archive digests; do not persist temporary download URLs.
