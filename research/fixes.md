# Observed failures and fixes in research pass 1

The JSONL history and failed-source snapshots are authoritative. This narrative
does not replace or overwrite the original command results.

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

The retained legacy reports include earlier CMD and compiler failures. They
lack exact source/version bindings and are not promoted into current passed
volume. Their raw bytes are preserved under `evidence/legacy/` with hashes.
