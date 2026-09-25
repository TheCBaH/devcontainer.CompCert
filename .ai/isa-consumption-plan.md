# Using the captured ISA data: phase 2 plan — maximal x86 and RISC-V admission

Revised 2026-09-25 at `f4b93e4`. Phase 1 (stages S0–S7: trustworthy capture,
OCaml normalization, the GAS differential runner, the first difficult-form
slices, component extraction, feature configuration and closure) is complete.
Its design review, measurements and slice-by-slice evidence are preserved in
git history (`git show f4b93e4:.ai/isa-consumption-plan.md` and
`git show f4b93e4:.ai/isa-consumption-tracker.md`); this document keeps only
the design rules that still govern new work and the phase-2 strategy.
Execution status lives in [isa-consumption-tracker.md](isa-consumption-tracker.md).

## 1. Goal

Admit the largest possible set of x86 (XED) and RISC-V (riscv-opcodes)
instruction forms into this assembler's verified support contract, using the
sources already captured. "Admitted" keeps its phase-1 meaning: a record is
**promoted-support** only when a persisted case makes GNU `as` and this
assembler emit identical bytes for that exact source form, under a recorded
configuration. A form that the encoder happens to accept but has no such case
is not counted.

The phase ends when every remaining unpromoted record is either
`oracle-unavailable` with a recorded GAS probe, or owned by a residual-ledger
row whose missing capability has been consciously deferred by name (not
"everything else"). No new ingestion source is part of this phase: the gap is
admission, not ingestion.

## 2. Where phase 1 left us

Measured with `make tools-isa-residual-ledger` and
`compcert_tools.exe isa-inventory family-admission` at `f4b93e4`:

| Profile | Records | Promoted | Normalized-only / GAS-generatable | Blocked (ledger-owned) |
|---|---:|---:|---:|---:|
| riscv_opcodes/riscv32 | 1,089 | 734 | 20 / 0 | 335 |
| riscv_opcodes/riscv64 | 1,154 | 783 | 30 / 0 | 341 |
| xed_resolved/x86_32 | 7,887 | 1,022 | 6 / 5 | 6,854 |
| xed_resolved/x86_64 | 10,571 | 1,030 | 0 / 5 | 9,536 |

Blocked records by residual-ledger row (x86-32 / x86-64, RV32 / RV64):

| Ledger row | Blocked | Largest families |
|---|---:|---|
| `RES-X86-EVEX` | 4,230 / 4,321 | AVX512F_512/256/128/SCALAR (~1,840), AVX512BW (516), AVX512_FP16 (~570), AVX512DQ (230), AVX10_2_BF16 (168), AVX10_V2_AUX (114) |
| `RES-X86-APX` | — / 2,460 | APX_F_N3 (1,866), APX_F (383) |
| `RES-X86-VEX` | 1,080 / 1,106 | AVX (266/292), FMA (192), XOP (166), AVX2 (153), FMA4 (128) |
| `RES-X86-BASE-INT` | 846 / 812 | I86 (418/355), I386 (139/117), I186, PPRO, CMOV, BMI1/2 |
| `RES-X86-LEGACY-SIMD` | 395 / 437 | PENTIUMMMX (128/132), SSE2 (60), 3DNOW (49), SSE (41), SSSE3MMX (32) |
| `RES-X86-X87` | 156 / 152 | X87 (141/137), FCMOV, FCOMI |
| `RES-X86-SYSTEM` | 147 / 215 | 58 small families |
| `RES-X86-AMX` | — / 33 | AMX_* |
| `RES-RV-FP` | 107 / 117 | rv_q (31), rv_zfh (25), Zfa files (~31), rv_f fcsr pseudos (8) |
| `RES-RV-HINT-MISC` | 70 / 65 | rv_zimop (42), rv_zicbo (7), rv_zicfiss (7) |
| `RES-RV-COMPRESSED` | 59 / 50 | rv_zcb (11), rv_zcmop (9), rv_c/rv32_c/rv64_c leftovers, rv_zcmp (6) |
| `RES-RV-BASE-INT` | 43 / 46 | loads/stores, branches and branch pseudos, `lui`/`auipc`, shifts, `fence`, `ecall` |
| `RES-RV-ATOMIC-SYNC` | 32 / 33 | rv_zabha (18), rv_zalasr (8) |
| `RES-RV-PRIV` | 24 / 27 | rv_h (12+3) |
| `RES-RV-ZBA-UW` | — / 3 | `add.uw`, `slli.uw`, `zext.w` |

