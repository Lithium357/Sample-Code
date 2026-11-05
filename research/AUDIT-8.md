# Focused spot-check correction audit (task 8)

This is a bounded review of self-check/build behavior, selected SQL outputs and
sampled input boundaries. It is not an exhaustive correctness, security,
portability or benchmark-origin audit. No legacy origin hold is cleared here.
Generation/task-family IDs are retained; edits belong to research-pass-8-corrections.
Exact model build remains unavailable. The larger candidate-pool goal stays active.

## Reviewed revision and evidence categories

The four user-named files have identical Git blobs in reviewed commit
841a981d15d252cc97cfa27d311c6e27054bfc5e and pre-correction main
3223d8d0f4a5fc016843947083d2de1453625c42. The issues therefore remained current.
Original source snapshots are in evidence/review_sources, deliberate SQL mutants
in evidence/mutations, and harness snapshots in evidence/harness. These are
control material excluded from ordinary source/working-code training exports.

* Mutation-demonstrated test gaps: running-balances last-posting filter,
  ranking selection, overlap audit and question-summary threshold. Correct
  original output was observed; deliberately broken outputs survived old checks.
  These are not observed failures of the original query implementations.
* Build configuration falsely reporting success: nine C/C++ programs built
  with assertions disabled still returned zero and printed passed messages.
  This includes the named Robin Hood map and removed map_put/map_erase calls.
* Review suggestions without an observed implementation failure: missing
  sampled prime boundaries/oracle coverage and other limits listed below.
  New prime oracle checks match the retained implementations; no algorithm fix
  or expanded input contract was needed.
* Probe/harness failure: the initial correction probe incorrectly demanded
  that an existing guard's compiler diagnostic literally contain NDEBUG. The
  already-protected packet example reports its #error text instead. Record
  de0cbf37c22b4c8fba01d0a90379ece7 is retained. The corrected probe matches the
  exact #error text from the explicit guard; it cannot accept an unrelated
  compiler failure. This is separate from a sample implementation failure.

Complete pre-fix probe: 96d9d3a341fe4cb690869029e89e9154. Additional SQL before
probe: dae66a27996a4b619340374b433f5fdd. Post-fix probe:
caed469772614a9fa074b874775f62a5. Additional SQL after probe:
1f7663149c3d4788b8ae4d6fcdef0d5c. Ordinary local source execution:
362fa03e4a434549871132637302a906. Each record contains source/harness hashes,
versions, invocation and captured commands/results. MSVC /DNDEBUG is the local
counterpart of GCC/Clang -DNDEBUG; exact flags are recorded. Linux CI additionally
retains its existing sanitizer runs and repeats normal/NDEBUG checks.

## C/C++ files inspected

Scope: headers/contracts, assert call sites, main/self-test blocks, representative
limits and actual disabled-assertion compile/run behavior for all eleven files
currently in advanced/c, advanced/cpp, curated/c and curated/cpp. Algorithm bodies
were not comprehensively re-proved. Guard insertion is the only C/C++ source edit.

| File | Before | Important assertion pattern / existing tests |
| --- | --- | --- |
| advanced/c/robin_hood_map.c | false success | map_put, map_erase, output-producing map_get inside assertions; 40000 reference steps, allocation-failure state |
| advanced/c/incremental_frames.c | false success | feed/encode calls inside assertions; split boundaries, 256-byte payload, poison/errors/callback state |
| advanced/c/offline_connectivity.c | false success | solve calls and output comparison inside assertions; BFS oracle on 8 vertices/80 events, plus invalid/empty cases |
| advanced/cpp/order_statistic_treap.cpp | false success | erase/select/rank calls in assertions; multiset oracle, duplicates, range erasure, extrema |
| advanced/cpp/ntt_convolution.cpp | false success | convolution calls in assertions; 400 naive-oracle cases and inverse checks through 4096 |
| advanced/cpp/coroutine_generator.cpp | false success | runtime checks vanish, including begin on empty generator; other loops run without validation |
| curated/c/varint_codec.c | false success | encode/decode calls in assertions; fixed wire/MAX values, malformed encodings and truncations |
| curated/cpp/command_lexer.cpp | false success | checks/temporary constructor vanish; quoting, malformed offsets, copy/move and round trips |
| curated/cpp/pmr_catalog.cpp | false success | operations mostly remain, but correctness/cleanup/limit comparisons disappear; 32-name/128-byte boundaries are present |
| curated/c/packet_bytes.c | already rejects NDEBUG | existing guard retained; 0..1024 payloads, independent wire vectors, canaries and failure nonwrites |
| curated/cpp/owned_stream.cpp | already rejects NDEBUG | existing guard retained; ownership/state-changing I/O inside assertions is safe only with that gate |

