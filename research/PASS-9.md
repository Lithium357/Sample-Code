# Research pass 9: encoding buffers and dynamically scoped records

Two original, self-contained language-specific examples, no services, credentials
or benchmark/evaluation problems. GPT-6 family is the available system identity;
exact generation build is unavailable. Task/provenance summary and available
human excerpts are in provenance/research-pass-9.txt, with existing governing
requests retained. These are synthetic examples, not independent projects or
Morderca performance evidence. Prior correction batch remains in AUDIT-8.md.

## Ruby: strict incremental transcoding

curated/ruby/strict_transcode.rb uses Encoding::Converter primitive statuses to
convert finite binary UTF-16LE chunks to UTF-8 or US-ASCII. It preserves caller
strings, owns each converter, finalizes EOF, and returns only complete output.
Admitted input/output caps are 65536 bytes; destination fragments are 1..64 bytes.
The interface deliberately provides no output iterator or rollback of enumerator
side effects. It performs no BOM removal, newline conversion or normalization.

Independent scalar-to-UTF16/UTF8 byte constructors, with literal supplementary
anchors, provide expected bytes. Every two-part byte split of 153 deterministic
valid inputs runs with five fragment capacities. Boundary scalars, NUL, BOM,
CR/LF, invalid/lone surrogates, truncated EOF, US-ASCII unrepresentable scalars,
exact/exceeded input/output limits, invalid configuration, frozen strings and
upstream exception identity/no publication are exercised. 90402 always-on checks
pass locally. No exhaustive all-scalar/all-chunk-partition correctness claim.
Three controls reject omitted EOF finalization, premature finalization per chunk
and an omitted output limit. Mutants are excluded control material.

Local command: Python work/run_native.py --research --path
curated/ruby/strict_transcode.rb --require-tools (actual interpreter/absolute argv
are in evidence). Native Ruby 3.4.12, x64-mingw-ucrt; successful controller run
228bb074405141bdb163000747332c13. All commands, runtime probes, source/harness
hashes and captured results are preserved. API consulted, not copied:
https://docs.ruby-lang.org/en/3.4/Encoding/Converter.html .

## Perl: record reads with bounded dynamic scope

curated/perl/scoped_records.pl owns a raw regular-file handle, localizes $/ only
during each read and coalesces short reads into records of 1..4096 bytes. It
accepts/rejects a short final record, preserves callback exception identity and
caller eval state, and permits nested synchronous callbacks. Earlier callbacks
remain observable on later failure. Paths with spaces, arbitrary bytes and
empty files are local fixtures. No VMS, pipe/device, concurrent-file mutation,
filesystem snapshot or transaction guarantee is made.

An independent substr partition oracle checks lengths 0..96 plus 255/256/257
and 4095/4096/4097, widths 1..24 plus 4095/4096, and four ambient separator
states. Nested readers exercise a scalar-reference separator. Explicit tests
cover exact/rejected short tails, argument failures, absent paths, callback
exceptions and fresh reads after failure. 588032 checks pass locally. Read/close
I/O faults and unusual filesystems were not injected; no exhaustive I/O proof.
Two controls catch removal of dynamic localization and acceptance of a rejected
short tail. Source supports Perl 5.16+ syntax; tested local runtime is Perl
5.42.3 x86_64-cygwin-thread-multi (Git MSYS), not a native Win32 Perl claim.

Local command: MORDERCA_PERL set to Git's perl.exe; Python work/run_native.py
--research --path curated/perl/scoped_records.pl --require-tools. The sandboxed
probe was not_tested, then reviewed outside-sandbox execution passed; final
run cca4996d0a164a44a7a1387ac7fc44ce includes both controls. Actual argv,
versions and hashes are recorded. API consulted: https://perldoc.perl.org/perlvar .

## Preserved failures and scope

Two initial control runs required the wrong diagnostic from broken variants;
ordinary sources passed and earlier independent assertions caught the mutations.
Both failed records and exact controller edits remain in fixes.md/history. No
expected source answers were weakened. Generated source is distinct from
execution-validated/candidate totals; mutants, controllers, logs, documentation
and snapshots add no source-token volume. The 309 legacy holds remain unchanged.
Cross-platform CI validation will be recorded separately when observed terminal;
local success is not a claim about a future workflow result.

Local checkpoint: two new files / 4325 cl100k_base tokens (Ruby 2409, Perl 1916).
Generated and execution-validated totals are each 237400 tokens in 369 files;
candidate volume is 72369 tokens in 60 files. Held legacy volume stays 165031
tokens in 309 files. Counts include comments and inline fixtures, with no lexical
component separation; no Morderca tokenizer was used. Repeated checks do not
increase token volume.