Installed-tool capability (probed 2026-09-25 through the same binaries the
suites invoke): `x86_64-linux-gnu-as` 2.44 accepts every x86 family probed —
APX (r16–r31, `{nf}`, NDD), EVEX masking/zeroing/broadcast, AVX10.2, AMX,
FMA, VSIB gathers, XOP, MMX, 3DNow, x87 memory widths. RISC-V GAS (2.44 RV64,
2.43.1 RV32) accepts Zfh, Zfa, Q, Zabha, Zacas, Zawrs, Zimop, Zcb, Zcmp, Zcmt,
Zcmop, Zfbfmin, H, Zicbo*, Zicfiss and Ssctr, but **not** Zalasr, Zilsd
(RV32) or Smrnmi (`mnret`). Those three are the only families expected to end
the phase as `oracle-unavailable`; everything else has an oracle today.

## 3. Why the phase-1 method does not scale

Phase 1 admitted ~1,000 x86 and ~750 RISC-V forms, each by hand, in several
places at once:

1. a per-mnemonic `Opcode` constructor plus encode/decode arms in
   `x86_family_encode.ml` (9,060 lines) or `riscv_family_encode.ml` (7,901);
2. a per-iform/per-name match arm in `isa_norm_xed.ml` (6,035 lines) or
   `isa_norm_riscv.ml` (6,087), whose fall-through is the catch-all
   `unhandled-iform` / `unhandled-native-name` blocker;
3. hand-written corpus entries in `isa_gen_difficult.ml` (6,643 lines);
4. a hand-written credit predicate, `promoted_case` in
   `isa_family_admission.ml`, which restates what the corpus already proves
   and had to be split into seven functions because one large string match
   breaks the 32-bit ARM OCaml 4.14 backend.

At roughly 5–10 lines per form per place, the remaining ~9,500 x86-64 records
would add on the order of 200,000 hand-written lines. The blocker report is
also uninformative at this scale: "unhandled-iform=4,321" says nothing about
which missing construct (opmask, broadcast, VSIB, REX2, implicit operand)
would unlock the most forms.

Phase 2 therefore starts with infrastructure that turns admission into data,
then works the families in yield order.

## 4. Design rules carried forward

These phase-1 rules remain binding; new work may not weaken them.

* **Sources.** XED and riscv-opcodes are the only ISA ingestion sources.
  Python preserves upstream facts; OCaml owns interpretation. The coarse XED
  export exists only for the directory-group inventory contract and is never a
  second authority.
* **Oracle independence.** GNU `as` bytes are the differential reference.
  Deriving an encoder table *and* its expected bytes from the same record is
  not verification. Generating encoder tables from XED/riscv-opcodes is
  allowed precisely because the expected bytes still come from GAS.
  `.byte`/`.insn` probes never count as named-instruction coverage.
* **Two assertions per case.** GAS assembled the intended form (or a recorded
  canonical alternative) *and* this assembler produced the same bytes under the
  same mode, feature and layout configuration. Credit only the observed form.
* **Three-valued requirements.** Unknown blocks positive generation. `Req_any`
  preserves alternative-extension availability; an import never requires every
  importing extension.
* **Outcome table.** Byte mismatch is a hard failure, including in replay;
  our rejection of a promoted case is a regression; GAS rejecting a supposedly
  valid case is investigated, never blanket-skipped; an unavailable GAS
  capability is `oracle-unavailable` with probe evidence; an accepted negative
  fails.
* **Operand variation.** Finite, declared obligations per family (register
  classes and edges, immediate endpoints and encoding-choice boundaries,
  memory shapes, modes/features, syntax variants), no unconstrained Cartesian
  product; seed and budget are reported.
* **Tiers.** Tier one (`*-check`) is toolchain-free, replays committed
  artifacts and is on `asm-test`/`asm-ci`; tier two (`*-regen`) needs GNU
  tools and stays off the critical path; tier three is the Python producer
  lane. `asm/tools` builds with a targeted `dune build
  tools/bin/compcert_tools.exe`, never `@all`.
