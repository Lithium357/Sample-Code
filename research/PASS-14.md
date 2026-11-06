# Research pass 14: applicative measured validation

curated/fsharp/applicative_panel.fsx is original synthetic F# 8 source, executed
with .NET SDK F# Interactive, standard library only. Family:
validation.applicative-measured-panel. A custom builder uses and! to combine
independent errors in field order and let! to gate dependent validation. It is
synchronous, does not promise parallelism, and preserves arbitrary exceptions.

The example validates width/height 1..10000 mm and optional coat 0..1000 mm,
then requires coat <= half the shorter side. Length and area use different F#
units of measure. The explicit wire grammar permits 1..5 ASCII integer digits,
optional dot and 1..3 fractional digits, leading zeros, no sign/whitespace,
grouping/exponent/Unicode digits. None means absent; Some empty/null is invalid.
Bounds ensure area arithmetic stays within decimal capacity. Error codes and
field identity are part of the stated local contract.

## Validation and preserved compilation failures

Command: Python work/run_native.py --research --path
curated/fsharp/applicative_panel.fsx --require-tools. Actual .NET SDK 10.0.401,
F# language mode 8.0, managed_runtime execution on Windows. Exact commands,
source/harness hashes, SDK/runtime probes and captured output are in history.
Final local record e1544fb5285147cfa5bcb263e65b3cfd passes 546 always-on checks,
five execution controls and the dimensional type-rejection control.

Eight literal panel/error fixtures check values, field/error order, null/empty
versus absence, zero coat, exact ranges and dependent geometry. Generic builder
fixtures check each source once, accumulated errors, skipped dependent stage,
success, return-from and exception identity. Separate lexical/scaled-int64
reference code uses neither regex nor TryParse nor the builder. It compares 25
literal strings and 63 generated combinations under two ranges and three
cultures (en-US/fr-FR/ar-SA). A dedicated French-culture probe precedes the panel
fixtures. Culture is restored in finally. This is finite grammar/boundary
coverage, not every possible string or every locale/runtime version.

Five mutants must fail: discarded right errors, reversed error order, ambient
culture parsing, longer-side geometry and relaxed fractional grammar. A separate
FSI invocation must reject assignment of decimal<mm^2> to decimal<mm> with
FS0001. It is labeled negative_type_control, not a claim of a standalone
compile-only artifact or successful managed execution of the ill-typed source.
All deliberately bad material is excluded from ordinary training exports.

Initial record 075ed78852d04dd5943c7f58f1f454e5 failed with FS3156 in a multiline
fixture equality expression. The same literal expectations now live in a data
table. Record 4a91890b2c9f482ba917c526b61d2e28 then failed with FS0001: the
unannotated geometry helper had inferred plain decimals. Explicit decimal<mm>
argument types fixed that production type-inference issue. No expected values,
boundaries or issue ordering were changed. Original source snapshots and both
failed compiler results remain. Ordinary execution first passed in
111960184db240848420009a992f6086, then the final controller passed all controls.
No ordinary runtime output failure was observed after compilation succeeded.

## Scope and provenance

No NuGet/network service, async scheduling, custom localization, UI, native AOT
or exhaustive computation-expression algebra proof. The builder is an ordinary
generic DU-based validation facility; callers can construct Invalid lists, so
it does not claim a nonempty-list type invariant. Units-of-measure rejection
is compiler evidence, separate from runtime parser/geometry evidence.

Available human excerpts, resumed instruction and labeled agent-selected task
are in provenance/research-pass-14.txt and session.json. Generation model family
GPT-6; exact build unavailable. API reference consulted without copying examples:
https://learn.microsoft.com/en-us/dotnet/fsharp/language-reference/computation-expressions .
No benchmark/evaluation problem or solution was intentionally imported. These
checks validate synthetic examples and do not measure Morderca performance.
Held legacy files remain held. Tool/controller/provenance/report volume is
excluded from code counts. New F# cross-platform CI remains pending until its
own run is observed; preceding pool CI is recorded separately in PASS-13.md.

Volume checkpoint: one new file / 2260 cl100k_base tokens. Generated and
execution-validated totals are 249442 tokens / 375 files; candidate volume is
84411 tokens / 66 files. Legacy holds stay 165031 tokens / 309 files. These
are whole-file counts including comments/inline fixtures, with no lexical
component split or Morderca tokenizer. Publication recovery adds no duplicate
source volume: the pool's 3153 tokens were already recorded in task 13.
