# Plan: Add RISC-V 32-bit and RISC-V 64-bit Assembler Support

## 1. Goal

Extend the retargetable assembler in `asm/` with two Linux target profiles:

| Registry name | ISA baseline | ABI | ELF class | Execution |
|---|---|---|---|---|
| `riscv32` | RV32IMAFD, little-endian | ILP32D | ELF32 | `qemu-riscv32` |
| `riscv64` | RV64IMAFD, little-endian | LP64D | ELF64 | `qemu-riscv64` |

The profiles are driven first by assembly emitted by CompCert's existing
`rv32-linux` and `rv64-linux` backends. They must use the same staged AST,
codec, image builder, browser API, differential oracle, and execution gates as
the existing x86-32, x86-64, ARM, and AArch64 profiles.

GitHub-hosted runners have no native RISC-V environment. No test may depend on
executing a RISC-V ELF directly. Every execution of target code, including
smoke tests, negative controls, helper conformance, and assembled CompCert
fixtures, must explicitly invoke QEMU. Parser, codec, linker, and JavaScript
portability tests still run as ordinary host-side OCaml/JavaScript tests because
they do not execute target code.

## 2. Scope and completion boundary

The first completed delivery supports the integer vertical slices already used
for the four initial targets:

- `return42`;
- integer arguments and add/subtract/multiply;
- comparisons and conditional selection;
- forward and backward control flow;
- direct calls;
- global loads and stores;
- `.text` and `.data`, symbols, alignment, and the data directives actually
  present in the generated corpus;
- internal address binding and fixup application;
- canonical and diagnostic disassembly;
- freestanding execution under QEMU user mode.

The target is not declared complete merely because a handwritten `addi` can be
encoded. Both profiles must pass the same phase, differential, portability, and
execution gates as the existing profiles.

The following are later coverage increments, not blockers for the first
vertical slices:

- the compressed `C` extension;
- vectors, bit-manipulation, crypto, and vendor extensions;
- arbitrary handwritten GNU assembly outside the CompCert-driven corpus;
- PIC/GOT/TLS forms not emitted by the selected fixtures;
- the full floating-point corpus, despite `F` and `D` being part of the ABI
  profile;
- dynamic linking or a target libc;
- native RISC-V CI hardware.

Excluding `C` initially is deliberate. It keeps every instruction four bytes
while the target, paired fixups, and QEMU path are established. The GNU oracle
must be invoked with an explicit `-march` that does not include `c`; relying on
the toolchain's configured default would make fixture bytes vary by container.

## 3. Non-negotiable design decisions

### 3.1 Two profiles, one target family

Implement a `riscv_family` functor parameterized by XLEN and profile data,
following the existing `x86_family` pattern. `riscv32` and `riscv64` are thin
instantiations. Shared instruction descriptions must not be copied between the
two targets.

The family parameter supplies at least:

- XLEN (`32` or `64`);
- registry name and GNU triple;
- accepted ISA/ABI profile;
- availability of RV64-only instructions and `W` forms;
- pointer-sized data directive and fixup width;
- immediate and shift-width rules.

The generic codec, assembler core, and image libraries must not learn about
RISC-V. Any new generic abstraction must be justified by a target-independent
test and must also make sense for an existing target.

### 3.2 Numeric registers are canonical

CompCert prints `x0` through `x31` and `f0` through `f31`, so those are the
canonical dump spellings. The source parser may also accept standard integer
ABI aliases (`zero`, `ra`, `sp`, `a0`, and so on), but aliases normalize to the
same register values and never create distinct instruction forms. Differential
disassembly uses GNU `objdump -M no-aliases,numeric` to avoid alias-dependent
text comparisons.

### 3.3 Explicit, reproducible GNU profile

Never inherit the assembler's configured default ISA. The shared target matrix
must carry explicit flags:

```text
riscv32: -march=rv32imafd -mabi=ilp32d
riscv64: -march=rv64imafd -mabi=lp64d
```

Bring-up oracle runs also use `-mno-relax`, and controlled GNU links use the
matching ELF emulation and `--no-relax`. A later relaxation phase adds a second
gate against normal GNU relaxation. Tool versions and the complete flag set are
written into fixture provenance.