* **Production purity.** Target libraries never read JSON, import producer
  code or invoke tools at runtime. Anything derived from the captures reaches
  production as checked-in, reviewed OCaml.
* **Portability.** Native, js_of_ocaml and Melange must produce identical
  bytes (`asm-js-portable`, `asm-purity`), and the 32-bit ARM OCaml 4.14
  backend must compile every module. Generated tables must be shaped for this
  (arrays or chunked lists, not one giant `match`).
* **Configuration.** Every enabled form belongs to a feature; features are
  validated once at the API/CLI boundary and enforced on every path (text,
  normalized AST, lowered AST, decode, relaxation, padding).
* **Ledger discipline.** Every blocked family is owned by exactly one
  residual-ledger row; closing a family changes the ledger; a drop in coverage
  or a denominator change is reported, not absorbed.

## 5. Phase-2 infrastructure

### 5.1 Credit from evidence, not a predicate (INF-01)

Replace `promoted_case` with a lookup built from the persisted corpora: a
record is promoted when some committed case with a `Pass` verdict names its
`(target, form_id, lookup_key)` and is not a negative. `pilot_case` becomes
the same lookup over non-passing cases. Acceptance: the family-admission and
residual-ledger reports are byte-identical before and after, and the
1,966-line module shrinks to the classifier. This also removes the ARM-backend
workaround.

### 5.2 Operand-vocabulary-driven XED normalization (INF-02)

Normalize XED records from their parsed operands rather than by iform name.
Define a reviewed vocabulary mapping XED operand facts (name, visibility,
register lookup such as `GPRv_R`/`XMM_B`/`ZMM_R3`/`MASK1`, memory width,
immediate kind, `BCRC`, `VSIB`, tuple type) to normalized operand domains.
Per-iform arms remain only as reviewed overrides.

The catch-all blocker becomes construct-specific: an unrecognized operand
yields `unknown-operand:<construct>` and an unsupported encoding feature
yields `unsupported-encoding:<feature>` (e.g. `evex-opmask`, `evex-broadcast`,
`vsib`, `rex2`, `is4`, `implicit-operand`). Acceptance: every currently
promoted x86 form normalizes to an identical dump; the family-admission report
gains a per-construct blocker histogram that becomes the x86 work order.

Do the same for RISC-V from `variable_fields` plus `arg-lut`: each field name
maps to an operand domain and syntax role (gpr/fpr/vr, split immediates, CSR,
rounding mode, `aq`/`rl`, `nf`, `vm`), with unknown fields reported by name.

### 5.3 Generated cases (INF-03)

Build difficult-corpus entries from normalized forms: per operand domain, an
obligation generator (representative and edge registers, immediate endpoints
and boundaries, base/index/scale/displacement memory shapes, mask and
broadcast variants), rendered by per-architecture syntax recipes (AT&T for
x86, GNU RISC-V). Configuration (`-march`, `--32/--64`, `-mno-relax`, rvc
policy) comes from the form's feature mapping. Hand entries remain for forms
with labels, relocations or other special layout. The budget stays one case
per (form, target, obligation) unless a family declares sampling, which the
coverage report must then show.

### 5.4 Scalable oracle regeneration (INF-04)

The current difficult corpus takes about 13 minutes to regenerate; tens of
thousands of cases need batching. Assemble many cases per GAS invocation with
per-case labels and recorded offsets, compare per case, and automatically fall
back to single-case runs on any failure so a batch never hides which case
failed. Shard committed artifacts by architecture/profile/ledger row, and make
regeneration incremental (only cases whose input, argv or tool version
changed). Offline replay stays exact per case.

### 5.5 Table-driven encoders (INF-05)

The largest lever and the one requiring a recorded design decision before
implementation (DEC-X86-TABLE, DEC-RV-TABLE in the tracker).

**RISC-V.** Every fixed-format riscv-opcodes form is `match | Σ insert(field,
value)` with fields from `arg-lut`. Add a generic form-table encoder/decoder
keyed by mnemonic: match/mask, field list, per-field operand recipe and
syntax order, feature. A tool emits the table from the capture into a
checked-in OCaml module; hand-written encoders keep ownership of forms with
fixups, relaxation, compressed-register subsets or expansion. Most of Zimop,
Zfh, Q, Zfa, Zabha, Zacas, H, Svinval, Zicbo and the privileged forms need
nothing else.

