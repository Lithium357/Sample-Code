# Research pass 10: owned PowerShell pipeline source

curated/powershell/owned_block_source.ps1 is an original synthetic example for
PowerShell 7.3+ clean blocks and .NET synchronous Stream input. Task family:
io.owned-stream-pipeline-lifecycle. Available provenance, labeled agent-selected
task and human excerpts: provenance/research-pass-10.txt. Model family is GPT-6;
exact build is unavailable. No standardized benchmark/evaluation problem or
documentation example was intentionally used to generate this task.

Read-OwnedBlocks takes stream ownership only once begin executes. Binding
failures retain caller ownership. Each output object contains a fresh byte array
and zero-based offset; short reads are emitted as short blocks, not mistaken
for EOF. BlockSize is 1..4096. A clean block disposes the stream after normal
completion, downstream early stop, read/consumer errors and cancellation.
Cancellation is cooperative before each synchronous Read. A blocked Read is
not interrupted and earlier output remains observable on later failure.

## Execution and useful controls

Command: Python work/run_native.py --research --path
curated/powershell/owned_block_source.ps1 --require-tools. Exact absolute
invocations/commands, source and harness hashes, platform and runtime probes
are recorded in immutable evidence history. Local mode is native PowerShell
7.6.5 Core on Windows, with an inline C# Stream test fixture compiled via
Add-Type. The mixed fixture is counted in its containing source file, without
claiming lexical language/comment/fixture separation.

Final local run 1aba9e0a819b4ab6ba6a40710f424450 passes 555067 always-on checks
and three negative execution controls. Cases include lengths 0/1/2/7,
255/256/257 and 4095/4096/4097, five block sizes including 1 and 4096, and
three independent short-read caps. Each emitted byte is checked against the
original input by offset, with independent length/count conservation. Retained
output arrays are mutated to check nonaliasing. An actual FileStream fixture
uses a path with spaces/brackets and NUL/CR/LF/high bytes.

Select-Object -First 1 must trigger exactly one read and one disposal. A
pre-canceled token must perform zero reads and dispose once. A consumer cancels
after the first object: no later read is allowed, and the prefix remains visible.
An injected second-read IOException and a consumer error both require cleanup.
Invalid block sizes must preserve caller ownership; an acquired unreadable
stream must be rejected and disposed. Mutants omitting disposal, ignoring
cancellation or reusing the working buffer must fail the specified assertions.
Mutants are archived as excluded control material, never registry cases.

Initial failure 11114ce152fb42dcb91378b94ab35e2d was a fixture type-visibility
error, not observed wrong output from the source command. It is retained with
the original source snapshot. The corrected test uses a public exception base
and exact error ID; original byte expectations were unchanged. See fixes.md.

## Limits and counting

No Ctrl+C/StopProcessing injection, concurrent stream access, nonreturning read,
throwing Dispose, multi-runspace behavior, extreme Int64 offset or exhaustive
all-Stream implementation claim is made. No output transaction is promised.
The tested cleanup cases do not prove every PowerShell host lifecycle.
API reference consulted, without copying its example:
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_methods?view=powershell-7.4

One new file contributes 2387 cl100k_base tokens. Current generated and
execution-validated totals: 239787 tokens / 370 files. Candidate total: 74756
tokens / 61 files. The 309 legacy holds / 165031 tokens remain unchanged.
Counts include comments/inline fixtures; no Morderca tokenizer was used.
Controllers, logs, reports and broken snapshots contribute no source volume.
Cross-platform CI for this new source remains pending until observed; the
completed preceding Ruby/Perl workflow is reported separately in PASS-9.md.