### 3.4 Freestanding tests are the common denominator

Do not make RV32 support depend on a Linux ILP32D libc or dynamic loader.
Debian's `riscv64-linux-gnu` binutils are the preferred oracle for both ELF64
and ELF32, subject to a behavioral tool gate. RV32 uses the 32-bit ISA/ABI
flags and `elf32lriscv` linker emulation; RV64 uses `elf64lriscv`.

If the distro binutils cannot produce both formats, install one pinned GNU
RISC-V toolchain that can. Do not silently substitute a host assembler, LLVM
configuration, or a differently configured ISA. The test gate must prove the
selected tools by assembling, linking, inspecting, and running one ELF of each
class under the corresponding QEMU binary.

CompCert fixture generation needs `ccomp -S`, not libc linking. Project-owned
compiler-driver wrappers should add the explicit `-march`/`-mabi` pair when the
packaged cross GCC defaults are unsuitable, especially for RV32. The existing
libc-based Hello World cross smoke remains separate and must not become a
prerequisite for RISC-V assembler support.

### 3.5 All target execution goes through QEMU

Use QEMU user mode as the required execution backend:

```text
timeout 10s qemu-riscv32 <static-freestanding-elf>
timeout 10s qemu-riscv64 <static-freestanding-elf>
```

The actual scripts use argument arrays and the emulator value from
`tools/target-matrix.sh`. They do not probe the host and then run an ELF
directly. Static helper ELFs use direct Linux syscalls and need no `-L`
sysroot. QEMU system mode on the `virt` machine may remain an auxiliary
tool/GDB gate, but it is not required for the primary assembler execution path.

## 4. Target architecture

Add these production packages:

```text
asm/targets/riscv_family/
  riscv_family_encode.ml
  riscv_family.ml
  dune
asm/targets/riscv32/
  riscv32_encode.ml
  riscv32.ml
  dune
asm/targets/riscv64/
  riscv64_encode.ml
  riscv64.ml
  dune
```

As with the existing targets, the encode package contains instruction types,
normalization, lowering, codecs, decode, fixups, and text padding without
depending on the lexer. The frontend package adds the lexical profile, operand
parser, and target directives.

Register both concrete targets in `asm/driver/registry.ml`, add their libraries
to `asm/driver/dune`, and include them in the browser builds and production
dependency audit. `Driver.Portable.targets` should then expose six deterministic
target names.

### 4.1 Syntax and frontend

The initial lexical profile must cover:

- `#` line comments;
- no immediate sigil—integer immediates are bare expressions;
- integer and floating-point numeric registers;
- ABI register aliases as input-only spellings;
- `offset(base)` load/store operands;
- numeric local labels such as `1:` and `1b`;
- `%hi`, `%lo`, `%pcrel_hi`, and `%pcrel_lo` expression modifiers;
- symbols and symbol addends;
- rounding-mode operands when floating-point coverage is added.

Target directive handling initially includes `.option nopic` emitted by
CompCert and the feature/relaxation state needed to interpret `.option` safely.
Support `.option push`, `.option pop`, `.option relax`, `.option norelax`,
`.option rvc`, and `.option norvc` only when their state transitions and error
behavior have focused tests. Until `C` exists, `.option rvc` is rejected with a
typed unsupported-feature diagnostic, not ignored.

Common directives remain in the shared driver. Extend the directive contract
tables only for measured RISC-V spellings such as `.balign`, `.long`, `.quad`,
`.type`, `.size`, `.section`, `.globl`, and metadata-only `.cfi_*` directives.
Unknown `.attribute` or `.option` forms must never be silently discarded.

### 4.2 Instruction and pseudo-instruction coverage

Start with the instruction inventory produced from the six CompCert fixtures;
do not guess it from the ISA manual. The expected implementation families are:

