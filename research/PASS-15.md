# Research pass 15: scoped native Nim binary lines

Task `research-pass-15`, family `io.scoped-binary-line-reader`. This finalizes
the already pending work for the user's publication request. Further generation
is paused. The module and separate fixture add 2,351 `cl100k_base` tokens:
614 source tokens and 1,737 dedicated-fixture tokens, including comments.

`curated/nim/scoped_lines.nim` owns a regular file for a generic callback and
closes it across return and callback exceptions. Escaped reader references reject
subsequent reads. LF terminates byte records; CR, NUL and high bytes are data.
The limit is 1..1024 bytes; oversize and I/O failures poison the reader and return
no partial current record. Earlier callback effects remain visible. EOF is
cached. No asynchronous access, file snapshot, rollback, fatal-process cleanup
or close-failure exception-priority guarantee is claimed.

## Recorded execution and controls

The completed debug-native record `569b3f9b5d7140f18188cd9f9a45e117` ran 354
checks under Nim 2.4.0 / ARC / MSVC 19.51.36257 on Windows x64. Its immutable
record includes exact argv, runtime versions, source/harness SHA-256 hashes and
observed stdout/stderr. The module header's broader compiler intent is not
evidence of execution on Nim 1.6 or other versions.

The fixture compares 60 text/limit combinations against an independently split
LF list, covering empty input, final unterminated data, trailing LF, all byte
values other than the delimiter, exact 1024 and oversize 1025-byte cases. It
checks real native handle closure, callback exception identity, escaped readers,
poison/no-retry behavior, injected I/O exception identity, cached EOF read counts,
generic void/value/reference callbacks, nil callbacks and validation order.
Fixtures use temporary directories and filenames containing spaces.

The full controller additionally builds `-d:release --assertions:off` and six
deliberately broken module copies: omitted close, ignored poison, discarded CR,
one extra allowed byte, omitted EOF cache and omitted I/O poison. Each must fail
the intended fixture assertion; compile failures alone do not establish that
these execution controls work. Mutants are archived only under evidence and
excluded from normal working-code training candidates. The final full-controller
outcomes are recorded below.

## Failures and incomplete invocations retained

Initial records `674dea332cac4ea79b8e7ff634c9d70c` and
`ca0e1a4b3c3440dfa784f39a712651c5` compiled successfully but the Windows native
handle observer terminated with STATUS_INVALID_HANDLE (0xC0000008) while
checking the already closed handle. The second record's trace localized that
failure. This was a test-observation failure, not an observed reader-output
failure. The Windows fixture now catches precisely that native exception using
MSVC SEH in its C probe; other exception codes continue searching. Production
module behavior and literal expected values were not weakened. Original failed
source snapshots and results remain in history.

The invocation begun at 23:47 UTC was interrupted at the user's pause; its
empty history file remains incomplete. The 23:56 invocation initially had an
empty history file at inspection but subsequently completed: record
`610cb642bf9040e5974abc0023dced0b`, finished 2026-11-07 00:01:37 UTC, passed
debug/release execution and all six intended mutation rejections. A missing
process-list entry had been insufficient to establish termination. The earlier
policy observation is retained and explicitly corrected by
`publication-nim-observation-correction`; no completed result was reconstructed.

The fresh publication-verification record `fc1358e217d5437391d76a5f075da6c6`
also passed: 354 checks in each of the normal and release/assertions-off builds,
then six mutants each exited 1 with its intended diagnostic. This record includes
the current controller hash and the exact compiler/executable commands. The
source hashes match the current working module and fixture. Both completed
controller records remain in immutable history.

Windows fixture requires MSVC SEH; its native observer uses GetHandleInformation.
The alternate POSIX fcntl observer has not yet been executed for this batch.
Nim's test-only importutils.privateAccess API is experimental. JavaScript,
other memory managers, alternative Windows C compilers and native non-Windows
execution remain unchecked. Passing the recorded finite checks is not an
exhaustive correctness or Morderca performance claim.

Available prompt excerpts and the agent-selected task are preserved in
`provenance/research-pass-15.txt` and `provenance/session.json`. Generation model
family is reported as GPT-6; the exact checkpoint/version is unavailable.
No standardized benchmark problem or solution was intentionally imported.

Volume checkpoint: 377 registered files / 251,793 generated tokens; the same
source hashes have execution evidence. Training candidates are 68 files /
86,762 tokens. The 309 legacy holds remain 165,031 tokens. Counts include
comments and inline fixtures; no Morderca tokenizer was used.
