# Focused coverage review, research pass 1

This is a focused review of observable contracts, not a claim that every
feature in all retained legacy examples has now been audited.

| Existing feature | Gap found | Added evidence |
| --- | --- | --- |
| SQLite booking insert/update triggers | Only valid bookings inserted | Seven exact rejection cases, including a partially valid multi-row statement; state checked before cleanup; positive boundaries; either missing trigger detected by mutation |
| Task reopening guard | No attempted reopening | Exact trigger rejection and unchanged task/history tables |
| Wallet/inventory constraints | Positive rows only for selected guards | Negative balance, missing FK and zero-movement rejections with unchanged state |
| Equal-version reading retransmission | Older version tested, equal version omitted | Same version with different value must leave the database unchanged |
| Advanced accounting/BOM guards | Generic IntegrityError could mask wrong rejection | Extended error name + message + full state comparison before rollback |
| Sudoku solution validation | Rows/columns checked, boxes and givens omitted | Every box, every given, malformed grid shape/value checks |
| DAG validation | Missing/nil task and invalid worker cases omitted | Rejections before a side-effect-counted task can execute |
| Frame decoder error branches | Unsupported type/argument/reset behaviors omitted | Bad type with a recomputed valid CRC; null argument, empty feed and explicit reset checks |

Use the companion harness for expected SQLite ABORT failures; it verifies domain
state before its own rollback and verifies test cleanup. Raw SQL/error/state
hash observations are recorded in the evidence ledger.

New tests cover malformed/empty inputs, meaningful boundaries, failure cleanup
and state preservation within their contracts. ARM tests check access ranges,
canaries, termination and ABI-preserved state, without claiming GNU/ELF native
portability. Missing runtimes do not receive a pass.

Residual gaps include exhaustive legacy feature auditing, wider dialect/ISA
coverage and origin review of retained material. Rerunning aggregate checks
with source-bound commands improves reproducibility, not the completeness of
their original assertions or evaluation cleanliness.