- U type: `lui`, `auipc`;
- J type: `jal` and the encodings behind `j`, `call`, and `tail`;
- I type: `jalr`, integer immediates, and loads;
- B type: `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`;
- S type: integer stores;
- R type: integer arithmetic, comparisons, and the required `M` operations;
- RV64-only word operations such as `addiw`, `addw`, `subw`, and `mulw` when
  present in the RV64 corpus;
- canonical NOP encoding for executable alignment.

GNU pseudo-instructions that CompCert emits—at least `mv`, `nop`, `j`, `jr`,
`jalr`, `call`, `tail`, `la`, and `lla` as measured—must lower in the target
module to real encodings and fixups. Pseudo expansion is observable in lowered
AST and codec/disassembly expect tests. It must not be delegated to GNU tools at
runtime.

### 4.3 Encoding and decoding

Describe the base 32-bit formats with the existing codec EDSL. Add focused
tests for the non-contiguous immediate layouts:

- B-type branch offsets;
- J-type jump offsets;
- S-type store offsets;
- U/I and U/S high/low pairs;
- sign extension, alignment, and positive/negative range boundaries.

Encoding writes one 32-bit instruction word in little-endian memory order.
Decoding consumes exactly four bytes in the initial non-compressed profile,
reports the stable form ID, and emits canonical numeric register spellings.
Every new form needs encode/decode round trips, boundary errors, GNU byte
comparison, and a QEMU behavioral case when the form affects execution.

### 4.4 Fixups and internal linking

Define typed RISC-V fixup kinds rather than treating relocations as strings.
The initial set is expected to include:

- B-type PC-relative branch;
- JAL PC-relative jump/call;
- absolute 32-bit and 64-bit data;
- HI20 plus LO12-I/LO12-S;
- PCREL_HI20 plus PCREL_LO12-I/PCREL_LO12-S;
- the AUIPC/JALR call or tail pair.

RISC-V's `%pcrel_lo(label)` refers to the anchor of a matching high relocation,
not directly to the final symbol. Model that pairing explicitly and diagnose a
missing, duplicate, or mismatched anchor. Do not make the generic linker infer
pairs by parsing labels or printed fixup names. If the current lowered AST
cannot carry an explicit pair identity, add the smallest target-independent
pair/anchor field and exercise it with synthetic linker tests before using it
from RISC-V.

Range and alignment checks occur when the image is bound. Out-of-range branch,
jump, high/low, and RV32 address values are errors; truncation is never an
accepted fallback.

Bring-up first compares unrelaxed AUIPC/low-part sequences with GNU
`--no-relax`. After that passes, add a RISC-V relaxation ladder and compare the
post-link layout and bytes with normal GNU `ld` relaxation. Relaxation must
iterate through the shared layout engine because shortening a call changes all
following symbol addresses. Do not enable `R_RISCV_RELAX` byte parity in CI
until layout, relocation observations, and QEMU execution agree.

## 5. Delivery phases

### Phase 0 — Freeze profiles and prove the tools

1. Refactor `tools/target-matrix.sh` so target capabilities are explicit rather
   than assuming every target has a libc, a unique tool prefix, or identical
   assembler/linker flags. Keep separate sets for assembler targets and the
   existing libc cross-smoke targets.
2. Add `riscv32` and `riscv64` entries with configure target, ISA/ABI flags,
   ELF class/machine expectations, linker emulation, QEMU binary, word size,
   and controlled link addresses.
3. Add the cross binutils/GCC and QEMU packages to the amd64 devcontainer path.
   Add `qemu-system-misc` only if the auxiliary RISC-V system/GDB gate is
   enabled.
4. Extend `tools/asm-tool-gate.sh` with independent RV32 and RV64 direct-syscall
   ELFs. Give them distinct exit statuses so emulator/profile mix-ups fail.
5. Record GNU assembler, linker, objdump/readelf, QEMU, flags, ELF headers, and
   hashes in provenance.

Exit criterion: a fresh GitHub-compatible amd64 container creates one ELF32 and
one ELF64 RISC-V executable, `readelf` reports the intended class and RISC-V
machine, and the two ELFs return their distinct expected statuses only when run
through `qemu-riscv32` and `qemu-riscv64`.

### Phase 1 — Generate and inventory real CompCert fixtures

