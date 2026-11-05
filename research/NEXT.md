# Active goal continuation notes

This is planning/control material, not generated training volume or validation.
The user wants broad language coverage, uncommon practical contracts, and
approximately 2B useful code tokens. The active goal and counting rules are in
`long-run-goal.json`; exact current totals are in `volume.json`.

Use training_candidate_tokens for the quality goal and execution_validated_tokens
for technical execution volume. The existing legacy hold covers 309 files /
165,031 tokens at this checkpoint. Review available provenance and feature/
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
The task-8 focused correction batch is in AUDIT-8.md: four SQL outputs now
have exact checks/mutations, all eleven C/C++ examples reject NDEBUG, and the
sampled Nim/Ruby basics have independent complete/bounded oracles. This does
not clear the 309 legacy origin holds. Remaining review suggestions include
offline connectivity maxima 12/160, NTT public cap 2^18, calendar full rows and
cohort pre-signup/later-cell cases; these have no reproduced implementation
failure in that audit. Continue varied examples after this checkpoint.
Candidate next contracts (not yet implemented or validated):

* C bounded scatter/gather ownership and partial-progress contracts; C++
  exception contracts for fallible acquisition beyond the stream owner.
* Rust borrowed vectored input with exact partial errors is now pass 11.
  It shares a split family with the existing output cursor; avoid treating
  future translations/close variants as independent projects. OS readiness
  and native readv/writev behavior remain outside the injected fixture evidence.
* Nim module-level resource cleanup beyond the completed ARC sink/copy hooks.
* Ruby encoding conversion/invalid-byte boundaries are completed in pass 9;
  broaden another practical contract rather than duplicating strict transcoding.
  Perl dynamically scoped raw record reads/nested callbacks are also covered.
* PowerShell owned source cancellation/clean-block lifecycle is now pass 10.
  Further coverage could exercise Ctrl+C/StopProcessing or throwing cleanup
  explicitly; those were not tested here. CMD native
  command exit-status handling beyond the completed literal-expansion case.
* Bash cancellation/signals beyond the completed waited producer/consumer
  publication contract; preserve finite-producer and non-NUL limitations.
* AArch64 now adds packed signed24 decoder/visitor callback frames in pass 12;
  hardware, C compiler interoperability and unwinding remain untested. ARMv7
  beyond its folded-buffer function remains a gap. RISC-V now includes canonical
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
