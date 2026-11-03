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