1. Build isolated CompCert configurations for `rv32-linux` and `rv64-linux`.
   Use project-owned compiler wrappers where necessary to pin the matching
   `-march` and `-mabi` flags.
2. Generate `-S` output for `return42` and the five existing M2 fixture sources.
   These sources are freestanding and must not acquire system-header or libc
   dependencies.
3. Assemble each file directly with GNU `as`; retain section bytes, symbols,
   relocations, disassembly, controlled-link bytes, flags, and tool versions.
4. Write `asm/docs/riscv-inventory.md` from the measured instructions,
   directives, pseudo-instructions, relocations, alignments, and expressions.
5. Check in the normalized fixture/oracle bundle so ordinary `make asm-test`
   remains offline and cross-toolchain-free.

Exit criterion: both CompCert configurations reproduce all committed assembly
fixtures without skips, every fixture is accepted by the pinned GNU command,
and the reviewed inventory—not an anticipated ISA list—defines implementation
scope.

### Phase 2 — Land the target family and `return42`

1. Add the family and two concrete packages, frontend profiles, Dune wiring,
   registry entries, and typed error domains.
2. Implement only the forms and directives needed for `return42` and function
   return.
3. Add token, source AST, normalized AST, lowered AST, image byte, codec,
   disassembly, and negative diagnostic expects for both profiles.
4. Add direct-normalized and direct-lowered path-coherence cases.
5. Run the same portable fixture under native OCaml, js_of_ocaml/Node, and
   Melange/Node and require byte-identical output and diagnostics.

Exit criterion: both fixtures bind to the controlled addresses, match the GNU
oracle bytes, disassemble canonically, and are ready for QEMU execution through
the common image path.

### Phase 3 — Complete the integer M2 slices

Implement one semantic slice at a time across both XLEN profiles:

1. integer arguments and arithmetic;
2. comparison/selection and conditional branches;
3. loops and backward branches;
4. direct calls and call pseudo expansion;
5. global address materialization, loads, stores, and `.data`.

For each slice, add codec boundary tests, phase dumps, GNU object and controlled
link comparisons, relocation classification, canonical disassembly, and QEMU
execution before moving to the next slice.

Exit criterion: all six CompCert fixtures produce correct fixed-layout images
on RV32 and RV64, and all target-generated code executes under the appropriate
QEMU user emulator with the expected result.

### Phase 4 — Extend the execution ABI and QEMU conformance

1. Add RISC-V profile IDs without renumbering the existing four IDs. Document
   this as an additive profile extension of execution ABI v1; if review finds
   that the frozen change-control rule forbids new profile IDs, introduce ABI
   v2 instead of weakening or silently editing v1.
2. Add `asm/helpers/riscv32.s` and `asm/helpers/riscv64.s`, using direct Linux
   syscalls and no C, libc, crt objects, or dynamic loader. Share only frozen
   constants through the existing include mechanism.
3. Validate the RISC-V syscall ABI, 16-byte stack alignment, callee-saved
   register checks, memory mapping, result publication, fault attribution, and
   instruction-cache synchronization. Use the Linux RISC-V cache-flush syscall
   where required rather than assuming a local `fence.i` is sufficient.
4. Extend the ABI profile model, manifest tests, snippet AST corpus,
   return-42/return-41 mutation control, conformance exemptions, and helper
   provenance.
5. Require passing return, wrong-result, trap, spin/timeout, stack-boundary,
   stack-corruption, and helper-validation cases for both widths.

Exit criterion: the ABI conformance job reports the same normalized completion,
fault, timeout, and protocol outcomes for six profiles, and every RISC-V target
execution in the logs visibly names its QEMU binary.

### Phase 5 — Add normal linker relaxation

1. Inventory GNU's relaxed output and relocation records separately from the
   no-relax baseline.
2. Implement call/tail relaxation only for measured pairs and ranges.
3. Verify convergence when shortened fragments shift later labels and paired
   fixups.
4. Compare controlled-link bytes and disassembly with GNU's relaxed link.
5. Execute both relaxed and deliberately forced-long cases through QEMU.