**x86.** Add a generic form-row encoder: encoding space (legacy, VEX, XOP,
EVEX, REX2, EVEX map-4), map, opcode, mandatory prefix, `W`/`L`, ModRM
`reg` digit or register role, ordered operand roles and classes, immediate
width, EVEX tuple type for disp8*N, and feature. Rows are generated from the
XED resolved capture into checked-in OCaml; the existing `Opcode`
constructors stay for forms with fixups, relaxation or special selection
(`jmp`/`jcc`/`call`, `mov` immediate width choice, accumulator short forms).
The shared prefix emitters already exist (legacy, REX, two- and three-byte
VEX, EVEX for the admitted subset); EVEX needs aaa/z/b/L'L/R'/V'/X
completion, and REX2/EVEX-map-4 are new.

Decoder policy: table rows must decode strictly, and form-selection priority
among rows sharing an opcode must be deterministic and tested for collisions
against the hand-written alternatives.

### 5.6 Feature coverage for everything admitted (INF-06)

Only `zmmul`, `m` and `x87` are feature-gated components today; F, D, A, V,
Zb*/Zk*/Zv*, SSE*, AVX*, AVX-512 are admitted but ungated. Every table row
carries its feature from the start. Retrofitting the already-admitted
hand-written forms into components is a separate, behavior-preserving task.
Feature names map to GAS spellings (`-march=` components for RISC-V,
`-march=+ext`/`.arch` for x86) recorded with a probe. Defaults remain "every
implemented component" so existing accepted input does not change.

### 5.7 Mode policy for x86_32 (DEC-X86-MODE16)

The `x86_32` export includes forms applicable in 16-bit mode. Decide whether
16-bit-only forms are tested via `.code16` (GAS supports it; this assembler
would need a mode state) or recorded as `oracle-unavailable`/out of scope for
the `x86_32` target. Until decided they stay blocked under their ledger row.

## 6. Work order

