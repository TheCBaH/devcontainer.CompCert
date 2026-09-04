# Sourcing whole-ISA instruction/extension data

This is a sourcing survey, not the inventory itself: where to obtain a
normative, machine-readable list of *every* instruction/extension for each of
the six supported profiles (`x86_32`, `x86_64`, `arm`, `aarch64`, `riscv32`,
`riscv64`), as opposed to the CompCert/gcc-*emitted* subset Milestone 5
already measures. It exists to support the "Full-ISA instruction/extension
coverage" axis and the "Parallel track: whole-ISA instruction and extension
inventory" section of [`asm_plan.md`](asm_plan.md), and the matching item in
[`next.md`](../next.md). Findings below are from live research on
2026-09-04 (repo sizes, licenses, file layouts) - re-verify before acting, all
of it can drift.

## Why binutils comes first

This project already treats installed binutils (`as`/`objdump`) as its byte
oracle for every target (`asm-fixture-oracle`, `gas_frontier.t`, the `gas:`
differential field across every `classify-*`/`assemble-c` manifest - see
`asm/docs/corpus.md` and `asm/docs/fixture-oracle.md`). Its *source* answers
exactly the same question this project's own assembler answers - "what does
`as` accept" - and already carries per-instruction extension tags, not just a
mnemonic list:

- `opcodes/i386-opc.tbl` (x86_32/x86_64, shared): one line per
  instruction-variant, e.g. `movbe, 0x0f38f0, Movbe, D|Modrm|...,
  {...}` - `Movbe`, `APX_F`, `Amd64`, `i486`, `i386&No64` etc. are literal
  extension/feature tags already on each line.
- `opcodes/aarch64-tbl.h`: entries carry `AARCH64_FEATURE (SVE2)` /
  `AARCH64_FEATURES (2, SVE2, F8F32MM)` macros next to each encoding.
- `gas/config/tc-arm.c`'s `insns[]` table: ARM/Thumb/VFP/NEON, feature-gated
  via `ARM_EXT_*`/`ARM_FEATURE_CORE`-style bitmasks.
- `opcodes/riscv-opc.c` + `include/opcode/riscv-opc.h`: RISC-V, largely
  regenerated from upstream `riscv-opcodes` (below) rather than hand-authored
  in binutils itself.

Repo: `git://sourceware.org/git/binutils-gdb.git` (GitHub mirror, e.g.
`gnutools/binutils-gdb`). **~640MB** with decades of history - unattractive as
a full submodule, but git supports shallow submodules
(`git submodule add --depth 1`), the standard way to vendor a repo this size
for reference-only use. License GPLv3 - fine for a read-only reference
consumed by doc/tooling generation and never linked into the shipped
assembler, the same posture this repo already takes toward `modules/CompCert`.

## GNU as / LLVM / QEMU, specifically

- **GNU as**: covered above - the primary reference, and the tool this
  project already trusts as ground truth.
- **Clang/LLVM**: `llvm/lib/Target/{X86,ARM,AArch64,RISCV}/*.td` (TableGen).
  The cleanest *extension-tagging* convention found anywhere in this survey:
  every instruction record carries `Predicates = [HasSVE2]`,
  `Requires<[HasAVX2]>`, `Predicates = [HasStdExtZba]`, etc., and files are
  already split by extension family (`RISCVInstrInfoZb.td`'s own header
  comment documents exactly which sub-extensions and spec versions it
  covers). Apache-2.0, very permissive. Problem: `llvm/llvm-project` is a
  **~4.1GB monorepo** - not submodule-able whole. The practical approach,
  matching this repo's existing "generated, not committed" treatment of
  `compcert-lib/`, is a partial/sparse clone done by tooling into a
  gitignored cache directory (`git clone --filter=blob:none --sparse`, then
  `sparse-checkout set llvm/lib/Target/X86 llvm/lib/Target/ARM
  llvm/lib/Target/AArch64 llvm/lib/Target/RISCV`), not a `.gitmodules` entry.
- **QEMU**: already installed in this devcontainer as the execution oracle
  for `asm-fixture-oracle` - zero new setup cost if used. Its
  `target/riscv/*.decode` and `target/arm/tcg/*.decode` files use
  `decodetree`, a clean declarative bit-field DSL (`%imm_i 20:s12`,
  field-name-then-bit-range) directly comparable to `riscv-opcodes`'s own
  format. ARM's decode is **already split into one file per extension
  family**: `a32.decode`, `t16.decode`, `t32.decode`, `a64.decode`,
  `vfp.decode`, `neon-dp.decode`, `neon-ls.decode`, `mve.decode`,
  `sve.decode`, `sme.decode`, `sme-fa64.decode` - exactly the
  "extensions tracked individually" shape this track wants. Caveat: **x86 in
  QEMU is not decodetree-based** - `target/i386` is a large handwritten
  `translate.c`, so QEMU is not useful for x86. Repo ~686MB, GPLv2 - same
  shallow-submodule-or-cache treatment as binutils if vendored.

