# Validation

Historical aggregate summary from the initial generation. It lacks exact
command/version/source bindings and must not be treated as current research
evidence after edits. See `research/evidence/history/` and `research/volume.json`.

Local validation completed on November 2, 2026.

All **268 programs** passed their embedded checks: **1084 explicit fixtures**.

| Language | Programs passed | Fixtures | Validation mode |
| --- | ---: | ---: | --- |
| nim | 32/32 | 132 | Nim JavaScript backend + Node.js |
| cmd | 19/19 | 79 | native runtime |
| assembly | 13/13 | 54 | Keystone assembler + Unicorn x86-64 emulation |
| powershell | 30/30 | 123 | native runtime |
| sql | 23/23 | 75 | native runtime |
| bash | 22/22 | 91 | Git Bash: syntax check + fixture execution |
| rust | 31/31 | 127 | native runtime |
| ruby | 38/38 | 156 | native runtime |
| go | 28/28 | 115 | native runtime |
| php | 32/32 | 132 | native runtime |

Source hashes and byte counts were checked against `manifest.json`.
SQLite checks include expected-result assertions, `integrity_check`, and `foreign_key_check`.
PHP and Ruby checks include syntax validation. Rust and Go were compiled before execution.

Nim was compiled with its JavaScript backend and executed using Node.js.
Assembly instructions were assembled using Keystone and executed under Unicorn x86-64 emulation,
with Linux exit system calls intercepted. This verifies instruction behavior but does not establish
native NASM/ELF loading compatibility. The included Linux workflow checks the native Nim C backend
and NASM/ld execution; Windows CI checks CMD, PowerShell, and SQL.
CI results are separate from these local results and must be read from the workflow runs.

These bounded fixtures do not establish correctness over unrestricted inputs.
Related non-SQL programs share specifications, so a shared specification error could affect several languages.
Explicit expected outputs were checked against the specifications before generation.

See `validation-report.json` for every file and its validation mode.