Exit criterion: relaxed and unrelaxed modes are explicit, deterministic, and
both behaviorally correct. No test result depends on an unstated GNU default.

### Phase 6 — Broaden CompCert coverage

Grow coverage from the measured CompCert corpus in small slices:

- remaining integer and `M` instructions;
- uninitialized storage and multi-file references when the shared linker
  milestone supports them;
- floating-point loads/stores, arithmetic, comparisons, conversions, and
  rounding modes for `F`/`D`;
- PIC `la`, PLT calls, GOT and additional relocation modifiers;
- atomics/fences if emitted by the selected CompCert/runtime corpus;
- jump tables and larger range cases.

Each increment keeps encoder, decoder, GNU differential, browser equality, and
QEMU execution in sync. Add the compressed extension only as its own feature
milestone with 16/32-bit decode-length tests, compressed fixups, alignment, GNU
parity, and QEMU execution; never turn it on implicitly by changing `-march`.

## 6. Test strategy

### 6.1 Host-side tests

Run on the existing OCaml/container matrix:

- lexer and operand parser expectations;
- staged AST and diagnostic expectations;
- codec consistency, encode/decode round trips, and immediate properties;
- linker/fixup unit and property tests;
- fixture hash and offline oracle checks;
- native/js_of_ocaml/Melange equality;
- dependency purity and layer checks.

These tests manipulate bytes and ASTs only. They are not evidence that RISC-V
machine code executes correctly.

### 6.2 GNU differential tests

For both profiles compare:

- raw instruction and section bytes;
- stable form selection;
- ELF class and machine;
- symbols and visibility;
- relocation offset, type, symbol/anchor, and addend;
- controlled-link section addresses and final bytes;
- canonical disassembly using numeric registers and no aliases.

Keep no-relax and relax artifacts distinct. A relocation-bearing object is not
compared as though its zero placeholder were a final instruction.

### 6.3 QEMU behavioral tests

All target behavior is tested under QEMU, including RV64 even if a future
runner happens to be RISC-V. Each run has:

- an explicit emulator command;
- a bounded host timeout;
- exact expected return/result data;
- normalized fault/timeout classification;
- emulator and helper provenance;
- retained stdout, stderr, manifest, result record, bound image, and
  disassembly on failure.

Use independently GNU-assembled direct-syscall snippets to establish QEMU/tool
health before using assembler-produced images. Retain the induced wrong-result
control so a broken runner cannot make the execution gate pass vacuously.

## 7. GitHub Actions plan

Keep GitHub runner architecture and guest architecture separate.

1. The ordinary `asm` host matrix continues to build the complete six-target
   registry and run all non-execution tests on its existing host platforms.
2. The fixed `ubuntu-24.04` tool-gate job proves the RISC-V binutils and both
   QEMU user emulators behaviorally.
3. The fixed `ubuntu-24.04` ABI conformance job assembles the new helpers and
   runs both RISC-V profiles through QEMU.
4. Add a `riscv-oracle` matrix over `riscv32` and `riscv64`, with
   `fail-fast: false`, for CompCert fixture regeneration checks, GNU
   differential comparison, controlled linking, and QEMU execution.
5. During bring-up, upload artifacts with `if: always()`. Once stable, retain
   full artifacts on failure and a compact provenance/summary artifact on
   success.
6. Do not add a RISC-V `runs-on` label, self-hosted runner requirement, native
   execution fallback, or KVM requirement. QEMU TCG user mode is the required
   execution path.

Cache keys, if added after reproducibility is established, include the CompCert
revision, target profile, ISA/ABI flags, OCaml/Rocq versions, devcontainer lock
state, and relevant tool versions. RV32 and RV64 must never share a cache entry
solely because they use the same GNU tool prefix.

## 8. Expected repository changes

