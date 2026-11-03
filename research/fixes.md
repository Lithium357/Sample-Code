# Observed failures and fixes in research pass 1

The JSONL history and failed-source snapshots are authoritative. This narrative
does not replace or overwrite the original command results.

Pass 5 retained the Bash descriptor fixture's failed redirection-based leak
assertion. Its replacement verifies known-open /dev/fd state and rejects a
known-open negative control, then requires closure after every owned scope.
This corrects a probing side effect, not expected ownership behavior. See
`PASS-5.md`, the failed-source snapshot and subsequent passing records.

Pass 5 also retained a genuine failed booking test before fixing SQLite's
flexible-typing gap. INTEGER affinity alone allowed text-valued minutes; the
new named CHECK enforces stored integer types. Tests pin the intended check,
verify valid affinity conversion and source-defined aggregate view results, and
detect removal of the new check. No failed result or original fixture was erased.

Pass 3 retained a C# runner failure after successful compilation: inherited
Platform=x64 changed MSBuild's default output path. The runner now sets an
explicit build output directory; unchanged C# tests then executed successfully.
See `PASS-3.md` and the source/harness-bound original and rerun records.

Pass-2 PHP fixture failures and the exclusive-create fix are documented in
`PASS-2.md`. The first ledger writer still hardcoded pass 1 for those failure
events. Append-only metadata-correction events identify their actual pass-2
task; the writer now reads task IDs from the lineage inventory. Original
events/results remain intact.

* The first repair-suite invocation could not find Ruby on PATH. It recorded
  `not_tested`. The workspace Ruby runtime was added to the validator environment
  and the suite was rerun successfully.
* The new Ruby record-stream test failed with a NameError: a modifier on an
  endless method definition was parsed outside the intended body. The helper
  was rewritten as a normal method; expectations were unchanged.
* PowerShell's new local CSV fixture used `New-Item -LiteralPath`, which that
  cmdlet does not accept. It now uses `-Path` on an owned GUID directory.
* The validator initially selected Nim's C backend despite a `transpiled_js`
  case. That attempted to invoke unavailable GCC. Backend selection was fixed
  in the harness; the unsuccessful invocation remains recorded as a failure.
* Nim's JS string-JSON overload surfaced a host SyntaxError rather than the
  module's expected Nim exception. The module now uses Nim's stream parser on
  both backends. The same malformed-input expectations then passed.
* Bash initially resolved to WSL's launcher, which could not open the Windows
  fixture path. The local environment now selects Git Bash explicitly. Both
  invocations and their executable/version probes remain in history.
* Final PowerShell scalar-type tests exposed an array reaching an incidental
  Int32 conversion failure instead of the documented InvalidReading error.
  The validator now explicitly accepts only Int32/Int64 or decimal strings and
  rejects arrays and floats through its own error contract. The failed type
  test and unchanged expectations are retained.

The retained legacy reports include earlier CMD and compiler failures. They
lack exact source/version bindings and are not promoted into current passed
volume. Their raw bytes are preserved under `evidence/legacy/` with hashes.


## Research pass 6 harness diagnostics

PowerShell run dd9909ffbed4495581c71c7d299b9423 failed resolving the internal
ParameterBindingValidationException type literal, not reading fixture bytes.
Use the public binding-exception base AND exact FullyQualifiedErrorId. The
source expectation remains rejection before I/O. Subsequent runs passed.

Nim run ba98d300b0e44f4fafebfd0322ba5f62 passed runtime checks but failed the
negative-compile assertion. The compiler correctly rejected a copy, using its
own specific unavailable-copy diagnostic instead of the custom hook text.
Require code 1 plus =copy/OwnedBytes and the still-live first variable. The
rejection requirement remains; source and raw original result are preserved.


Tcl pass-6 run 65db0f856dac4bc18c475759d947d2d6 failed parsing an expected-value
expression missing a closing bracket. After fixing that syntax, run
6808b491cf6444ed8197cc5aac51a5f2 completed all assertions but failed the embedded
adapter sentinel: puts returns empty. Print and return the final success value;
77007943e7fc4ca6bb843f63a5804561 passes. Original sources/results remain retained.


SQL Server CI run 41656069870 / source-bound run
d93d3468774a40e0802eb24bfc308331 executed the original T-SQL successfully on
SQL Server 2022 16.0.4305.5 (RTM-CU27-GDR), then failed cleanup. Docker cp made
the file root-owned directly in sticky /tmp; the normal mssql user could read
but not delete it. The failed result is imported unchanged, with copied source
hash, sqlcmd success and rm failure; it is not counted as a successful validation.
Fix: create a uniquely named private directory as the normal container user,
copy into it, then remove the exact file and nonrecursively rmdir the owned
folder as that same user. No privileged Docker exec is introduced. Cleanup
errors are recorded without masking an original test error. The source itself
is unchanged; a clean CI rerun is required for promotion.


SQL Server run 1afa527a0f184d8fbdaa1dfce1f8ccf9 (workflow 41656604474)
confirmed the private-directory cleanup fix, but failed the completion sentinel:
-b -r 1 correctly routes PRINT to stderr, while the adapter inspected stdout
alone. Both command streams, code 0 SQL execution and successful file/directory
cleanup are preserved in the failed result. The original run also had this
sentinel error, masked by its cleanup exception. Fix: retain the exact same
completion text requirement and -b failure behavior, checking the recorded
stdout AND stderr as documented for sqlcmd -r 1. No SQL expectation or expected
output text is changed. The unchanged T-SQL still requires a wholly successful
new validation run before qualification.
