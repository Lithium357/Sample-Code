# Research pass 7: migration behavior, streams and protocol boundaries

Continuation of the unchanged approximately 2B-token goal under
`provenance/research-pass-7.txt`. Exact generation build is unavailable. No
standardized benchmark problems/solutions are intentionally used. All counts
exclude harnesses, prompts, failure snapshots, logs and archive duplicates.

## Retained T-SQL coverage first

The existing constraint/migration fixture now checks the backfilled default
before any explicit update, a new-row default, NULL updates, accepted lower/
upper bounds, six pre-migration rejection paths and one migration rejection,
failed multirow statement atomicity, immediate rows/transaction state, an empty
update, savepoint restoration and outer rollback of temporary schema. Its
parameterized text comparison uses binary conversion to avoid collation or
trailing-space equivalence hiding changed bytes. Original behavior is retained.

Five generated negative controls remove the CHECK/UNIQUE, omit savepoint
rollback, change the default, or change the bound note. Each must exit 1 with
its specific SQL error number and identifying message. Controls are not extra
training source. A temporary validation branch was necessary because the local
host has no SQL Server engine; native-engine source-bound run
2547ee0894f644589a56e8b299551246 passed all five controls. Full workflow
41661352324 passed, then tested commit 94bc9e5a65c1862e7ae2785368c8aefbb81def6b
was promoted to main with an expected-head check. No local engine pass is claimed.
The original task-family/generation task are retained; this edit is task 7.

## Go immutable conditional snapshots

`curated/go/conditional_snapshot.go` snapshots a bounded Reader, publishes no
partial result on input error, uses a digest ETag, and delegates conditional
HTTP/range rules to net/http.ServeContent with a fresh seek cursor per request.
Fixtures use direct httptest calls, fixed independent hash/date/body references,
HEAD and method rejection, strong/weak validators and precedence, single/suffix/
clamped/multipart ranges, malformed/unsatisfiable ranges, binary/empty input,
reader failures, an owned temporary file and 320 concurrent range requests.
No listener/DNS/external service is used. Source version-specific error text or
error-header stripping is not asserted as a universal HTTP guarantee.

Local native run 6f7145255f91499cbb955c589c80b3b0 passed. The initial -race run
a4e3ed8171714b409e3ab3700d5e3336 failed before compilation because CGO was
disabled. That original failure/snapshot remains. A preflight now records the
Go configuration and marks the unavailable local race setup not_tested
(d17b5ea861a04d738c2a9e5e2ea15c79). Native uninstrumented execution is separate;
Linux CI explicitly performs the race check. No race pass is claimed locally.

The ledger previously linked a later success solely by source path. It now
requires matching platform, execution mode AND instrumentation before making a
resolution link. Historical links with mismatched scopes receive append-only
corrections rather than deletion. In particular, a normal native pass cannot
resolve the unavailable local race configuration.

## PHP user stream filter

`curated/php/bom_filter.php` strips exactly one initial UTF-8 BOM as bytes, with
at most three held prefix bytes. Short EOF prefixes, later BOMs, NUL/high bytes,
READ/WRITE paths, incremental/final flush, consumed-input accounting, filter
removal, isolated interleaved instances, close counts and invalid parameters
are checked. It creates new output buckets where bytes change, avoiding writes
to version-dependent bucket properties. Fixed expected bytes are tested across
all three-way write partitions of the small corpus and several read chunk sizes.
It is not UTF-8 validation. Local run bc0a0b0726154899b6500e7aaa7762f1 passed.
API reference: [PHP user filters](https://www.php.net/php-user-filter.filter.php)
and [filter removal](https://www.php.net/manual/en/function.stream-filter-remove.php).

Further results, exact current totals and remaining limitations are appended
after source-bound CI evidence is imported. The long-run goal remains active.