| Area | High-level changes |
|---|---|
| `asm/targets/` | Add the RISC-V family plus RV32/RV64 instantiations |
| `asm/driver/` | Register both targets and link their libraries |
| `asm/test/` | Add phase, codec, property, differential, snippet, execution, and error cases |
| `asm/fixtures/` | Add CompCert RV32/RV64 sources and normalized GNU oracle artifacts |
| `asm/helpers/` | Add freestanding execution ABI helpers for both widths |
| `asm/docs/contracts.md` | Expand directive, form, target, runtime, and fixup matrices |
| `asm/docs/exec-abi-v1.md` | Document additive profiles, or supersede with v2 if required by frozen policy |
| `asm/docs/riscv-inventory.md` | Record measured CompCert syntax and implementation scope |
| `tools/target-matrix.sh` | Add ISA/ABI, ELF, linker, emulator, and capability metadata |
| `tools/asm-*.sh` | Extend tool, fixture, oracle, helper, and cross-reference paths without native execution |
| `.devcontainer/Dockerfile` | Install the selected RISC-V cross tools on the CI host path |
| `.github/workflows/asm.yml` | Add RISC-V oracle/QEMU jobs and extend existing gates |
| `README.md` and `.ai/asm_plan.md` | Advertise six targets and mark the RISC-V Milestone 6 work |

Audit all lists and pattern matches that currently assume four targets. In
particular, update target registry tests, dump inputs, xref/differential target
lists, execution ABI profile matches, snippet byte controls, fixture scripts,
tool-gate snippets, documentation tables, and comments. Exhaustive OCaml
matches should remain exhaustive; shell scripts must fail on an unknown target
rather than falling through to another profile's defaults.

## 9. Risks and mitigations

| Risk | Mitigation |
|---|---|
| RV32 libc/toolchain is unavailable | Use freestanding `-S`, GNU `as`/`ld`, direct syscalls, and QEMU; never gate on libc |
| GNU defaults enable `C` or a different ISA | Pass and record explicit `-march`/`-mabi` flags |
| GNU linker relaxation changes bytes and layout | Establish a no-relax baseline, then add relaxation as an explicit phase |
| `%pcrel_lo` is paired with the wrong high relocation | Carry explicit anchor/pair identity and add mismatch diagnostics |
| RV32/RV64 share a tool prefix and artifacts are mixed | Include profile, ELF class, ABI flags, and distinct QEMU exit codes in every path/gate |
| Pseudo-instructions hide several real encodings | Expose pseudo lowering in the lowered AST and compare post-link bytes |
| QEMU availability is mistaken for correctness | Run independent assemble/link/execute probes and record exact versions |
| Execution ABI changes weaken a frozen contract | Add profile IDs without changing existing values only after contract review; otherwise use ABI v2 |
| RISC-V code leaks into generic layers | Enforce Dune layer audit and require a synthetic target-independent test for any core extension |
| Browser builds regress | Run the complete six-target registry through native, js_of_ocaml, and Melange equality gates |

## 10. Definition of done

RISC-V support is complete for the initial scope when all of the following are
true:

- `riscv32` and `riscv64` are public registry targets and build in the native
  and browser-portable production closure;
- both use one shared family implementation with only genuine XLEN/profile
  differences in the concrete modules;
- real CompCert RV32/RV64 versions of all six initial fixtures are checked in
  with reproducible GNU provenance;
- every fixture passes all staged AST and diagnostic expectations;
- every implemented form encodes and decodes coherently and matches the pinned
  GNU oracle at controlled addresses;
- paired PC-relative fixups, range failures, and unrelaxed call sequences have
  focused tests; relaxed sequences pass once Phase 5 is enabled;
- native OCaml, js_of_ocaml/Node, and Melange/Node produce byte-identical images
  and deterministic diagnostics;
- the direct tool probes, return-42 images, arithmetic/control-flow/global
  fixtures, negative result control, trap, timeout, and stack cases execute via
  `qemu-riscv32` or `qemu-riscv64` and report the expected normalized result;
- GitHub Actions uses only GitHub-hosted non-RISC-V runners and contains no
  direct target-execution fallback;
- ordinary offline `make asm-test` still needs neither a cross toolchain nor
  QEMU, while the dedicated oracle and execution jobs fail rather than skip if
  their RISC-V tools are missing;
- documentation and target matrices no longer claim or assume that only four
  profiles exist.