Nine missing guards now reject NDEBUG at compile time. No assertions are
redefined and no expected results or normal algorithms are changed. The after
probe requires all normal builds to execute and print success, then requires
all disabled builds to fail specifically at their #error guard. It never runs
a stale normal executable after a rejected disabled build. A passing negative
build test is not a claim that an NDEBUG executable ran correctly.

Remaining boundary suggestions, not implementation failures: offline connectivity
advertises 12 vertices/160 events but its random oracle uses 8/80. NTT advertises
a public cap of 2^18 while inverse fixtures stop at 4096; the mathematical 2^23
limit is not its public demo cap. These upper capacities were not newly executed
or mutation-tested in this focused batch. No full allocation/ABI/compiler-matrix
or all-input proof is claimed for any C/C++ example.

## SQL files inspected

Scope: six complete source scripts below, their printed SELECTs, embedded checks
and relevant contract/mutation harnesses. Other SQL files/dialects were not
systematically reviewed in this batch.

| File | Finding and action |
| --- | --- |
| sql/05_running_balances.sql | Confirmed: >=1 or omitted last-posting filter yields four rows instead of three while all three old checks pass. Added one tested end_of_day_balance view, literal expected rows/count, shared dates across accounts, two ties per date, and a zero balance. Old running assertions retained; now eight embedded checks and four filter/partition/order mutants. |
| sql/10_ranking_with_ties.sql | Confirmed: printed <=3 selection adds Drew while all four old checks pass. One tested top_division_scores view now has exact six-row expectations; seven total checks, plus weakened/removed filter controls. |
| sql/12_effective_dated_prices.sql | Confirmed: <= earlier-start predicate creates self-pairs while four old checks pass. One tested audit view now includes an unrelated product with a true overlap and another with touching non-overlap; original purchase expectations retained. Seven checks and self/touching controls. This audits overlaps; it does not enforce writer exclusion. |
| sql/20_conditional_pivot.sql | Confirmed: changing >=4 to >=5 alters printed positive counts while three old checks pass. One tested question_summary view now asserts three complete rows; six checks and threshold control. |
| sql/03_calendar_gap_fill.sql | Inspection only: row count, a gap, final sum and one trailing mean are checked. Full seven-row output and 366-step recursion cap are not exhaustively exercised. No mutation/implementation failure claimed; source unchanged. |
| sql/06_cohort_retention.sql | Inspection only: two January fractions checked, later January/February cells not checked. No pre-signup activity exercises the exclusion filter. No mutation/implementation failure claimed; source unchanged. |

Exact output tests use literal independent expected tables, row counts and both
EXCEPT directions. The displayed views are the same views being tested; the
implementation query is not duplicated to generate its expected answers. SQL05
keeps the existing account-1 balances and account-2 3000 check: the new earlier
account-2 pair nets to zero. The added shared date catches accidental omission
of account partitioning. SQL12 uses unpurchased products 3/4, so the existing
missing-price purchase for product 2 stays unchanged. There are nine specified
post-fix SQL mutations in the ordinary harness (four/two/two/one), all required
to fail with SQLITE_CONSTRAINT_CHECK. Broken variants are never registry cases.

## Sampled basic examples

* nim/sample_23_nth_prime.nim: original four fixed fixtures retained, fixed
  index 100 -> 541 added, and every supported index 1..100 compared with a
  separately constructed Eratosthenes sieve to 600. Trial division is unchanged.
  Indices outside 1..100 remain outside the stated precondition; no new rejection
  guarantee is invented.
* ruby/22_largest_prime_factor.rb: four original fixtures retained. A sieve
  builds primes through 4096, then descending divisor enumeration of each
  original n supplies expected results for all n=1..4096. This covers primes,
  powers (including 4096, 2187, 3125, 2401), mixed factors and n=1. It does not
  divide a shrinking n like the implementation. Contract is explicitly Integer
  n>=1; the bounded oracle neither caps that contract nor adds invalid-input
  promises. Large inputs beyond the oracle interval remain untested here.

No new independent projects or model-performance evidence are claimed. This
batch improves selection material and its evidence, not its eligibility by
blanket relabeling. The 309 legacy origin/coverage holds remain until their
separate lineage review requirements are met. Continue varied generation after
this correction checkpoint while keeping generated/executed/candidate counts distinct.
