# Active goal continuation notes

This is planning/control material, not generated training volume or validation.
The user wants broad language coverage, uncommon practical contracts, and
approximately 2B useful code tokens. The active goal and counting rules are in
`long-run-goal.json`; exact current totals are in `volume.json`.

Use training_candidate_tokens for the quality goal and execution_validated_tokens
for technical execution volume. The existing legacy hold covers 309 files /
163,825 tokens at this checkpoint. Review available provenance and feature/
failure coverage in small source-bound batches before clearing any hold. A
rerun or blanket relabel is not an origin/coverage audit. Preserve review scope,
unresolved gaps, source hashes and task-family links when recording promotions.

Continue rotating through the established languages as well as adding others.
Avoid making Go/Python dominate just because their runners are convenient.
Pass 4 completed C++ PMR failure guarantees, Rust streaming UTF-8, Nim schema
generation, PHP delegation cleanup, PowerShell ShouldProcess and GNU-linked
RISC-V emulation, and added Perl/GNU AWK. Avoid regenerating these as new tasks.
Pass 5 completed C byte packets, Ruby Fiber lifecycle, Bash descriptors and CMD
expansion, and reviewed three GCD variants plus SQLite bookings. Reviews bind
source/document hashes, task and family; the other legacy files remain held.
Pass 6 completed C++ stream ownership, Rust vectored-output progress, Nim ARC
byte ownership, PowerShell provider reads, Lua 5.4 closing iterators and Tcl
snapshot command-prefix events. It strengthened retained audit-trigger checks
and obtained native SQL Server execution of the retained T-SQL source.
Pass 7 completed Go conditional snapshots, PHP user stream filters, waited
Bash process substitution, native/emulated NASM ULEB32 and RV64I linked-text
ULEB32 emulation, plus T-SQL defaults, boundary/atomicity checks and five
constraint/binding controls. Do not regenerate these as independent tasks.
Candidate next contracts (not yet implemented or validated):

* C bounded scatter/gather ownership and partial-progress contracts; C++
  exception contracts for fallible acquisition beyond the stream owner.
* Rust vectored INPUT with borrowed buffers and exact partial-read errors;
  vectored-output cursor/retry behavior is already present.
* Nim module-level resource cleanup beyond the completed ARC sink/copy hooks.
* Ruby encoding conversion and invalid-byte boundaries, with explicit encodings.
* PowerShell cancellation/error-stream contracts beyond the completed provider
  literal-path fixture. CMD native
  command exit-status handling beyond the completed literal-expansion case.
* Bash cancellation/signals beyond the completed waited producer/consumer
  publication contract; preserve finite-producer and non-NUL limitations.
* ARM/AArch64 beyond the folded-buffer function. RISC-V now includes canonical
  ULEB32; native hardware/ELF loading remain untested for these ISAs. Do not
  infer native labels from linked-text emulation. T-SQL defaults/bounds/row state
  and mutations are now covered for its retained fixture; expand distinct joins,
  query plans or transaction-isolation scenarios with owned local fixtures.
* Additional executable functional and niche language runtimes, with exact
  versions/dialects and local fixtures; missing runtimes stay not_tested.

Do not count planned contracts, repeated executions, archives or failed snapshots.
Preserve failures, exact commands, modes and source/support hashes. Publish small
validated batches to main using a checked expected branch SHA. Append CI imports
only after verifying archive digests; do not persist temporary download URLs.
