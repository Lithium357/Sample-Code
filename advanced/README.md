# Advanced examples

These are separately authored programs of varying complexity, beyond the basic
parallel integer corpus. Every program includes runnable self-checks. They use
standard libraries and local fixtures, with no application services required.
Run files independently; the Go and Rust files each define their own main.

| Language | File | Core ideas and verification |
| --- | --- | --- |
| Nim | `persistent_avl.nim` | Immutable balanced search tree; path copying, single/double rotations, deletion and historical snapshots. Compared with a reference map after 1,200 mutations. |
| CMD | `knapsack.cmd` | 0/1 dynamic programming and subset reconstruction; compared with exhaustive subset enumeration at 21 capacities. |
| Assembly | `heap_sort.asm` | In-place signed int64 heapsort; ABI preservation, pointer indexing and signed/unsigned comparison distinctions. Checks duplicates, extreme values, empty input and idempotence. |
| PowerShell | `min_cost_flow.ps1` | Residual graphs, reverse arcs, Bellman-Ford shortest augmenting paths and negative-cycle rejection. Includes 256 exhaustive assignment comparisons. |
| SQL | `double_entry_posting.sql` | Balanced journal posting, draft isolation, immutability guards and reversal journals. Integer-cent accounting with SQLite triggers. |
| Bash | `csv_state_machine.sh` | Strict CSV state machine with escaped quotes, quoted newlines, CRLF and atomic publication; 49 encoding/parsing round trips. |
| Rust | `pratt_calculator.rs` | Tokenization, Pratt binding powers, checked arithmetic and precise error offsets. Tests right associativity, unary precedence, resource limits and 1,681 algebraic identities. |
| Ruby | `exact_cover.rb` | Algorithm X with reversible sparse-set updates and smallest-column branching; includes a 4x4 Sudoku constraint encoding. |
| Go | `dag_scheduler.go` | Bounded concurrent DAG scheduling, preflight cycle validation, dependency results, cooperative cancellation and goroutine joining. |
| PHP | `event_sourced_wallet.php` | Event replay, optimistic versions, idempotency receipts and command rejection without state mutation. In-memory store; no claim of persistence or cross-process atomicity. |
| Nim | `astar_grid.nim` | Weighted A* with an admissible Manhattan heuristic, stale heap entries and reconstructed routes; 100 Bellman-Ford comparisons. |
| CMD | `floyd_warshall.cmd` | All-pairs shortest paths, next-hop reconstruction and negative-cycle detection; 25 Bellman-Ford path comparisons. |
| Assembly | `utf8_validate.asm` | Strict UTF-8 scalar validation; rejects overlong sequences, surrogates, invalid continuations and truncation. |
| PowerShell | `critical_path.ps1` | Forward/backward project windows, critical tasks, slack and cycle rejection; 100 DAG comparisons. |
| SQL | `bill_of_materials.sql` | Recursive assembly explosion over a DAG, shared-component aggregation, shortages and cycle-prevention triggers. |
| Bash | `transactional_map.sh` | Nested savepoints and commit/rollback using undo logs; 1,000 comparisons with full-copy snapshots. |
| Rust | `persistent_segment_tree.rs` | Immutable lazy range updates/sums with structural sharing; checks every range across branched historical versions. |
| Ruby | `thompson_regex.rb` | Regex parser, Thompson compilation and epsilon-NFA simulation; differential tests against Ruby's regex engine and adversarial non-matches. |
| Go | `mvcc_store.go` | Serializable optimistic transactions, read/write conflicts, tombstones, phantom detection and snapshot-aware compaction; concurrent increments. |
| PHP | `lru_cache.php` | Doubly linked LRU map with expiry, cached null and invariant audits; 2,000 reference operations. Full-cache expiry sweeps cost O(capacity). |

## Verification

```text
python tools/verify_advanced.py --require-tools
python tools/verify_advanced.py --language nim --nim-backend js
python tools/verify_advanced.py --language assembly --emulate-assembly
```

The first command needs the selected native runtimes on PATH. Assembly targets
NASM, Linux x86-64 and ELF64. Non-Linux emulation needs NASM and Python's Unicorn
package; it assembles an optional flat image, executes its checks, and also
assembles the native ELF64 source. Native assembly execution runs in Linux CI.
The Nim JavaScript backend needs Node.js; native Nim needs a C compiler.

`manifest.json` counts these files separately from the original 268-program
collection. Refresh it with `python tools/catalog_advanced.py` after installing
`tiktoken`. The existing basic-corpus token totals remain unchanged.

These examples state their limits in source comments. They demonstrate core
techniques; they are not production replacements for parsers, accounting
databases, job platforms or general optimization libraries.
