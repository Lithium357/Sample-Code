# Available-lineage and behavior review: SQLite bookings

Reviewer: Codex assistant, research-pass-5; exact model build unknown.
Scope: sql/14_nonoverlapping_bookings.sql and the recorded behavioral driver.
Acceptance is conditional on this document/source hash and matching execution.

Available generation context is conversation-round-1 in provenance/session.json;
the later human research request explicitly named this booking example and asked
for actual overlapping insert/update rejection and unchanged-state tests.
The inspected source contains an original local booking schema/fixtures and
SQLite facilities, without an external benchmark identifier/imported problem
statement/dataset. No benchmark material was consulted. This is an available
lineage review, not a corpus-wide duplication search or evaluation-set guarantee.

## Inspected behavior and discovered gap

Half-open intervals overlap when each start is before the other's end, within
the same room. The update trigger excludes the old row's identity. Self-update,
touching boundaries, another room and movement to a valid interval are accepted.
RAISE(ABORT) must reject an entire statement, including its earlier rows, without
leaving partial data. The original source declared INTEGER columns but did not
enforce integer storage under SQLite's affinity rules. A new test genuinely
failed: INSERT INTO booking VALUES(10,30,'bad','zzz') was accepted.
The original failing run is 9303a2b964354f458db92dc43fc98728, with preserved source.

The fix adds named booking_integer_values CHECK using typeof for room/minutes.
It does not use STRICT or require its newer SQLite version. The rule is stored
INTEGER after affinity conversion: convertible numeric text is allowed and
asserted; nonnumeric text, fractional REAL and a value beyond signed-64-bit
INTEGER storage are rejected. NULL rejects through NOT NULL. IDs follow normal
SQLite INTEGER PRIMARY KEY semantics; room identifiers have no invented sign
restriction. This behavior follows SQLite's documented affinity model:
https://www.sqlite.org/datatype3.html

The aggregate expression is source-defined in booking_totals, then queried by
the harness against literal expected rows before and after accepted changes.
The terminal display SELECT reads that same view; tests do not silently replace
the source's aggregation with an independent, always-correct query expression.

## Evidence and scope

Final local run 3dd686a363f84740817b654875acd0aa passed on SQLite 3.53.1:
two original SQL checks, fifteen exact extended-code/message rejections, seven
additional behavior checks, and three intended negative-control detections.
Every expected rejection compares persistent state immediately before/after,
before savepoint cleanup. Negative controls remove each overlap trigger and the
integer-storage check; all fail at the intended forbidden operation. Affinity
conversion and exact aggregate rows are positive controls. Source/harness hashes,
commands, runtime and observations are in the immutable raw history.

The declared syntax target remains SQLite 3.25+; actual tested versions are
recorded rather than claiming execution on every release. This is a single
connection/owned in-memory fixture, not a test of concurrent clients or native
server dialects. The aggregate demonstration covers fixture workloads, not
arbitrarily large SUM overflow behavior. Exact error precedence for inputs
violating multiple constraints simultaneously is not promised; tests isolate
the intended failure. Other retained SQL cases are not approved by association.

Outcome: candidate with the documented scope and current source-bound pass.
This document is immutable for its review record; later evidence belongs in a
new review revision/pass report. Original generation task/family remain intact.
