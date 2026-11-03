# Active goal continuation notes

This is planning/control material, not generated training volume or validation.
The user wants broad language coverage, uncommon practical contracts, and
approximately 2B useful code tokens. The active goal and counting rules are in
`long-run-goal.json`; exact current totals are in `volume.json`.

Continue rotating through the established languages as well as adding others.
Avoid making Go/Python dominate just because their runners are convenient.
Candidate next contracts (not yet implemented or validated):

* C++ polymorphic memory resources with injected allocation failure and strong
  exception guarantees; C portable binary layout without aliasing violations.
* Rust incremental UTF-8 or vectored I/O with borrowed buffers and exact errors.
* Nim sink/copy hooks, compile-time validation or module-level resource cleanup.
* PHP generator delegation/cleanup and Ruby Enumerator/Fiber failure boundaries.
* PowerShell ShouldProcess/pipeline binding against owned fixtures; CMD expansion
  phases and literal exclamation/percent characters in safe local path handling.
* Bash descriptor ownership, process substitution and upstream failure status.
* Native/emulated RISC-V execution of retained source, if actual tools support it;
  ARM/AArch64 remain emulation-only and must not acquire native labels by inference.
* Additional executable functional and niche language runtimes, with exact
  versions/dialects and local fixtures; missing runtimes stay not_tested.

Do not count planned contracts, repeated executions, archives or failed snapshots.
Preserve failures, exact commands, modes and source/support hashes. Publish small
validated batches to main using a checked expected branch SHA. Append CI imports
only after verifying archive digests; do not persist temporary download URLs.
