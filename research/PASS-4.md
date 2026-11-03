# Research pass 4: allocation, streaming text and RISC-V execution

Automatic continuation of the active broad-language quality-gated volume goal.
Prompts and inherited human steering: `provenance/research-pass-4.txt`.
Exact generation model build remains unknown. No standardized benchmark or
evaluation material was intentionally used. All new fixtures are local.

## First batch

C++20 `pmr_catalog.cpp` implements transactional replacement using polymorphic
allocators. It validates names before allocation, builds using the existing
resource identity, and commits by swapping equal-allocator containers. Tests
inject failure at successive allocation requests until the operation completes,
checking unchanged contents and complete cleanup on each failure. They also
cover aliased input views, duplicate/empty/oversized names, NUL bytes and exact
limits. Long-string allocation assertions target the tested MSVC/libstdc++
implementations, not an unverified universal small-string-storage threshold.

Rust `incremental_utf8.rs` wraps the standard-library UTF-8 validator with a
streaming tail, byte offsets, sticky malformed-input errors, explicit finish/
reset transitions and recoverable size-limit errors. Tests partition valid
inputs at every pair of byte boundaries, compare buffered decoding against
whole-input std validation, and use literal malformed-byte/error fixtures.
This is an independent check of buffering/state behavior, not a claim of two
independent Unicode validation algorithms. Both examples passed locally.

## Retained RISC-V example

The bounded ASCII-fold source remains in the shared ISA task family
`buffer.bounded-ascii-fold`. Its original generation task remains pass 1;
pass-4 edits and validation are subsequent work, not a new independent example.
The source now disables linker relaxation and describes validation modes rather
than carrying a permanently hardcoded untested label.

The new adapter uses real GNU RV64 cross-as/ld/objcopy, links .text at a known
address, checks the ELF machine/type/entry, and executes the resulting .text in
Unicorn. It does not patch unresolved branch relocations itself. Checks cover
411 vectors, high-bit unsigned length/capacity values, all byte values, null
zero-copy pointers, source immutability, exact memory access bounds, destination
canaries, stack and preserved integer registers. Two valid-code negative
controls must fail their intended assertions: disabled folding and clobbered s0.

The LP64 saved-register contract was checked against the
[RISC-V psABI specification](https://riscv-non-isa.github.io/riscv-elf-psabi-doc/).
The tested scope is linked-text emulation: not native hardware, an ELF loader,
OS behavior, timing, or relaxed-link optimization behavior. The local Windows
host has Unicorn but lacks the GNU cross-tools; its attempt is recorded as
not_tested. CI installs the cross-tools and records the actual result. A prior
syntax-only pass is not promoted retroactively into execution evidence.

Current counts and source-bound results are in `volume.json` and
`evidence/history/`. Native/managed execution and emulation remain distinguished.
The long-run target remains active; documentation/harnesses/logs are not source
volume, and a rerun adds no tokens by itself.
