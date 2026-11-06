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


## Research pass 7 validation-scope correction

The first local Go race run a4e3ed8171714b409e3ab3700d5e3336 failed before
compilation because CGO was disabled. Preserve it; preflight Go configuration
now makes that missing setup not_tested, not passed. Ordinary native execution
does not prove the race setup was fixed. The change ledger now matches platform,
mode and instrumentation for resolution links and appends corrections to older
links that crossed those scopes. Raw source-bound records remain authoritative.


NASM pass-7 run 1d6fd14590db44c1a540dc45ae0c5fe7 failed the negative-control
reason assertion after primary vectors passed. The always-success stub failed
on missing output in the first (successful) case; place the already-present
empty-input case first to require wrong-status detection. Same case set and
expected values; b7370dbebe8249f2b42cd926aa1df2d0 passes. Original evidence kept.

## Research pass 9 control diagnostics and runtime availability

Ruby run 798bf54a575b45c18d927f56e8460e5f passed ordinary execution but the
control controller expected an early-finish diagnostic. Treating each chunk as
complete instead first fails the independent scalar byte oracle. The controller
now requires that diagnostic; expected bytes and original implementation did
not change. Successful rerun: 228bb074405141bdb163000747332c13. Ruby execution
disables unused RubyGems to avoid its installation-specific gemrc write warning.

Perl fb5d7422ff9e456fae3874a75b24b50e is not_tested: Git's MSYS runtime could
not create its process object in the sandbox. The reviewed outside-sandbox local
execution e5b6ab6aaac04ae8b3e9daa9c9836e92 passed. Initial control run
2669e29380a6455cb81cab4bd5c1dacb expected callback separator failure, but the
empty input already catches separator restoration failure before any callback.
The controller now requires that existing earlier diagnostic; no fixture answer
changed. Rerun cca4996d0a164a44a7a1387ac7fc44ce passed both controls. These are
controller expectation failures and a runtime availability issue, not observed
failures of either ordinary implementation. All original records are retained.

## Research pass 10 PowerShell fixture type visibility

Run 11114ce152fb42dcb91378b94ab35e2d failed in the fixture before invoking the
invalid-size test because ParameterBindingValidationException is not publicly
accessible as a PowerShell type. The test now requires the accessible public
ParameterBindingException base and the exact ParameterArgumentValidationError,
Read-OwnedBlocks error identifier. Ordinary function behavior was unchanged;
source snapshot and original failed record remain. Subsequent local run
26ccbe9a7d8e4834b5b1f02e9b43a1eb passed, then final controller run
1aba9e0a819b4ab6ba6a40710f424450 passed three deliberate source regressions.
No expected byte outputs were changed. Source labels PowerShell 7.3+ syntax;
local runtime actually observed is PowerShell 7.6.5 Core on Windows.

## Research pass 11 mutation/borrow controller diagnostics

Ordinary Rust debug and optimized executions passed in initial controller run
91fca8b836cb4454b2e4d2a6323ecfb3. The omitted-advancement mutant first failed the
complete-capacity assertion (9 versus 8), before the controller's expected flat
byte oracle failure. That existing assertion now has the explicit label complete
capacity invariant and the controller requires it; no answer was changed.
Run dc02a237b3ec4b65a230782dfbba885a then passed execution controls but the alias
gate diagnostic named bytes[_], not the controller's expected bytes. Rust already
reported E0502 as intended. The excluded gate now borrows the whole bytes array,
so its message matches the named contract. Working implementation was unchanged.
Both failed source/harness records remain; final run
3ca1328048bf4adc8f1615feeaac6e9a passes debug/optimized execution, three execution
mutants and the E0502 compile rejection. These were controller diagnostic issues,
not observed implementation failures. Expected destination bytes stayed unchanged.

## Research pass 12 Unicorn invalid-access observation

Run 3da39f96e9944572a5a7fb75407c9734 failed with an uninformative UcError after
the ordinary A64 vector suite reached its deliberate missing-bounds-check variant.
Raising inside Unicorn's invalid-memory callback did not reliably expose the
intended assertion before the engine error. The probe now records the invalid
access, returns false, and translates the engine error into a contextual assertion
with entry/count/available/PC and access details. Assembly/answers are unchanged.
Run ad2bd335492f4acebbcaa3c45be07d6f confirms read address 0, size 1, count 1,
available 0 in the omitted-guard variant. After adding the signed-count mutation,
final local run 367e4a8fe4a14b3383574614e4651b2d passes all five controls.
Original failed records remain; this was a control-observation problem, not an
observed ordinary implementation failure.

Explicit local --aarch64-linked run 6222197d14b64cd38c950a16f4fcfb54 is not_tested
because aarch64-linux-gnu-as is missing, not passed GNU assembly/linking. Positive
local evidence is Keystone marked-body plus Unicorn. Required GNU CI results must
be observed separately; none of these modes imply native hardware execution.

## Research pass 14 F# compilation fixes

075ed78852d04dd5943c7f58f1f454e5: FS3156 in a multiline fixture equality; moved
the unchanged expected records/issues into a literal fixture table. Next run
4a91890b2c9f482ba917c526b61d2e28: FS0001 because the geometry helper inferred
unmeasured decimal arguments. Added explicit decimal<mm> argument/option types.
The first is fixture syntax; the second is production type inference, both
compile-time failures, not observed wrong runtime results. Source snapshots and
original records remain. 111960184db240848420009a992f6086 passes execution;
e1544fb5285147cfa5bcb263e65b3cfd also passes five execution controls and the
FS0001 incompatible-units gate. No expected value or boundary was weakened.