Order by instructions admitted per unit of effort, with infrastructure first
because it multiplies everything after it. Each item corresponds to a
residual-ledger row (task IDs are the ledger's `GEN-05-*` IDs) or an INF task.

1. **INF-01, INF-02, INF-04** — credit from evidence, construct-keyed
   blockers, batched regeneration. No coverage change; they make every later
   step cheaper and the x86 order measurable.
2. **Free credit.** RISC-V normalized-only records (`rv_i` 13, `rv_m` 7,
   `rv64_i` 5, `rv64_m` 5) and x86's 5 GAS-generatable plus 6 SSE/SSE2
   normalized-only records only need passing cases. Then x86 forms the encoder
   already implements for CompCert but never normalized (`mov`, `lea`,
   `push`/`pop`, `call`/`jmp`/`ret`, `imul`/`mul`/`div`, `neg`/`not`,
   shifts/rotates, `setcc`, `cmovcc`, `movzx`/`movsx`, the 13 x87 forms).
3. **RISC-V to completion** (INF-05 RISC-V table, INF-03 generated cases):
   base-integer shapes (`GEN-05-RV-BASE`), Zba leftovers, FP remainder
   including Zfh/Zfhmin/Q/Zfa/Zfbfmin and fcsr pseudos (`GEN-05-RV-FP`),
   Zimop and the other hint/misc families (`GEN-05-RV-MISC`), Zabha/Zacas/
   Zawrs (`GEN-05-RV-ATOMIC`), privileged forms (`GEN-05-RV-PRIV`), then the
   compressed remainder (`GEN-05-RV-C`). Target: blocked falls to the
   oracle-unavailable residue (Zalasr, Zilsd, Smrnmi and any Zclsd forms GAS
   rejects) on both profiles.
4. **x86 legacy completion** (INF-05 x86 table, legacy space first):
   `GEN-05-X86-INT` (implicit operands, string/`rep`, bit ops, exchange and
   atomics, 16-bit operand size, high-byte registers, BMI/LZCNT/POPCNT/ADX/
   MOVBE), `GEN-05-X86-X87` (memory-width table, `st(i)` both directions,
   popping/reversed, FCMOV/FCOMI, control), `GEN-05-X86-SIMD` (MMX register
   class, SSE/SSE2/SSE3/SSE4.2/SSE4a remainders, AES/PCLMUL/SHA/GFNI, 3DNow).
   About 1,400 x86-64 records.
5. **VEX/XOP completion** (`GEN-05-X86-VEX`): ymm completions of AVX/AVX2,
   `vvvv`/`rm` ≥ 8 selection of the three-byte prefix, VSIB, mixed-width and
   lane forms, FMA, F16C, is4 (FMA4, XOP) and the XOP maps, VNNI/IFMA/
   NE_CONVERT/VAES/VPCLMULQDQ/GFNI/SHA512/SM3/SM4. About 1,100 records.
6. **EVEX** (`GEN-05-X86-EVEX`): machinery first — opmask `{%kN}` and `{z}`,
   embedded broadcast `{1toN}`, rounding/SAE, disp8*N from the tuple type,
   registers 16–31, 128/256-bit lengths, k-register instructions — each
   landed with a small family and negative cases. Then the families
   mechanically: AVX512F, BW, DQ, CD, FP16, VBMI/VBMI2, VNNI, IFMA, BITALG,
   VPOPCNTDQ, GFNI/VAES/VPCLMULQDQ, BF16, AVX10.2. Xeon-Phi-only families
   (ER, PF, 4FMAPS, 4VNNIW) last, after a GAS probe. About 4,300 records.
7. **APX** (`GEN-05-X86-APX`, x86-64 only): REX2 and r16–r31, EVEX map-4
   promotions of legacy integer forms, NDD, `{nf}`, CCMP/CTEST, CFCMOV,
   PUSH2/POP2, JMPABS. Depends on steps 4 and 6; about 2,460 records, mostly
   mechanical once they land.
8. **AMX and system** (`GEN-05-X86-AMX`, `GEN-05-X86-SYSTEM`): tile registers
   and SIB-only memory; then the 58 small system families, which are largely
   fixed opcodes. Privilege level does not affect assembly: GAS encodes these
   under an `-march` feature, so they are admitted as ordinary features and
   only GAS rejections become `oracle-unavailable`.

Steps 3 and 4 are independent and can proceed in parallel after step 2.

## 7. Architecture-specific notes

**RISC-V.** Distinguish XLEN from instruction length. Baseline cases use
explicit `-march` without `c`, `-mabi` and `-mno-relax`; GAS compresses
opportunistically under `c` (including `nop` → `c.nop`), so compressed suites
must not rely on uncompressed filler. Extension filenames are evidence, not
`-march` spellings; a mnemonic can appear in several extension files and be
shadowed per profile (e.g. `rv32_zclsd`'s `c.ld`/`c.sd`), so check ownership
per profile before admitting. RV32 (2.43.1) and RV64 (2.44) GAS differ in
version: probe each extension on both and attribute any gap to the tool.

**x86.** AT&T syntax. Operand reversal is not universal; suffixes and implicit
operands are form-specific; x87 has its own size-suffix naming. GAS
encoding pseudo-prefixes (`{vex}`, `{evex}`, `{disp32}`, `{load}`, `{store}`,
`{rex2}`, `{nf}`) may force a form; use them only after probing both GAS and
our parser, and never report a direct-AST-only test as syntax coverage. Test
every byte-register and REX interaction in both modes: phase 1 found spurious
REX and dropped REX.B/X bugs this way. Do not infer vector semantics solely
from the iform name.

## 8. Acceptance for each admission slice

A slice (one family or one machinery increment) closes when:

* each newly promoted record has at least one passing persisted case per
  applicable profile, satisfying its declared obligations, plus negative cases
  for each new constraint (range, register subset, mode, feature);
* the encoding was verified against real GAS before the encoder was written,
  and GAS's intended form was checked, not only its bytes;
* `make asm-isa-difficult-regen` (tier two) and `make asm-isa-difficult-check`,
  `make tools-test`, `make tools-integration`, `make tools-boundary`,
  `make asm-fmt-check` and `make asm-ci` pass; `make asm-js-portable` and
  `make asm-purity` pass when production code changed;
* the residual ledger changes to match (a closed family leaves its row; a row
  with no families left is deleted), and the tracker records the before/after
  counts from the family-admission report.