## Per-architecture recommendation

| Target | Primary source | Format / extension tagging | License | Size | Vendoring |
|---|---|---|---|---|---|
| x86_32 / x86_64 | **binutils** `i386-opc.tbl` + **Intel XED** `datafiles/` | XED's `datafiles/` is literally **one directory per extension** (`avx512f`, `avx-vnni`, `apx-f`, `cet`, `amx-*`, ...) - the cleanest x86-specific split found | XED: Apache-2.0; binutils: GPLv3 | XED **~7.9MB**; binutils ~640MB | XED as a **real submodule** (small, permissive); binutils shallow/cache |
| ARM (A32/T32/VFP/NEON) | **QEMU** `target/arm/tcg/*.decode` + binutils `tc-arm.c`/`arm-dis.c` feature bits | QEMU: one file per extension family already; binutils: feature-bitmask macros per entry | GPLv2/v3 | QEMU ~686MB | Shallow submodule or sparse fetch-cache, not full |
| AArch64 (base/SIMD/crypto/SVE/SVE2) | **QEMU** `target/arm/tcg/{a64,sve,sme,sme-fa64}.decode` + binutils `aarch64-tbl.h`'s `AARCH64_FEATURE(...)` macros | Same as above; **ARM's own MRA XML** (A64/A32/T32 ISA "Exploration tools" on developer.arm.com) is the most authoritative but is a **manual portal download with ARM's own license notice stamped on every generated file** - not git-distributable, `mra_tools` confirms it must be fetched separately and isn't bundled | ARM's own terms, needs explicit review before any vendoring | n/a | Not submodule-able; optional, manually-acquired cross-check only |
| RISC-V 32/64 | **`riscv-opcodes`** (`github.com/riscv/riscv-opcodes`) | One line per instruction, `mnemonic operands bit=val...`, one file per extension under `extensions/` (`rv_i`, `rv32_zbb`, `rv64_zba`, `rv_zicsr`, ...); generates `encoding.h`/LaTeX/etc. via its own `Makefile`; used upstream by Spike/PK/the RISC-V manual/binutils itself | RISC-V International's own permissive license (repo `LICENSE`) | Small (few MB) | **Ideal full submodule** - same shape as `asm/vendor/{err_trace,fmt}/upstream` already in this repo |

A sixth, cross-cutting option worth naming: **Capstone**
(`capstone-engine/capstone`, BSD, **~70.5MB**) bundles pre-generated
LLVM-derived tables (`RISCVGenInstrInfo.inc` and equivalent X86/ARM/AArch64
directories) for *all six* targets in one small repo - a much cheaper way to
get LLVM's data than cloning `llvm-project`. It is disassembler-table-oriented
(bit-pattern to mnemonic decode tries) rather than the
assembler-mnemonic-acceptance direction this project actually needs, so treat
it as a secondary cross-check, not a primary source.

## Vendoring strategy

Three tiers, matching conventions this repo already uses:

1. **Submodule directly** - small, permissively licensed, already partitioned
   by extension, same shape as `asm/vendor/{err_trace,fmt}/upstream`:
   `riscv-opcodes` for RISC-V, XED's `datafiles/` for x86.
2. **Fetch into a gitignored cache via tooling** - too large to submodule,
   copyleft, reference-only, same treatment `compcert-lib/` already gets:
   binutils (shallow) and/or QEMU (shallow, sparse-checked to
   `target/arm/tcg/`) for ARM/AArch64.
3. **Manual, license-gated, optional** - ARM's own MRA XML, only if the
   per-extension QEMU/binutils data proves insufficient for ARM/AArch64
   specifically.

## Suggested pilot

Per the RISC-V-first pilot named in `asm_plan.md`'s "Parallel track" section:

1. Add `riscv-opcodes` as a real submodule (`asm/vendor/isa-data/riscv-opcodes/upstream`,
   following the `err_trace`/`fmt` pattern - pinned commit, not taken from
   opam/apt) and add `xed`'s `datafiles/` the same way for x86, since both are
   small and permissively licensed enough to just vendor outright.
2. Define the inventory file format/schema against those two first (per-entry:
   mnemonic, extension/ISA level, CompCert/gcc-emitted? - mechanically derived
   from the existing M5 corpora, not eyeballed -, implementation state,
   deferral reason if unimplemented).
3. Add a generation command, most likely one more `asm/tools` subcommand
   alongside `target-matrix`/`fixture`/`corpus`/`gas-xref`, following the
   generate-then-diff-gate pattern `tools-matrix`/`tools-matrix-diff` already
   establish in the root `Makefile`.
4. Only then decide how to reach ARM/AArch64 and the remaining x86/binutils
   cross-checks (shallow submodule vs. fetch-cache), once the schema and
   tooling shape are proven on the two easy cases.

Not started: no submodule has been added yet, no `asm/tools` subcommand
exists, and no per-target inventory file has been created. This document is
the sourcing survey only; see `next.md` and `asm_plan.md`'s "Parallel track"
section for where the follow-on work itself is tracked.
