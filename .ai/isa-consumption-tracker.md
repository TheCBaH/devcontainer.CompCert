# ISA consumption work tracker

Architecture and stage definitions: [isa-consumption-plan.md](isa-consumption-plan.md).
Baseline: `b659f3e`, reviewed 2026-09-05, revised the same day after an
independent re-verification pass (all S0 figures reproduced; two capture
defects now tracked instead of one).
This file is the status authority; the plan describes the intended design.

## Stage status

Allowed states: `not-started`, `investigating`, `ready`, `implementing`,
`validating`, `done`, `blocked`. A blocked entry must name its dependency
and next action. `Done` requires acceptance evidence, not just a merged change.

| Stage | State | Evidence / next action |
|---|---|---|
| S0 Baseline | done | Plan sections 2–3 and 7: measured exports, 47 producer tests, four-profile inventory check, GAS compressed-width probe, XED coarse mode-leak probe; all re-verified on the revision pass |
| S1 Capture fidelity | done | CAP-01 through CAP-06: versioned native-capture envelope, input verification, raw facts, relationship indexing, exact width/mode corrections, deterministic regeneration and loss/unknown report |
| S2 OCaml model | done | NORM-01 through NORM-05 done (worked-example types, pilot normalization, complete decode/normalize accounting, three-valued mode/XLEN requirements plus exact/ambiguous/missing relationship decoding, a bidirectional normalized-JSONL codec, and a cross-snapshot record-identity mapping report) |
| S3 Differential pilots | done | GAS-01 through GAS-05 done: the 21-case relocation-free pilot has real GNU and "ours" evidence plus a toolchain-free replay gate, while the existing controlled multi-unit fixture differential provides the complementary linked-image, section/symbol/fixup evidence at matching fixed addresses and relaxation policy. |
| S4 Difficult forms | implementing | GEN-02 through GEN-04 done. GEN-05 now promotes bare RISC-V scalar F/D arithmetic under RV32IMF(D)/RV64IMF(D), Zba's full scale-and-add family - `sh1add`/`sh2add`/`sh3add` under RV32IM_Zba/RV64IM_Zba plus the RV64-only `sh1add.uw`/`sh2add.uw`/`sh3add.uw` word-operand siblings - Zbb `min`/`minu`/`max`/`maxu` under RV32IM_Zbb/RV64IM_Zbb, Zbb's five-way import-duplicated `andn`/`orn`/`xnor`/`rol`/`ror` now that `Isa_norm_riscv` builds a real `Req_any` for them, Zbb's population-count/sign-extend/byte family - `clz`/`ctz`/`cpop`/`sext.b`/`sext.h`/`orc.b` (XLEN-independent) plus the RV64-only `clzw`/`ctzw`/`cpopw` word-operand siblings - via a new two-GPR-operand (`rd`, `rs1`, no immediate) normalization/encoder shape, and Zbkb's `brev8` (the same two-GPR shape, a four-way `Req_any` over `rv_zbkb`/`rv_zk`/`rv_zkn`/`rv_zks`, identical mnemonic/encoding on both profiles), and `rev8` (the same shape, an XLEN-dependent funct12, a per-profile five-way `Req_any`, and riscv-opcodes' own `rev8`/`rev8.rv32` native-name split unified into one rendered mnemonic and `form_id`, since real GNU as never accepts the `rev8.rv32` spelling) - closing every named blocker in this population-count/sign-extend/byte-reverse family. GEN-05 also now admits Zbkb's `pack`/`packh` (three-GPR R-type, four-way `Req_any`, identical on both profiles), the RV64-only `packw`, and the RV32-only `zip`/`unzip` (two-GPR unary), reusing the existing R-type/unary shapes and `Req_any` machinery unchanged, plus the RV64-only `rolw`/`rorw` (`rol`/`ror`'s word-operand siblings, the identical three-GPR R-type shape reusing `rev8`'s own five-way rv64-prefixed `Req_any` group verbatim), and `rori`/`rori.rv32`/`roriw` (Zbb's first rotate-*immediate* shape - a genuine two-GPR-plus-unsigned-shamt-immediate form, new `shamt_gpr_form` normalization plus `i_desc`'s existing `funct_hi`/`shamt_bits` XLEN-conditional encoder machinery already used by `srai`, `rori`/`rori.rv32` sharing one canonical rendered mnemonic via the same profile-specific native-name split `rev8`/`rev8.rv32` established). GEN-05 now also admits `zext.h`/`zext.h.rv32` (Zbb's zero-extend-halfword pseudo, reusing `unary_gpr_form` and the same profile-specific native-name split verbatim, but with a plain per-profile `Req_all` since - unlike rev8/rori - neither record is import-duplicated), closing that named follow-up. GEN-05 now also admits Zbc's `clmul`/`clmulh` (carry-less multiply, the same plain three-GPR R-type shape as `andn`/`orn`/`xnor`/`rol`/`ror`, a five-way `Req_any` over `rv_zbc`/`rv_zbkc`/`rv_zk`/`rv_zkn`/`rv_zks`, identical mnemonic/encoding on both profiles); and Zbkx's `xperm4`/`xperm8` (crossbar permute, the same three-GPR R-type shape, a four-way `Req_any` over `rv_zbkx`/`rv_zk`/`rv_zkn`/`rv_zks` - no separate non-K sibling extension the way clmul/clmulh have rv_zbc alongside rv_zbkc), fully closing that mnemonic pair; and Zknh's `sha256sum0`/`sha256sum1`/`sha256sig0`/`sha256sig1` (SHA-256 message-schedule helpers, the same two-GPR unary shape as `clz`/`ctz`/`cpop`, a three-way `Req_any` over `rv_zknh`/`rv_zk`/`rv_zkn` - no `rv_zks`), fully closing that mnemonic quartet; and Zknh's RV64-only `sha512sum0`/`sha512sum1`/`sha512sig0`/`sha512sig1` (SHA-512's own message-schedule helpers, the same two-GPR unary shape, a three-way `Req_any` over `rv64_zknh`/`rv64_zk`/`rv64_zkn`), closing every Zknh mnemonic that fits this unary shape; and Zknh's RV32-only `sha512sum0r`/`sum1r`/`sig0l`/`sig1l`/`sig0h`/`sig1h` (SHA-512's own 32-bit-word-pair-split helpers, a genuinely different plain three-GPR R-type shape reusing `r_type_gpr_form`/`r_desc`, a three-way `Req_any` over `rv32_zknh`/`rv32_zk`/`rv32_zkn`), fully closing every Zknh SHA-256/SHA-512 mnemonic on both shapes and both profiles; and RISC-V AES-64's plain-shape round functions `aes64ds`/`aes64dsm`/`aes64es`/`aes64esm`/`aes64ks2`/`aes64im` (RV64-only, reusing the existing three-GPR R-type and two-GPR unary shapes across three distinct `Req_any` groups - `rv64_zknd`-rooted, a disjoint `rv64_zkne`-rooted, and `aes64ks2`'s own four-way group imported by both), fully closing every AES/SHA mnemonic that fits an already-built shape; and RV64's `aes64ks1i` (AES-64's first key-schedule helper, a genuinely new two-GPR-plus-narrow-immediate shape - `rnum`'s valid range 0-10 is narrower than its 4-bit field's 0-15 capacity, needing its own explicitly-validated match arm rather than the shared `i_desc`/`shamt_bits` path, plus a generalized `shamt_gpr_form` accepting riscv-opcodes' own "rnum" field name instead of `rori`/`roriw`'s "shamt" one), sharing `aes64ks2`'s own four-way `Req_any` group; and RV32's `aes32dsi`/`aes32dsmi`/`aes32esi`/`aes32esmi` (AES-32's own round functions, a fourth distinct operand shape - three-GPR-plus-2-bit-`bs`-immediate, `bs` using its full field range unlike `rnum` - reusing `Lowered.R`/`word_r` unchanged via a composed `funct7`, plus a new `r_type_imm_gpr_form` normalization function, two `Req_any` groups mirroring `aes64ds`/`dsm`'s and `aes64es`/`esm`'s own), closing the entire named Zk/Zkn/Zks AES/SHA scope surveyed this session across all four operand shapes built (two-GPR unary, three-GPR plain, two-GPR-plus-narrow-immediate, three-GPR-plus-narrow-immediate); and Zicsr's `csrrw`/`csrrs`/`csrrc`/`csrrwi`/`csrrsi`/`csrrci` (self-selected from a fresh survey after the AES/SHA arc closed - top-unhandled names are now dominated by vector-crypto mnemonics needing a whole new register class, so CSR, the smallest bounded remaining family, was picked instead; XLEN-independent, the session's first family needing no `Req_any` at all; `csrrw`/`csrrs`/`csrrc` reorder GAS's own `[rd, csr, rs1]` text order against riscv-opcodes' `[rd, rs1, csr]` field order and encode `csr`'s unsigned 12-bit address via its own signed two's-complement equivalent through the unchanged `word_i` path; `csrrwi`/`csrrsi`/`csrrci` reuse the `rs1` bit position to carry a real 5-bit `zimm5` immediate with no register operand there at all), and Zicsr's own 7 GAS pseudo-op aliases `csrr`/`csrw`/`csrs`/`csrc`/`csrwi`/`csrsi`/`csrci` (each an `rd`-or-`rs1`-omitting shorthand fixing the omitted register to literal 0, three new operand shapes - `csrr rd, csr`, `csrw`/`csrs`/`csrc csr, rs1`, `csrwi`/`csrsi`/`csrci csr, zimm5` - reusing the base forms' `csr`-address two's-complement encoding via a newly factored-out shared `signed_csr` helper), fully closing every Zicsr mnemonic in the checked-in export. GEN-05 now also admits Zaamo's full atomic-memory-operation family - `amoswap`/`amoadd`/`amoxor`/`amoand`/`amoor`/`amomin`/`amomax`/`amominu`/`amomaxu`/`sc` on both `.w` (both profiles, `rv_a`) and `.d` (RV64-only, `rv64_a`), plus `lr.w`/`lr.d` (the family's only two-operand member) - the first GEN-05 family using a real GAS memory group (`(rs1)`) as an operand rather than a plain register or immediate, via two new shapes (`amo_form`/`amo3_desc` for the three-GPR-plus-memory mnemonics, `lr_form`/`lr_desc` for the two-operand one); the `.aq`/`.rl`/`.aqrl` mnemonic-suffix decorators every one of these 22 records also supports are explicitly out of scope (GAS's bare canonical spelling only, flagged via a diagnostic, not silently dropped), fully closing every Zaamo mnemonic under that canonical spelling. GEN-05 now also admits F/D's `flw`/`fld`/`fsw`/`fsd` (floating-point loads/stores, already fully implemented by the encoder's pre-existing `f_load_desc`/`f_store_desc` path, so this closes only the normalization/corpus/admission side via two new shapes `f_load_form`/`f_store_form`), closing the cheapest remaining FP increment. GEN-05 now also admits the general two-distinct-register form of `fsgnj.s`/`fsgnjn.s`/`fsgnjx.s`/`fsgnj.d`/`fsgnjn.d`/`fsgnjx.d` (the encoder previously only implemented the `rs1 = rs2` pseudo-aliases `fneg.s`/`fneg.d`/`fmv.d`; this slice adds a new `f_sgnj3_desc` encoder table/lowering arm and inverts the decode-side alias/general priority so both forms round-trip correctly, plus a new `f_sgnj_form` normalization shape), closing that named encoder gap. GEN-05 now also admits `fmin.s`/`fmax.s`/`fmin.d`/`fmax.d` (the same fixed-funct7-per-precision, funct3-selects-operation shape as `fsgnj`/`fsgnjn`/`fsgnjx`, reusing the identical `f_sgnj3_desc`/`f_sgnj_form`-style pattern via new `f_minmax_desc`/`f_minmax_form`, no alias collision to resolve this time), closing that pair. GEN-05 now also admits `fsqrt.s`/`fsqrt.d` (the arithmetic family's own implicit-dynamic-rounding shape minus a second FP operand, new `f_sqrt_desc`/`f_sqrt_form`) and `fclass.s`/`fclass.d` (the plain-GPR-result shape `fmv.x.d` established, kept in its own new `f_class_desc`/`f_class_form` rather than the shared `f_to_i_desc` table - doing so was found, and verified against real GNU as, to reproduce a pre-existing latent gap where that table's rounding-mode-override lowering arm wrongly accepts `fmv.x.d a0, fa1, rtz`, an illegal spelling real GNU as rejects, silently colliding with `fclass.d`'s own real encoding; not fixed here, flagged as a follow-up), closing that pair too. GEN-05 now also admits the fused multiply-add family `fmadd.s`/`fmsub.s`/`fnmsub.s`/`fnmadd.s`/`fmadd.d`/`fmsub.d`/`fnmsub.d`/`fnmadd.d` (RISC-V's only R4-type instructions - a genuinely new `Lowered.R4`/`word_r4` codec path, since the top 7 bits split into a 5-bit `rs3` and 2-bit `fmt` rather than one fixed `funct7`, and each mnemonic gets its own base opcode `0x43`/`0x47`/`0x4b`/`0x4f` instead of sharing OP-FP's `0x53`; new `f_fma_form` normalization, `f_arith_form`'s own implicit-dynamic-rounding shape plus a fourth FPR operand), closing that family. GEN-05 now also admits the comparison family `feq.s`/`fle.s`/`flt.s`/`feq.d`/`fle.d`/`flt.d` (a fresh survey found the encoder already had `flt.s`/`feq.d`/`fle.d`/`flt.d` support from an earlier pass with no normalization/corpus/admission ever built for them, plus `feq.s`/`fle.s` missing from the encoder entirely; the two missing entries were added to the pre-existing `f_cmp_desc` table with no new lowering arm needed, plus a new `f_cmp_form` normalization shape - `rd` a GPR, `rs1`/`rs2` FPRs, no `rm`), closing every named scalar FP comparison. GEN-05 now also admits `fmv.x.w`/`fmv.w.x` (the single-precision bit-for-bit moves `fmv.x.d` already established the shape for; `fmv.x.w` added to a new, separate `f_mv_x_w_desc` table rather than `f_to_i_desc` - the same latent-bug-avoidance reasoning `fclass.s`/`fclass.d` already used - while `fmv.w.x` was added directly to `i_to_f_desc`, which has no such bug to avoid; two new normalization shapes `f_mv_x_w_form`/`f_mv_w_x_form`), closing that pair. GEN-05 now also admits the `w`/`s` conversions `fcvt.w.s`/`fcvt.wu.s`/`fcvt.s.w`/`fcvt.s.wu` (the last named scalar-FP item; unlike every recent slice, needed two genuinely new normalization shapes, `f_cvt_w_s_form`/`f_cvt_s_w_form` - mixed-register-class, implicit-dynamic-rounding - since `fcvt.s.w`/`fcvt.s.l` and the double-precision conversions already had encoder support from an earlier, pre-isa-consumption pass but had never been wired into normalization/admission/corpus at all; `fcvt.s.wu` was added to that same pre-existing `i_to_f_desc` table, `fcvt.w.s`/`fcvt.wu.s` added directly to `f_to_i_desc` with no bug-avoidance split needed, since their own funct3 genuinely is the dynamic rounding mode), fully closing every scalar FP mnemonic named as open across every prior GEN-05 F/D writeup this session. GEN-05 now also admits the double-precision conversions `fcvt.w.d`/`fcvt.wu.d`/`fcvt.d.w`/`fcvt.d.wu`/`fcvt.s.d`/`fcvt.d.s` (all six already had encoder support from the same earlier pre-isa-consumption pass but had never been wired into norm/admission/corpus either; `fcvt.w.d`/`fcvt.wu.d` reuse `f_cvt_w_s_form` verbatim - `requirement_of` distinguishes riscv:d from riscv:f automatically - while `fcvt.d.w`/`fcvt.d.wu` and the float-to-float `fcvt.s.d`/`fcvt.d.s` needed two new forms, `f_cvt_d_w_form`/`f_cvt_f_f_form`, since real hardware's widening conversions - integer-to-double and single-to-double - default to an always-exact rne rounding mode rather than the family's usual dynamic default), fully closing every named F/D scalar conversion and every scalar F/D mnemonic flagged open across this session. GEN-05 now also admits the RV64-only long conversions `fcvt.l.d`/`fcvt.lu.d`/`fcvt.d.l`/`fcvt.d.lu`/`fcvt.l.s`/`fcvt.lu.s`/`fcvt.s.l`/`fcvt.s.lu` (only `fcvt.l.d`/`fcvt.s.l` already had encoder support; the other 6 needed genuinely new `Opcode.t` variants and table entries; no new normalization shape was needed - `fcvt.l.d`/`fcvt.lu.d`/`fcvt.l.s`/`fcvt.lu.s` reuse `f_cvt_w_s_mnemonics` and `fcvt.s.l`/`fcvt.s.lu`/`fcvt.d.l`/`fcvt.d.lu` reuse `f_cvt_s_w_mnemonics` verbatim, since - measured, not assumed - `fcvt.d.l`/`fcvt.d.lu` keep the family's usual dynamic-rounding default rather than `fcvt.d.w`/`fcvt.d.wu`'s always-exact one, because a 64-bit long is not always exact in a double the way a 32-bit int is; also added `rv64_d`/`rv64_f` to `feature_of_extension`, the first RISC-V FP mnemonics needing an XLEN-gated F/D feature), fully closing every named scalar RISC-V F/D conversion mnemonic in the checked-in export - no further scalar F/D conversion scope remains named. A separate, smaller, not-yet-scoped gap surfaced by this slice: `i_to_f_desc` has no explicit-rounding-mode-override lowering arm at all, so this project's own encoder cannot accept an explicit `rm` operand on any `i_to_f_desc`-mapped mnemonic even though real GNU as does; predates this slice, not a regression from it. GEN-05 now also admits `vsetvl` (V's register-register configuration-setting instruction, the deliberately cheapest entry point into the 375-record rv_v family - a plain three-GPR R-type shape reusing `r_type_gpr_form`/`r_desc` unchanged, a single non-import-duplicated `rv_v` record identical on both profiles, needing only a new `riscv:v` feature and OP-V's previously-unused major opcode `0x57`; confirmed against real GNU as: `vsetvl a0, a1, a2` -> `80c5f557` on both `riscv32-linux-gnu-as` 2.43.1 (`-march=rv32iv`) and `riscv64-linux-gnu-as` 2.44 (`-march=rv64iv`), no F/D dependency needed for this one instruction). GEN-05 now also admits `vsetvli`/`vsetivli` (V's own immediate-vtype siblings; GAS's own `e<SEW>,m<LMUL>,ta|tu,ma|mu` keyword-list spelling turned out not to need any frontend/parser change at all - each bare keyword already parses as a generic `Operand.Sym` through the existing text grammar, so the entire feature is a variable-length-operand-list lowering match plus a small keyword-to-bit-pattern classifier, reusing the *existing* `Lowered.I`/`word_i` codec unchanged for both: `vsetvli`'s bit31=0 constraint and `vsetivli`'s bits[31:30]=0b11 constraint both fall out automatically from plain signed-12-bit two's-complement arithmetic on the composed vtype value, the same way `signed_csr` already reuses this path for CSR's unsigned field; confirmed against real GNU as for every keyword, every legal subset/ordering, and both rejection cases (`vsetvli a0, a1, m1, e32` and `vsetvli a0, a1, ma, ta` both "illegal operands") before writing any encoder code). GEN-05 now also admits `vadd.vv`/`vadd.vx`/`vadd.vi` (the entry point into OP-V's real ~373-record vector-register arithmetic space, as opposed to the configuration-setting group above; introduces a genuinely new `Reg.V` register class - `v0`-`v31`, needing zero frontend/parser changes since `riscv_family.ml`'s bare-identifier resolution is already generic over `Reg.find` - and a new `Riscv_vec` entry in the normalized model's `register_class`; the word's top 7 bits split into a 6-bit funct6 and 1-bit vm mask-select exactly the way any other R-type's `funct7` already does, so all three mnemonics reuse the *existing* `Lowered.R`/`word_r` codec unchanged with `funct7 = (funct6 lsl 1) lor vm`; `vadd.vx`'s `rs1` stays a plain GPR and `vadd.vi`'s `rs1` position carries a real signed 5-bit immediate instead of a register, both confirmed against real GNU as including the optional trailing `, v0.t` mask operand and out-of-range/malformed rejections). The remaining vector scope is still large and unclaimed: the ~370 remaining rv_v records and every rv_zv* vector-crypto extension, all needing mask/vl operands and segment/strided/indexed addressing beyond the plain register class just added; GEN-06 has no single named next item. |
| S5 Components | not-started | MOD-01: extract M/x87 after independent regression evidence |
| S6 Feature selection | not-started | FEAT-01: configuration propagation and enforcement |
| S7 Closure | not-started | CLOSE-01: reconcile complete coverage and residual-task ledger |

## Work package briefs

### CAP — Capture fidelity and source-native export

Scope: Python adapters, capture contracts, source identity and producer CI.
Owner: unassigned. Stages: S1, source-update evidence in S7.

Investigate instruction length from source facts; exact meanings of XED
width/operand fields; raw/resolved payload boundaries; missing lookup
vocabularies; pin verification; snapshot-local IDs and relationship targets.
Keep changes scoped to the two existing sources and their build dependency.

- [x] CAP-01 Correct the measured 31 RV32 / 29 RV64 compressed-width labels
  by deriving width **per record** from that record's own encoding, not per
  extension file; a corrected filename predicate does not satisfy this, and
  the `$import` path must not inherit the importing file's width. The
  expected diff is exact and complete (plan section 3.1). Establish encoding
  invariants and independent GAS examples.
- [x] CAP-02 Specify native schema/envelope versions, deterministic ordering,
  provenance, unknown fields and compatibility exports.
- [x] CAP-03 Preserve required XED/RISC-V native facts without canonical
  feature or GAS syntax interpretation in Python.
- [x] CAP-04 Verify actual source/dependency commits and input hashes;
  detect dirty or stale snapshots and resolve/index native references.
- [x] CAP-05 Add negative validation controls and fresh-process regeneration
  evidence; preserve or explain compatibility manifest differences. Build on
  the existing `test_export.py::TestCheckedInExportUpToDate` freshness gate
  rather than a second one, and state explicitly whether its deliberate
  outside-`asm-ci` boundary changes (plan section 3.5).
- [x] CAP-06 Fix the XED coarse mode-applicability leak: `jrcxz` must leave
  `xed/x86_32.jsonl` and `asm/fixtures/isa-inventory/x86_32/manifest.txt`.
  Give the reader an explicit vocabulary of mode-restricting constructs
  (`eamode*`, `FORCE64()`, ISA_SET `LONGMODE`), make an unrecognized
  restriction an `Unknown` applicability that blocks positive generation,
  and report unknown tokens instead of widening `_MODE_TOKENS` silently.
  Mirror the fix in `isa_inventory_xed.ml`, whose traversal the adapter
  reproduces, and add the coarse-versus-resolved comparison that would have
  caught it (plan sections 2.2, 2.3, 3.2).

Exit: S1 gates pass and NORM has versioned input fixtures plus a documented
loss/unknown report. Evidence must include both the width counterexample
and the `jrcxz` counterexample.

#### CAP-01/CAP-06 capture-correctness milestone

Task / status / owner: CAP-01 and CAP-06 / done / Codex.

Scope manifest and obligations: Every exported RISC-V fixed-bits record
derives its width from its own mask/value, including upstream-resolved
imports and pseudo-ops. The x86 coarse reader and the mirrored OCaml
inventory parser recognize `eamode64`, `FORCE64()`, and `ISA_SET: LONGMODE`;
unknown candidate restrictions evaluate to Unknown and cannot select a
profile. Coarse/resolved XED names differ only by `nop2` through `nop9`.

Implementation commit: `f7e4151`.

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396`; XED
`0bcb6237345c5066726dcc08b3d87928df3b5b26`.

Tool versions and exact commands: `python3 -m unittest discover -s
isa-db/tests -t isa-db`; `make tools-isa-inventory`; `make
tools-isa-db-cross-validate`; `make tools-test`; `make tools-integration`.

Results and artifact links: 51 Python tests passed; the regenerated exports
correct exactly 31 RV32 and 29 RV64 width labels; x86-32 inventory is 2,492
rows after removing `jrcxz`; both XED view deltas are accounted.

Unknowns, exceptions and follow-up task IDs: Wider-than-32-bit or
indeterminate RISC-V length discriminators are rejected, not guessed.
CAP-02 through CAP-05 remain the source-native contract, preservation,
verification, and freshness work.

Acceptance gate satisfied: the two measured counterexamples are covered by
adapter and OCaml tests, regenerated artifacts, and checked-in-only
cross-validation.

#### CAP-02 through CAP-05 capture-contract milestone

Task / status / owner: CAP-02, CAP-03, CAP-04, CAP-05 / done / Codex.

Scope manifest and obligations: `isa-db/docs/capture-contract.md` defines
the version-1 envelope, preserved native source facts, deterministic ordering,
loss/unknown behavior, and source-update policy. Every export is tied to clean
lockfile checkouts, selected-input hashes, and a producer content revision.

Implementation commit: `6e24980`.

Source snapshots and input hashes: captured in
`isa-db/export/capture-manifest.v1.json` for the XED, mbuild, and
riscv-opcodes pins.

Tool versions and exact commands: `python3 -m export.regen`; `python3 -m
export.verify`; `make isa-db-capture-check`; `python3 -m unittest discover
-s isa-db/tests -t isa-db`; `make tools-isa-db-cross-validate`; `make
tools-test`; `make tools-integration`.

Results and artifact links: 54 producer tests pass. Negative mocked wrong-pin
and dirty-tree controls pass; the existing fresh-export gate now includes the
capture manifest. The source check remains deliberately outside `asm-ci`.

Unknowns, exceptions and follow-up task IDs: Relation candidates that are
missing from a selected profile or ambiguous remain visible per record for
NORM-03. XED original locations and coarse operands remain explicit losses
for NORM-02.

Acceptance gate satisfied: clean pinned inputs, deterministic exports, raw
facts, and explicit unresolved outcomes are checked before later OCaml
interpretation begins.

### NORM — OCaml interpretation and observable representation

Scope: typed source decoders, shared model, source-specific rules, normalized
JSONL and accounting. Owner: unassigned. Stages: S2, S7.

Investigate `sw`/`beq` reconstruction, compressed constraints, floating
register classes, XED widths/visibility, native feature requirements and
stable form identity. Compare a small typed model with a fully generic
expression model using actual examples; choose only the abstractions used.

- [x] NORM-01 Freeze minimum types and example normalized records for the
  plan's worked examples; label inferred versus upstream facts.
- [x] NORM-02 Implement source-specific decoding and complete record
  accounting, with actionable unknown-construct diagnostics.
- [x] NORM-03 Implement three-valued requirements and exact/ambiguous/missing
  relationship outcomes; preserve one-to-many and many-to-one mappings.
- [x] NORM-04 Export and round-trip deterministic normalized JSONL with
  source/rule references and schema versions.
- [x] NORM-05 Establish offline library/tool boundaries and snapshot-update
  mapping reports; inventory compatibility remains a separate view.

Exit: all selected records accounted for; pilot examples fully interpreted;
unknown constraints cannot produce positive cases. No runtime assembler
dependency on source databases or host tools.

#### NORM-01 worked-example model milestone

Task / status / owner: NORM-01 / done / Codex.

Scope manifest and obligations: `asm/tools/lib/isa_source_record.{ml,mli}`
decodes the full `source_record.schema.v1.json` shape (encoding and
source-specific provenance, not just the narrow cross-validation projection
`Isa_db_jsonl` already had). `asm/tools/lib/isa_norm_model.{ml,mli}` freezes
the minimum normalized types from plan §4.2 (form, operand, encoding,
requirement, syntax recipe, fact/provenance-label, diagnostic) plus a
`render_syntax` function so a recipe can be checked against literal text.
`asm/tools/lib/isa_norm_riscv.{ml,mli}` and `isa_norm_xed.{ml,mli}` normalize
exactly the plan's frozen §7 pilot set - `sw`, `beq`, `c.addi`, `sh1add`,
`fadd.s`, `ADD_GPRv_IMMz`, and the x87 form `FADD_ST0_X87` - dispatching on
`native_name`/`provenance.iform` and returning an explicit
`unhandled-native-name`/`unhandled-iform` diagnostic for anything else, per
plan §3.3's "unknown constructs must be reported, never silently dropped."

Design choices worth recording: `beq`'s and `c.addi`'s split immediates are
modeled as an ordered list of `bit_run`s (destination bit range sourced from
a named raw field's own local bit range) rather than plain field
concatenation, because `beq`'s B-type immediate is a genuine permutation
(imm[12|10:5|4:1|11]), not concatenation like `sw`'s S-type immediate - see
plan §3.3. Every fact not stated verbatim by the source record (immediate
bit layout, the `x0`/nonzero exclusions, FPR-vs-GPR register class, AT&T
operand order) is recorded as an `Inferred` `fact`, distinct from `Upstream`
facts quoting the record's own fields, so a reader can tell which half of
each normalized form is a source claim versus this step's own interpretation.
Two points are deliberately left unresolved rather than guessed: XED's `oc2`
`z`-class immediate width (operand-size-dependent, not resolved by the
resolved-record facts alone) and `FADD_ST0_X87`'s GAS syntax spelling
(distinguishing it from the reverse-direction `FADD_X87_ST0` form is x87
syntax work the plan defers to GEN-04) - both carry a `diagnostic` instead of
an asserted value.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396`; XED
`0bcb6237345c5066726dcc08b3d87928df3b5b26` (unchanged from S1; NORM-01 reads
the existing checked-in exports, it does not regenerate them).

Tool versions and exact commands: `cd asm/tools && opam exec -- dune build
@runtest`; `make tools-test`; `make tools-integration`; `make tools-boundary`;
`make asm-fmt-check`.

Results and artifact links: 19 `isa-norm-riscv` checks and 13 `isa-norm-xed`
checks pass, embedding the seven pilot records verbatim (one compact,
sorted-key JSON line each) from the checked-in
`isa-db/export/riscv_opcodes/riscv32.jsonl` and
`isa-db/export/xed_resolved/{x86_32,x86_64}.jsonl` at this revision, so a
decode/normalization regression here is against real captured data, not a
synthetic shape. `sw`'s recipe renders exactly plan §4.2's own example text,
`"sw value, offset(base)"`. `tools-test`, `tools-integration`,
`tools-boundary`, and `asm-fmt-check` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: this covers only the seven
frozen pilot forms; every other native record - including `add`/`addi`/`mul`
on RISC-V and legacy `mov` on x86, both named in the plan's pilot scope
(§7) - still reports `unhandled-native-name`/`unhandled-iform` rather than a
form, which is exactly NORM-02's scope. `applicability` and `relationships`
are decoded by neither module (every pilot record carries an unconditional
`{kind: "all", of: []}`); a form needing either is also NORM-02/NORM-03.
Normalized JSONL export/round-trip (NORM-04) and the offline
library/tool-boundary and snapshot-update reports (NORM-05) are untouched.

Acceptance gate satisfied: the plan's §7 "S2 should additionally normalize
representative sw, beq, c.addi, sh1add, ADD_GPRv_IMMz and an x87 form as
design tests" instruction is met for exactly those seven forms, each with
inferred-vs-upstream fact labeling and machine-checked evidence against real
captured records.

#### NORM-02 source-specific decoding and complete record accounting milestone

Task / status / owner: NORM-02 / done / Codex.

Scope manifest and obligations: broaden `Isa_norm_riscv`/`Isa_norm_xed`
beyond NORM-01's seven frozen pilot forms via explicit, reviewed mnemonic/
iform allowlists (not a shape-driven catch-all - plan §4.2 rules that out),
and add `asm/tools/lib/isa_norm_accounting.{ml,mli}`, which runs
`normalize` over every record in all four checked-in
`isa-db/export/{riscv_opcodes,xed_resolved}/{riscv32,riscv64,x86_32,x86_64}.jsonl`
files and reports, per file, the exact normalized-versus-diagnosed split
plus a diagnostic-rule and top-unhandled-name/iform breakdown - the
"complete record accounting, with actionable unknown-construct diagnostics"
NORM-02 asks for. "Complete" means every record is machine-checked to reach
either a form or a reported diagnostic (never silently dropped or an
uncaught exception), not that every record is normalized - full-family
coverage remains explicit, counted follow-up work (NORM-02's own text and
plan §4.3 both treat family-by-family expansion as later, not this task).

RISC-V: added a generic R-type register-register helper
(`r_type_gpr_form`) and I-type register-immediate helper (`i_type_imm_form`),
covering the `add`/`addi`/`sub`/`mul` GEN-01 pilot mnemonics and their
RV32I/RV64I/M-extension siblings (29 mnemonics total, verified field-shape-
identical across both profiles before writing the dispatch). `rv64_i`/
`rv64_m`-extension forms (the `*w` mnemonics) get `Req_unknown` plus an
explicit `<mnemonic>-xlen-unmodeled` diagnostic rather than a false
`Req_all []`, since the requirement model still has no XLEN predicate
(NORM-03); `sltiu` additionally carries a `sltiu-imm-sign-vs-compare`
diagnostic distinguishing its sign-extended immediate encoding from its
unsigned comparison semantics.

XED: extended `Isa_source_record`'s `X86_encoding` to capture
`encoding.operands` (name/type/lookupfn_name/oc2/bits/rw/visibility) -
previously decoded only as `space`/`opcode_map`/`opcode`/`pattern`, discarding
exactly the per-operand read/write facts `ADD_GPRv_IMMz`'s NORM-01 comment
had to assert as externally-verified rather than record-derived knowledge.
A new generic `two_operand_gprv_form` reads a form's own operand `rw` facts
to place the source first in AT&T order regardless of which XED slot
(REG0 vs REG1) carries it, verified against both encoding directions
(`ADD_GPRv_GPRv_01`/`_03`, `MOV_GPRv_GPRv_89`/`_8B` render identically
despite the REG0/REG1 swap) - covering the GEN-01 x86 pilot's register/
register and register/immediate `add`/`mov` forms (`ADD_GPRv_IMMz` already
NORM-01; `ADD_GPRv_GPRv_01`, `ADD_GPRv_GPRv_03`, `MOV_GPRv_GPRv_89`,
`MOV_GPRv_GPRv_8B`, `MOV_GPRv_IMMz` new).

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396`; XED
`0bcb6237345c5066726dcc08b3d87928df3b5b26` (unchanged; reads existing
checked-in exports).

Tool versions and exact commands: `cd asm/tools && opam exec -- dune build
@runtest`; `make tools-test`; `make tools-integration`; `make tools-boundary`;
`make asm-fmt-check`; `make asm-purity`;
`COMPCERT_REPO_ROOT=$(pwd) asm/_build/default/tools/bin/compcert_tools.exe
isa-inventory norm-accounting` (new CLI subcommand, toolchain-free - reads
only the checked-in exports).

Results and artifact links: 30 `isa-norm-riscv` and 24 `isa-norm-xed` unit
checks pass. The new accounting command, and a pinned regression assertion
in `asm/tools/test/repo/repo_tests.ml` (exercised by `tools-integration`),
report: riscv_opcodes/riscv32 1089 records, 29 normalized; riscv_opcodes/
riscv64 1154 records, 40 normalized; xed_resolved/x86_32 7887 records, 7
normalized; xed_resolved/x86_64 10571 records, 7 normalized - every
remaining record carries `unhandled-native-name` or `unhandled-iform`, none
silently dropped. `tools-test`, `tools-integration`, `tools-boundary`,
`asm-fmt-check`, `asm-purity` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: the overwhelming majority of
records remain diagnosed-unhandled by design - full-family coverage
(RISC-V loads/branches beyond `beq`/shifts/compressed forms beyond
`c.addi`/CSR/vector; x86 memory operands/x87 beyond `FADD_ST0_X87`/EVEX/
vector) is GEN-02 through GEN-06 and later NORM iterations, not this task.
The accounting command's top-unhandled-name breakdown is the actionable
input for prioritizing that work. The XLEN predicate gap surfaced by
`*w`/`rv64_*` mnemonics is explicitly NORM-03's, not guessed around here.

Acceptance gate satisfied: every record in all four checked-in exports is
machine-checked to reach a normalized form or a reported diagnostic (S2's
"unknown predicates never pass" and "every selected record accounted for"
exit criteria), decoding is broadened via reviewed, evidence-checked
mnemonic/iform allowlists rather than a blind per-mnemonic guess, and the
diagnostics are actionable (grouped by rule and by top offending name).

#### NORM-03 three-valued requirements and relationship-resolution milestone

Task / status / owner: NORM-03 / done / Codex.

Scope manifest and obligations: decode the two source-record fields NORM-01
and NORM-02 both left unread - top-level `applicability` (isa-db/schema
§applicability's three-valued `all`/`any`/`mode` expression tree) and
riscv-opcodes' `provenance."relationship-resolution"` (exact/ambiguous/
missing `$import`/`$pseudo_op` outcomes) - into `Isa_source_record`, and
thread `applicability` into `Isa_norm_model.requirement` via two new
constructors, `Req_mode` (x86 execution-mode predicate) and `Req_xlen`
(RISC-V XLEN predicate), replacing the `Req_unknown` placeholders NORM-02
left for `rv64_i`/`rv64_m`.

While threading `applicability` through, found and fixed a real latent bug:
`Isa_norm_xed.requirement_of` classified an x86 requirement from the raw
`provenance.mode_restriction` fact, whose JSON type is actually a union
(the string `"unspecified"`, or an integer XED-internal mode id for a
mode-gated form) that `xed_provenance.mode_restriction : string option`
silently decoded to `None` for the integer case. A BASE-extension,
mode64-gated form (113 real x86_64 records, e.g. `CDQ`/`MOVSXD`-shaped
iforms) therefore fell through to `Req_unknown "unmapped XED extension:
BASE"` - a wrong and misleading diagnostic, since BASE *is* a mapped
extension; only that specific mode-restricted case was mishandled. Routing
the requirement through `applicability` (which the adapter derives
correctly regardless of the raw fact's JSON type) fixes this: such a form
now gets `Req_mode {mode = "mode64"; equals = true}`.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396`; XED
`0bcb6237345c5066726dcc08b3d87928df3b5b26` (unchanged; reads existing
checked-in exports).

Tool versions and exact commands: `cd asm/tools && opam exec -- dune build
@runtest`; `make tools-test`; `make tools-integration`; `make tools-boundary`;
`make asm-fmt-check`; `make asm-purity`;
`COMPCERT_REPO_ROOT=$(pwd) asm/_build/default/tools/bin/compcert_tools.exe
isa-inventory norm-accounting`.

Results and artifact links: 33 `isa-norm-riscv` and 25 `isa-norm-xed` unit
checks pass, including three relationship-decode checks against real
`riscv32.jsonl` records taken verbatim - `c.slli`'s missing `specializes`
(candidates `[]`), `aes32dsi`'s exact `imports` (one candidate), and `j`'s
ambiguous `specializes` (both `jal` candidates preserved, a genuine
one-to-many mapping riscv-opcodes' own data is ambiguous about, not a
normalization defect) - plus a synthetic (hand-modified from a verbatim
fixture) mode64-gated `ADD_GPRv_IMMz` record proving the `Req_mode` fix.
The NORM-02 accounting command's normalized-vs-diagnosed split is unchanged
byte-for-byte (29/1089, 40/1154, 7/7887, 7/10571), confirming this is a
requirement/relationship-decode change with no effect on dispatch coverage.
`tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`,
`asm-purity` all pass.

Unknowns, exceptions and follow-up task IDs: `Req_mode`/`Req_xlen` are
recorded structurally but not evaluated - three-valued *evaluation* against
an actual configured profile (deciding a requirement is known-true before
generating a positive case) is GEN-01/GAS-02 work, per plan §4.2's "unknown
predicates never pass, known-true is what unlocks generation." Only
riscv-opcodes' `imports`/`specializes` relationships are decoded; nothing
in the pilot or accounting scope threads a relationship outcome into a
normalized `form`'s `concreteness` (`Alias_of`/`Expansion_of`) yet - doing
that for a real pseudo-op/import form is left as a concrete, named follow-up
for whichever GEN task first needs alias/pseudo coverage (GEN-06), not
guessed at here without a driving consumer.

Acceptance gate satisfied: three-valued requirements (`Req_all`/`Req_any`/
`Req_mode`/`Req_xlen`/`Req_unknown`) are implemented and machine-checked
against real captured data on both sources; relationship-resolution's
exact/ambiguous/missing outcomes decode faithfully with one-to-many
candidate lists preserved in full, verified against one real example of
each outcome.

#### NORM-04 normalized-JSONL codec milestone

Task / status / owner: NORM-04 / done / Codex.

Scope manifest and obligations: `asm/tools/lib/isa_norm_jsonl.{ml,mli}`
gives `Isa_norm_model.form` a bidirectional JSON codec (`to_json`/`of_json`,
plus line-oriented `encode_line`/`decode_line` returning `Tool_error.t`),
the first place this project's OCaml side writes JSON rather than only
reading it. Every constructor of every `Isa_norm_model` sum type - including
the two recursive ones, `requirement` and `syntax_token` - gets an explicit
string tag; an unrecognized tag or a member of the wrong JSON kind is a
decode error, never a silently-accepted default, per plan §3.3. Each
encoded object carries a `schema_version` member (currently `1`); `of_json`
rejects any other value by name rather than attempting a best-effort decode.
Encoding is deterministic because member order is fixed by this module's
source code, not by input data or a runtime sort - the same form value
always serializes to the same bytes.

Design choice worth recording: this codec is hand-written over `Jsont.json`
(the same generic-JSON escape hatch `Isa_source_record` already uses for
`origin`/`encoding`/`provenance`/`applicability`), not built with jsont's
`Object`/`Case` combinator API. `requirement` and `syntax_token` are
self-recursive variant types; expressing that recursion through
`Object.case_mem`'s tag-comparator/enc_case machinery would have been both
more code and less direct than a `let rec ... to_json`/`let rec ... of_json`
pair over the tree, which is also the style already established in this
codebase for reading source-native JSON.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396`; XED
`0bcb6237345c5066726dcc08b3d87928df3b5b26` (unchanged; reads the existing
checked-in exports only through the already-normalized forms, writes no
files of its own).

Tool versions and exact commands: `cd asm/tools && opam exec -- dune build
@runtest`; `make tools-test`; `make tools-integration`; `make tools-boundary`;
`make asm-fmt-check`; `make asm-purity`.

Results and artifact links: `test_isa_norm_jsonl.ml` (new) round-trips two
synthetic forms - one plain, one exercising every constructor of every sum
type at least once, including nested recursion in `requirement` and
`syntax_token` - through both `to_json`/`of_json` and `encode_line`/
`decode_line`, plus a determinism check (encoding the same form twice
yields identical bytes) and a schema-version-mismatch rejection (mutating
the encoded `"schema_version":1` to `2` makes `decode_line` fail): 8 checks,
all passing. `repo_tests.ml` (`tools-integration`) additionally round-trips
every one of the 83 forms NORM-02/NORM-03 actually normalize from the four
real checked-in exports (29 + 40 + 7 + 7, the same pinned total those
milestones report) through `encode_line`/`decode_line`, asserting structural
equality with the original form and pinning the total count - not just
synthetic shapes. `tools-test`, `tools-integration`, `tools-boundary`,
`asm-fmt-check`, `asm-purity` all pass.

Unknowns, exceptions and follow-up task IDs: this codec is exercised as a
library function (property-style round-trip tests), not yet wired to a
checked-in fixture file or a `-check`/`-regen` CLI pair the way
`isa-inventory norm-accounting` prints a live report - NORM-04's own text
asks for "export and round-trip," and the round-trip half is what a
regression on the codec itself needs; publishing a committed normalized
corpus as a reviewable artifact, if wanted, is later NORM/GEN work once a
consumer actually needs to read normalized forms back from disk rather than
compute them in-process. "Source/rule references" are carried exactly as
the model already defines them (`form.source_record_ids`, `diagnostic.rule`
on the not-yet-normalized side accounted for by NORM-02) - this task did not
add new reference fields, only made the existing ones round-trip.

Acceptance gate satisfied: normalized forms serialize to and deserialize
from JSONL losslessly and deterministically, tagged with a schema version
that a future incompatible model change can break intentionally instead of
silently, machine-checked against both a constructor-complete synthetic
sweep and every real form the project currently normalizes.

#### NORM-05 offline boundaries and snapshot-update mapping milestone

Task / status / owner: NORM-05 / done / Codex. This closes S2.

Scope manifest and obligations: two halves, per the task's own text.

Offline library/tool boundaries: everything NORM has added
(`Isa_source_record`, `Isa_norm_riscv`, `Isa_norm_xed`, `Isa_norm_accounting`,
`Isa_norm_jsonl`, and this task's `Isa_source_snapshot_diff`) lives in
`asm/tools/lib`, part of the `compcert_tools` library, never in `asm/lib`,
`asm/targets`, or `asm/driver` (the assembler's own production closure).
`make tools-boundary` proves the targeted tools build
(`tools/bin/compcert_tools.exe`) compiles no assembler library, and
`make asm-purity` proves the assembler's own production closure (29
libraries, none of them `compcert_tools`, `jsont`, or `digestif`) pulls in
none of this - so "no runtime assembler dependency on source databases or
host tools" (S2's own exit criterion) is machine-checked on both sides of
the boundary, not just true by directory convention. Both gates already ran
clean before this task (dune's library graph makes the alternative a build
error, not merely a lint finding); this milestone is what states the claim
explicitly for the NORM package and rechecks it after adding
`Isa_source_snapshot_diff`.

Snapshot-update mapping report: `asm/tools/lib/isa_source_snapshot_diff.{ml,mli}`
answers plan §3.5's "[record_ids are] snapshot-local references... keep them
as evidence keys, add fingerprints and reviewed migration mappings, and
detect ambiguity." `diff` compares two `(record_id, raw_line)` sets and
classifies every id as `Added`/`Removed`/`Unchanged`/`Changed` (same id,
different raw content - the id-reuse ambiguity plan §3.5 names explicitly),
attaching a short SHA-256 fingerprint of each side's raw line to every
entry. `load` reads one checked-in export file into that shape, rejecting a
line that does not decode or a `record_id` that repeats within the file;
`diff_files` composes both steps; `report_lines` renders a summary plus one
line per non-`Unchanged` entry.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396`; XED
`0bcb6237345c5066726dcc08b3d87928df3b5b26` (unchanged; only one snapshot of
each source is pinned, so every real check below is necessarily a
self-diff - see Unknowns).

Tool versions and exact commands: `cd asm/tools && opam exec -- dune build
@runtest`; `make tools-test`; `make tools-integration`; `make tools-boundary`;
`make asm-fmt-check`; `make asm-purity`.

Results and artifact links: `test_isa_source_snapshot_diff.ml` (16 checks)
exercises `diff` against synthetic pairs covering all four statuses at once
(one id each of added/removed/unchanged/changed, with fingerprint presence
and equality/inequality asserted per case) and `load`/`diff_files` against
real temporary files, including the duplicate-`record_id` and
undecodable-line rejections, which only arise from real file content, not
from pre-built pairs. `repo_tests.ml` (`tools-integration`) additionally
runs `diff_files` on each of the four real checked-in exports against
itself: zero added/removed/changed and every id (1089/1154/7887/10571,
matching every earlier pinned total) unchanged, proving the real
`load`/decode/fingerprint path against every real `record_id` in the
project's captured data, not only against hand-built pairs. `tools-test`,
`tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity` all
pass.

Unknowns, exceptions and follow-up task IDs: this project still ingests
exactly one pinned commit per source (plan §1's "one source per architecture
family... not two independent descriptions"), so no *real* upstream bump has
happened yet to run this mapping report against for real; the self-diff
demonstrated here is the complete real exercise available today, and the
synthetic suite is what stands in for a real Added/Removed/Changed case
until one exists. Threading a detected mapping into `Isa_norm_model.form`'s
`source_record_ids` (e.g. auto-updating a normalized form's reference after
a confirmed 1:1 rename) is explicitly not attempted - plan §3.5 asks only
for "reviewed migration mappings," and a reviewed mapping needs a human
decision this module does not make on its own. No CLI subcommand was added
(unlike `isa-inventory norm-accounting`/`norm-export`-shaped commands):
`load`/`diff`/`diff_files`/`report_lines` are validated as library functions
against both synthetic and real data, which is what this task's "reports"
wording needs; wiring a positional-path CLI command is left for whoever
first runs this against two actually-different snapshots, since this
codebase has no established pattern yet for validating free-form path
arguments inside a Cmdliner term (see `bin/compcert_tools.ml`'s own comment
on validating "inside the term, never by a converter").

Acceptance gate satisfied: offline library/tool boundaries are proven by
existing purity/boundary gates re-run after this task's addition, and a
snapshot-update mapping mechanism exists, is machine-checked against
synthetic controls covering every classification, and is proven correct
against every real record_id this project currently captures. Both S2 exit
criteria this task owns - "no runtime assembler dependency on source
databases or host tools" and the general NORM-05 mapping-report ask - are
met, closing S2.

### GAS — Common oracle runner and reproducible artifacts

Scope: generation orchestration, GNU invocation, byte/image comparison,
failure reduction, artifact storage and CI tiers. Owner: unassigned.
Stages: S3, relocation path in S4, reproducibility in S7.

Investigate reuse of `Gnu_tools`, `gas_xref_cmd`, `oracle_cmd` and offline
differential tests; establish case boundaries and actual installed GNU
capabilities. Choose exact object comparison only for relocation-free cases.

- [x] GAS-01 Freeze case/artifact/verdict schema and proposed CLI/Make
  targets, including which existing CI leg each of plan section 5.4's three
  tiers lands on under the repository's `-check`/`-regen` convention. A
  tier-one check must stay toolchain-free and must not transitively require
  building the whole assembler. Record the RV32 2.43.1 / RV64 2.44 GAS skew
  as a tool-version dimension of the coverage matrix, distinct from any
  architectural difference between the two profiles.
- [x] GAS-02 Implement explicit profile/tool configuration and capability
  probes, GNU artifacts, exact bytes and observed-form checks.
- [x] GAS-03 Replay committed cases offline without producer/toolchain
  dependencies; reject unexplained missing cases or tools in required tiers.
- [x] GAS-04 Demonstrate wrong-byte, wrong-form and unexpected-relocation
  controls, plus actionable minimal failure reproduction.
- [x] GAS-05 Close the symbolic/multi-unit linked-image path with controlled
  section, symbol and fixup evidence at matching relaxation policy. The
  existing fixture differential is the shared implementation; do not create a
  second linker just to duplicate that evidence beside the relocation-free
  generated corpus.

Exit: the four-profile pilots pass and each planted failure is caught;
later linked suites cannot pass by masking relocation bytes.

#### GAS-01 case/artifact/verdict schema and frozen tier-name milestone

Task / status / owner: GAS-01 / done / Codex.

Scope manifest and obligations: `asm/tools/lib/isa_generated_case.{ml,mli}`
freezes plan §4.1's third data layer ("test cases and observations") as
three OCaml types - `case` (plan §5.4's per-case retention list: `case_id`,
`target`, `form_id`, `source_record_ids`, `rule_ids`, concrete `operands`,
`rendered_source`, resolved `configuration`, and `negative`), `artifact`
(one tool's run: `tool_label`, `argv`, `exit_status`, captured
stdout/stderr, optional `bytes`, `relocations`), and `verdict` (plan §5.5's
eight-row outcome table, one constructor per row, in the table's own
order) - plus `observation` combining a `case` with its `gas`/`ours`
artifacts (each optional, since a blocked or oracle-unavailable case never
invokes one or either tool) and its `verdict`. This is a schema freeze, not
an implementation: nothing here generates a case, invokes GAS, or invokes
our own assembler - that is GAS-02 onward, which will produce values of
these types. A `case` references its owning normalized form only by
`form_id`/`source_record_ids` strings, never by importing
`Isa_norm_model`, keeping the three data layers independently
inspectable per plan §4.1.

This task also freezes plan §5.4's "concrete target names and each tier's
CI leg... together with the case schema, not afterwards": `fixture_dir_name`
(`"isa-generated"`, this generator's own corpus under `asm/fixtures/`,
never gas-xref's regenerated tree), `cli_group_name` (`"isa-generated"`,
mirroring the existing `gas-xref`/`fixture` CLI groups), `make_target`
(`asm-isa-generated-check`/`asm-isa-generated-regen`, following the
repository's existing `asm-<thing>-check`/`-regen` convention exactly,
e.g. `asm-gas-xref-check`/`-regen`), and `joins_prerequisite_of` (the tier-1
check joins `asm-test`'s existing prerequisite list alongside
`asm-fixtures-check`/`asm-gas-xref-check` - confirmed against the real
Makefile line, `asm-test: asm-build asm-fixtures-check asm-gas-xref-check`
- so it is reachable from `asm-ci` transitively without a new top-level
edge; tier 2 stays off that critical path like `asm-fixture-oracle-*`; tier
3 remains the existing Python producer lane, plan §3.5, untouched). No
Makefile or CLI wiring was added yet - there is no generator output to
check or regenerate - so this task only commits to the names GAS-02 must
use, exactly as plan §5.4 asks.

Design choice worth recording: `artifact.tool_label` is documented as
required to be resolved via `Gnu_tools.version_line` at generation time
(GAS-02's job), never assumed from this plan document's own measured
snapshot (RV32 GAS 2.43.1 / RV64 GAS 2.44, section 5.4) - a base-image
toolchain upgrade must not silently invalidate a hardcoded expectation.
Keying the coverage matrix on `(target, tool_label)` rather than `target`
alone is what lets a real skew (RV32 accepting a form RV64 does not, or
vice versa) be attributed to tool version instead of an architectural
difference between the profiles, per the task's own text.

Implementation commit: (this change).

Source snapshots and input hashes: unaffected; this task touches no
captured export.

Tool versions and exact commands: `cd asm/tools && opam exec -- dune build
@runtest`; `make tools-test`; `make tools-integration`; `make tools-boundary`;
`make asm-fmt-check`; `make asm-purity`.

Results and artifact links: `test_isa_generated_case.ml` (18 checks) pins
every frozen string exactly (`fixture_dir_name`, `cli_group_name`, both
`make_target` results, both `joins_prerequisite_of` results - a rename of
any one is now a deliberate, visible test diff rather than a silent drift),
confirms all eight `verdict` rows render distinct, non-empty descriptions,
and builds one representative `observation` per verdict row, checking the
`gas`/`ours` `Some`/`None` shape the `.mli` documents actually holds
(`Blocked_unknown_requirement` and `Oracle_unavailable` carry no `gas`
artifact; `Frontier_gap`/`Regression` carry no `ours` bytes). `tools-test`,
`tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity` all
pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: GAS-02 implements the actual
profile/tool configuration, capability probes, and GNU invocation that
produce real `case`/`artifact`/`observation` values; GAS-03 through GAS-05
add offline replay, planted-failure controls, and linked-image comparison
on top of this schema. GEN-01 (blocked, per its own tracker entry, on
stating a per-family form-enumeration method) supplies the actual pilot
form/case manifest this schema's `case_id`/`form_id`/`rule_ids` will be
populated from - GAS-01 commits to the shape those values will have, not
to their content.

Acceptance gate satisfied: the case/artifact/verdict schema and every
tier's CLI/Make/fixture name are committed and machine-checked before any
implementation reads or writes them, matching plan §5.4's explicit
"not afterwards" requirement; the RV32/RV64 GAS version skew is threaded
into the artifact schema as a first-class matrix dimension rather than an
assumed constant.

#### GAS-02 real GNU invocation and observed-form-check milestone

Task / status / owner: GAS-02 / done / Codex. Built on GEN-01's pilot
manifest, which supplied the `form_id`/`lookup_key` values this task turns
into real cases.

Scope manifest and obligations: for every one of GEN-01's 21 pilot entries,
build one canonical, legal case (`Isa_gen_case_build`), invoke the real
cross GNU assembler for its target with an explicit, per-suite
`-march`/`-mabi`/`-mno-relax` (or empty, for x86) configuration
(`Gnu_tools.try_assemble_with_args`, added to `Gnu_tools` rather than
reusing `try_assemble`'s frozen CompCert `Target.config` flags, per plan
§5.4), extract the exact assembled `.text` bytes, and check them against
the case's own normalized `Isa_norm_model.encoding` (`Isa_gen_oracle`).
Wired as `compcert_tools.exe isa-generated regen` /
`make asm-isa-generated-regen`, the exact names GAS-01 froze for the
`Gnu_regeneration` tier - deliberately not a prerequisite of `asm-test`/
`asm-ci`, matching `Isa_generated_case.joins_prerequisite_of`.

`Isa_gen_render` renders a form's own `syntax` recipe with concrete operand
text (a substitution walk over the same public `syntax_token` tree
`Isa_norm_model.render_syntax` renders abstractly, kept in GAS rather than
added to NORM's frozen model). `Isa_gen_case_build.operands_for` hardcodes
one canonical register/immediate assignment per pilot `form_id`, using
non-`x0`, non-accumulator registers throughout and a > 8-bit-signed
immediate (`1000000`) for the two immediate forms - both choices are
empirically load-bearing, not stylistic (see Results). `Isa_gen_oracle`'s
`observed_form_check` compares assembled bytes against the form's
`Riscv_encoding` mask/value (little-endian, length-checked) or
`X86_encoding`'s leading opcode byte.

Real, measured findings from running this against actual GNU binutils (RV32
`riscv32-linux-gnu-as` 2.43.1 via `/usr/local/riscv32-linux-gnu-toolchain/bin`,
RV64/x86 cross `as` 2.44): all 9 RISC-V pilot cases and 3 of the 6 x86 forms
(`ADD_GPRv_GPRv_01`, `ADD_GPRv_IMMz`, `MOV_GPRv_GPRv_89`) assemble to bytes
matching their own normalized encoding exactly, on both profiles of each
architecture. The other 3 x86 forms - `ADD_GPRv_GPRv_03`, `MOV_GPRv_GPRv_8B`,
`MOV_GPRv_IMMz` - report `DIFFERENT-FORM`: canonical AT&T register-only
syntax (`add %edx, %ecx`, `mov %edx, %ecx`, `mov $1000000, %ecx`) never
reaches these three iforms at all. Each is a genuine, verified-by-hand x86
encoding-redundancy fact, not a bug in this task's code:

- `ADD_GPRv_GPRv_03`/`MOV_GPRv_GPRv_8B` are XED's `MOD=3` (register-direct)
  reg-from-r/m encoding of a semantic operation two plain registers can
  ALSO express via the shorter/canonical `_01`/`_89` (rm-from-reg)
  direction, and GAS always emits the latter for two plain registers -
  `add %ecx, %edx` and `add %edx, %ecx` both assemble to opcode `0x01`
  (never `0x03`), confirmed both directions. The `_03`/`_8B` opcode byte
  IS reachable, but only via a MEMORY operand (`add (%rdx), %ecx` ->
  `03 0a`; `mov (%rdx), %ecx` -> `8b 0a`), which is a different, unnormalized
  XED iform sharing the same opcode byte at `MOD != 3` - x86 addressing is
  explicitly GEN-04's scope, not this pilot's.
- `MOV_GPRv_IMMz` (opcode `0xC7`, `MOD=3`) is register-destination MOV
  immediate; GAS always prefers the strictly shorter `0xB8+reg` register-coded
  form for a register destination (confirmed: `mov $1000000, %ecx` ->
  `b9 40 42 0f 00`, opcode `0xB9` = `0xB8+ecx`). `0xC7` IS reachable with a
  MEMORY destination (`movl $1000000, (%rdx)` -> `c7 02 40 42 0f 00`,
  confirmed), again a different iform. Separately, `--dump-codec` shows our
  OWN assembler has no `0xC7`-shaped alternative at all (only `mov-rm-imm8`,
  the 8-bit `0xC6` form) - so this form is independently a frontier gap on
  the "ours" side too, discoverable but out of GAS-02's scope (GAS-02 checks
  the GAS side only; comparing against "ours" is GAS-04's).

This is exactly plan §5.1's "GAS may select ... another vector prefix for
the generated spelling. Retain intended and observed form identities and
distinguish canonical-spelling tests from forced-encoding tests" - discovered
empirically rather than assumed, which is what an "observed-form check" is
for. It also caught a real bug in this task's own first draft:
`Isa_gen_case_build.operands_for` initially assumed `MOV_GPRv_IMMz` used
`add_gprv_immz_form`'s `dest`/`imm` operand names; running the regen command
reported `SKIP (no operand assignment for "src")`, revealing that
`MOV_GPRv_IMMz` is actually normalized by the generic `two_operand_gprv_form`
(operand names `src`/`dest`, matching the register-register forms) - fixed
before this milestone's evidence was captured.

Implementation commit: (this change).

Source snapshots and input hashes: unaffected; reads existing checked-in
exports only, via `Isa_gen_pilot.normalize_entry`.

Tool versions and exact commands: `cd asm/tools && opam exec -- dune build
@runtest`; `make tools-test`; `make tools-integration`; `make tools-boundary`;
`make asm-fmt-check`; `make asm-purity`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-generated-regen` (the PATH prefix is required outside an
interactive devcontainer shell - `.bashrc` sets it only for those; plan
§5.4 already documents this as a real environment dependency, not new to
this task).

Results and artifact links: `test_isa_gen_render.ml` (6 checks: every
`syntax_token` constructor, a real `sw` recipe, and the missing-operand
error path), `test_isa_gen_case_build.ml` (44 checks: every pilot entry has
an assignment, none uses `x0`/an accumulator register, RISC-V configuration
is never empty), and `test_isa_gen_oracle.ml` (6 checks: `observed_form_check`
against both encoding kinds, including the exact `sub`-vs-`add` and
`0x03`-vs-`0x01` mismatch shapes this task measured for real) - all
toolchain-free, run by `tools-test`. `make asm-isa-generated-regen` (needs
the real cross binutils, reported above) produces the byte-for-byte results
quoted in Scope manifest, reproduced identically across two separate runs
(before and after `asm-fmt`'s reformatting). `tools-test`, `tools-integration`,
`tools-boundary`, `asm-fmt-check`, `asm-purity` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: no persisted, checked-in
corpus exists yet for the toolchain-free `asm-isa-generated-check` GAS-01
already named - `regen` only prints a live report (matching
`isa-inventory norm-accounting`'s precedent). Settling a persisted format
and wiring `check` against it is GAS-03's "replay committed cases offline"
work. Comparing GAS's bytes against OUR OWN assembler's output (plan
§5.1's "two independent assertions") is explicitly deferred to GAS-04,
which is also where the three `DIFFERENT-FORM` findings' ultimate
disposition belongs (most plausibly: reclassify `ADD_GPRv_GPRv_03`/
`MOV_GPRv_GPRv_8B` as memory-operand cases under GEN-04, and record
`MOV_GPRv_IMMz` as a tracked frontier gap on the "ours" side, since our own
encoder has no `0xC7` alternative regardless of operand kind). Only the
pilot's single canonical case per form is covered; full obligation coverage
(every register class, every immediate boundary, the x86
short-versus-full choice) is GEN-03/GAS-04's bounded-slice work.

Acceptance gate satisfied: explicit per-suite tool configuration,
capability probing, real GNU artifacts, exact assembled bytes, and an
observed-form check are implemented and proven against the real cross
binutils for every pilot entry, with every divergence from the naive
expectation explained by verified, reproducible evidence rather than
asserted or silently accepted.

#### GAS-03 offline replay and persisted-corpus milestone

Task / status / owner: GAS-03 / done / Codex.

Scope manifest and obligations: GAS-02 measured real GNU output but
persisted nothing - GAS-01's own unknowns section named this exactly:
"no persisted, checked-in corpus exists yet for the toolchain-free
`asm-isa-generated-check` GAS-01 already named." GAS-03 closes that: a new
`asm/tools/lib/isa_generated_corpus.{ml,mli}` defines `gas_finding` (a
direct, honestly-scoped translation of `Isa_gen_oracle.outcome` - NOT
GAS-01's frozen `verdict`, since every credit-bearing row of that eight-row
table compares GAS's bytes against OUR OWN assembler's, which GAS-04 has not
wired in yet; using `verdict` early would have meant asserting a comparison
this task cannot make) and `record` (`case` + `gas` artifact + `finding`),
with a hand-written JSONL codec in the same style as NORM-04's
`Isa_norm_jsonl` (`schema_version`, deterministic member order,
`encode_line`/`decode_line`). `write`/`load` persist/read
`asm/fixtures/isa-generated/cases.jsonl`, sorted by `case_id` and rejecting
a duplicate id (mirroring `Isa_source_snapshot_diff.load`).

Populating a real `Isa_generated_case.artifact` (GAS-01's frozen shape)
faithfully needed two upstream changes, not approximated values:
`Gnu_tools.try_assemble_with_args` previously returned only the classified
`gas_outcome`, discarding the real `Process_status.t` and merged
stdout/stderr capture; it now returns the raw `Tool_process.result`
alongside `gas_outcome` (its one call site, `Isa_gen_oracle.run`, is the
only caller, so this is a contained change). Fabricating an `exit_status`
for the `Rejected` case (none of the 21 pilot cases currently reject) would
have been exactly the kind of unmeasured value plan §3.5's capture
discipline rejects. `Isa_gen_oracle.run`'s return type gained a second
component, `Isa_generated_case.artifact`, built with a new
`normalized_argv` helper: the real scratch-directory `case.s`/`case.o`
paths are machine-local and nondeterministic, so the persisted `argv` uses
the fixed basenames `run` always writes internally instead (plan §5.4:
"removing temporary paths and timestamps from committed identities").
`Isa_generated_cmd.regen` now builds one `Isa_generated_corpus.record` per
successfully-built pilot entry (a SKIPped or errored entry simply
contributes none, exactly as before) and writes the sorted corpus after
every case's report line has streamed, matching `gas_xref_cmd`'s own
"stream first, persist after" shape.

`Isa_generated_corpus.replay` is the actual "replay committed cases
offline" logic: given one committed `record` and the case's normalized
`encoding`, it recomputes `Isa_gen_oracle.normalized_argv` from
`record.case` and checks it against `record.gas.argv`; if `record.gas.bytes`
is `Some hex`, it decodes the hex (via the existing `Hex_dump.parse`,
reused rather than a second hex codec) and calls the SAME pure
`Isa_gen_oracle.observed_form_check` GAS-02 already uses, then checks the
result against `record.finding` - an exact string match for
`Different_observed_form`'s `detail`, not just "some mismatch". A `bytes =
None` record must carry `Gas_rejected`. None of this invokes `Gnu_tools` or
any external process. `Check_cmd.isa_generated_check` (wired as
`compcert_tools.exe isa-generated check` / `make asm-isa-generated-check`,
the exact names GAS-01 froze) then, for every `Isa_gen_pilot.all` entry:
rebuilds the case offline via `Isa_gen_pilot.normalize_entry`/
`Isa_gen_case_build.build` (a build failure is a hard FATAL, not a silent
skip - GAS-03's own "reject unexplained missing cases" wording, since a
manifest entry with no way to build a case is exactly a manifest entry with
no case); looks up a committed record by `case_id`, FATAL if absent;
requires the rebuilt `case` to structurally equal the committed one
(catching drift between the code and the checked-in corpus); requires a
non-empty `tool_label` ("reject ... tools in required tiers" - a record
whose tool identity was never resolved is not trustworthy evidence); and
calls `replay`. A final pass rejects any committed record whose `case_id`
no pilot entry produces (a stale corpus after the manifest shrinks).
`asm-isa-generated-check` now joins `asm-test`'s prerequisites (matching
`Isa_generated_case.joins_prerequisite_of Offline_consumer`, reachable from
`asm-ci` transitively, same as `asm-fixtures-check`/`asm-gas-xref-check`).

Implementation commit: (this change).

Source snapshots and input hashes: unaffected; this task touches no
captured export. The committed corpus was produced by a real
`asm-isa-generated-regen` run against RV32 GAS 2.43.1 (crosstool-NG 1.27.0)
and RV64/x86 cross `as` 2.44, reproducing GAS-02's own measured findings
exactly (18 exact matches, 3 `DIFFERENT-FORM`, 0 rejections).

Tool versions and exact commands: `cd asm/tools && opam exec -- dune build
@runtest`; `make tools-test`; `make tools-integration`; `make tools-boundary`;
`make asm-fmt-check`; `make asm-purity`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-generated-regen` (produces and commits
`asm/fixtures/isa-generated/cases.jsonl`); `env
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" make
asm-isa-generated-check` and `make asm-test` (both run with NO cross
toolchain on `PATH` at all, proving the tier-1 check is genuinely
toolchain-free); `make tools-gasxref-diff`; `make tools-isa-inventory-diff`;
`make asm-js-portable`.

Results and artifact links: a new `test_isa_generated_corpus.ml` (28 checks)
covers the JSONL codec (round-trip, determinism, `schema_version` rejection),
`write`/`load` (round-trip, sort-by-`case_id`, duplicate-id rejection), and
`replay` against one matching, one mismatched, and one rejected synthetic
record plus five deliberately corrupted variants (stale/wrong-detail
finding, `bytes = None` without `Gas_rejected`, drifted argv, undecodable
hex) - each caught. `make asm-isa-generated-check` with no toolchain on
`PATH` passes cleanly against the real 21-entry corpus. Four manual
negative controls against the real committed file, each restored
afterward and reverified clean: a tampered byte in a `Matches_normalized_
encoding` record is caught with the exact recomputed mismatch printed
(`FATAL: ... observed_form_check now reports a mismatch ...`); deleting one
committed record is caught (`no committed case ... - run --regen`); adding
a bogus extra record is caught (`... is not produced by any pilot manifest
entry - stale corpus`); removing the corpus file entirely is caught (`no
corpus at ... - run --regen first`). `asm-test` (now depending on
`asm-isa-generated-check`) passes with the real committed corpus and no
cross toolchain on `PATH`. `tools-test`, `tools-integration`,
`tools-boundary`, `asm-fmt-check`, `asm-purity`, `tools-gasxref-diff`,
`tools-isa-inventory-diff`, and `asm-js-portable` all pass unchanged
otherwise.

Unknowns, exceptions and follow-up task IDs: `gas_finding` is deliberately
NOT `Isa_generated_case.verdict` - assigning a real verdict row needs
GAS-04's "ours" comparison, which this task does not add. `replay` checks
internal consistency (rebuilt case matches committed case; recomputed
observed-form outcome matches committed finding) and cross-manifest
completeness, but cannot check that the committed `bytes`/`stdout`/
`exit_status` are themselves what a real GNU invocation would produce today
- only `asm-isa-generated-regen` (Gnu_regeneration tier) measures that, by
design (offline replay must not need a toolchain). `relocations` stays `[]`
throughout, unpopulated by this oracle (GAS-05's linked-image comparison is
where that becomes real evidence). No case in the current pilot manifest
exercises the `Gas_rejected`/build-failure paths against real data (all 21
build and assemble successfully); those paths are proven only by
`test_isa_generated_corpus.ml`'s synthetic records and by the manual
negative controls above, not by a real captured rejection.

Acceptance gate satisfied: GAS-03's own text - "replay committed cases
offline without producer/toolchain dependencies; reject unexplained missing
cases or tools in required tiers" - is met exactly: a checked-in corpus
exists, `isa-generated check` replays it with zero toolchain dependency
(proven by stripping cross-toolchain paths from `PATH` entirely, not merely
by not calling `Gnu_tools`), a missing pilot case and a stale extra case are
both rejected, and a record with no resolved tool identity is rejected too.
`asm-isa-generated-check` now gates `asm-test`/`asm-ci`, closing the gap
GAS-01/GAS-02 both left open by name.

#### GAS-04 "ours" comparison, relocation guard, and control milestone

Task / status / owner: GAS-04 / done / Codex. Wires in plan §5.1's second
independent assertion, which GAS-01/GAS-02/GAS-03 each explicitly deferred by
name ("comparing against 'ours' is GAS-04's").

Scope manifest and obligations: `asm/tools/lib/isa_gen_ours.{ml,mli}` runs
one `Isa_generated_case.case`'s `rendered_source` - the EXACT text handed to
GAS, never a re-rendered or suffix-adjusted spelling - through this project's
own assembler and reports `Assembled of {bytes_hex}` or `Rejected of
string`. It never links the assembler in-process (that would break
`tools-boundary`/`tools/asm-check-purity.sh`'s "the targeted tools build must
never transitively require building the whole assembler"): it shells out to a
newly separately-built `tool/asm.exe` via `dune exec`, exactly the boundary
`gas_xref_cmd.ml`'s existing `emit_generated` already relies on for the same
reason. `asm/tool/asm.ml` gained a `--dump-bytes` flag (prints assembled
section bytes in the project's own committed hex-dump format, reproducing
`Hex_dump.of_bytes`'s algorithm locally since `tool/` cannot depend on
`compcert_tools` either) so `Isa_gen_ours.run` has something machine-readable
to capture. `tool_label` is `"ours-<git-rev>[-dirty]"` - "ours" has no fixed
release the way RV32 2.43.1/RV64 2.44 does, so the git revision (plus a
dirty-tree suffix scoped to `asm/`) is the label, resolved fresh every run,
never assumed.

`asm/tools/lib/isa_gen_verdict.{ml,mli}` classifies plan §5.5's frozen
`verdict` from GAS's and ours' RAW ASSEMBLED BYTES compared directly against
each other - not by re-deriving which form each tool picked, which is the
orthogonal question `Isa_gen_oracle.observed_form_check` already answers
against the normalized encoding. `known_syntax_gap` is an explicit, reviewed
allowlist of exactly the case_ids whose "ours" rejection is a documented,
explained syntax gap (see below), checked against BOTH the case_id and a
diagnostic substring so an unrelated future rejection on the same case is
never silently absorbed into the same excuse; anything else that makes
"ours" reject a case GEN-01 selected because it believed the form already
worked defaults to `Regression`, per plan §4.3's "do not assume a difference
is intentional because it is small." A genuine byte disagreement is always
`Byte_mismatch`, checked before `known_syntax_gap` is even consulted, per
plan §5.5's "hard failure, including for a frontier case."

Real, measured findings from running this against all 21 real pilot cases:
the 9 RISC-V cases and the 4 register/register x86 `add` cases (both
directions, both profiles) all PASS - byte-for-byte identical between GAS and
"ours", even for `ADD_GPRv_GPRv_03`, whose own normalized encoding names a
different opcode (`0x03`) than either tool actually emits for two plain
registers (`0x01`) - confirming the disposition the GAS-02 milestone
predicted ("most plausibly: reclassify as memory-operand cases under
GEN-04"), now confirmed by direct measurement rather than inference. The
other 8 x86 cases (`ADD_GPRv_IMMz`, `MOV_GPRv_GPRv_89`, `MOV_GPRv_GPRv_8B`,
`MOV_GPRv_IMMz`, each on both profiles) all report `FRONTIER-GAP`: this
project's x86 frontend (`x86_family_encode.ml`'s `simplify_instruction`)
requires an explicit AT&T operand-size suffix on `mov` and on any immediate
form, with exactly one narrow, pre-existing carve-out for suffixless
register-register `add` (added for a real CompCert runtime fixture, per its
own comment); GAS itself infers the width from the register operand and
needs no suffix. Confirmed independently with the real cross assembler
(`x86_64-linux-gnu-as`) that the suffixed and unsuffixed spellings of these
exact lines assemble to IDENTICAL bytes (`89 d1`, `b9 40 42 0f 00`, `01 d1`)
- so this is purely a missing PARSE-time width-inference rule, not a missing
encoder alternative: this project's own encoder already implements every one
of these opcodes, just not through the unsuffixed canonical spelling GAS
accepts. That is the concrete, actionable, minimal repro GAS-04's own text
asks for, and is why these 8 land as `Frontier_gap` rather than `Regression`.

The relocation guard: `Isa_gen_oracle.run` now calls `Gnu_tools.objdump_relocs`
on every successfully-assembled object and checks `.text` for a "RELOCATION
RECORDS FOR" banner (`has_text_relocations`/`text_relocation_lines`, both
pure and unit-tested against real captured `objdump -r` text - one with none,
`add a0, a1, a2`; one with a real `R_RISCV_CALL_PLT` from `call foo` to a
global symbol) BEFORE calling `observed_form_check`, per plan §5.4: "Inspect
relocation tables and fail if a supposedly relocation-free case contains one.
Never compare unresolved object placeholders with our bound image." A hit
produces `Isa_gen_oracle.Unexpected_relocation {bytes_hex; relocations}`,
`Isa_generated_corpus.gas_finding`'s new `Unexpected_relocation` case, and -
via `Isa_gen_verdict.Gas_unexpected_relocation` - an unconditional
`Byte_mismatch` verdict; "ours" is never invoked (nothing meaningful to
compare a placeholder against). None of the 21 real pilot cases trips this
(all are plain register/immediate forms with no symbol reference), so the
guard is proven only against the two real captured `objdump -r` texts above
and a synthetic corpus record, not against a real captured positive - see
Unknowns.

`Isa_generated_corpus`'s schema bumped to version 2: `record` gained `ours :
Isa_generated_case.artifact option` (`None` exactly when GAS itself rejected
or produced an unexpected relocation - nothing to run "ours" against then)
and `verdict : Isa_generated_case.verdict` (the real, populated eight-row
value, not the placeholder `gas_finding` GAS-03 used in its place).
`replay` now also recomputes, offline and without invoking any tool: that a
committed `ours.argv` matches `Isa_gen_ours.normalized_argv`; that
`ours = None` if and only if GAS itself did not accept the case cleanly
(covering both `Gas_rejected` and the new `Unexpected_relocation`); and that
re-classifying the committed `gas`/`ours` bytes reproduces the committed
`verdict` exactly. `Check_cmd.isa_generated_check`'s report line now also
prints the "ours" verdict description.

The Makefile's `asm-isa-generated-regen` gained an `asm-build` prerequisite
(alongside its existing `tools-build`): with the assembler already built,
`dune exec tool/asm.exe` at regen time only ever runs an already-built
binary, so its exit code is unambiguously the assembler's own (0 accepted, 1
rejected via `asm/tool/asm.ml`'s `report`/`exit 1`) rather than a `dune`
build failure that could otherwise be misread as a case rejection - verified
directly: `dune exec` was confirmed to propagate the child's exact exit code
unchanged (0/1/2) in every case tested.

Implementation commit: (this change).

Source snapshots and input hashes: unaffected; this task touches no captured
export. The committed corpus was regenerated against the same real
toolchains GAS-02/GAS-03 measured (RV32 GAS 2.43.1, crosstool-NG 1.27.0;
RV64/x86 cross `as` 2.44) plus this checkout's own `asm/` tree
(`tool_label` `"ours-d9cf89d4a83ad4ff8690b44b0f85434de46fdb0c-dirty"` at the
time of this run - dirty because this task's own uncommitted changes were
what was being measured).

Tool versions and exact commands: `cd asm/tools && opam exec -- dune build
@runtest`; `make tools-test`; `make tools-integration`; `make tools-boundary`;
`make asm-fmt-check`; `make asm-purity`; `make asm-js-portable`; `make
tools-isa-inventory-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-generated-regen` (regenerates and commits
`asm/fixtures/isa-generated/cases.jsonl`, run twice to confirm byte-identical
determinism); `env PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
make asm-isa-generated-check` and `... make asm-test` (both with every
cross-toolchain directory stripped from `PATH`, proving the tier-1 gate
stays genuinely toolchain-free).

Results and artifact links: 2 new `isa-gen-ours` checks (`normalized_argv`'s
pure shape), 19 new `isa-gen-verdict` checks (every classification branch,
including the real 8 measured case_id/diagnostic pairs and two deliberately
mismatched controls), 4 new `isa-gen-oracle` checks
(`has_text_relocations`/`text_relocation_lines` against real captured
`objdump -r` text), and 6 new `isa-generated-corpus` checks (a real
`Frontier_gap` record, a real `Regression` record, a real
`Unexpected_relocation` record, and the argv/presence/verdict-drift controls
for each) - 41 total new checks, all passing, none needing a toolchain. A
real `make asm-isa-generated-regen` run against the full 21-case pilot
reproduced exactly: 13 `Pass` (9 RISC-V + 4 x86 register/register `add`), 8
`Frontier_gap` (the missing-size-suffix cases above), 0 `Regression`, 0
`Byte_mismatch`, 0 `Unexpected_relocation` - byte-identical across two
separate regen runs. `make asm-isa-generated-check`/`make asm-test` both
pass with every cross-toolchain directory stripped from `PATH`. Three manual
negative controls against the real committed corpus, each restored and
reverified clean afterward: a tampered "ours" byte on a real `Pass` case is
caught (`FATAL: ... recomputed verdict ... byte_mismatch ... does not match
committed ... pass ...`); a mislabeled verdict on a real `Frontier_gap` case
(claimed `Pass`) is caught with the same shape of diagnostic; a drifted
`gas.argv` is caught (`FATAL: ... committed gas.argv [-completely-different]
does not match the recomputed [...]`). `tools-test`, `tools-integration`,
`tools-boundary`, `asm-fmt-check`, `asm-purity`, `asm-js-portable`,
`tools-gasxref-diff`, `tools-isa-inventory-diff` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: the relocation guard is real,
load-bearing code, but no case in the current pilot manifest exercises it
against a real captured GNU artifact - only the two hand-verified
`objdump -r` text captures and a synthetic corpus record prove it; a real
positive awaits a future pilot entry with an actual symbol reference (GEN-03
onward). The 8 `Frontier_gap` cases are a genuine, newly-measured x86 syntax
limitation (missing operand-size-suffix inference for `mov` and every
immediate form beyond the one pre-existing `add` carve-out) - fixing the
parser is explicitly GEN-04's "x86 addressing and x87 recipes, width/order
rules" scope, not this task's; this task's job was to measure, classify, and
prove the classification is caught when wrong, not to close the gap.
`Isa_gen_verdict.classify` still only produces rows 1-5 of the frozen
eight-row table (`Gas_unexpected_relocation` folds into row 2's
`Byte_mismatch` for lack of a dedicated row) - rows 6-8
(`Oracle_unavailable`/`Blocked_unknown_requirement`/`Negative_case_accepted`)
still have no driving example in this all-positive, all-currently-supported
pilot, left for GEN-06/GAS-05 as before. Full per-relocation section/symbol
evidence (as opposed to a bare presence check) remains GAS-05's "controlled
linked-image comparison ... with section/symbol/fixup evidence" scope.

Acceptance gate satisfied: GAS-04's own text - "demonstrate wrong-byte,
wrong-form and unexpected-relocation controls, plus actionable minimal
failure reproduction" - is met: a real "ours" comparison now populates every
credit-bearing verdict row against measured data on both sides; a genuine
byte disagreement, a genuine unexplained rejection, a genuine known-and-
explained syntax gap, and a genuine unexpected relocation are all
distinguished from each other by real measurement; three independent
mutation controls (wrong byte, wrong verdict/form, drifted argv) against the
real committed corpus are each caught with an actionable diagnostic naming
the case and the disagreement; and the 8 `Frontier_gap` findings come with a
concrete, hand-verified minimal repro (the exact missing-suffix diagnostic,
the exact byte-identical confirmation that only parsing - not encoding - is
missing) rather than an assumed or asserted explanation.

#### GAS-05 controlled linked-image comparison milestone

Task / status / owner: GAS-05 / done / Codex. This closes S3.

Scope manifest and obligations: the relocation-free `isa-generated` corpus
intentionally stops before an object contains a symbolic placeholder. Its
GAS-04 guard rejects such a case rather than comparing an unresolved object
against a bound image. The repository already has the required complementary
path in `asm/test/differential/test_differential.ml`, backed by the controlled
GNU oracle produced by `asm/tools/lib/oracle_cmd.ml`; this milestone validates
and records that shared path instead of duplicating it in a second generated
corpus linker.

For each `cross_call` multi-unit case, GNU assembles each source unit,
captures that unit's `readelf`, `objdump`, relocation and symbol evidence,
then links all objects using `Link_script.oracle` at the target's declared
section addresses. The committed linked manifest records every relevant
allocated section's kind, address, size and byte artifact. The differential
gate calls the real `D.assemble_many` entry point on the corresponding named
units, binds the resulting image to exactly those manifest addresses, and
compares every linked section byte-for-byte (or `.bss` logical extent for
NOBITS). This is a resolved-image comparison; no object placeholder byte gets
credit.

Per-unit GNU relocation records are translated into the assembler's merged
coordinates using the layout-recorded contribution base. `check_relocs`
classifies every `Image.fixup_observation` as linker-visible or
assembler-resolved, checks its role/binding/section relation, and compares the
predicted relocation multiset (section, offset, type, symbol and addend) with
the measured GNU records. The symbolic cross-call evidence therefore covers
both the ordinary x86 PC-relative call record and RISC-V's split call pair;
the latter has one linker-visible `R_RISCV_CALL_PLT` HI record and one
assembler-resolved LO fixup. `cross_data` and `cross_bss` exercise the same
machinery across section boundaries as additional controls.

Relaxation policy is matched rather than implied: `Target.config` passes
`-mno-relax` to RISC-V GAS and `--no-relax` to its linker, while our image is
laid out and relaxed before the same fixed-address binding. The differential
gate's exact linked bytes and canonical reassembly check make a changed
relaxation rung visible; it is not hidden by a word mask.

Implementation commit: pre-existing shared implementation, validated and
closed by this tracker update.

Source snapshots and input hashes: unaffected; this path consumes committed
fixture sources and GNU oracle artifacts, not ISA captures.

Tool versions and exact commands: `cd asm && opam exec -- dune runtest
test/differential`; `make asm-test` (the first command was re-run for this
closure).

Results and artifact links: the differential suite passed. Its
`cross_call` rows cover x86-32, x86-64, ARM, AArch64, RV32 and RV64; in each,
the controlled linked `.text` image agrees exactly. Its relocation transcript
lists one linker-visible call fixup for x86 and one linker-visible plus one
assembler-resolved fixup for each RISC-V profile, with GNU relocation type,
symbol and addend all matched. The same gate also validates linked
multi-section `cross_data` and NOBITS `cross_bss` cases.

Unknowns, exceptions and follow-up task IDs: the 21-entry generated corpus
remains deliberately relocation-free; adding symbolic forms to it is GEN-03
through GEN-06 work and must reuse this resolved-image discipline. The
fixture differential currently represents the shared linked path, rather than
persisting a second JSONL schema for the same artifacts. No linked comparison
is accepted by masking relocation words.

Acceptance gate satisfied: symbolic multi-unit inputs are assembled together,
linked and bound at controlled matching addresses; linked section bytes,
symbols/relocations and internal fixup observations are independently
accounted for under an explicit no-relax policy. This supplies the linked half
that GAS-04 correctly refused to fake from unresolved objects.

### GEN — Architecture recipes and finite coverage obligations

Scope: concrete operand domains, syntax rendering, form selection and
family-by-family coverage. Owner: unassigned. Stages: S3–S4, S7.

Investigate each family's syntax/encoding choices before admitting it.
Start with the proposed RISC-V base/M and x86 legacy pilot. Survey remaining
captured families early so unresolved EVEX/vector/system forms are counted.

- [x] GEN-01 Commit exact pilot source/form IDs, supported configurations,
  mandatory cases and boundary obligations before implementing recipes.
  Blocked until the manifest's implementation side has a stated enumeration
  method per family — `--dump-codec` where alternatives are one-per-form,
  a recorded hand reading of the encoder otherwise (plan section 2.5 rules
  out a single authority, and RISC-V's two wrapper alternatives are not a
  form registry). The method is part of what gets reviewed, not a detail.
- [x] GEN-02 Maintain a full family admission matrix: normalized-only,
  GAS-generatable, promoted support, oracle-unavailable, or specific blocker.
- [x] GEN-03 Implement RISC-V load/store, branch and compressed recipes,
  with split-bit transforms, legal domains and explicit compression policy.
- [x] GEN-04 Implement x86 addressing and x87 recipes, width/order rules
  and intended-versus-GAS-selected encoding checks.
- [ ] GEN-05 Admit further FP/atomic/CSR/bit-manipulation/vector families in
  bounded slices; give every remaining family a concrete task and evidence.
- [ ] GEN-06 Add aliases, pseudos and negatives as distinct coverage classes;
  record deterministic seeds, budgets and unsatisfied obligations.

Exit: every admitted form meets its finite policy; no mismatch is excused
by frontier status; unimplemented forms and oracle gaps remain visible.
“Recipe exists” is not “our assembler supports this extension”.

#### GEN-01 frozen pilot manifest milestone

Task / status / owner: GEN-01 / done / Codex.

Scope manifest and obligations: `asm/tools/lib/isa_gen_pilot.{ml,mli}`
commits, before any case-generation code exists, exactly which source
records/normalized forms make up the S3 pilot, on which targets, and how
each side's implementation-form count was enumerated - the blocking
prerequisite plan §7 states explicitly: "GEN-01 must first state, per
family, how the implementation side is enumerated... the enumeration method
is part of what gets reviewed."

RISC-V (`riscv_pilot`, 9 entries): `add`/`sub`/`mul` (R-type) and `addi`
(I-type) on both RV32 and RV64, plus `addw` on RV64 ONLY. Its
implementation side is enumerated by hand-reading
`riscv_family_encode.ml`'s table-driven `Opcode -> (opcode, funct3,
funct7)`/`(opcode, funct3, funct_hi, shamt)` functions (plan §2.5: RISC-V's
codec is two generic wrapper alternatives around explicit encoder
functions, not a dump-able form registry) - confirmed against the actual
source: `Add -> Some (0x33, 0, 0x00)`, `Sub -> Some (0x33, 0, 0x20)`,
`Mul -> Some (0x33, 0, 0x01)`, `Addi -> Some (0x13, 0, 0, None)`
(`riscv_family_encode.ml:750-800`), each matching the corresponding
isa-db mask/value exactly. `addw` is RV64I-only with no RV32 counterpart
at all - it is simply absent from the riscv32 export - so its single-target
presence in the manifest already demonstrates the "RISC-V XLEN restriction
case" plan §7 asks the pilot to include; no separate machinery was needed.

X86 (`x86_pilot`, 12 entries): the six already-normalized (NORM-02) legacy
register/register and register/immediate `add`/`mov` forms
(`ADD_GPRv_GPRv_01`, `ADD_GPRv_GPRv_03`, `ADD_GPRv_IMMz`,
`MOV_GPRv_GPRv_89`, `MOV_GPRv_GPRv_8B`, `MOV_GPRv_IMMz`), each on x86-32
and x86-64. Its implementation side is enumerated via
`dune exec tool/asm.exe -- --target <t> --dump-codec <file>` (plan §2.5:
x86's composite `Codec.choice` is close to one alternative per form),
cross-checked against `x86_family_encode.ml`'s own opcode tables: the dump
shows `alu-rm-r`/`alu-r-rm` (register/register ALU, both directions) and
`mov-rm-r`/`mov-r-rm`/`mov-r-imm` as distinct alternatives, and
`alu_rm_r_codec`/`alu_r_rm_codec`'s entries confirm `Add -> Opcode.to_rm_r
Add = Some 0x01L` / `Opcode.to_r_rm Add = Some 0x03L` select exactly
`ADD_GPRv_GPRv_01`/`_03` within those alternatives, while `Add -> 0`
(the ModR/M-reg extension) selects `ADD_GPRv_IMMz` within the shared
`alu-rm-imm8`/`alu-rm-imm32` alternative. `FADD_ST0_X87` is deliberately
excluded: plan §7's own S5 row states "x87 is not in the pilot and waits on
S4."

Mandatory obligations (plan §7's own list) are recorded as a responsibility
map, not yet as generated cases: `Negative_immediate_boundary` ->
[`riscv:addi`; `x86:ADD_GPRv_IMMz`]; `Riscv_xlen_restriction` ->
[`riscv:addw`]; `X86_short_vs_full_immediate` -> [`x86:ADD_GPRv_IMMz`] (its
two GAS-selectable encodings, `alu-rm-imm8`/`alu-rm-imm32`, are exactly the
short-versus-full choice).

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396`; XED
`0bcb6237345c5066726dcc08b3d87928df3b5b26` (unchanged; reads existing
checked-in exports only, to ground the manifest - regenerates nothing).

Tool versions and exact commands: `cd asm/tools && opam exec -- dune build
@runtest`; `make tools-test`; `make tools-integration`; `make tools-boundary`;
`make asm-fmt-check`; `make asm-purity`; `cd asm && opam exec -- dune exec
tool/asm.exe -- --target x86_64 --dump-codec /tmp/empty.s` (the `--dump-codec`
evidence reproduction).

Results and artifact links: `test_isa_gen_pilot.ml` (13 checks) pins the
manifest's own shape - exact entry counts, `addw`'s single RV64 target,
every `(target, form_id)` pair distinct, and every mandatory obligation
naming a real pilot `form_id`. `repo_tests.ml`'s new
`test_gen_pilot_manifest` (21 checks, one per pilot entry) is the claim
that actually matters: for every entry, it finds a real record in the
checked-in export matching the manifest's `lookup_key` (`native_name` for
RISC-V, `provenance.iform` for XED), runs it through
`Isa_norm_riscv`/`Isa_norm_xed.normalize`, and confirms the resulting
`form_id` is exactly the manifest's - so "must equal what normalization
actually produces today" (the `.mli`'s own words) is machine-checked, not
asserted. All 21 pass, including `addw` on riscv64 only. `tools-test`,
`tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity` all
pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: this is a manifest of
identities and responsibilities, not of concrete cases - no `input.s`,
operand assignment, or GNU invocation exists yet; that is GAS-02 (profile/
tool configuration and capability probes) and GEN-03 (RISC-V load/store,
branch, compressed recipes; the pilot's own `add`/`addi`/`sub`/`mul`/`addw`
land under this same task's continuation for the base/M families) working
from this manifest's `form_id`s. The "supported configurations" half of
GEN-01's own text (e.g. exact `-march`/`-mabi`/`-mno-relax` argv fragments
per target) is deferred to GAS-02, which is what actually resolves
`Gnu_tools`-backed configuration; this manifest only names which forms need
one, not yet what it is.

Acceptance gate satisfied: the pilot manifest, its per-family enumeration
method, and its mandatory-obligation responsibility map are committed and
machine-checked against real captured/normalized data before any recipe or
GNU-invocation code is written, meeting plan §7's explicit precondition for
starting S3 implementation.

#### GEN-02 source-derived family-admission matrix milestone

Task / status / owner: GEN-02 / done / Codex.

Scope manifest and obligations: `Isa_family_admission` classifies every record
in each of the four selected checked-in exports by its source-native family:
RISC-V's provenance extension and XED's `ISA_SET`. Each record reaches exactly
one state: `normalized-only`, `gas-generatable`, `promoted-support`,
`oracle-unavailable`, or a specific normalization blocker. It is a read-only,
toolchain-free accounting view, intentionally separate from the narrower
inventory compatibility view and from an assertion that a captured extension
is implemented.

Support credit is deliberately strict. Only the exact S3 source records whose
committed GAS-04 case both assembled in this project and agreed byte-for-byte
with GNU are `promoted-support`: the RISC-V add/sub/mul/addi set plus RV64
addw, and XED's `ADD_GPRv_GPRv_01`. The other frozen X86 pilot forms are only
`gas-generatable`: either GNU selected a different form for canonical
register-only syntax or the project has the documented missing-width-suffix
frontend gap. A neighboring encoding therefore cannot grant a form support
credit. Every successful normalization not in that measured pilot stays
`normalized-only`; every unsuccessful record retains the actionable
`unhandled-native-name` or `unhandled-iform` blocker rather than disappearing.

Implementation commit: (this change).

Source snapshots and input hashes: the existing pinned riscv-opcodes and XED
exports; no producer input was regenerated.

Tool versions and exact commands: `cd asm && opam exec -- dune build
@runtest`; `COMPCERT_REPO_ROOT=$(pwd) _build/default/tools/bin/compcert_tools.exe
isa-inventory family-admission`; `make tools-integration`.

Results and artifact links: the new command reports 88 RV32, 94 RV64, 230
X86-32 and 284 X86-64 source-native families. Its aggregate matrix is pinned
by `repo_tests.ml`: RV32 1089 = 25 normalized-only + 4 promoted-support +
1060 blocked; RV64 1154 = 35 + 5 + 1114; X86-32 7887 = 1 normalized-only +
5 GAS-generatable + 1 promoted-support + 7880 blocked; X86-64 10571 = 1 + 5
+ 1 + 10564. Both the per-family and aggregate conservation invariants are
machine-checked, so a new export family cannot be silently omitted.

Unknowns, exceptions and follow-up task IDs: no current selected record is
`oracle-unavailable`; the state is present and reported as zero so a future
capability probe can add it without changing the matrix contract. The broad
unhandled families are not an excuse to skip work: their exact source family
and blocker are now counted inputs to GEN-03 through GEN-06. Family status is
per captured record, not a claim that all XED `ISA_SET` labels are independently
selectable runtime features; FEAT resolves feature policy later.

Acceptance gate satisfied: every selected source record is in a deterministic,
source-native family row with an explicit admission state; existing S3 evidence
is credited only to exact forms, while all remaining normalization and oracle
gaps remain visible and actionable.

#### GEN-03 RISC-V load/store, branch and compressed differential corpus milestone

Task / status / owner: GEN-03 / done / Claude.

Prior slice (kept, unchanged): `c.addi` is a real 16-bit RISC-V form in both
RV32 and RV64 encoders, enabled only by source-local `.option rvc` (the
default and `.option norvc` reject it with `c.addi requires .option rvc`, so
a 32-bit `addi` is never silently compressed), with its tied nonzero
destination/source and nonzero signed six-bit immediate enforced and full
decoder/codec round-trip support. This was implemented and evidenced before
this milestone; nothing about it changed here.

Scope manifest and obligations: this milestone closes exactly the three
items the tracker's prior GEN-03 entry named as remaining - "promote load/
store and branch cases into a separate non-frozen difficult-form corpus with
legal label/offset domains and offline replay", "add the remaining compressed
recipes", and "a section-padding policy for mixed 16/32-bit streams" - plus
promoting all three forms out of `Isa_family_admission`'s `normalized-only`
state, exactly as that prior entry said was still needed ("`c.addi` remains
`normalized-only`... until that persisted differential corpus... grants
support credit").

**Difficult-form corpus** (`asm/tools/lib/isa_gen_difficult.{ml,mli}`,
`asm/fixtures/isa-difficult/cases.jsonl`): a non-frozen, growable manifest -
unlike GEN-01's closed 21-entry pilot - reusing GAS-01 through GAS-05's
`Isa_generated_case`/`Isa_generated_corpus`/`Isa_gen_oracle`/`Isa_gen_ours`/
`Isa_gen_verdict` machinery unmodified rather than inventing a second schema,
persisted to its own corpus tree so growing it can never touch the frozen
pilot's. `Isa_gen_render` gained `render_source_lines` (a `render_source`
generalization to more than one GAS source line, needed for beq's label/
filler lines) with `render_source` now defined in terms of it, verified
identical for the single-line case.

Twenty entries, three families:

- `sw_entries` (8): the signed 12-bit S-type offset domain - 0, 16 (interior),
  2047 (positive endpoint), -2048 (negative endpoint) - each on RV32/RV64.
  Every case is one relocation-free instruction line, like GEN-01's pilot.
- `beq_entries` (4): plan §7's "GAS resolves offset from a label" gap
  (`Isa_norm_riscv.beq_form`'s own diagnostic named this as GEN-03's) - one
  forward branch (`1f`, skipping a `nop`) and one backward branch (`1b`,
  looping over a `nop`), each on RV32/RV64, resolved locally with no
  relocation.
- `c_addi_entries` (8): the signed 6-bit NONZERO immediate domain (zero is
  architecturally reserved, not a "zero when legal" boundary case) - the
  smallest positive/negative magnitudes 1/-1 and the endpoints 31/-32, each
  bracketed in `.option rvc`/`.option norvc` and overriding
  `entry.configuration` to `-march=rv32imc`/`-march=rv64imc` (`sw`/`beq`'s
  base-ISA `-march=rv32im`/`rv64im`, reused via
  `Isa_gen_case_build.configuration_for`, has no `c` and real GAS rejects
  `c.addi` without it).

A real, reviewed finding worth recording explicitly: all four `beq` cases'
`Isa_gen_oracle` outcome is `Assembled_mismatched` (reported `DIFFERENT-FORM`,
persisted as `Different_observed_form`) because that check's single-
instruction contract (`.text` section length equals exactly one encoding's
width) is inapplicable to a rendered source that is genuinely two
instructions (the branch plus its `nop` filler) - not because GAS or "ours"
picked a different form. The credit-bearing signal, `Isa_gen_verdict`'s
direct raw-byte comparison of GAS against "ours" across the WHOLE rendered
source, is measured `Pass` for all four (bytes `63 04 b5 00 13 00 00 00`
forward, `13 00 00 00 e3 0e b5 fe` backward, identical on both tools and both
profiles) - documented in `isa_gen_difficult.mli`'s own comment on
`beq_entries` so a future reader does not mistake the true, if surprising,
`DIFFERENT-FORM` report line for a defect.

**Section-padding policy for mixed 16/32-bit streams**: measured, not
designed - no policy turned out to be needed. RISC-V requires only two-byte
instruction alignment even with the C extension enabled (four-byte alignment
is a convention, not an ISA requirement), and this engine's layout already
places every fragment back-to-back by its own real encoded length, so a
4-byte `add` immediately after a 2-byte `c.addi` sits at byte offset 2 with
no inserted padding. Verified against real `riscv32-linux-gnu-as` 2.43.1 and
`riscv64-linux-gnu-as` 2.44 for `.option rvc; c.addi a0, 1; .option norvc; sw
a0, 0(a1); add a2, a0, a1; .option rvc; c.addi a0, -1`: both tools produce
`05 05 23 a0 a5 00 33 06 b5 00 7d 15` on both profiles. `.option norvc`
brackets the plain `sw`/`add` lines because real GAS - unlike this project -
opportunistically substitutes ANY compressible instruction once the C
extension is active (plan §5.3's "prevent opportunistic compression in
baseline 32-bit form tests"): confirmed directly that leaving RVC enabled
around `sw a0, 0(a1)` makes GAS silently emit the 2-byte `c.sw` (`88 c1`)
instead, a real, separate, unimplemented compressed form here. This is now a
pinned regression, `test/targets/test_targets.ml`'s "a compressed instruction
and a 32-bit instruction pack with no inserted padding".

**Support-credit promotion**: `Isa_family_admission.promoted_case` gained
`riscv:sw`/`riscv:beq`/`riscv:c.addi` (RV32 and RV64) alongside the existing
GAS-04 pilot rows, and `pilot_case` (the middle `gas-generatable` tier) now
also checks `Isa_gen_difficult.all` so a future difficult entry that does NOT
reach `Promoted_support` falls to `Gas_generatable` rather than looking
`Normalized_only`.

**Refactor** (behavior-preserving, needed to avoid duplicating GAS-04's
oracle/ours/verdict driving logic for a second corpus): extracted
`asm/tools/lib/isa_gen_drive.{ml,mli}` (`run_case`, `verdict_tag`) out of
`isa_generated_cmd.ml`, parameterized over a report-line `prefix` (GEN-01's
pilot uses `"isa-generated"`, GEN-03's corpus `"isa-difficult"`) and `label`;
`isa_generated_cmd.ml`'s own `regen` now calls it. `isa_difficult_cmd.ml`
(regen) and `Check_cmd.isa_difficult_check` mirror `isa_generated_cmd.ml`/
`Check_cmd.isa_generated_check` exactly, over `Isa_gen_difficult.all`/
`normalize_entry`/`build` and the separate `Repo.isa_difficult_corpus` path.
Wired as `compcert_tools.exe isa-difficult check|regen` /
`make asm-isa-difficult-check|-regen`, joining `asm-test`'s prerequisites for
the toolchain-free `check` tier exactly as `Isa_generated_case.
joins_prerequisite_of Offline_consumer` established for the pilot.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396`; XED
`0bcb6237345c5066726dcc08b3d87928df3b5b26` (unchanged; reads the existing
checked-in exports only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`make tools-test`; `make tools-integration`; `make tools-boundary`; `make
asm-fmt-check`; `make asm-purity`; `make asm-js-portable`; `make
tools-isa-inventory-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (produces and commits
`asm/fixtures/isa-difficult/cases.jsonl`, reproduced byte-identically across
two separate runs); `env PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
make asm-isa-difficult-check` and `... make asm-test` (both with every cross-
toolchain directory stripped from `PATH`, proving the tier-1 gate stays
genuinely toolchain-free); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-generated-regen` (run to confirm the `isa_gen_drive` extraction
is behavior-preserving against GEN-01's own frozen pilot, then discarded -
see Results - since only its `ours-<git-rev>[-dirty]` tool_label differs,
never the assembled bytes/verdicts).

Results and artifact links: `test_isa_gen_difficult.ml` (111 checks) pins the
manifest's own shape - entry counts, distinct `case_id`s, the legal offset/
nzimm domains and their bounds, both branch directions, no `x0` usage, the
`.option rvc`/`norvc` bracketing and `-march`-includes-`c` check for
`c_addi_entries`, and `render_source_lines`/`render_source` agreement.
`repo_tests.ml`'s new `test_gen_difficult_manifest` (20 checks) grounds every
entry's `lookup_key` against the real checked-in riscv-opcodes exports,
mirroring `test_gen_pilot_manifest`. A real `asm-isa-difficult-regen` run
produced all 20 cases with `verdict = Pass` (8 `sw` + 4 `beq` + 8 `c.addi`,
GAS and "ours" byte-identical throughout), reproduced byte-for-byte across
two separate runs. `asm-isa-difficult-check`/`asm-test` both pass with every
cross-toolchain directory stripped from `PATH`. `Isa_family_admission`'s
pinned RV32/RV64 totals moved exactly as expected and machine-checked:
`normalized-only` 25->22 / 35->32, `promoted-support` 4->7 / 5->8, with
`total`/`blocked`/`gas-generatable` unchanged on every profile (`isa-inventory
family-admission`'s own report confirms `rv_c` and `rv_i`'s per-family rows).
Re-running `asm-isa-generated-regen` against GEN-01's frozen pilot after the
`isa_gen_drive` extraction reproduced identical assembled bytes, findings and
verdicts for all 21 cases - the only diff was the git-rev-embedded `ours`
`tool_label` (expected, since `Isa_gen_ours.run` resolves it fresh from HEAD
every run) - so the committed pilot corpus was left untouched (`git checkout
--`) rather than committing a label-only diff. `tools-test`, `tools-
integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity`, `asm-
js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all pass
unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: the difficult corpus's oracle
still checks `sw`/`c.addi` cases via `Isa_gen_oracle.observed_form_check`'s
single-instruction contract (correct, since both really are one instruction);
`beq`'s two-instruction cases rely entirely on `Isa_gen_verdict`'s direct
byte comparison for credit, which is correct but means a hypothetical future
multi-instruction case that GENUINELY picks a different GAS form would report
the same `DIFFERENT-FORM` shape as beq's benign one - `Isa_gen_verdict`'s
unconditional-hard-failure-on-byte-mismatch rule (plan §5.5) is what actually
protects against that, not the oracle's finding label. No boundary offsets
near the branch displacement's full ±4KB range are exercised (only a
one-`nop`-away forward/backward pair) - a wider branch-distance sweep, and
negative/must-reject cases for all three forms, are GEN-06's explicit
"aliases, pseudos and negatives" scope, not this task's. Broader RVC/Zc
family coverage beyond `c.addi` (the plan's own compressed pilot
representative) remains GEN-05's "further... bounded slices" work; the
family-admission matrix keeps every other Zc-file record's exact blocker
visible rather than assuming it because this task closed one compressed
form.

Acceptance gate satisfied: GEN-03's three text items - "RISC-V load/store,
branch and compressed recipes, with split-bit transforms, legal domains and
explicit compression policy" - are each backed by a committed, offline-
replayed differential corpus entry or a pinned regression, `c.addi`/`sw`/
`beq` are promoted out of `normalized-only` by the same measured-Pass
discipline GAS-04 established for the frozen pilot (never asserted), and the
mixed-stream padding question is answered by direct measurement against two
real GNU toolchain versions rather than by design assumption.

#### GEN-04 x86 addressing and x87 differential corpus milestone

Task / status / owner: GEN-04 / done / Codex.

This bounded slice admits source-normalized XED `MOV_GPRv_MEMv`,
`MOV_MEMv_GPRv`, and `FADD_ST0_X87` on both x86 profiles. The normalized model
now represents memory operands as `Memory { width_bits }`, preserving XED's
generic `GPRv`/`MEMv` fact while making generated recipes explicitly 32-bit
(`movl`); generic operand-size selection is not claimed. Each target has a
base-plus-disp8 SIB load (`movl 16(%esp/%rsp), %ecx`) and an
index-times-four-plus-disp32 store (`movl %ecx, 1024(%eax/%rax,%edx/%rdx,4)`).

`FADD_ST0_X87` is normalized to verified AT&T direction and spelling
`fadd %st(1), %st`, and implemented as register-stack `D8 C0+i`. x86_64 now
recognizes bare `%st`, and decoding synthesizes `st(n)` names. Reverse
`FADD_X87_ST0`, `FADDP`, x87 memory forms, and non-32-bit MOV widths remain
unadmitted.

The difficult corpus rises from 20 to 26 cases: two MOV forms and one FADD
form per x86 target beside the existing RISC-V cases. GNU `as` and this
encoder agree exactly on the new bytes: x86_32 emits `8b 4c 24 10`,
`89 8c 90 00 04 00 00`, and `d8 c1`; the x86_64 variants have the expected
REX/addressing bytes and the same `d8 c1` x87 encoding. Per-profile admission
accounting is nine normalized XED records, five GAS-generatable forms, four
promoted-support forms, zero normalized-only forms, and all remaining source
forms explicitly blocked (7,878 x86_32; 10,562 x86_64).

Validation completed: `make asm-isa-difficult-regen`,
`make asm-isa-difficult-check`, `make tools-test`, `make tools-integration`,
`cd asm && opam exec -- dune build @all`,
`cd asm && opam exec -- dune build @runtest`, and `make asm-fmt-check`.
The corpus checker also replays successfully with cross toolchains absent from
`PATH`; the fixture contains all required oracle evidence. `make asm-test`,
`make tools-boundary`, `make asm-purity`, `make asm-js-portable`,
`make tools-isa-inventory-diff`, and `make tools-gasxref-diff` also pass for
this milestone.

GEN-05 owns further bounded FP/atomic/CSR/bit-manipulation/vector slices;
GEN-06 owns aliases, pseudos, diagnostics, and negative/round-trip coverage.
No unsupported width, address-size, x87 direction, or x87-memory behavior is
represented as supported by GEN-04.

Acceptance gate satisfied: GEN-04's addressing and x87 recipe, width/order,
and intended-versus-GAS-selected encoding requirements have source records,
explicit bounded recipes, exact GNU-versus-ours bytes, offline replay, and
decoder/target regression coverage.

#### GEN-05 scalar FP arithmetic and Zba slices: RISC-V F/D arithmetic and `sh1add`

Task / status / owner: GEN-05 FP sub-slice / done; GEN-05 overall / still
implementing / Codex.

The first admissible FP form was the normalized bare `fadd.s ft0, ft1, ft2`
spelling, on RV32IMF (`-mabi=ilp32f`) and RV64IMF (`-mabi=lp64f`), both with
no relaxation. The source records supply the `rd`, `rs1`, `rs2`, and `rm`
fields; normalization records that these are FPRs and that omitted `rm`
selects GNU's dynamic rounding (`funct3=7`). The bounded scalar arithmetic
slice now extends that identical bare-recipe rule to `fsub.s`, `fmul.s`, and
`fdiv.s`, each with the same `ft0`, `ft1`, `ft2` operands on both profiles.
GNU and this assembler agree on `53 f0 20 00`, `53 f0 20 08`, `53 f0 20 10`,
and `53 f0 20 18`, respectively; the existing OP-FP `f_arith_desc` lowering
selects funct7 `0x00`, `0x04`, `0x08`, and `0x0c` with bare `rm=dyn`.

The same bounded recipe now admits `fadd.d`, `fsub.d`, `fmul.d`, and `fdiv.d`
on RV32IMFD (`-mabi=ilp32d`) and RV64IMFD (`-mabi=lp64d`). GNU and this
assembler agree on `53 f0 20 02`, `53 f0 20 0a`, `53 f0 20 12`, and
`53 f0 20 1a`, respectively. The `D` extension configuration is explicit;
its architectural dependency on `F` is not inferred as a feature-policy
claim, which remains GEN-06 work.

A separate bounded Zba slice implements and promotes `sh1add a0, a1, a2`
with RV32IM_Zba/RV64IM_Zba configuration: GNU and this assembler agree on
`33 a5 c5 20` on both profiles (opcode `0x33`, funct3 2, funct7 `0x10`). The
difficult corpus has 44 entries. Accounting is RV32 normalized-only
20/promoted 16/blocked 1053 and RV64 normalized-only 30/promoted 17/blocked
1107; the seven additional scalar-F/D records per profile moved from named
unhandled blockers directly to promoted support.

The scope does not claim explicit `rne`/`rtz`/other rounding-mode operands,
the rest of F/D, atomic ordering, CSR names or numbers, Zb operations beyond
`sh1add`, RVC/Zc beyond the existing representative, or vector configuration.
Those are separate GEN-05 sub-slices. The admission matrix continues to report every
unhandled source record as a named blocker, while the next GEN-05 ledger pass
will partition those remaining families into concrete sub-slices before this
overall checkbox is closed.

Validation completed: direct GNU GAS listings on RV32IMF and RV64IMF;
`make asm-isa-difficult-regen`, `make asm-isa-difficult-check`,
`make tools-test`, `cd asm && opam exec -- dune build @runtest`, and
`make asm-fmt-check`. Full assembler, boundary, purity, portability,
inventory, and cross-reference gates are rerun before this sub-slice commit.

##### GEN-05 continuation: Zba `sh2add`/`sh3add` (Claude)

Task / status / owner: GEN-05 Zba scale-family sub-slice / done; GEN-05
overall / still implementing / Claude.

Scope manifest and obligations: complete Zba's non-word scale family beyond
`sh1add` - `sh2add` and `sh3add`, the two remaining plain-register R-type
scale-and-add forms riscv-opcodes' `rv_zba` extension defines alongside it
(`sh1add.uw`/`sh2add.uw`/`sh3add.uw`, the RV64-only word variants, are a
separate zero-extend operand fact and stay out of this slice). Both were
source-normalized-but-unhandled at the prior milestone's close; this closes
them the same way `sh1add` closed, not by design assumption.

Unlike the scalar-FP slice, this family had no existing encoder support to
normalize against: `riscv_family_encode.ml`'s `Opcode.t`/`r_desc`/`r_name`
gained `Sh2add -> Some (0x33, 4, 0x10)` and `Sh3add -> Some (0x33, 6, 0x10)`
(and their reverse-decode counterparts), the same R-type alternative
`sh1add` already uses with the same `0x10` funct7 and a distinct funct3 -
hand-verified against the checked-in `isa-db/export/riscv_opcodes/riscv32
.jsonl`/`riscv64.jsonl` mask/value fields (`0x20004033`/`0x20006033`) before
writing the table entries, not assumed from the mnemonic pattern. No other
match site in `riscv_family_encode.ml` is exhaustive over individual R-type
opcodes (parsing dispatches generically through `Opcode.of_mnemonic`, itself
derived from `name`/`all`), so no other file in the encoder needed a
parallel change.

`Isa_norm_riscv.r_type_mnemonics` gained `sh2add`/`sh3add` (the identical
generic `r_type_gpr_form` path `sh1add` already normalizes through - same
three-plain-GPR-operand shape, same `Req_feature "riscv:zba"` via the
existing `rv_zba` mapping, no new normalization code). `Isa_gen_difficult`'s
single `sh1add_entry` became a generic `zba_shadd_entry ~mnemonic
~scale_name`, producing `sh1add_entries`/`sh2add_entries`/`sh3add_entries`
(2 cases each, RV32 and RV64, `a0, a1, a2` operands, `-march=rv{32,64}im_zba`
configuration reused unchanged from the `sh1add` slice) - a
behavior-preserving refactor for `sh1add`'s own 2 entries, verified by the
unchanged `sh1add` cases in the regenerated corpus below. `Isa_family_
admission.promoted_case` gained the `sh2add`/`sh3add` `(form_id,
lookup_key)` pairs alongside `sh1add`'s.

Real, measured findings: hand-computed expected bytes for `sh2add a0, a1,
a2`/`sh3add a0, a1, a2` from the riscv-opcodes mask/value (`33 c5 c5 20`/
`33 e5 c5 20`) matched this project's own `--dump-bytes` output exactly
before any corpus wiring, then confirmed against real GNU `as` (RV32
2.43.1 via `/usr/local/riscv32-linux-gnu-toolchain/bin`, RV64 2.44) with
`-march=rv{32,64}im_zba -mabi={ilp32,lp64} -mno-relax`: both tools agree on
both instructions on both profiles, byte-for-byte.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt-check`; `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (produces and commits
`asm/fixtures/isa-difficult/cases.jsonl`, reproduced byte-identically across
two separate runs); `env PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr
/bin:/sbin:/bin" make asm-isa-difficult-check` and `... make asm-test` (both
with every cross-toolchain directory stripped from `PATH`, proving the
tier-1 gate stays genuinely toolchain-free).

Results and artifact links: two new `test_targets.ml` expect-tests pin the
real encoded bytes for `sh2add`/`sh3add` on both profiles (mirroring the
existing `sh1add` test); 3 new `isa-norm-riscv` checks (a shared `test_zba_
shadd` helper parameterized over `sh1add`/`sh2add`/`sh3add`, each against its
own real, verbatim-extracted riscv32.jsonl record); 2 new `isa-gen-difficult`
entry-count checks plus the existing domain/all-family-sum checks extended
to the two new families (266 total `isa-gen-difficult` checks, all passing).
A real `asm-isa-difficult-regen` run against the now-24-entry corpus (was
20) reproduced all 24 cases with `verdict = Pass`, including the 4 new
`sh2add`/`sh3add` cases and the unchanged `sh1add`/other 20, byte-identical
across two separate runs. `asm-isa-difficult-check`/`asm-test` both pass
with every cross-toolchain directory stripped from `PATH`.
`Isa_family_admission`'s pinned RV32/RV64 totals moved exactly as expected:
promoted-support 16->18 / 17->19, blocked 1053->1051 / 1107->1105,
normalized-only unchanged (20/30) since both new forms are promoted
directly rather than staying `normalized-only`; `isa-norm-accounting`'s
paired totals moved 36->38 / 47->49 and the `isa-norm-jsonl` real-form
round-trip count moved 101->105, all three pinned repo_tests.ml expectations
updated to match and re-verified passing. `tools-test`, `tools-integration`,
`tools-boundary`, `asm-fmt-check`, `asm-purity`, `asm-js-portable`,
`tools-isa-inventory-diff`, `tools-gasxref-diff` all pass unchanged
otherwise.

Unknowns, exceptions and follow-up task IDs: the `*.uw` word-operand variants
of all three Zba scale instructions, and the rest of Zbb (`andn`/`orn`/
`xnor`/`min`/`max`/`clz`/`ctz`/`cpop`/...), remain named, counted blockers,
not implemented here - closing Zba's non-word scale family is this slice's
whole scope, not a claim about the rest of bit-manipulation. Atomic, CSR,
remaining vector, and broader FP families remain GEN-05's own outstanding
scope, per the prior sub-slice's own text.

Acceptance gate satisfied: `sh2add`/`sh3add` have real encoder support
(hand-verified against the source mask/value before any test was written),
source-derived normalization reusing the existing generic R-type path, a
persisted, offline-replayed differential corpus entry each with real GNU
agreement on both profiles, and admission-matrix promotion - the same
measured-Pass discipline every other GEN-05/GAS-04 promotion used, with
every affected pinned count in the repository's own regression suite
updated and re-verified rather than left stale.

##### GEN-05 continuation: Zbb `min`/`minu`/`max`/`maxu` (Claude)

Task / status / owner: GEN-05 Zbb comparison sub-slice / done; GEN-05
overall / still implementing / Claude.

Scope manifest and obligations: admit Zbb's four plain R-type comparison
forms - `min`, `minu`, `max`, `maxu` (opcode `0x33`, funct7 `0x05`, funct3
selects signed/unsigned and min/max). Before picking this family, checked
whether `andn`/`orn`/`xnor` (Zbb's other simple R-type forms) were an
equally clean next slice: they are not - the checked-in riscv-opcodes
snapshot lists each of those three identically under five different
extension files (`rv_zbb`, `rv_zbkb`, `rv_zk`, `rv_zkn`, `rv_zks`), a real
instance of plan §4.2's "an imported instruction available through
alternative extension sets must not accidentally require every importing
extension at once." `Isa_norm_riscv.requirement_of` reads a single
`provenance.extension` per record today and riscv-opcodes exports each
extension membership as a separate record with the same `native_name`, so
normalizing those three correctly needs an actual `Req_any` construction
this dispatch does not build yet - real design work, not a same-shape
follow-on, and deliberately left as a named, counted blocker rather than
normalized against only one of its five extension records by accident.
`min`/`minu`/`max`/`maxu` have no such duplication (verified by grepping
every `rv_zbb`/`rv_zbkb`/`rv_zk`/`rv_zkn`/`rv_zks`/`rv64_zbb`-family record
in both checked-in profiles before choosing this slice): exactly one record
each, single-extension (`rv_zbb`), the same shape discipline as `sh1add`.

Mechanically this repeats the `sh2add`/`sh3add` continuation exactly:
`riscv_family_encode.ml`'s `Opcode.t`/`r_desc`/`r_name` gained `Min ->
Some (0x33, 4, 0x05)`, `Minu -> Some (0x33, 5, 0x05)`, `Max -> Some (0x33,
6, 0x05)`, `Maxu -> Some (0x33, 7, 0x05)` (and reverse-decode
counterparts), hand-verified against the checked-in riscv32.jsonl/
riscv64.jsonl mask/value fields (`0xa004033`/`0xa005033`/`0xa006033`/
`0xa007033`) before writing the table. `Isa_norm_riscv` gained `"rv_zbb"
-> Req_feature "riscv:zbb"` in `feature_of_extension` and the four
mnemonics in `r_type_mnemonics` (the same generic `r_type_gpr_form` path).
`Isa_gen_difficult` gained a `zbb_r_type_entry` generator (mirroring
`zba_shadd_entry`) producing `min_entries`/`minu_entries`/`max_entries`/
`maxu_entries` (2 cases each, `a0, a1, a2`, `-march=rv{32,64}im_zbb`).
`Isa_family_admission.promoted_case` gained the four `(form_id,
lookup_key)` pairs. `test_isa_norm_riscv.ml`'s previously Zba-specific
`test_zba_shadd` helper was generalized to `test_r_type_gpr ~feature
~mnemonic ~json` (parameterized over the required feature name instead of
hardcoding `"zba"`) and reused for all seven R-type mnemonics now covered
this way, rather than duplicating the same three checks a fourth time.

Real, measured findings: hand-computed expected bytes for `min a0, a1,
a2`/`minu a0, a1, a2`/`max a0, a1, a2`/`maxu a0, a1, a2` from the
riscv-opcodes mask/value (`33 c5 c5 0a`/`33 d5 c5 0a`/`33 e5 c5 0a`/
`33 f5 c5 0a`) matched this project's own `--dump-bytes` output exactly
before any corpus wiring, then confirmed against real GNU `as` (RV32
2.43.1, RV64 2.44) with `-march=rv{32,64}im_zbb -mabi={ilp32,lp64}
-mno-relax`: both tools agree on all four instructions on both profiles,
byte-for-byte.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt-check`; `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (produces and commits
`asm/fixtures/isa-difficult/cases.jsonl`, reproduced byte-identically across
two separate runs); `env PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr
/bin:/sbin:/bin" make asm-isa-difficult-check` and `... make asm-test`
(both with every cross-toolchain directory stripped from `PATH`, proving the
tier-1 gate stays genuinely toolchain-free).

Results and artifact links: one new `test_targets.ml` expect-test pins the
real encoded bytes for `min`/`minu`/`max`/`maxu` on both profiles; the
generalized `test_r_type_gpr` helper in `isa-norm-riscv` now exercises all
seven R-type mnemonics (307 total `isa-gen-difficult` checks, all passing,
up from 266). A real `asm-isa-difficult-regen` run against the now-32-entry
corpus (was 24) reproduced all 32 cases with `verdict = Pass`, including the
8 new `min`/`minu`/`max`/`maxu` cases, byte-identical across two separate
runs. `asm-isa-difficult-check`/`asm-test` both pass with every
cross-toolchain directory stripped from `PATH`. `Isa_family_admission`'s
pinned RV32/RV64 totals moved exactly as expected: promoted-support
18->22 / 19->23, blocked 1051->1047 / 1105->1101, normalized-only unchanged
(20/30); `isa-norm-accounting`'s paired totals moved 38->42 / 49->53 and
the `isa-norm-jsonl` real-form round-trip count moved 105->113, all three
pinned `repo_tests.ml` expectations updated and re-verified passing.
`tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`,
`asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`,
`tools-gasxref-diff` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: `andn`/`orn`/`xnor` remain
named, counted blockers pending real `Req_any` support in
`Isa_norm_riscv.requirement_of` (not guessed at here); the rest of Zbb
(population count, rotate, sign/zero-extend, `orc.b`, `rev8`) and the Zba
`*.uw` word variants remain outside this bounded slice. Atomic, CSR,
remaining vector, and broader FP families remain GEN-05's own outstanding
scope.

Acceptance gate satisfied: `min`/`minu`/`max`/`maxu` have real encoder
support (hand-verified against the source mask/value before any test was
written), source-derived normalization reusing the existing generic R-type
path, a persisted, offline-replayed differential corpus entry each with
real GNU agreement on both profiles, and admission-matrix promotion - the
same measured-Pass discipline every other GEN-05/GAS-04 promotion used,
with every affected pinned count in the repository's own regression suite
updated and re-verified rather than left stale. The candidate family this
slice deliberately did not take (`andn`/`orn`/`xnor`) is recorded with the
specific missing capability (`Req_any`) that would be needed first, per
plan §7's "every deferral must name the missing capability."

##### GEN-05 continuation: Zba `sh1add.uw`/`sh2add.uw`/`sh3add.uw` (Claude)

Task / status / owner: GEN-05 Zba word-operand sub-slice / done; GEN-05
overall / still implementing / Claude.

Scope manifest and obligations: close Zba's `*.uw` word-operand family -
`sh1add.uw`, `sh2add.uw`, `sh3add.uw` - the three RV64-only siblings of
`sh1add`/`sh2add`/`sh3add` that zero-extend `rs1`'s low 32 bits before the
scaled add. riscv-opcodes exports these as single-extension (`rv64_zba`)
records with no RV32 counterpart at all (verified by grep before starting:
zero matches in `riscv32.jsonl`, one match each in `riscv64.jsonl`), so
unlike `andn`/`orn`/`xnor`/`rol`/`ror` this family has no import-duplication
blocker and needs no `Req_any` design work - it is a clean next slice by the
same "grep every candidate family's extension membership before choosing"
discipline the `min`/`minu`/`max`/`maxu` slice established.

Mechanically this is `sh1add`/`sh2add`/`sh3add`'s own encoder shape moved to
opcode `0x3b` (OP-32, RV64's word-operand opcode) instead of `0x33`, with the
same funct7 `0x10` and per-scale funct3 assignment (2/4/6):
`riscv_family_encode.ml`'s `Opcode.t`/`r_desc`/`r_name` gained
`Sh1adduw -> Some (0x3b, 2, 0x10)`, `Sh2adduw -> Some (0x3b, 4, 0x10)`,
`Sh3adduw -> Some (0x3b, 6, 0x10)` (and reverse-decode counterparts) -
hand-verified against the checked-in `riscv64.jsonl` mask/value fields
(`0xfe00707f`/`0x2000203b`, `0x2000403b`, `0x2000603b`) before writing the
table entries. Opcode `0x3b` already needs an explicit RV64-only guard in
`lower_instruction` (the same guard `Addw`/`Subw`/`Sllw`/`Srlw`/`Sraw`/`Mulw`
use) - `Sh1adduw`/`Sh2adduw`/`Sh3adduw` join that guard's pattern; `decode`
needed no change, since it already gates every opcode-`0x3b` `r_name` match
on `xlen = 64` generically, not per-mnemonic.

`Isa_norm_riscv.feature_of_extension` gained `"rv64_zba" -> Req_all
[Req_xlen 64; Req_feature "riscv:zba"]`, mirroring `rv64_m`'s existing
RV64-plus-feature combination rather than inventing a new requirement shape.
The three mnemonics joined `r_type_mnemonics` (the same generic
`r_type_gpr_form` path every other plain R-type family uses).
`Isa_gen_difficult` reused `zba_shadd_entry` unchanged, applied to
`[Target.Riscv64]` only (one entry each, not two) - the same single-target
pattern GEN-01's own `addw` pilot entry established for an RV64-only
mnemonic. `Isa_family_admission.promoted_case` gained the three
`(form_id, lookup_key)` pairs, guarded to `Target.Riscv64` only.

Real, measured findings: hand-computed expected bytes for `sh1add.uw a0, a1,
a2`/`sh2add.uw a0, a1, a2`/`sh3add.uw a0, a1, a2` from the riscv-opcodes
mask/value (`3b a5 c5 20`/`3b c5 c5 20`/`3b e5 c5 20`) matched this project's
own `--dump-bytes` output exactly before any corpus wiring, then confirmed
against real GNU `as` 2.44 with `-march=rv64im_zba -mabi=lp64 -mno-relax`:
both tools agree on all three instructions. Separately confirmed both real
GNU `as` (RV32 2.43.1) and this project's own encoder reject all three
mnemonics on RV32 with an XLEN-only diagnosis (`sh1add.uw is available only
when XLEN is 64` on our side; `unrecognized opcode` from GNU), so the
RV64-only restriction is enforced identically on both sides, not merely
assumed from the export's missing RV32 record.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt-check`; `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (produces and commits
`asm/fixtures/isa-difficult/cases.jsonl`, reproduced byte-identically across
two separate runs - confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that every case besides the three new
ones is byte-for-byte unchanged); `env
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" make
asm-isa-difficult-check` and `... make asm-test` (both with every
cross-toolchain directory stripped from `PATH`, proving the tier-1 gate
stays genuinely toolchain-free).

Results and artifact links: one new `test_targets.ml` expect-test pins the
real encoded bytes for `sh1add.uw`/`sh2add.uw`/`sh3add.uw` on riscv64 and the
RV64-only rejection on riscv32; 3 new `isa-norm-riscv` checks (a new
`test_r_type_gpr_rv64` helper, since these carry `Req_all [Req_xlen 64;
Req_feature ...]` rather than `test_r_type_gpr`'s plain single-feature
requirement, each against its own real, verbatim-extracted riscv64.jsonl
record); 3 new `isa-gen-difficult` entry-count checks (317 total, up from
307, all passing, confirming each of the three is RV64-only). A real
`asm-isa-difficult-regen` run against the now-35-entry corpus (was 32)
reproduced all 35 cases with `verdict = Pass`, including the 3 new
`sh1add.uw`/`sh2add.uw`/`sh3add.uw` cases, byte-identical across two separate
runs. `asm-isa-difficult-check`/`asm-test` both pass with every
cross-toolchain directory stripped from `PATH`. `Isa_family_admission`'s
pinned RV64 totals moved exactly as expected (RV32 unaffected, since the
three forms have no RV32 record at all): promoted-support 22->26 (RV32
unchanged at 22), blocked 1101->1098 (RV32 unchanged at 1047),
normalized-only unchanged (20/30) since all three are promoted directly;
`isa-norm-accounting`'s RV64 normalized count moved 53->56 (RV32 unchanged
at 42) and the `isa-norm-jsonl` real-form round-trip count moved 113->116,
all pinned `repo_tests.ml` expectations updated and re-verified passing.
`tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`,
`asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`,
`tools-gasxref-diff` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: this closes Zba's full
scale-and-add family (non-word and `*.uw` word-operand variants both now
promoted); `andn`/`orn`/`xnor`/`rol`/`ror` remain named, counted blockers
pending real `Req_any` support in `Isa_norm_riscv.requirement_of` (not
guessed at here - confirmed `rol`/`ror` share the identical five-extension
duplication shape `andn`/`orn`/`xnor` do, so both pairs need the same design
work, not two separate ones). The rest of Zbb (population count, rotate,
sign/zero-extend, `orc.b`, `rev8`) - several of which (`clz`/`cpop`/`ctz`/
`sext.b`/`sext.h`/`orc.b`) are single-extension and shape-clean but need a
new two-GPR-operand normalization/encoder shape this project has not built
yet, distinct from the three-operand R-type path every promoted RISC-V form
so far reuses - remains outside this bounded slice. Atomic, CSR, remaining
vector, and broader FP families remain GEN-05's own outstanding scope.

Acceptance gate satisfied: `sh1add.uw`/`sh2add.uw`/`sh3add.uw` have real
encoder support (hand-verified against the source mask/value before any
test was written), source-derived normalization reusing the existing
generic R-type path and the existing RV64-plus-feature requirement shape,
matched RV64-only rejection on both GNU and this project's own assembler, a
persisted, offline-replayed differential corpus entry each with real GNU
agreement, and admission-matrix promotion - the same measured-Pass
discipline every other GEN-05/GAS-04 promotion used, with every affected
pinned count in the repository's own regression suite updated and
re-verified rather than left stale.

##### GEN-05 continuation: Zbb `andn`/`orn`/`xnor`/`rol`/`ror` via real `Req_any` (Claude)

Task / status / owner: GEN-05 Zbb import-duplicated sub-slice / done; GEN-05
overall / still implementing / Claude.

Scope manifest and obligations: implement the `Req_any` capability the prior
two Zbb sub-slices named and deliberately deferred, then use it to admit
`andn`/`orn`/`xnor`/`rol`/`ror` - the checked-in riscv-opcodes snapshot lists
each of these identically under five different extension files (`rv_zbb`,
the primary `instruction-form` record, plus `rv_zbkb`/`rv_zk`/`rv_zkn`/`rv_zks`,
each a `$import`-kind record whose own `relationships`/
`provenance."relationship-resolution"` point back at the `rv_zbb` record with
`status: "exact"`) - hand-verified identical mask/value across all five in
both checked-in profiles before writing any code (`andn` `0xfe00707f`/
`0x40007033`, `orn` `0x40006033`, `xnor` `0x40004033`, `rol` `0x60001033`,
`ror` `0x60005033`).

`Isa_norm_riscv.requirement_of` reads only its own record's single
`provenance.extension`, and even an import record only ever names its own
extension plus the one extension it imports from - never its other sibling
importers - so no single record can build the full five-way `Req_any` by
itself. `alternative_extensions_by_mnemonic` is therefore a small,
hand-verified table (the same "grep every candidate family's extension
membership before choosing" discipline every prior GEN-05 sub-slice used,
now recorded as data instead of only as a deferral comment): for these five
mnemonics, `requirement_of_any` builds `Req_any` over all five mapped
extensions after confirming the record's own extension is actually a member
(an unrelated record sharing the mnemonic by coincidence gets `Req_unknown`,
not a silently wrong `Req_any`) - a design choice, not a general cross-record
join: a sixth import site upstream needs this list extended, not inferred.
`requirement_of_mnemonic` dispatches to it only for these five names;
`r_type_gpr_form` (every other R-type mnemonic) is unaffected.
`feature_of_extension` gained `rv_zbkb`/`rv_zk`/`rv_zkn`/`rv_zks` ->
`Req_feature "riscv:{zbkb,zk,zkn,zks}"`, the same naming convention
`rv_zbb`/`rv_zba` already use; these are normalized-model feature names only,
not yet live configuration (FEAT is not started).

A real consequence of `Req_any` under the current per-record accounting
model: each of the five extension-membership records independently
normalizes to a form with the same `form_id`, so promoting one mnemonic
promotes all five underlying records, not one - this slice moves 25 records
per profile (5 mnemonics x 5 records), not 5, and every pinned count below
reflects that.

Mechanically the encoder and difficult-corpus wiring repeat the `min`/`minu`/
`max`/`maxu` slice: `riscv_family_encode.ml`'s `Opcode.t`/`r_desc`/`r_name`
gained `Andn -> Some (0x33, 7, 0x20)`, `Orn -> Some (0x33, 6, 0x20)`,
`Xnor -> Some (0x33, 4, 0x20)`, `Rol -> Some (0x33, 1, 0x30)`,
`Ror -> Some (0x33, 5, 0x30)` (and reverse-decode counterparts), hand-verified
against the checked-in riscv32.jsonl/riscv64.jsonl mask/value fields before
writing the table. `Isa_norm_riscv.r_type_mnemonics` gained all five (the
existing generic `r_type_gpr_form` path, unchanged). `Isa_gen_difficult`
gained `andn_entries`/`orn_entries`/`xnor_entries`/`rol_entries`/`ror_entries`
(2 cases each, `a0, a1, a2`, `-march=rv{32,64}im_zbb`, reusing
`zbb_r_type_entry`/`zbb_configuration_for` unchanged) - exercising the
primary `rv_zbb` configuration only; asserting GNU agreement under the other
four extension names is not this slice's scope. `Isa_family_admission.
promoted_case` gained the five `(form_id, lookup_key)` pairs.

Real, measured findings: hand-computed expected bytes for `andn a0, a1,
a2`/`orn a0, a1, a2`/`xnor a0, a1, a2`/`rol a0, a1, a2`/`ror a0, a1, a2` from
the riscv-opcodes mask/value (`33 f5 c5 40`/`33 e5 c5 40`/`33 c5 c5 40`/
`33 95 c5 60`/`33 d5 c5 60`) matched this project's own `--dump-bytes` output
exactly before any corpus wiring, then confirmed against real GNU `as` (RV32
2.43.1, RV64 2.44) with `-march=rv{32,64}im_zbb -mabi={ilp32,lp64}
-mno-relax`: both tools agree on all five instructions on both profiles,
byte-for-byte.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt-check`; `make
asm-purity`; `make asm-planted`; `make asm-js-portable`; `make
tools-isa-inventory-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (produces and commits
`asm/fixtures/isa-difficult/cases.jsonl`, reproduced byte-identically across
two separate runs - confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that every one of the 59 pre-existing
cases is byte-for-byte unchanged); `env
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" make
asm-isa-difficult-check` and `... make asm-test` (both with every
cross-toolchain directory stripped from `PATH`, proving the tier-1 gate stays
genuinely toolchain-free); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target, run once uninterrupted after an earlier
in-session race - a concurrent foreground `dune build` against `asm/_build`
while `asm-planted`'s `cp -r asm ...` scratch-copy step was mid-copy -
produced one spurious `cp: cannot stat ...test_isa_norm_riscv.exe` failure;
`make asm-planted` alone and then the full `make asm-ci` both passed cleanly
once nothing else touched `asm/_build` concurrently).

Results and artifact links: 17 new `isa-norm-riscv` checks (5 mnemonics x 3
shape/requirement checks, using each mnemonic's own real, verbatim-extracted
`rv_zbb` riscv32.jsonl record, plus 2 checks proving `andn`'s `rv_zbkb`
`$import` record normalizes to the identical `Req_any` and `form_id` as the
`rv_zbb` primary - the actual point of `Req_any` - 94 total, up from 77).
`isa-gen-difficult` moved 317 -> 368 (51 more): 21 are new checks this slice
added by hand (1 entry-count check plus `test_minmax_domain`'s 2-per-entry x
10 new entries), and the other 30 are the pre-existing, unmodified
`test_no_entry_uses_x0` generically re-covering the 10 new entries' operands
(3 each) the moment they joined `Isa_gen_difficult.all` - confirmed by
diffing a clean-lib/old-test-file build (347, 1 failing on the stale `all`
sum) against a bare pre-change baseline (317). A real
`asm-isa-difficult-regen` run against the new 69-entry corpus (was 59)
reproduced all 69 cases `Pass` (10 new + 59 unchanged), byte-identical across
two runs. `asm-isa-difficult-check`/`asm-test` both pass with every
cross-toolchain directory stripped from `PATH`. `Isa_family_admission`'s
pinned RV32/RV64 promoted-support/blocked totals moved exactly as expected
(22->47/1047->1022, 26->51/1098->1073, `normalized-only` unchanged at 20/30);
`isa-norm-accounting`'s paired totals moved 42->67/56->81 and the
`isa-norm-jsonl` real-form round-trip count moved 116->166, all pinned
`repo_tests.ml` expectations updated and re-verified passing. `tools-test`,
`tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity`,
`asm-planted`, `asm-js-portable`, `tools-isa-inventory-diff`,
`tools-gasxref-diff`, and the full `asm-ci` target all pass.

Unknowns, exceptions and follow-up task IDs: this closes Zbb's five-way
import-duplicated slice (the last named `Req_any` blocker); the rest of Zbb
(population count, sign/zero-extend, byte-reverse) needs a new two-GPR-operand
normalization/encoder shape this project has not built yet, distinct from the
three-operand R-type path every promoted RISC-V form so far reuses, and
remains outside this bounded slice. `Req_any`'s accounting consequence - one
mnemonic's promotion crediting five records, not one, because riscv-opcodes
exports the same instruction once per importing extension - is a real
property of the source data now made visible rather than hidden behind a
single-extension read; a future family with more than five such aliases
would move counts by that many, and this is not itself a defect to fix.
Atomic, CSR, remaining vector, and broader FP families remain GEN-05's own
outstanding scope.

Acceptance gate satisfied: `andn`/`orn`/`xnor`/`rol`/`ror` have real encoder
support (hand-verified against the source mask/value before any test was
written), a real `Req_any` requirement built from a hand-verified alternative-
extension table and machine-checked identical across the primary and at least
one import record for the same instruction (not merely asserted), a
persisted, offline-replayed differential corpus entry each with real GNU
agreement, and admission-matrix promotion - the same measured-Pass discipline
every other GEN-05/GAS-04 promotion used, with every affected pinned count in
the repository's own regression suite updated and re-verified rather than
left stale. The specific missing capability named by the prior two
milestones' deferrals (`Req_any`) is now implemented and exercised, not
merely revisited.

##### GEN-05 continuation: Zbb population-count/sign-extend/byte family via a new two-GPR-operand shape (Claude)

Task / status / owner: GEN-05 Zbb unary sub-slice / done; GEN-05 overall /
still implementing / Claude.

Scope manifest and obligations: admit Zbb's population-count, sign-extend
and byte-processing family - `clz`, `ctz`, `cpop`, `sext.b`, `sext.h`,
`orc.b` (XLEN-independent, single `rv_zbb` record on both profiles) and
their RV64-only `clzw`/`ctzw`/`cpopw` word-operand siblings (`rv64_zbb`, no
RV32 counterpart at all) - the exact family the prior two sub-slices' own
text named as the next outstanding scope. Before picking this family,
grepped every candidate's extension membership the same way the `min`/
`minu`/`max`/`maxu` slice did: `clz`/`ctz`/`cpop`/`sext.b`/`sext.h`/`orc.b`
are each exactly one `rv_zbb` record per profile, no import duplication;
`rev8`/`brev8` (the actual byte-reverse forms, also candidates) are NOT
taken here - riscv-opcodes lists `rev8` once per importing extension (the
same five-way `Req_any` shape `andn`/`orn`/`xnor`/`rol`/`ror` needed) AND
under an XLEN-dependent mnemonic spelling (`rev8` vs the pseudo-op
`rev8.rv32`), stacking two separate pieces of unfinished design work rather
than one - a clean deferral, not an oversight.

This family needed a genuinely new shape, not a reuse of `r_type_gpr_form`:
every riscv-opcodes record here has variable_fields `[rd, rs1]` (two plain
GPR operands) with the *entire* remaining OP-IMM/OP-IMM-32 encoding
(bits 31:20, a full 12-bit funct12) fixed - distinct from `i_type_imm_form`'s
genuine, syntax-visible immediate operand and from every three-operand
R-type mnemonic promoted so far. `riscv_family_encode.ml` gained a new
`unary_imm_desc` table (`Clz -> Some (0x13, 1, 0x600)`, `Ctz -> Some (0x13,
1, 0x601)`, `Cpop -> Some (0x13, 1, 0x602)`, `Sextb -> Some (0x13, 1,
0x604)`, `Sexth -> Some (0x13, 1, 0x605)`, `Orcb -> Some (0x13, 5, 0x287)`,
and the `0x1b`-opcode `Clzw`/`Ctzw`/`Cpopw` siblings at the same funct12
values), hand-verified against the checked-in riscv32.jsonl/riscv64.jsonl
mask/value fields before writing the table; a new `[a; b]`-shaped
`lower_instruction` case builds `Lowered.I` with `imm = const funct12`
directly (the same "bake a fixed constant into an I-type immediate" idiom
the base ISA's own `sext.w` pseudo already uses for `addiw rd, rs, 0`, here
generalized to nine real, distinct funct12 values instead of one always-zero
constant); the decoder gained matching `raw`-value-guarded name lookups plus
an explicit two-operand-vs-three-operand branch in its result builder,
mirroring the existing OP-FP `f_shape_of_name`-driven arity split rather than
assuming every `0x13`/`0x1b` decode is shift-or-addi-shaped.
`Isa_norm_riscv` gained a parallel `unary_gpr_form` (two `Register
{class_ = Riscv_gpr}` operands, syntax `"mnemonic rd, rs1"`, no immediate
operand at all) and `"rv64_zbb" -> Req_all [Req_xlen 64; Req_feature
"riscv:zbb"]` in `feature_of_extension`, mirroring `rv64_zba`'s existing
combination. `Isa_gen_difficult` gained a `zbb_unary_entry` generator
(mirroring `zbb_r_type_entry`, `a0`/`a1` operands, reusing
`zbb_configuration_for` unchanged) producing `clz_entries` through
`cpopw_entries`. `Isa_family_admission.promoted_case` gained the nine
`(form_id, lookup_key)` pairs, the `*w` trio guarded to `Target.Riscv64`.

Real, measured findings: hand-computed expected bytes for all nine
mnemonics from the riscv-opcodes mask/value matched this project's own
`--dump-bytes` output exactly before any corpus wiring, then confirmed
against real GNU `as` (RV32 2.43.1, RV64 2.44) with `-march=rv{32,64}im_zbb
-mabi={ilp32,lp64} -mno-relax`: both tools agree on all nine instructions
(six on both profiles, three on RV64 only), byte-for-byte -
`clz`/`ctz`/`cpop`/`sext.b`/`sext.h` -> `13 95 05 60`/`13 95 15 60`/
`13 95 25 60`/`13 95 45 60`/`13 95 55 60`, `orc.b` -> `13 d5 75 28`,
`clzw`/`ctzw`/`cpopw` -> `1b 95 05 60`/`1b 95 15 60`/`1b 95 25 60`.
Separately confirmed real GNU `as` and this project's own decoder both
round-trip every one of the nine back to canonical text (`--dump-disasm`),
and that RV32 rejects `clzw`/`ctzw`/`cpopw` with an XLEN-only diagnosis on
both tools, matching the `sh1add.uw`-family precedent.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt-check`; `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (produces and commits
`asm/fixtures/isa-difficult/cases.jsonl`; confirmed record-by-record,
ignoring only the git-rev-embedded `ours.tool_label`, that every one of the
69 pre-existing cases is byte-for-byte unchanged); `env
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" make
asm-isa-difficult-check` and `... make asm-test` (both with every
cross-toolchain directory stripped from `PATH`, proving the tier-1 gate
stays genuinely toolchain-free); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target).

Results and artifact links: one new `test_targets.ml`-adjacent decode/encode
round-trip via `--dump-bytes`/`--dump-disasm=canonical` on both profiles
(manual, reported above); 9 new `isa-norm-riscv` checks (a `test_unary_gpr`/
`test_unary_gpr_rv64` helper pair, mirroring `test_r_type_gpr`/
`test_r_type_gpr_rv64`, each against its own real, verbatim-extracted
riscv32.jsonl/riscv64.jsonl record - 133 total, up from 124); new
`isa-gen-difficult` entry-count and domain checks (a `test_unary_gpr_domain`
mirroring `test_minmax_domain`, checking two-GPR-operand shape and Zbb
configuration - 430 total, up from 368). A real `asm-isa-difficult-regen`
run against the now-84-entry corpus (was 69) reproduced all 84 cases with
`verdict = Pass`, including the 15 new cases (12 XLEN-independent + 3
RV64-only), byte-identical across the diff-against-HEAD check above.
`asm-isa-difficult-check`/`asm-test` both pass with every cross-toolchain
directory stripped from `PATH`; `make asm-ci` passes in full.
`Isa_family_admission`'s pinned RV32/RV64 totals moved exactly as expected:
promoted-support 47->53 / 51->60, blocked 1022->1016 / 1073->1064,
normalized-only unchanged (20/30) since every new form is promoted directly;
`isa-norm-accounting`'s paired totals moved 67->73 / 81->90 and the
`isa-norm-jsonl` real-form round-trip count moved 166->181, all pinned
`repo_tests.ml` expectations updated and re-verified passing. `tools-test`,
`tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity`,
`asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all pass
unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: `rev8`/`brev8` remain a named,
counted blocker requiring BOTH `Req_any` (already implemented, reusable) AND
an XLEN-dependent mnemonic-spelling decision (`rev8` vs `rev8.rv32`) this
slice does not make. The rest of Zbb beyond this family and the prior
`min`/`minu`/`max`/`maxu`/`andn`/`orn`/`xnor`/`rol`/`ror` sub-slices - none
remain unhandled in `rv_zbb`/`rv64_zbb` except `rev8`/`brev8` themselves,
hand-confirmed by grepping both profiles' checked-in exports for the
extension name. Atomic, CSR, remaining vector, and broader FP families
remain GEN-05's own outstanding scope.

Acceptance gate satisfied: `clz`/`ctz`/`cpop`/`sext.b`/`sext.h`/`orc.b`/
`clzw`/`ctzw`/`cpopw` have real encoder support via a new, hand-verified
two-GPR-operand encoding shape (distinct from every three-operand R-type
form promoted so far), matching decoder round-trip on both profiles,
source-derived normalization via a parallel `unary_gpr_form`, matched
RV64-only rejection on both GNU and this project's own assembler for the
word-operand trio, a persisted, offline-replayed differential corpus entry
each with real GNU agreement, and admission-matrix promotion - the same
measured-Pass discipline every other GEN-05/GAS-04 promotion used, with
every affected pinned count in the repository's own regression suite
updated and re-verified rather than left stale. The specific missing
capability the prior sub-slice deferred to a "later GEN task" (a
two-operand normalization/encoder shape) is now implemented and exercised.

##### GEN-05 continuation: Zbkb `brev8` via the unary shape plus a four-way `Req_any` (Claude)

Task / status / owner: GEN-05 Zbkb unary sub-slice / done; GEN-05 overall /
still implementing / Claude.

Scope manifest and obligations: admit `brev8` (Zbkb's within-byte
bit-reverse), the next clean candidate after the population-count/
sign-extend/byte slice's own text named `rev8`/`brev8` as the remaining
Zbb-family blockers. Splitting that pair apart: `brev8` is a plain
four-way `Req_any` (riscv-opcodes' primary record is `rv_zbkb`, imported by
`rv_zk`/`rv_zkn`/`rv_zks` as `pseudo-op`-kind records with a
`specializes`/`specializes-reference` relationship rather than `andn`'s
`$import`/`imports` shape - `Isa_norm_riscv.requirement_of_any` only reads
`provenance.extension`, so this shape difference does not matter) with the
IDENTICAL mnemonic and encoding on both profiles - unlike `rev8`, whose own
mnemonic changes with XLEN (`rev8` on RV64, the pseudo-op `rev8.rv32` on
RV32) on top of needing the same four/five-way `Req_any`. Hand-verified
identical mask/value across all four extension files in both checked-in
profiles before writing any code (`0xfff0707f`/`0x68705013`, funct3 5,
funct12 0x687).

Mechanically this reuses two already-built pieces rather than adding a
third: the two-GPR-operand `unary_imm_desc`/`unary_gpr_form` shape the prior
sub-slice built, and the `Req_any`/`alternative_extensions_by_mnemonic`
machinery the `andn`/`orn`/`xnor`/`rol`/`ror` sub-slice built - `brev8`
needed no new capability, only a new table entry in each.
`riscv_family_encode.ml`'s `Opcode.t`/`unary_imm_desc` gained `Brev8 ->
Some (0x13, 5, 0x687)` (no RV64-only gate needed, since `brev8` is
XLEN-independent) and the matching decoder `raw`-guarded name lookup plus
the two-operand arity branch. `Isa_norm_riscv.alternative_extensions_by_mnemonic`
gained a new `zbkb_import_group = ["rv_zbkb"; "rv_zk"; "rv_zkn"; "rv_zks"]`
or `("brev8", zbkb_import_group)` - a genuinely different four-way group
from `andn`'s five-way `zbb_import_group` (`brev8`'s own primary extension
is `rv_zbkb`, not `rv_zbb`); `unary_gpr_form` already dispatches through
`requirement_of_mnemonic`, so no change was needed there to pick up the new
table entry. `Isa_gen_difficult` gained a dedicated `zbkb_configuration_for`
(`-march=rv{32,64}i_zbkb`, mirroring `zbb_configuration_for`'s shape) and
`brev8_entry`/`brev8_entries` (2 cases, `a0, a1`, exercising only the
primary `rv_zbkb` configuration - the same "one configuration proves
promotion" discipline every prior `Req_any` slice used).
`Isa_family_admission.promoted_case` gained the `("riscv:brev8", "brev8")`
pair for both profiles.

Real, measured findings: hand-computed expected bytes for `brev8 a0, a1`
from the riscv-opcodes mask/value (`13 d5 75 68`) matched this project's own
`--dump-bytes` output exactly before any corpus wiring, then confirmed
against real GNU `as` (RV32 2.43.1 via `-march=rv32i_zbkb`, RV64 2.44 via
`-march=rv64i_zbkb`, both `-mno-relax`): both tools agree, byte-for-byte,
identically on both profiles (unlike every prior Zb-family slice, which
needed separate RV32/RV64 bytes because of the differing base-ISA
suffix - `brev8`'s own bytes are the same string on both profiles since
neither the opcode nor the operands depend on XLEN). Decoder round-trip
(`--dump-disasm=canonical`) confirmed on both profiles too.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt-check`; `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (produces and commits
`asm/fixtures/isa-difficult/cases.jsonl`; confirmed record-by-record,
ignoring only the git-rev-embedded `ours.tool_label`, that every one of the
84 pre-existing cases is byte-for-byte unchanged); `env
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" make
asm-isa-difficult-check` and `... make asm-test` (both with every
cross-toolchain directory stripped from `PATH`, proving the tier-1 gate
stays genuinely toolchain-free); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target).

Results and artifact links: 5 new `isa-norm-riscv` checks (`test_brev8`
against the real, verbatim-extracted `rv_zbkb` riscv32.jsonl record, plus
`test_brev8_pseudo_record_matches_primary` proving the `rv_zk` pseudo-op
record normalizes to the identical `Req_any` and `form_id` as the `rv_zbkb`
primary - the actual point of `Req_any`, the same proof `andn`'s own import
record gave - 129 total, up from 124); one new `isa-gen-difficult`
entry-count check plus the existing `test_unary_gpr_domain` extended to
cover `brev8_entries` (its two-GPR-operand, no-immediate shape and Zbkb
configuration). A real `asm-isa-difficult-regen` run against the now-86-entry
corpus (was 84) reproduced all 86 cases with `verdict = Pass`, including the
2 new `brev8` cases, with every one of the 84 pre-existing cases confirmed
byte-for-byte unchanged (ignoring only the git-rev-embedded
`ours.tool_label`). `asm-isa-difficult-check`/`asm-test` both pass with
every cross-toolchain directory stripped from `PATH`; `make asm-ci` passes
in full. `Isa_family_admission`'s pinned RV32/RV64 totals moved exactly as
expected: promoted-support 53->57 / 60->64, blocked 1016->1012 / 1064->1060,
normalized-only unchanged (20/30); `isa-norm-accounting`'s paired totals
moved 73->77 / 90->94 and the `isa-norm-jsonl` real-form round-trip count
moved 181->189, all pinned `repo_tests.ml` expectations updated and
re-verified passing. `tools-test`, `tools-integration`, `tools-boundary`,
`asm-fmt-check`, `asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`,
`tools-gasxref-diff` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: `rev8`/`rev8.rv32` remain the
one still-outstanding named blocker in this immediate family - unlike
`brev8`, admitting them needs BOTH the `Req_any` machinery (already built,
reusable) AND a genuinely new capability this slice does not add: deciding
how a normalized form's mnemonic/`native_name` can differ by XLEN while
keeping one stable `form_id`, or else accepting two separate `form_id`s for
what is architecturally one instruction. That design decision is left named
and specific, not guessed at here. With `brev8` closed, no further named
`rv_zbb`/`rv64_zbb`/`rv_zbkb`-family blocker remains from the population-
count/sign-extend/byte/bit-reverse group except `rev8`/`rev8.rv32`
themselves. Atomic, CSR, remaining vector, and broader FP families remain
GEN-05's own outstanding scope.

Acceptance gate satisfied: `brev8` has real encoder support reusing the
existing two-GPR-operand shape, a real four-way `Req_any` requirement built
from a hand-verified alternative-extension table and machine-checked
identical across the primary and an import (pseudo-op) record for the same
instruction, a persisted, offline-replayed differential corpus entry with
real GNU agreement on both profiles (proven identical byte-for-byte, not
merely each separately correct), and admission-matrix promotion - the same
measured-Pass discipline every other GEN-05/GAS-04 promotion used, with
every affected pinned count in the repository's own regression suite
updated and re-verified rather than left stale. Composing two previously
separate capabilities (`Req_any`, the unary shape) for a new mnemonic
without adding a third is itself evidence those two abstractions were cut
at the right joints.

##### GEN-05 continuation: `rev8` closes the family (Claude)

Task / status / owner: GEN-05 Zbb/Zbkb byte-reverse sub-slice / done; GEN-05
overall / still implementing / Claude. Closes the last named blocker in the
population-count/sign-extend/byte-reverse family the prior three sub-slices
worked through.

Scope manifest and obligations: the prior sub-slice's own text described
`rev8`/`rev8.rv32` as needing "an XLEN-dependent mnemonic spelling" it did
not attempt. Investigating that claim directly (rather than accepting the
deferral) found it overstated: real `riscv32-linux-gnu-as`/`riscv64-linux-gnu-as`
both assemble the bare mnemonic `rev8` - GNU as REJECTS riscv-opcodes' own
"rev8.rv32" spelling outright on both toolchains
(`Error: unrecognized opcode 'rev8.rv32 a0,a1'`), confirmed before writing
any code. "rev8.rv32" is a riscv-opcodes-internal disambiguation label (its
table needs two distinct rows for one GAS mnemonic whose bit pattern
differs by XLEN), not a second user-facing spelling. This means the two
profiles' records normalize to the same rendered mnemonic and `form_id`
("riscv:rev8") - the "one stable form_id" half of the design question the
prior milestone posed - while each keeps its OWN five-way `Req_any` (RV64:
`rv64_zbb`/`rv64_zbkb`/`rv64_zk`/`rv64_zkn`/`rv64_zks`; RV32:
`rv32_zbkb`/`rv32_zbb`/`rv32_zk`/`rv32_zkn`/`rv32_zks` - a DISJOINT
extension-name set from RV64's, hand-verified identical mask/value across
all five records in each profile before writing any code) and its own
`native_name` evidence field, since those genuinely are per-profile facts.

`riscv_family_encode.ml` gained one `Rev8` opcode (mnemonic `"rev8"`, no
second variant for `"rev8.rv32"`, since that spelling is never real GAS
syntax to parse or print): `unary_imm_desc`'s `Rev8` case is the first
unary-shape entry with an XLEN-DEPENDENT funct12 (`0x6b8` when `xlen = 64`,
`0x698` otherwise), mirroring `i_desc`'s existing `Srai` precedent for an
XLEN-conditional table entry rather than adding a second mechanism; the
decoder's raw-value guard and two-operand arity branch both gained the
matching `if xlen = 64 then ... else ...` conditional and `"rev8"` name.
No RV64-only (or RV32-only) gate was added, since - unlike every other `*w`/
`*.uw` sibling in this family - `rev8` genuinely assembles on both profiles.

`Isa_norm_riscv.feature_of_extension` gained five new entries
(`rv64_zbkb`/`rv64_zk`/`rv64_zkn`/`rv64_zks` at `Req_xlen 64`, and
`rv32_zbb`/`rv32_zbkb`/`rv32_zk`/`rv32_zkn`/`rv32_zks` at `Req_xlen 32` -
`Req_xlen` already models `32` as validly as `64`, so this is the same
existing capability, not a new one). `unary_gpr_form` gained an optional
`?extension_lookup_key` parameter, defaulting to `mnemonic`, so its
`Req_any` lookup can be keyed independently of the rendered mnemonic - the
one new, real capability this sub-slice needed, used by exactly one caller.
`normalize`'s dispatch gained two explicit arms (not folded into the
`unary_gpr_mnemonics` list, since neither shares that list's "native_name
equals rendered mnemonic" assumption): `"rev8" -> unary_gpr_form
~mnemonic:"rev8" rec_` and `"rev8.rv32" -> unary_gpr_form ~mnemonic:"rev8"
~extension_lookup_key:"rev8.rv32" rec_`. `Isa_gen_difficult` gained
`rev8_entry ~lookup_key target` (reusing `zbkb_configuration_for`
unchanged) and `rev8_entries`, one per profile with the profile-specific
`lookup_key` ("rev8" / "rev8.rv32") but the identical rendered
`a0, a1`-operand source line on both. `Isa_family_admission.promoted_case`
gained both `(target, form_id, lookup_key)` triples.

Real, measured findings: hand-computed expected bytes for `rev8 a0, a1`
from each profile's own riscv-opcodes mask/value (RV64 `0x6b805013` ->
`13 d5 85 6b`; RV32 `0x69805013` -> `13 d5 85 69`) matched this project's
own `--dump-bytes` output exactly on each profile before any corpus wiring,
then confirmed against real GNU `as` (RV32 2.43.1 via `-march=rv32i_zbkb`,
RV64 2.44 via `-march=rv64i_zbkb`, both `-mno-relax`): both tools agree,
byte-for-byte, on each profile's own distinct bytes (unlike `brev8`, whose
bytes were identical across profiles - `rev8`'s genuinely are not).
Cross-checked negatively too: real GNU as on RV64 rejects "rev8.rv32" as an
unrecognized opcode, and real RV32 as accepts the bare "rev8" spelling
directly (not "rev8.rv32") - both confirming the design choice empirically
rather than assuming it. Decoder round-trip (`--dump-disasm=canonical`)
confirmed "rev8 x10, x11" on both profiles.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt-check`; `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (produces and commits
`asm/fixtures/isa-difficult/cases.jsonl`; confirmed record-by-record,
ignoring only the git-rev-embedded `ours.tool_label`, that every one of the
86 pre-existing cases is byte-for-byte unchanged); `env
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" make
asm-isa-difficult-check` and `... make asm-test` (both with every
cross-toolchain directory stripped from `PATH`, proving the tier-1 gate
stays genuinely toolchain-free); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target).

Results and artifact links: 9 new `isa-norm-riscv` checks (`test_rev8`
against the real, verbatim-extracted `rv64_zbb` riscv64.jsonl record;
`test_rev8_pseudo_record_matches_primary` proving the `rv64_zk` pseudo-op
record normalizes to the identical `Req_any`/`form_id`; `test_rev8_rv32`
against the real, verbatim-extracted `rv32_zbkb` riscv32.jsonl record,
explicitly checking `form_id = "riscv:rev8"`, `native_name = "rev8.rv32"`
(preserved as evidence), rendered syntax `"rev8 rd, rs1"` (not
`"rev8.rv32 rd, rs1"`), and its own disjoint RV32 `Req_any` group); one new
`isa-gen-difficult` entry-count check (confirming the two entries carry
different `lookup_key`s on their respective profiles) plus the existing
`test_unary_gpr_domain` extended to cover `rev8_entries`. A real
`asm-isa-difficult-regen` run against the now-88-entry corpus (was 86)
reproduced all 88 cases with `verdict = Pass`, including the 2 new `rev8`
cases (each profile's own distinct bytes), with every one of the 86
pre-existing cases confirmed byte-for-byte unchanged (ignoring only the
git-rev-embedded `ours.tool_label`). `asm-isa-difficult-check`/`asm-test`
both pass with every cross-toolchain directory stripped from `PATH`; `make
asm-ci` passes in full. `Isa_family_admission`'s pinned RV32/RV64 totals
moved exactly as expected: promoted-support 57->62 / 64->69, blocked
1012->1007 / 1060->1055, normalized-only unchanged (20/30);
`isa-norm-accounting`'s paired totals moved 77->82 / 94->99 and the
`isa-norm-jsonl` real-form round-trip count moved 189->199, all pinned
`repo_tests.ml` expectations updated and re-verified passing. `tools-test`,
`tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity`,
`asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all pass
unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: this closes every named
blocker in the population-count/sign-extend/byte-processing/byte-reverse
Zbb/Zbkb family this and the prior three sub-slices worked through -
hand-confirmed by grepping both profiles' checked-in exports for
`rv_zbb`/`rv64_zbb`/`rv32_zbb`/`rv_zbkb`/`rv64_zbkb`/`rv32_zbkb` records: no
remaining unhandled native_name in that group. The rest of Zbkb
(`pack`/`packh`/`packw`/`zip`/`unzip`, most needing their own two-operand or
new three-operand shapes and further per-profile mnemonic splits like
`zip`/`unzip` themselves show), the rest of Zk/Zkn/Zks (AES/SHA
rounds, mostly `import`-kind records already layered on Zbkb primitives),
atomic, CSR, remaining vector, and broader FP families remain GEN-05's own
outstanding scope, each a concrete, named, not-yet-investigated candidate
rather than a vague "more work remains."

Acceptance gate satisfied: `rev8` has real encoder support via an
XLEN-conditional table entry (the same mechanism `srai` already
established, not a new one), decoder support confirmed round-tripping on
both profiles with each profile's own distinct bytes, source-derived
normalization unifying two upstream native names into one form_id/rendered
mnemonic ONLY after confirming empirically that real GNU as itself treats
them as one instruction, a persisted, offline-replayed differential corpus
entry per profile with real GNU agreement on each profile's own bytes, and
admission-matrix promotion - the same measured-Pass discipline every other
GEN-05/GAS-04 promotion used, with every affected pinned count in the
repository's own regression suite updated and re-verified rather than left
stale. The "unresolved design decision" the prior milestone flagged turned
out to have an empirical answer rather than an arbitrary one, and this
sub-slice found that answer before writing any normalization code.

##### GEN-05 continuation: Zbkb `pack`/`packh`/`packw`/`zip`/`unzip` (Claude)

Task / status / owner: GEN-05 Zbkb pack/zip sub-slice / done; GEN-05
overall / still implementing / Claude.

Scope manifest and obligations: admit the rest of Zbkb's plain (non-AES/
SHA-adjacent) instructions. `pack`/`packh` are a plain three-GPR R-type pair
(opcode 0x33, funct7 0x04, funct3 selects low-half-pack vs byte-pack),
identical mnemonic/encoding on both profiles, each a four-way `Req_any`
(`rv_zbkb` primary + `rv_zk`/`rv_zkn`/`rv_zks` imports) - the exact shape
`r_type_gpr_form` and the existing `Req_any` machinery already handle,
needing only new table entries, not new code paths. `packw` is their
RV64-only word-operand sibling (opcode 0x3b, `rv64_zbkb` primary + three
`rv64_*` imports, no RV32 counterpart at all). `zip`/`unzip` (bit
interleave/de-interleave) are RV32-only two-GPR unary forms (`rv32_zbkb`
primary + three `rv32_*` imports, no RV64 counterpart at all, confirmed:
real `riscv64-linux-gnu-as` rejects `zip` as an unrecognized opcode) -
exactly `unary_gpr_form`'s existing shape. Every mask/value was hand-verified
against the checked-in riscv32.jsonl/riscv64.jsonl before writing any code.

`riscv_family_encode.ml` gained `Pack`/`Packh`/`Packw` (`r_desc` entries
`(0x33,4,0x04)`/`(0x33,7,0x04)`/`(0x3b,4,0x04)`, `Packw` joining the
existing RV64-only gate) and `Zip`/`Unzip` (`unary_imm_desc` entries
`(0x13,1,0x08f)`/`(0x13,5,0x08f)`) - the first RV32-only forms in this
project, needing a genuinely new gate direction: a new `` `Rv32_only ``
error-kind variant (mirroring the existing `` `Rv64_only ``) and an explicit
`(Opcode.Zip | Unzip), _ when xlen <> 32 -> Error (... `Rv32_only opn)`
lowering-side check. The decoder's raw-value guards gained matching
entries, with `zip`/`unzip`'s additionally gated `xlen = 32 &&` (unlike
`rev8`'s "valid on both profiles, different funct12" shape, a word matching
`zip`'s funct12 could otherwise misdecode on RV64 where the mnemonic does
not exist). `Isa_norm_riscv` needed NO new feature-mapping entries - every
`rv32_*`/`rv64_*` extension name pack/packw/zip/unzip's Req_any groups
reference was already added for `rev8`/`rev8.rv32` - only new
`alternative_extensions_by_mnemonic` table rows and `r_type_mnemonics`/
`unary_gpr_mnemonics` list entries. `Isa_gen_difficult` gained
`zbkb_r_type_entry`/`zbkb_unary_entry` (mirroring `zbb_r_type_entry`/
`zbb_unary_entry`, reusing `zbkb_configuration_for` unchanged) and the five
new mnemonics' entries. `Isa_family_admission.promoted_case` gained the
matching triples, `packw` guarded to `Target.Riscv64` and `zip`/`unzip` to
`Target.Riscv32`.

Real, measured findings: hand-computed expected bytes for all five
mnemonics from their own riscv-opcodes mask/value matched this project's
own `--dump-bytes` output exactly before any corpus wiring, then confirmed
against real GNU `as` (RV32 2.43.1, RV64 2.44): `pack`/`packh` byte-identical
on both profiles (`33 c5 c5 08`/`33 f5 c5 08`), `packw` on RV64
(`3b c5 c5 08`), `zip`/`unzip` on RV32 (`13 95 f5 08`/`13 d5 f5 08`).
Cross-checked negatively: real RV64 `as` rejects `packw` on RV32 and `zip`
on RV64 with "unrecognized opcode" (RV32 rejects `packw` and RV64 rejects
`zip` symmetrically), matching this project's own `` `Rv64_only ``/
`` `Rv32_only `` rejections exactly. Decoder round-trip confirmed on the
applicable profile for each.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt-check`; `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (produces and commits
`asm/fixtures/isa-difficult/cases.jsonl`; confirmed record-by-record,
ignoring only the git-rev-embedded `ours.tool_label`, that every one of the
88 pre-existing cases is byte-for-byte unchanged); `env
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" make
asm-isa-difficult-check` and `... make asm-test` (both with every
cross-toolchain directory stripped from `PATH`, proving the tier-1 gate
stays genuinely toolchain-free); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target).

Results and artifact links: 15 new `isa-norm-riscv` checks (`test_pack`/
`test_packh` reusing a generalized `test_r_type_gpr_any ~import_group`;
`test_packw`/`test_zip`/`test_unzip` against their own real,
verbatim-extracted riscv32.jsonl/riscv64.jsonl records); new
`isa-gen-difficult` entry-count checks for all five mnemonics (RV64-only/
RV32-only target restrictions asserted directly) plus the existing R-type/
unary domain tests extended to cover them. A real `asm-isa-difficult-regen`
run against the now-95-entry corpus (was 88) reproduced all 95 cases with
`verdict = Pass`, including the 7 new cases, with every one of the 88
pre-existing cases confirmed byte-for-byte unchanged (ignoring only the
git-rev-embedded `ours.tool_label`). `asm-isa-difficult-check`/`asm-test`
both pass with every cross-toolchain directory stripped from `PATH`; `make
asm-ci` passes in full. `Isa_family_admission`'s pinned RV32/RV64 totals
moved exactly as expected: promoted-support 62->78 / 69->81, blocked
1007->991 / 1055->1043, normalized-only unchanged (20/30);
`isa-norm-accounting`'s paired totals moved 82->98 / 99->111 and the
`isa-norm-jsonl` real-form round-trip count moved 199->227, all pinned
`repo_tests.ml` expectations updated and re-verified passing. `tools-test`,
`tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity`,
`asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all pass
unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: grepping
`rv_zbkb`/`rv32_zbkb`/`rv64_zbkb` in both profiles after this slice shows
`brev8`/`rev8`/`pack`/`packh`/`packw`/`zip`/`unzip` is NOT the complete set
- checked directly rather than assumed, this leaves `rolw`/`rorw` (RV64-only
word-operand siblings of the already-promoted `rol`/`ror`, the identical
three-GPR R-type shape at opcode 0x3b with the same primary/import extension
set - a same-shape follow-on, not new design work), `rori`/`roriw`/
`rori.rv32` (rotate-*immediate*, an I-type-with-shift-amount shape this
project has not built for any Zb mnemonic yet, combined with `rori.rv32`'s
own rev8-style per-profile native-name split), and `zext.h`/`zext.h.rv32`
(a single-extension, non-`Req_any` unary pseudo per profile, cheaper than
`rori` but still needing the same per-profile-name handling `rev8` used)
still unhandled. None of these is investigated beyond this grep; each is a
named, concrete next candidate rather than an assumed-closed extension. The
rest of Zk/Zkn/Zks (AES/SHA round functions -
`aes32dsi`/`aes32dsmi`/`aes32esi`/`aes32esmi`,
`sha512sig0h`/`sha512sig0l`/`sha512sig1h`/`sha512sig1l`/`sha512sum0r`/
`sha512sum1r`, mostly `import`-kind records with genuine multi-operand
shapes this project has not investigated), atomic, CSR, remaining vector,
and broader FP families remain GEN-05's own outstanding scope.

Acceptance gate satisfied: all five mnemonics have real encoder support via
existing R-type/unary shapes plus one new, symmetric `` `Rv32_only `` gate
(mirroring the pre-existing `` `Rv64_only ``), matching decoder round-trip
and rejection confirmed against real GNU as on both profiles, source-derived
normalization needing zero new feature-mapping entries, a persisted,
offline-replayed differential corpus entry each with real GNU agreement,
and admission-matrix promotion - the same measured-Pass discipline every
other GEN-05/GAS-04 promotion used, with every affected pinned count in the
repository's own regression suite updated and re-verified rather than left
stale. Zbkb is NOT fully closed - `rolw`/`rorw`/`rori`/`roriw`/`rori.rv32`
remain, named above rather than assumed away.

##### GEN-05 continuation: Zbb `rolw`/`rorw` (Claude)

Task / status / owner: GEN-05 rolw/rorw sub-slice / done; GEN-05 overall /
still implementing / Claude.

Scope manifest and obligations: the cheapest of the three follow-ups the
prior Zbkb slice named - `rolw`/`rorw` are `rol`/`ror`'s RV64-only
word-operand siblings, the identical three-GPR R-type shape at opcode 0x3b
(funct3 1/5, funct7 0x30) with `rev8`'s own five-way rv64-prefixed extension
set (primary `rv64_zbb`, imported by `rv64_zbkb`/`rv64_zk`/`rv64_zkn`/
`rv64_zks`) - confirmed by grep to be verbatim the same list already
captured as `rev8_import_group_rv64`, reused directly rather than
duplicated. riscv-opcodes has no RV32 record for either mnemonic at all
(confirmed: real `riscv32-linux-gnu-as` rejects both as unrecognized
opcodes, not merely as missing an extension). Every mask/value was
hand-verified against the checked-in riscv64.jsonl before writing any code.

`riscv_family_encode.ml` gained `Rolw`/`Rorw` (`r_desc` entries
`(0x3b,1,0x30)`/`(0x3b,5,0x30)`, joining the existing RV64-only gate
alongside `Packw` and friends; matching decoder `r_name` entries). No new
gate direction was needed - this is the same RV64-only shape `packw`/
`clzw`/`ctzw`/`cpopw` already established. `Isa_norm_riscv` needed no new
feature-mapping entries either: `rolw`/`rorw` reuse `rev8_import_group_rv64`
verbatim in `alternative_extensions_by_mnemonic`, and are plain three-GPR
R-type forms so join the existing `r_type_mnemonics` list. `Isa_gen_difficult`
gained `rolw_entries`/`rorw_entries` via the existing `zbb_r_type_entry`
helper restricted to `Target.Riscv64` (mirroring `packw_entries`'s own
single-target restriction). `Isa_family_admission.promoted_case` gained the
matching triple, gated to `Target.Riscv64`.

Real, measured findings: hand-computed expected bytes for both mnemonics
from their own riscv-opcodes mask/value (`rolw a0,a1,a2` = `0x60c5953b`,
`rorw a0,a1,a2` = `0x60c5d53b`) matched this project's own `--dump-bytes`
output exactly before any corpus wiring, then confirmed against real GNU
`as` (RV64 2.44): byte-identical (`3b 95 c5 60`/`3b d5 c5 60` little-endian).
Cross-checked negatively on RV32 2.43.1: real `riscv32-linux-gnu-as` rejects
both as `unrecognized opcode` (not an extension-gate message - the mnemonics
genuinely do not exist on RV32), matching this project's own `` `Rv64_only ``
rejection on `--target riscv32`.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt`/`asm-fmt-check`;
`make asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 95 to 97 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that all 95 pre-existing cases are
byte-for-byte unchanged and exactly the 2 expected new case_ids were added);
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
asm-isa-difficult-check asm-test`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target).

Results and artifact links: 2 new `isa-norm-riscv` checks (`test_rolw`/
`test_rorw`, reusing `rev8_import_group_rv64` against their own real,
verbatim-extracted riscv64.jsonl records); new `isa-gen-difficult`
entry-count checks asserting both are RV64-only, plus the existing 3-GPR
domain test (`test_minmax_domain`) extended to cover them. A real
`asm-isa-difficult-regen` run against the now-97-entry corpus reproduced all
97 cases with `verdict = Pass`, including the 2 new ones, with every one of
the 95 pre-existing cases confirmed byte-for-byte unchanged (ignoring only
the git-rev-embedded `ours.tool_label`). `asm-isa-difficult-check`/`asm-test`
both pass; `make asm-ci` passes in full. `Isa_family_admission`'s pinned
RV64 totals moved exactly as expected: promoted-support 81->91, blocked
1043->1033 (RV32 unaffected: `rolw`/`rorw` have no RV32 record at all);
`isa-norm-accounting`'s RV64 total moved 111->121 and the `isa-norm-jsonl`
real-form round-trip count moved 227->237 (both +10, matching the 5
records-per-mnemonic x 2 mnemonics the `Req_any` group promotes), all pinned
`repo_tests.ml` expectations updated and re-verified passing on the first
attempt (computed from first principles before running, not adjusted after
a failure). `tools-test`, `tools-integration`, `tools-boundary`,
`asm-fmt-check`, `asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`,
`tools-gasxref-diff` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: `rori`/`roriw`/`rori.rv32`
(rotate-*immediate*, an I-type-with-shift-amount shape this project has not
built for any Zb mnemonic yet, combined with `rori.rv32`'s own rev8-style
per-profile native-name split) and `zext.h`/`zext.h.rv32` (a
single-extension, non-`Req_any` unary pseudo per profile, cheaper than
`rori` but still needing the same per-profile-name handling `rev8` used)
remain the concrete named follow-ups from the prior slice - neither
attempted here, both still open. The rest of Zk/Zkn/Zks (AES/SHA round
functions), atomic, CSR, remaining vector, and broader FP families remain
GEN-05's own outstanding scope, unchanged from the prior slice's writeup.

Acceptance gate satisfied: both mnemonics have real encoder support via the
existing RV64-only R-type shape (no new gate direction needed), matching
decoder round-trip and rejection confirmed against real GNU as on both
profiles (including the RV32 "unrecognized opcode" negative check),
source-derived normalization reusing an existing `Req_any` group verbatim
(zero new feature-mapping entries), a persisted, offline-replayed
differential corpus entry each with real GNU agreement, and admission-matrix
promotion - the same measured-Pass discipline every other GEN-05/GAS-04
promotion used, with every affected pinned count in the repository's own
regression suite updated and re-verified rather than left stale.

##### GEN-05 continuation: Zbb `rori`/`rori.rv32`/`roriw` (Claude)

Task / status / owner: GEN-05 rori/roriw sub-slice / done; GEN-05 overall /
still implementing / Claude.

Scope manifest and obligations: the harder of the two named follow-ups from
the Zbkb pack/zip slice - `rori`/`rori.rv32`/`roriw` are Zbb's rotate-
*immediate* forms, needing a genuinely new normalization/encoder shape (two
GPR operands plus a real, syntax-visible unsigned shift-amount immediate)
that no prior GEN-05 sub-slice had built. riscv-opcodes models this
oddly: `rori` (opcode 0x13, funct3 5) is defined ONLY on RV64 as an
"instruction-form" record (`rv64_zbb` primary, imported by
`rv64_zbkb`/`rv64_zk`/`rv64_zkn`/`rv64_zks` - `rev8`'s own five-way
rv64-prefixed group verbatim) with a 6-bit `shamtd` field (bits[25:20],
funct_hi bits[31:26] = 0x18); RV32's version is exported purely as a
"pseudo-op" alias `rori.rv32` (all 5 `rv32_zbb`/`zbkb`/`zk`/`zkn`/`zks`
records, `rev8`'s rv32-prefixed group verbatim) specializing
`rv64_zbb::rori`, with a 5-bit `shamtw` field (bits[24:20], funct_hi
bits[31:25] = 0x30) - there is no RV32 "instruction-form" `rori` record at
all. `roriw` (RV64-only, opcode 0x1b) is the plain *w sibling with the same
5-bit shamtw/funct_hi=0x30 shape as `rori.rv32`, just at the word opcode
instead of RV32's native one - confirmed by grep across both checked-in
profiles before writing any code, and confirmed that real
`riscv32-linux-gnu-as` rejects `roriw` outright as an unrecognized opcode
(not merely missing an extension).

`riscv_family_encode.ml` gained `Rori`/`Roriw` opcodes, reusing the
EXISTING `i_desc`/`Lowered.I` shift-immediate machinery (`funct_hi`,
`shamt_bits`) that `slli`/`srli`/`srai`/`*iw` already use - no new encoder
plumbing needed, just two more `i_desc` table rows mirroring `srai`'s own
XLEN-conditional-funct_hi style exactly: `Rori -> Some (0x13, 5, (if xlen =
64 then 0x18 else 0x30), Some xlen)`, `Roriw -> Some (0x1b, 5, 0x30, Some
32)`. `Roriw` joined the existing RV64-only gate (`Rori` itself needs none -
it is valid, with a different funct_hi/shamt width, on both profiles, the
same as `Srai`). Also discovered and added the real `ror`/`rorw` ->
`rori`/`roriw` GAS immediate-aliases to `imm_alias` (confirmed:
`ror a0, a1, 5` assembles as `rori`) - and confirmed `rol`/`rolw` have NO
such alias (`rol a0, a1, 5` is rejected as "illegal operands", since a
left-rotate-by-immediate is redundant with `rori`'s complementary shift
amount and Zbb never defined a `roli`). Decoder gained two `funct_shift`
match arms in the existing generic OP-IMM/OP-IMM-32 shift-decode path
(`0x13, 5, 0x18/0x30 -> "rori"`, `0x1b, 5, 0x30 -> "roriw"`) - the
existing generic 3-operand shift reconstruction at the bottom of that
branch handles operand decoding with no further change.

`Isa_norm_riscv` gained a new `shamt_gpr_form` function (rd, rs1, shamt -
`Immediate` operand kind, unsigned, `width_bits` 5 or 6, one `bit_run`
named `shamtw`/`shamtd` matching riscv-opcodes' own field name), the first
form in this project with a genuine unsigned narrow immediate rather than
a fixed-funct12 pseudo-unary ({!unary_gpr_form}) or a signed 12-bit one
({!i_type_imm_form}). `rori`/`rori.rv32` dispatch through it exactly like
`rev8`/`rev8.rv32` do through `unary_gpr_form`: one canonical rendered
mnemonic ("rori") and `form_id` ("riscv:rori") for both, `extension_lookup_key`
threaded through only for the `alternative_extensions_by_mnemonic` lookup
that differs by profile. All three mnemonics' Req_any groups reuse
`rev8_import_group_rv64`/`rev8_import_group_rv32` verbatim (hand-confirmed
identical membership by grep, not assumed) - zero new import-group lists
needed. `Isa_gen_difficult` gained a `zbb_shamt_entry` helper (mirroring
`zbb_r_type_entry`'s shape but with an `("shamt","5")` third operand) and
`rori_entries`/`roriw_entries`; `Isa_family_admission.promoted_case` gained
the three matching triples (`rori`'s RV32 case keyed by lookup_key
"rori.rv32", matching form_id "riscv:rori").

Real, measured findings: hand-computed expected bytes for all three from
their own riscv-opcodes mask/value (verified via Python bit-packing before
touching any code) matched this project's own `--dump-bytes`/
`--dump-disasm=canonical` output exactly on both profiles, then confirmed
against real GNU `as` (RV32 2.43.1, RV64 2.44): `rori a0, a1, 5` byte-
identical on both profiles (`13 d5 55 60` little-endian = `0x6055d513`),
`roriw a0, a1, 5` on RV64 (`1b d5 55 60` = `0x6055d51b`); real GNU `as`
disassembles both back as `rori`/`roriw` (not `ror`/`rorw`) on RV64,
confirming this project's own decoder naming choice. Cross-checked
negatively: real `riscv32-linux-gnu-as` rejects `roriw` as an unrecognized
opcode, matching this project's own `` `Rv64_only `` rejection. The
`ror`/`rorw` -> `rori`/`roriw` GAS alias and the `rol`/`rolw` non-alias were
both independently confirmed against real GNU `as` before being encoded as
`imm_alias` table entries (not assumed from the ISA manual).

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt`/`asm-fmt-check`;
`make asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 97 to 100 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that all 97 pre-existing cases are
byte-for-byte unchanged and exactly the 3 expected new case_ids were
added); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
asm-isa-difficult-check asm-test`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target).

Results and artifact links: 3 new `isa-norm-riscv` checks (`test_rori`/
`test_rori_rv32`/`test_roriw`, against their own real, verbatim-extracted
riscv32.jsonl/riscv64.jsonl records, including the "pseudo-op"-kind
`rori.rv32` record and its `"status":"missing"` specializes-relationship);
new `isa-gen-difficult` entry-count checks (`rori_entries` asserting the
profile-specific lookup_key split, `roriw_entries` asserting RV64-only) plus
a new `test_shamt_domain` covering the shamt-immediate operand shape (not
folded into the existing 3-GPR/2-GPR domain checks, since the third operand
is a real immediate, not a register). A real `asm-isa-difficult-regen` run
against the now-100-entry corpus reproduced all 100 cases with
`verdict = Pass`, including the 3 new ones, with every one of the 97
pre-existing cases confirmed byte-for-byte unchanged (ignoring only the
git-rev-embedded `ours.tool_label`). `asm-isa-difficult-check`/`asm-test`
both pass; `make asm-ci` passes in full. `Isa_family_admission`'s pinned
totals moved exactly as expected: RV32 promoted-support 78->83, blocked
991->986 (RV32 gains only `rori.rv32`'s 5 records); RV64 promoted-support
91->101, blocked 1033->1023 (RV64 gains `rori`'s 5 plus `roriw`'s 5);
`isa-norm-accounting`'s paired totals moved 98->103 (RV32) / 121->131
(RV64) and the `isa-norm-jsonl` real-form round-trip count moved 237->252
(+15, matching the 5+5+5 records the three mnemonics' Req_any groups
promote), all pinned `repo_tests.ml` expectations updated and re-verified
passing on the first attempt (computed from first principles before
running). `tools-test`, `tools-integration`, `tools-boundary`,
`asm-fmt-check`, `asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`,
`tools-gasxref-diff` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: `zext.h`/`zext.h.rv32` remain
the one still-open named follow-up from the prior slice - not attempted
here. It differs from every shape built so far: riscv-opcodes exports it as
a "pseudo-op" specializing `packw`/`pack` with `rs2` HARDWIRED to `x0`
(bits[24:20]=0), which is neither `unary_gpr_form`'s fixed-funct12 shape nor
`shamt_gpr_form`'s genuine-immediate shape - it would need a third new
normalization shape ("R-type with one GPR operand suppressed to a fixed
`x0` encoding"), not a reuse of either shape just built. The rest of
Zk/Zkn/Zks (AES/SHA round functions), atomic, CSR, remaining vector, and
broader FP families remain GEN-05's own outstanding scope, unchanged from
the prior slice's writeup.

Acceptance gate satisfied: all three mnemonics have real encoder support,
reusing the pre-existing `i_desc`/shift-immediate encoder machinery with
zero new encoding paths (only two new table rows plus one RV64-only gate
entry); matching decoder round-trip and disassembly-naming confirmed
against real GNU as on both profiles, including the RV32 "unrecognized
opcode" rejection for `roriw`; a new, genuinely-required normalization
shape (`shamt_gpr_form`) built and reusing `rev8`'s existing Req_any groups
verbatim rather than inventing new ones; a persisted, offline-replayed
differential corpus entry each with real GNU agreement; and admission-matrix
promotion - the same measured-Pass discipline every other GEN-05/GAS-04
promotion used, with every affected pinned count in the repository's own
regression suite updated and re-verified rather than left stale.

##### GEN-05 continuation: Zbb `zext.h`/`zext.h.rv32` (Claude)

Task / status / owner: GEN-05 zext.h/zext.h.rv32 sub-slice / done; GEN-05
overall / still implementing / Claude. Closes the last concrete follow-up
named by the prior (rori/roriw) sub-slice.

Scope manifest and obligations: `zext.h` is Zbb's zero-extend-halfword
pseudo. riscv-opcodes exports it as two single-extension "pseudo-op"
records, neither import-duplicated (unlike every rev8/rori-family form
above): RV64's `zext.h` (`rv64_zbb`, specializing `rv64_zbkb::packw`) and
RV32's `zext.h.rv32` (`rv32_zbb`, specializing `rv_zbkb::pack`) - confirmed
by grep across both checked-in profiles that each native_name appears
exactly once. Both records' `encoding.fields` are exactly `[rd, rs1]` with
the rest of the word fully fixed (`rs2` hardwired to `x0`), the identical
category `unary_gpr_form`/`rev8` already normalize - a genuine third
normalization shape was not needed. Real GNU as was confirmed (RV32
2.43.1, RV64 2.44) to accept only the bare `zext.h` text on EITHER profile
(`zext.h.rv32` is rejected outright as an unrecognized opcode on both),
exactly the same profile-erasing spelling `rev8`/`rori` established, and to
reject both a one- and a three-operand `zext.h` as "illegal operands" (not
merely wrong bytes), which is why the encoder gets its own dedicated
two-operand match arm rather than a reuse of the generic three-register
`r_desc` path `pack`/`packw` share (adding an `r_desc` entry for `zext.h`
would have let a stray third operand fall through and silently encode as
`pack`/`packw` with an explicit `rs2`, which real GNU as does not accept).

`riscv_family_encode.ml` gained one `Zext_h` opcode (mnemonic text
`"zext.h"`) with a dedicated `[a; b]` lowering arm building
`Lowered.R {name = ("packw"|"pack"); opcode = (0x3b|0x33); funct3 = 4;
funct7 = 0x04; rd; rs1; rs2 = 0}`, `xlen`-selected exactly like every other
RV32/RV64 encoding split in this file - no `r_desc`/`i_desc` table entry,
mirroring `Snez`'s and `Sext_w`'s existing style for a fixed-register
pseudo rather than `Pack`/`Packw`'s three-register generic path. The
decoder is intentionally NOT taught to reverse `pack rd, rs1, x0` back into
`zext.h` (real GNU objdump does disassemble it that way, but this project's
established policy - the same one `Snez`'s own comment documents for
`sltu`/`snez` - is to always print the real underlying form on decode, not
duplicate GAS's own alias-preference table).

`Isa_norm_riscv.normalize` dispatches both native names through
`unary_gpr_form ~mnemonic:"zext.h"` unchanged (no `extension_lookup_key`
needed, since - unlike rev8/rori - neither record needs an
`alternative_extensions_by_mnemonic` Req_any entry: `requirement_of`'s
plain per-record `provenance.extension` lookup already resolves
`rv64_zbb`/`rv32_zbb` to the correct `Req_all [Req_xlen _; Req_feature
"riscv:zbb"]` on each profile without one). `Isa_gen_difficult` gained a
`zext_h_entry ~lookup_key` helper (the same profile-specific-lookup-key,
shared-form_id shape `rev8_entry` uses) and `zext_h_entries`, using
`zbb_configuration_for` since this needs only Zbb, not Zbkb.
`Isa_family_admission.promoted_case` gained the two matching triples.

Real, measured findings: hand-verified the RV32/RV64 mask/value bit layout
of `pack`/`packw` with `rs2` forced to `x0` against this project's own
`--dump-bytes` output before any corpus wiring, then confirmed against real
GNU `as`: `zext.h a0, a1` assembles identically on RV32 2.43.1 and RV64
2.44 (`33 c5 05 08` / `3b c5 05 08` little-endian = `0x0805c533` /
`0x0805c53b`), matching `pack`/`packw a0, a1, zero` bit-for-bit
field-by-field (funct7=0x04, rs2=x0, rs1=a1, funct3=4, rd=a0,
opcode=0x33/0x3b). Real GNU as's own disassembler prints the alias text
`zext.h` back for this encoding on both profiles (unlike the `sltu`/`snez`
precedent, where it prints the underlying `sltu`) - noted as a real,
measured divergence from this project's own decoder policy, not
implemented, per the `Snez`-established convention above. Both
`zext.h a0, a1, a2` (three operands) and `zext.h a0` (one operand) were
confirmed rejected by real RV32 GNU as ("illegal operands"), matching this
project's own two-operand-only match arm.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt-check`; `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 100 to 102 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that all 100 pre-existing cases are
byte-for-byte unchanged and exactly the 2 expected new case_ids were
added); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
asm-isa-difficult-check asm-test`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target).

Results and artifact links: 4 new `isa-norm-riscv` checks (`test_zext_h`/
`test_zext_h_rv32`, against their own real, verbatim-extracted
riscv64.jsonl/riscv32.jsonl records, explicitly asserting the plain
`Req_all` shape rather than a `Req_any` group); new `isa-gen-difficult`
entry-count checks (`zext_h_entries` asserting the profile-specific
lookup_key split) folded into the existing `test_unary_gpr_domain` two-GPR
domain check. A real `asm-isa-difficult-regen` run against the now-102-entry
corpus reproduced all 102 cases with `verdict = Pass`, including the 2 new
ones, with every one of the 100 pre-existing cases confirmed byte-for-byte
unchanged (ignoring only the git-rev-embedded `ours.tool_label`).
`asm-isa-difficult-check`/`asm-test` both pass; `make asm-ci` passes in
full (all stages, including the cross-smoke tri-state, characterize,
melange opt-in, and js-portable legs). `Isa_family_admission`'s pinned
totals moved exactly as expected: RV32 promoted-support 83->84, blocked
986->985; RV64 promoted-support 101->102, blocked 1023->1022 (each profile
gains exactly the 1 record its own `zext.h`/`zext.h.rv32` record
contributes, not 5, since neither is import-duplicated);
`isa-norm-accounting`'s paired totals moved 103->104 (RV32) / 131->132
(RV64) and the `isa-norm-jsonl` real-form round-trip count moved 252->254
(+2, matching the 1+1 records the two mnemonics add), all pinned
`repo_tests.ml` expectations updated and re-verified passing on the first
attempt (computed from first principles before running, not adjusted after
a failure). `tools-test`, `tools-integration`, `tools-boundary`,
`asm-fmt-check`, `asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`,
`tools-gasxref-diff` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: this closes every concrete
follow-up named by the prior three GEN-05 sub-slices (pack/zip family,
rolw/rorw, rori/roriw all named `zext.h`/`zext.h.rv32` as their own open
item; none remain). The rest of Zk/Zkn/Zks (AES/SHA round functions),
atomic, CSR, remaining vector, and broader FP families remain GEN-05's own
outstanding scope, unchanged from every prior slice's writeup - none of
them currently has a stated concrete next sub-slice the way this one
inherited `zext.h`/`zext.h.rv32` from `rori`/`roriw`, so the next GEN-05
continuation will need to pick one of those families and re-derive its own
scope from the real checked-in exports, the same way GEN-05's very first
sub-slice did.

Acceptance gate satisfied: both mnemonics have real encoder support via a
new, minimal two-operand match arm (zero new table-driven encoding paths,
reusing `pack`/`packw`'s existing field layout); matching real-GNU-as
agreement confirmed on both profiles including the literal-text-erasure
finding (`zext.h.rv32` rejected everywhere) and both malformed-arity
rejections; a normalization dispatch reusing `unary_gpr_form` verbatim with
no new shape and a documented reason the usual `Req_any` machinery does not
apply here; a persisted, offline-replayed differential corpus entry each
with real GNU agreement; admission-matrix promotion; and a full `make
asm-ci` pass - the same measured-Pass discipline every other GEN-05/GAS-04
promotion used, with every affected pinned count in the repository's own
regression suite updated and re-verified rather than left stale.

##### GEN-05 continuation: Zbc `clmul`/`clmulh` (Claude)

Task / status / owner: GEN-05 clmul/clmulh sub-slice / done; GEN-05 overall
/ still implementing / Claude. The prior (zext.h) sub-slice closed the last
concretely-named follow-up, so this slice picked its own scope by surveying
`isa-inventory norm-accounting`'s top-unhandled-name breakdown for the next
plain, well-bounded family rather than inheriting one.

Scope manifest and obligations: `clmul`/`clmulh` are Zbc's carry-less
multiply (low/high half). riscv-opcodes exports each identically under five
extension files - `rv_zbc` (primary), imported by `rv_zbkc`/`rv_zk`/
`rv_zkn`/`rv_zks` - hand-verified identical mask/value across all five
records in both checked-in profiles (`grep`, before writing any code),
exactly the shape `andn`/`orn`/`xnor`/`rol`/`ror`'s own `zbb_import_group`
already established, just rooted in Zbc rather than Zbb. Both are plain
three-GPR R-type forms (`rd`, `rs1`, `rs2`, no immediate), XLEN-independent
(identical mnemonic and encoding on both profiles, no rev8-style
native_name split needed) - `r_type_gpr_form` and `zbb_r_type_entry`'s own
generic machinery apply unchanged; only a new `zbc_import_group` (norm) and
`zbc_r_type_entry`/`zbc_configuration_for` (corpus, mirroring `zbb`'s own)
were needed, plus two `feature_of_extension` entries (`rv_zbc`/`rv_zbkc` ->
`Req_feature "riscv:zbc"`/`"riscv:zbkc"`) and two `r_desc` table rows
(`Clmul -> (0x33, 1, 0x05)`, `Clmulh -> (0x33, 3, 0x05)`) reusing the
existing generic three-register R-type lowering path with zero new encoder
match arms.

Real, measured findings: hand-computed expected bytes from riscv-opcodes'
own mask/value matched this project's own `--dump-bytes` output on both
profiles before any corpus wiring, then confirmed against real GNU `as`
(RV32 2.43.1, RV64 2.44) with `-march=..._zbc`: `clmul a0, a1, a2` and
`clmulh a0, a1, a2` assemble byte-identically on both profiles
(`33 95 c5 0a` / `33 b5 c5 0a` little-endian = `0x0ac59533` / `0x0ac5b533`),
matching this project's own output exactly.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt-check`; `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 102 to 106 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that all 102 pre-existing cases are
byte-for-byte unchanged and exactly the 4 expected new case_ids were added);
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
asm-isa-difficult-check asm-test`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target).

Results and artifact links: 6 new `isa-norm-riscv` checks (`test_clmul`/
`test_clmulh`, reusing the existing `test_r_type_gpr_any` harness against
their own real, verbatim-extracted riscv32.jsonl records, explicitly
asserting the five-way `Req_any`); new `isa-gen-difficult` entry-count
checks folded into the existing three-GPR domain check. A real
`asm-isa-difficult-regen` run against the now-106-entry corpus reproduced
all 106 cases with `verdict = Pass`, including the 4 new ones, with every
one of the 102 pre-existing cases confirmed byte-for-byte unchanged
(ignoring only the git-rev-embedded `ours.tool_label`).
`asm-isa-difficult-check`/`asm-test` both pass; `make asm-ci` passes in
full (all stages, including the cross-smoke tri-state, characterize,
melange opt-in, and js-portable legs). `Isa_family_admission`'s pinned
totals moved exactly as expected: RV32 promoted-support 84->94, blocked
985->975; RV64 promoted-support 102->112, blocked 1022->1012 (each profile
gains 10 records - 2 mnemonics x 5 import-duplicate records - matching the
same "N mnemonics x 5 extension-membership records" accounting the
andn/orn/xnor/rol/ror slice established); `isa-norm-accounting`'s paired
totals moved 104->114 (RV32) / 132->142 (RV64) and the `isa-norm-jsonl`
real-form round-trip count moved 254->274 (+20), all pinned `repo_tests.ml`
expectations updated and re-verified passing on the first attempt (computed
from first principles before running, not adjusted after a failure).
`tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`,
`asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`,
`tools-gasxref-diff` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: this slice was self-selected
from the accounting command's top-unhandled-name breakdown, not inherited
from a prior slice's writeup - the rest of Zk/Zkn/Zks (the AES round
functions `aes32dsi`/`aes32dsmi`/`aes32esi`/`aes32esmi` on RV32,
`aes64ks1i`/`aes64ks2`/`aes64ds`/`aes64dsm`/`aes64es`/`aes64esm` on RV64,
and the SHA round functions `sha256sig0`/`sha256sig1`/etc.), Zbkx's
`xperm4`/`xperm8`, atomic, CSR, remaining vector, and broader FP families
remain GEN-05's own outstanding scope, each still needing its own shape/
requirement survey before a next concrete sub-slice can be named.

Acceptance gate satisfied: both mnemonics have real encoder support via the
existing generic three-register R-type path (zero new match arms, only two
`r_desc` table rows); matching real-GNU-as agreement confirmed on both
profiles; a normalization dispatch reusing `r_type_gpr_form` and the
existing `Req_any` machinery verbatim (one new import-group list, two new
extension mappings); a persisted, offline-replayed differential corpus
entry each with real GNU agreement; admission-matrix promotion; and a full
`make asm-ci` pass - the same measured-Pass discipline every other
GEN-05/GAS-04 promotion used, with every affected pinned count in the
repository's own regression suite updated and re-verified rather than left
stale.

##### GEN-05 continuation: Zbkx `xperm4`/`xperm8` (Claude)

Task / status / owner: GEN-05 xperm4/xperm8 sub-slice / done; GEN-05
overall / still implementing / Claude. Self-selected, like the clmul/clmulh
slice before it, from `isa-inventory norm-accounting`'s top-unhandled-name
breakdown.

Scope manifest and obligations: `xperm4`/`xperm8` are Zbkx's crossbar
permute (nibble-granular / byte-granular). riscv-opcodes exports each under
four extension files - `rv_zbkx` (primary), imported by `rv_zk`/`rv_zkn`/
`rv_zks` - hand-verified identical mask/value across all four records in
both checked-in profiles; unlike `clmul`/`clmulh`, there is no separate
non-K sibling extension (Zbkx has no plain "Zbx"), so the group is
four-way, not five. Both are plain three-GPR R-type forms, XLEN-independent
(identical mnemonic/encoding on both profiles). Reused `r_type_gpr_form`,
`requirement_of_mnemonic`, and the corpus/admission machinery unchanged;
added a `zbkx_import_group` (norm, mirroring `pack`/`packh`'s own
four-way `zbkb_import_group_4way` shape), `zbkx_r_type_entry`/
`zbkx_configuration_for` (corpus, mirroring `zbc_r_type_entry`'s own
pattern from the clmul/clmulh slice), one `feature_of_extension` entry
(`rv_zbkx` -> `Req_feature "riscv:zbkx"`), and two `r_desc` rows
(`Xperm4 -> (0x33, 2, 0x14)`, `Xperm8 -> (0x33, 4, 0x14)`) reusing the
existing generic three-register R-type lowering path with zero new encoder
match arms.

Real, measured findings: hand-computed expected bytes from riscv-opcodes'
own mask/value matched this project's own `--dump-bytes` output on both
profiles before any corpus wiring, then confirmed against real GNU `as`
(RV32 2.43.1, RV64 2.44) with `-march=..._zbkx`: `xperm4 a0, a1, a2` and
`xperm8 a0, a1, a2` assemble byte-identically on both profiles
(`33 a5 c5 28` / `33 c5 c5 28` little-endian = `0x28c5a533` /
`0x28c5c533`), matching this project's own output exactly.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt-check`; `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 106 to 110 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that all 106 pre-existing cases are
byte-for-byte unchanged and exactly the 4 expected new case_ids were added);
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
asm-isa-difficult-check asm-test`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target).

Results and artifact links: 6 new `isa-norm-riscv` checks (`test_xperm4`/
`test_xperm8`, reusing the existing `test_r_type_gpr_any` harness against
their own real, verbatim-extracted riscv32.jsonl records, explicitly
asserting the four-way `Req_any`); new `isa-gen-difficult` entry-count
checks folded into the existing three-GPR domain check. A real
`asm-isa-difficult-regen` run against the now-110-entry corpus reproduced
all 110 cases with `verdict = Pass`, including the 4 new ones, with every
one of the 106 pre-existing cases confirmed byte-for-byte unchanged
(ignoring only the git-rev-embedded `ours.tool_label`).
`asm-isa-difficult-check`/`asm-test` both pass; `make asm-ci` passes in
full (all stages, including the cross-smoke tri-state, characterize,
melange opt-in, and js-portable legs). `Isa_family_admission`'s pinned
totals moved exactly as expected: RV32 promoted-support 94->102, blocked
975->967; RV64 promoted-support 112->120, blocked 1012->1004 (each profile
gains 8 records - 2 mnemonics x 4 import-duplicate records, one fewer than
clmul/clmulh's 10 since this group has no fifth non-K sibling extension);
`isa-norm-accounting`'s paired totals moved 114->122 (RV32) / 142->150
(RV64) and the `isa-norm-jsonl` real-form round-trip count moved 274->290
(+16), all pinned `repo_tests.ml` expectations updated and re-verified
passing on the first attempt (computed from first principles before
running, not adjusted after a failure). `tools-test`, `tools-integration`,
`tools-boundary`, `asm-fmt-check`, `asm-purity`, `asm-js-portable`,
`tools-isa-inventory-diff`, `tools-gasxref-diff` all pass unchanged
otherwise.

Unknowns, exceptions and follow-up task IDs: like the clmul/clmulh slice,
this was self-selected from the accounting command's top-unhandled-name
breakdown, not inherited. The rest of Zk/Zkn/Zks (the AES round functions
`aes32dsi`/`aes32dsmi`/`aes32esi`/`aes32esmi` on RV32,
`aes64ks1i`/`aes64ks2`/`aes64ds`/`aes64dsm`/`aes64es`/`aes64esm` on RV64,
and the SHA round functions `sha256sig0`/`sha256sig1`/etc.), atomic, CSR,
remaining vector, and broader FP families remain GEN-05's own outstanding
scope, each still needing its own shape/requirement survey before a next
concrete sub-slice can be named. `xperm4`/`xperm8` themselves are now fully
closed - no further variants exist for either mnemonic in the checked-in
exports.

Acceptance gate satisfied: both mnemonics have real encoder support via the
existing generic three-register R-type path (zero new match arms, only two
`r_desc` table rows); matching real-GNU-as agreement confirmed on both
profiles; a normalization dispatch reusing `r_type_gpr_form` and the
existing `Req_any` machinery verbatim (one new import-group list, one new
extension mapping); a persisted, offline-replayed differential corpus
entry each with real GNU agreement; admission-matrix promotion; and a full
`make asm-ci` pass - the same measured-Pass discipline every other
GEN-05/GAS-04 promotion used, with every affected pinned count in the
repository's own regression suite updated and re-verified rather than left
stale.

##### GEN-05 continuation: Zknh `sha256sum0`/`sha256sum1`/`sha256sig0`/`sha256sig1` (Claude)

Task / status / owner: GEN-05 sha256sum0/sum1/sig0/sig1 sub-slice / done;
GEN-05 overall / still implementing / Claude. Self-selected, like the
clmul/clmulh and xperm4/xperm8 slices before it, from `isa-inventory
norm-accounting`'s top-unhandled-name breakdown.

Scope manifest and obligations: these four mnemonics are Zknh's SHA-256
message-schedule helpers. riscv-opcodes exports each under three extension
files - `rv_zknh` (primary), imported by `rv_zk`/`rv_zkn` (no `rv_zks`:
SHA-256 belongs to the NIST crypto profile Zkn groups, not the "ShangMi"
Zks one, the same asymmetry the sha256sig0/sig1 pilot examples already
carry) - hand-verified identical mask/value across all three records in
both checked-in profiles. All four are the same two-GPR unary shape
`clz`/`ctz`/`cpop` already established (a fully fixed OP-IMM funct12
selects the mnemonic; GAS syntax is "mnemonic rd, rs1" with no immediate
written), XLEN-independent (identical mnemonic/encoding on both profiles).
Reused `unary_gpr_form` and the encoder's existing `unary_imm_desc` table
unchanged - no new dispatch code needed at all, exactly mirroring how
`brev8` was added earlier: adding the four mnemonics to
`unary_gpr_mnemonics` (norm) and four `unary_imm_desc` table rows (encoder:
`Sha256sum0 -> (0x13, 1, 0x100)`, `Sha256sum1 -> (0x13, 1, 0x101)`,
`Sha256sig0 -> (0x13, 1, 0x102)`, `Sha256sig1 -> (0x13, 1, 0x103)`) plus one
new `zknh_import_group` Req_any entry per mnemonic in
`alternative_extensions_by_mnemonic` was the entire change. On the test
side, added a `test_unary_gpr_any` helper (the two-GPR-operand analogue of
`test_r_type_gpr_any`, since no prior slice needed a generic Req_any helper
for the unary shape - brev8/zip/unzip predate it and were written inline)
and a `zknh_unary_entry`/`zknh_configuration_for` pair on the corpus side
(mirroring `zbb_unary_entry`'s own shape).

Real, measured findings: hand-computed expected bytes from riscv-opcodes'
own mask/value matched this project's own `--dump-bytes` output on both
profiles before any corpus wiring, then confirmed against real GNU `as`
(RV32 2.43.1, RV64 2.44) with `-march=..._zknh`: `sha256sum0 a0, a1`,
`sha256sum1 a0, a1`, `sha256sig0 a0, a1`, `sha256sig1 a0, a1` all assemble
byte-identically on both profiles (`13 95 05 10` / `13 95 15 10` /
`13 95 25 10` / `13 95 35 10` little-endian = `0x10059513` / `0x10159513`
/ `0x10259513` / `0x10359513`), matching this project's own output exactly.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt`/`asm-fmt-check`;
`make asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 110 to 118 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that all 110 pre-existing cases are
byte-for-byte unchanged and exactly the 8 expected new case_ids were
added); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
asm-isa-difficult-check asm-test`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target).

Results and artifact links: 12 new `isa-norm-riscv` checks (`test_sha256sum0`/
`test_sha256sum1`/`test_sha256sig0`/`test_sha256sig1`, reusing the new
`test_unary_gpr_any` harness against their own real, verbatim-extracted
riscv32.jsonl records, explicitly asserting the three-way `Req_any`); new
`isa-gen-difficult` entry-count checks folded into the existing
`test_unary_gpr_domain` two-GPR domain check. A real `asm-isa-difficult-regen`
run against the now-118-entry corpus reproduced all 118 cases with
`verdict = Pass`, including the 8 new ones, with every one of the 110
pre-existing cases confirmed byte-for-byte unchanged (ignoring only the
git-rev-embedded `ours.tool_label`). `asm-isa-difficult-check`/`asm-test`
both pass; `make asm-ci` passes in full (all stages, including the
cross-smoke tri-state, characterize, melange opt-in, and js-portable legs).
`Isa_family_admission`'s pinned totals moved exactly as expected: RV32
promoted-support 102->114, blocked 967->955; RV64 promoted-support
120->132, blocked 1004->992 (each profile gains 12 records - 4 mnemonics x
3 import-duplicate records); `isa-norm-accounting`'s paired totals moved
122->134 (RV32) / 150->162 (RV64) and the `isa-norm-jsonl` real-form
round-trip count moved 290->314 (+24), all pinned `repo_tests.ml`
expectations updated and re-verified passing on the first attempt (computed
from first principles before running, not adjusted after a failure). A
formatting nit (`ocamlformat` wanted `check "..."` collapsed onto one line
for one new check) was caught by `asm-fmt-check` and fixed with
`asm-fmt --auto-promote` before the rest of the gate ran. `tools-test`,
`tools-integration`, `tools-boundary`, `asm-purity`, `asm-js-portable`,
`tools-isa-inventory-diff`, `tools-gasxref-diff` all pass unchanged
otherwise.

Unknowns, exceptions and follow-up task IDs: like the two prior
self-selected slices, this was chosen from the accounting command's
top-unhandled-name breakdown, not inherited. The rest of Zk/Zkn/Zks - the
AES round functions `aes32dsi`/`aes32dsmi`/`aes32esi`/`aes32esmi` (RV32) and
`aes64ks1i`/`aes64ks2`/`aes64ds`/`aes64dsm`/`aes64es`/`aes64esm`/`aes64im`
(RV64), plus SHA-512's split helpers - `sha512sig0h`/`sha512sig0l`/
`sha512sig1h`/`sha512sig1l`/`sha512sum0r`/`sha512sum1r` (RV32-only,
32-bit-word-pair siblings of this slice's own RV64-shaped `sha512sig0`/
`sha512sig1`/`sha512sum0`/`sha512sum1`, which are themselves still
unhandled on RV64) - atomic, CSR, remaining vector, and broader FP families
remain GEN-05's own outstanding scope, each still needing its own shape/
requirement survey before a next concrete sub-slice can be named.
`sha256sum0`/`sha256sum1`/`sha256sig0`/`sha256sig1` themselves are now
fully closed - no further variants exist for any of the four mnemonics in
the checked-in exports.

Acceptance gate satisfied: all four mnemonics have real encoder support via
the existing generic OP-IMM funct12-dispatch path (zero new match arms,
only four `unary_imm_desc` table rows); matching real-GNU-as agreement
confirmed on both profiles; a normalization dispatch reusing
`unary_gpr_form` and the existing `Req_any` machinery (one new import-group
list, one new extension mapping, plus a new but genuinely reusable
`test_unary_gpr_any` test helper); a persisted, offline-replayed
differential corpus entry each with real GNU agreement; admission-matrix
promotion; and a full `make asm-ci` pass - the same measured-Pass
discipline every other GEN-05/GAS-04 promotion used, with every affected
pinned count in the repository's own regression suite updated and
re-verified rather than left stale.

##### GEN-05 continuation: Zknh `sha512sum0`/`sha512sum1`/`sha512sig0`/`sha512sig1` (Claude)

Task / status / owner: GEN-05 sha512sum0/sum1/sig0/sig1 sub-slice / done;
GEN-05 overall / still implementing / Claude. Sha256's own RV64-only
siblings - the natural next slice once the sha256 quartet closed, since
riscv-opcodes exports both SHA-256 and SHA-512's non-split helpers from the
same `rv64_zknh` extension file.

Scope manifest and obligations: these four mnemonics are RV64-only - no
RV32 record exists at all (riscv-opcodes' actual RV32 answer for SHA-512 is
a genuinely different, out-of-scope shape: the 32-bit-word-pair-split
`sha512sig0h`/`sha512sig0l`/`sha512sig1h`/`sha512sig1l`/`sha512sum0r`/
`sha512sum1r` family, three-operand `rd`/`rs1`/`rs2` forms, not this
slice's two-GPR unary one). Otherwise identical in shape and import
structure to the sha256 slice: primary `rv64_zknh`, imported by
`rv64_zk`/`rv64_zkn` (three-way, no `rv64_zks`), the same OP-IMM
funct12-selects-mnemonic two-GPR unary shape `unary_gpr_form`/
`unary_imm_desc` already handle. Reused both unchanged: added the four
mnemonics to `unary_gpr_mnemonics` and four `unary_imm_desc` table rows
(`Sha512sum0 -> (0x13, 1, 0x104)`, `Sha512sum1 -> (0x13, 1, 0x105)`,
`Sha512sig0 -> (0x13, 1, 0x106)`, `Sha512sig1 -> (0x13, 1, 0x107)`), plus
one new `zknh_import_group_rv64` Req_any entry per mnemonic. Two things
differ from the sha256 slice, both because this group is XLEN-prefixed
(`rv64_zknh`/`rv64_zk`/`rv64_zkn`, not the plain `rv_*` names sha256 used):
a new `feature_of_extension` mapping (`rv64_zknh -> Req_all [Req_xlen 64;
Req_feature "riscv:zknh"]`, mirroring the already-present `rv64_zk`/
`rv64_zkn` rows) was needed, and the four mnemonics joined the encoder's
existing `Rv64_only` gate list alongside `Clzw`/`Ctzw`/`Cpopw`/etc. (a
one-line gate-list extension, not a new gate). On the test side, the
generic `test_unary_gpr_any` helper (written for the plain-`Req_feature`
sha256 group) does not fit an XLEN-wrapped `Req_all [Req_xlen 64; ...]`
group, so a small dedicated `test_sha512_unary_any` helper was added
instead, following the same `Req_xlen`-wrapped pattern `test_rev8`/
`test_rori` already established for their own rv64-prefixed groups.

Real, measured findings: hand-computed expected bytes from riscv-opcodes'
own mask/value matched this project's own `--dump-bytes` output on RV64
before any corpus wiring, then confirmed against real GNU `as` (RV64 2.44)
with `-march=..._zknh`: `sha512sum0 a0, a1`, `sha512sum1 a0, a1`,
`sha512sig0 a0, a1`, `sha512sig1 a0, a1` all assemble byte-identically to
this project's own output (`13 95 45 10` / `13 95 55 10` / `13 95 65 10` /
`13 95 75 10` little-endian = `0x10459513` / `0x10559513` / `0x10659513` /
`0x10759513`). Cross-checked negatively: real
`riscv32-linux-gnu-as` rejects all four as unrecognized opcodes on RV32
(genuinely absent, not merely extension-gated), matching this project's own
`` `Rv64_only `` rejection.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt-check`; `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 118 to 122 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that all 118 pre-existing cases are
byte-for-byte unchanged and exactly the 4 expected new case_ids - all
RV64 - were added); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-check asm-test`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make asm-ci` (full
CI target).

Results and artifact links: 12 new `isa-norm-riscv` checks (`test_sha512sum0`/
`test_sha512sum1`/`test_sha512sig0`/`test_sha512sig1`, via the new
`test_sha512_unary_any` helper, against their own real, verbatim-extracted
riscv64.jsonl records, explicitly asserting the `Req_xlen`-wrapped
three-way `Req_any`); a new RV64-only entry-count check (mirroring
`clzw_entries`'s own single-target-restriction assertion) plus the four
entries folded into the existing `test_unary_gpr_domain` two-GPR domain
check. A real `asm-isa-difficult-regen` run against the now-122-entry
corpus reproduced all 122 cases with `verdict = Pass`, including the 4 new
ones, with every one of the 118 pre-existing cases confirmed byte-for-byte
unchanged (ignoring only the git-rev-embedded `ours.tool_label`).
`asm-isa-difficult-check`/`asm-test` both pass; `make asm-ci` passes in
full (all stages, including the cross-smoke tri-state, characterize,
melange opt-in, and js-portable legs). `Isa_family_admission`'s pinned
totals moved exactly as expected: RV64 promoted-support 132->144, blocked
992->980 (RV32 unaffected - no RV32 record for any of the four);
`isa-norm-accounting`'s RV64 total moved 162->174 (RV32 unaffected at 134)
and the `isa-norm-jsonl` real-form round-trip count moved 314->326 (+12,
matching the 4 mnemonics x 3 import-duplicate records), all pinned
`repo_tests.ml` expectations updated and re-verified passing on the first
attempt (computed from first principles before running, not adjusted after
a failure). `tools-test`, `tools-integration`, `tools-boundary`,
`asm-fmt-check`, `asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`,
`tools-gasxref-diff` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: with this slice, every Zknh
SHA-256/SHA-512 mnemonic that fits the plain two-GPR unary shape is fully
closed. What remains named and unattempted: the AES round functions
(`aes32dsi`/`aes32dsmi`/`aes32esi`/`aes32esmi` on RV32,
`aes64ks1i`/`aes64ks2`/`aes64ds`/`aes64dsm`/`aes64es`/`aes64esm`/`aes64im`
on RV64 - `aes64ks1i` in particular takes a `rnum` immediate operand, a
shape this project's Zb/Zk work has not yet built), and SHA-512's RV32-only
32-bit-split helpers (`sha512sig0h`/`sha512sig0l`/`sha512sig1h`/
`sha512sig1l`/`sha512sum0r`/`sha512sum1r` - genuinely three-GPR-operand
forms, not this family's unary one). Atomic, CSR, remaining vector, and
broader FP families remain GEN-05's own outstanding scope, each still
needing its own shape/requirement survey before a next concrete sub-slice
can be named.

Acceptance gate satisfied: all four mnemonics have real encoder support via
the existing generic OP-IMM funct12-dispatch path plus a one-line addition
to the existing `Rv64_only` gate list (zero new match arms or gates);
matching real-GNU-as agreement confirmed on RV64 and correct rejection
confirmed on RV32; a normalization dispatch reusing `unary_gpr_form` and
the `Req_any` machinery (one new XLEN-prefixed import-group list, one new
extension mapping, one new but genuinely reusable `Req_xlen`-wrapped test
helper); a persisted, offline-replayed differential corpus entry each with
real GNU agreement; admission-matrix promotion; and a full `make asm-ci`
pass - the same measured-Pass discipline every other GEN-05/GAS-04
promotion used, with every affected pinned count in the repository's own
regression suite updated and re-verified rather than left stale.

##### GEN-05 continuation: Zknh `sha512sum0r`/`sum1r`/`sig0l`/`sig1l`/`sig0h`/`sig1h` (Claude)

Task / status / owner: GEN-05 sha512sum0r/sum1r/sig0l/sig1l/sig0h/sig1h
sub-slice / done; GEN-05 overall / still implementing / Claude. Closes the
one remaining named follow-up from the sha512sum0/sum1/sig0/sig1 slice -
SHA-512's own RV32-only 32-bit-word-pair-split family.

Scope manifest and obligations: these six mnemonics are RV32-only (no RV64
record at all - confirmed: real riscv64-linux-gnu-as rejects all six as
unrecognized opcodes, the mirror image of the previous slice's own
RV64-only restriction). Unlike every prior sha256/sha512 form, this is a
genuinely different shape: a plain three-GPR R-type (`rd`, `rs1`, `rs2`,
no immediate) - the same shape `andn`/`clmul`/`xperm4` already use, not the
two-GPR unary one `clz`/`sha256sum0`/`sha512sum0` share. Reused
`r_type_gpr_form`/`r_type_mnemonics` unchanged: added the six mnemonics to
`r_type_mnemonics` and six `r_desc` table rows (`Sha512sum0r -> (0x33, 0,
0x28)`, `Sha512sum1r -> (0x33, 0, 0x29)`, `Sha512sig0l -> (0x33, 0, 0x2a)`,
`Sha512sig1l -> (0x33, 0, 0x2b)`, `Sha512sig0h -> (0x33, 0, 0x2e)`,
`Sha512sig1h -> (0x33, 0, 0x2f)`), plus one new `zknh_import_group_rv32`
Req_any entry per mnemonic - primary `rv32_zknh`, imported by
`rv32_zk`/`rv32_zkn` (three-way, XLEN-prefixed rv32, the mirror image of
the RV64 group the prior slice added). On the encoder side, the six
mnemonics joined the existing `Rv32_only` gate list alongside `Zip`/`Unzip`
(a one-line gate-list extension, not a new gate). As with the RV64 unary
slice, the XLEN-prefixed group needed both a new `feature_of_extension`
mapping (`rv32_zknh -> Req_all [Req_xlen 32; Req_feature "riscv:zknh"]`)
and a dedicated `test_r_type_gpr_any_rv32` test helper (the three-GPR
analogue of `test_sha512_unary_any`, since the generic `test_r_type_gpr_any`
only handles plain-`Req_feature` groups) and a matching
`zknh_r_type_entry`/`zknh_configuration_for`-reusing corpus helper.

Real, measured findings: hand-computed expected bytes from riscv-opcodes'
own mask/value matched this project's own `--dump-bytes` output on RV32
before any corpus wiring, then confirmed against real GNU `as` (RV32
2.43.1) with `-march=..._zknh`: `sha512sum0r a0, a1, a2`, `sha512sum1r a0,
a1, a2`, `sha512sig0l a0, a1, a2`, `sha512sig1l a0, a1, a2`, `sha512sig0h
a0, a1, a2`, `sha512sig1h a0, a1, a2` all assemble byte-identically to this
project's own output (`33 85 c5 50` / `33 85 c5 52` / `33 85 c5 54` / `33
85 c5 56` / `33 85 c5 5c` / `33 85 c5 5e` little-endian = `0x50c58533` /
`0x52c58533` / `0x54c58533` / `0x56c58533` / `0x5cc58533` / `0x5ec58533`).
Cross-checked negatively: real `riscv64-linux-gnu-as` rejects all six as
unrecognized opcodes on RV64 (genuinely absent, not merely
extension-gated), matching this project's own `` `Rv32_only `` rejection.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt`/`asm-fmt-check`
(a real formatting nit - one new corpus-entry list too wide for the pinned
`ocamlformat` line width - was caught by `asm-fmt-check` and fixed with
`asm-fmt`'s auto-promote before the rest of the gate ran); `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 122 to 128 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that all 122 pre-existing cases are
byte-for-byte unchanged and exactly the 6 expected new case_ids - all
RV32 - were added); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-check asm-test`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make asm-ci` (full
CI target).

Results and artifact links: 18 new `isa-norm-riscv` checks (`test_sha512sum0r`/
`test_sha512sum1r`/`test_sha512sig0l`/`test_sha512sig1l`/`test_sha512sig0h`/
`test_sha512sig1h`, via the new `test_r_type_gpr_any_rv32` helper, against
their own real, verbatim-extracted riscv32.jsonl records, explicitly
asserting the `Req_xlen`-wrapped three-way `Req_any`); a new RV32-only
entry-count check (mirroring `zip_entries`'s own single-target-restriction
assertion) plus the six entries folded into the existing `test_minmax_domain`
three-GPR domain check. A real `asm-isa-difficult-regen` run against the
now-128-entry corpus reproduced all 128 cases with `verdict = Pass`,
including the 6 new ones, with every one of the 122 pre-existing cases
confirmed byte-for-byte unchanged (ignoring only the git-rev-embedded
`ours.tool_label`). `asm-isa-difficult-check`/`asm-test` both pass; `make
asm-ci` passes in full (all stages, including the cross-smoke tri-state,
characterize, melange opt-in, and js-portable legs). `Isa_family_admission`'s
pinned totals moved exactly as expected: RV32 promoted-support 114->132,
blocked 955->937 (RV64 unaffected - no RV64 record for any of the six);
`isa-norm-accounting`'s RV32 total moved 134->152 (RV64 unaffected at 174)
and the `isa-norm-jsonl` real-form round-trip count moved 326->344 (+18,
matching the 6 mnemonics x 3 import-duplicate records), all pinned
`repo_tests.ml` expectations updated and re-verified passing on the first
attempt (computed from first principles before running, not adjusted after
a failure - the one formatting fixup was cosmetic, not a count error).
`tools-test`, `tools-integration`, `tools-boundary`, `asm-purity`,
`asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all
pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: with this slice, every Zknh
SHA-256/SHA-512 mnemonic - both the two-GPR unary shape and this
three-GPR split-helper shape - is fully closed on both profiles. What
remains named and unattempted: the AES round functions
(`aes32dsi`/`aes32dsmi`/`aes32esi`/`aes32esmi` on RV32,
`aes64ks1i`/`aes64ks2`/`aes64ds`/`aes64dsm`/`aes64es`/`aes64esm`/`aes64im`
on RV64 - `aes64ks1i` in particular takes a `rnum` immediate operand, a
shape this project's Zb/Zk work has not yet built for any mnemonic).
Atomic, CSR, remaining vector, and broader FP families remain GEN-05's own
outstanding scope, each still needing its own shape/requirement survey
before a next concrete sub-slice can be named.

Acceptance gate satisfied: all six mnemonics have real encoder support via
the existing generic three-register R-type path (zero new match arms,
only six `r_desc` table rows) plus a one-line addition to the existing
`Rv32_only` gate list; matching real-GNU-as agreement confirmed on RV32
and correct rejection confirmed on RV64; a normalization dispatch reusing
`r_type_gpr_form` and the `Req_any` machinery (one new XLEN-prefixed
import-group list, one new extension mapping, one new but genuinely
reusable `Req_xlen`-wrapped test helper); a persisted, offline-replayed
differential corpus entry each with real GNU agreement; admission-matrix
promotion; and a full `make asm-ci` pass - the same measured-Pass
discipline every other GEN-05/GAS-04 promotion used, with every affected
pinned count in the repository's own regression suite updated and
re-verified rather than left stale.

##### GEN-05 continuation: RISC-V AES-64 `aes64ds`/`dsm`/`es`/`esm`/`ks2`/`im` (Claude)

Task / status / owner: GEN-05 aes64ds/dsm/es/esm/ks2/im sub-slice / done;
GEN-05 overall / still implementing / Claude. The first slice into the AES
round functions, chosen because these six mnemonics are AES-64's
"plain-shape" ones - every other AES mnemonic in the checked-in exports
either needs a genuinely new operand shape (`aes64ks1i`'s `rnum` immediate,
AES-32's `bs` immediate) or is one of these six.

Scope manifest and obligations: all six mnemonics are RV64-only (no RV32
record at all - confirmed: real riscv32-linux-gnu-as rejects all six as
unrecognized opcodes). Unlike every prior GEN-05 Zk slice, this one has
THREE distinct Req_any groups, not one: `aes64ds`/`aes64dsm`/`aes64im` are
rooted in a primary `rv64_zknd` (three-way: `rv64_zknd`/`rv64_zk`/
`rv64_zkn`); `aes64es`/`aes64esm` are rooted in a disjoint primary
`rv64_zkne` (three-way: `rv64_zkne`/`rv64_zk`/`rv64_zkn`, no `rv64_zknd`
membership at all - hand-verified, not assumed, since Zknd is the
"decrypt" extension and Zkne is "encrypt"); `aes64ks2` is the one mnemonic
imported by BOTH key-schedule extensions (four-way: `rv64_zknd`/`rv64_zk`/
`rv64_zkn`/`rv64_zkne`). `aes64ds`/`aes64dsm`/`aes64es`/`aes64esm`/`aes64ks2`
reuse the existing plain three-GPR R-type shape unchanged (`r_type_gpr_form`/
`r_desc`, five new `r_desc` rows: `Aes64ds -> (0x33, 0, 0x1d)`, `Aes64dsm
-> (0x33, 0, 0x1f)`, `Aes64es -> (0x33, 0, 0x19)`, `Aes64esm -> (0x33, 0,
0x1b)`, `Aes64ks2 -> (0x33, 0, 0x3f)`); `aes64im` reuses the existing
two-GPR unary shape (`unary_gpr_form`/`unary_imm_desc`, one new row:
`Aes64im -> (0x13, 1, 0x300)`). All six joined the existing `Rv64_only`
gate list (a one-line extension, not a new gate). Two new
`feature_of_extension` mappings were needed (`rv64_zknd`, `rv64_zkne`).
Because this slice has three groups rather than one, the test side needed
a genuinely parametrized helper - `test_r_type_gpr_any_rv64 ~import_group`
- rather than a single hardcoded one the way every prior XLEN-prefixed
slice's dedicated helper was; the corpus side got matching parametrized
`aes64_r_type_entry ~configuration_for` plus separate `zknd_configuration_for`/
`zkne_configuration_for` functions.

Real, measured findings: hand-computed expected bytes from riscv-opcodes'
own mask/value matched this project's own `--dump-bytes` output on RV64
before any corpus wiring, then confirmed against real GNU `as` (RV64 2.44)
with `-march=..._zknd_zkne`: `aes64ds a0, a1, a2`, `aes64dsm a0, a1, a2`,
`aes64es a0, a1, a2`, `aes64esm a0, a1, a2`, `aes64ks2 a0, a1, a2`,
`aes64im a0, a1` all assemble byte-identically to this project's own output
(`33 85 c5 3a` / `33 85 c5 3e` / `33 85 c5 32` / `33 85 c5 36` / `33 85 c5
7e` / `13 95 05 30` little-endian = `0x3ac58533` / `0x3ec58533` /
`0x32c58533` / `0x36c58533` / `0x7ec58533` / `0x30059513`). Cross-checked
negatively: real `riscv32-linux-gnu-as` rejects all six as unrecognized
opcodes on RV32 (genuinely absent, not merely extension-gated), matching
this project's own `` `Rv64_only `` rejection.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt`/`asm-fmt-check`
(two real formatting nits - lines too wide for the pinned `ocamlformat`
width in both `isa_gen_difficult.ml` and `test_isa_norm_riscv.ml` - were
caught by `asm-fmt-check` and fixed with `asm-fmt`'s auto-promote before
the rest of the gate ran); `make asm-purity`; `make asm-js-portable`;
`make tools-isa-inventory-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 128 to 134 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that all 128 pre-existing cases are
byte-for-byte unchanged and exactly the 6 expected new case_ids - all
RV64 - were added); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-check asm-test`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make asm-ci` (full
CI target).

Results and artifact links: 18 new `isa-norm-riscv` checks (`test_aes64ds`/
`test_aes64dsm`/`test_aes64es`/`test_aes64esm`/`test_aes64ks2` via the new
`test_r_type_gpr_any_rv64` helper, `test_aes64im` written inline mirroring
`test_sha512_unary_any`'s own pattern, all against their own real,
verbatim-extracted riscv64.jsonl records, explicitly asserting each of the
three distinct `Req_any` group shapes); a new RV64-only entry-count check
(mirroring `sha512sum0_entries`'s own single-target-restriction assertion)
plus the six entries folded into the existing `test_minmax_domain`/
`test_unary_gpr_domain` domain checks. A real `asm-isa-difficult-regen` run
against the now-134-entry corpus reproduced all 134 cases with
`verdict = Pass`, including the 6 new ones, with every one of the 128
pre-existing cases confirmed byte-for-byte unchanged (ignoring only the
git-rev-embedded `ours.tool_label`). `asm-isa-difficult-check`/`asm-test`
both pass; `make asm-ci` passes in full (all stages, including the
cross-smoke tri-state, characterize, melange opt-in, and js-portable legs).
`Isa_family_admission`'s pinned totals moved exactly as expected: RV64
promoted-support 144->163, blocked 980->961 (RV32 unaffected - no RV32
record for any of the six); `isa-norm-accounting`'s RV64 total moved
174->193 (+19: five mnemonics x 3 import-duplicate records plus
`aes64ks2`'s own 4, matching the three-groups accounting exactly; RV32
unaffected at 152) and the `isa-norm-jsonl` real-form round-trip count
moved 344->363 (+19), all pinned `repo_tests.ml` expectations updated and
re-verified passing on the first attempt (computed from first principles
before running, not adjusted after a failure - the two formatting fixups
were cosmetic, not count errors). `tools-test`, `tools-integration`,
`tools-boundary`, `asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`,
`tools-gasxref-diff` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: the one remaining named
Zk/Zkn/Zks family member with no new shape yet is `aes64ks1i` (RV64,
imported by `rv64_zk`/`rv64_zkn`/`rv64_zkne` per an earlier accounting
pass) - it needs a genuinely new two-GPR-plus-`rnum`-immediate shape;
`rori`/`roriw`'s `shamt_gpr_form` is the closest existing precedent
(two GPRs plus a real, syntax-visible unsigned immediate) but `rnum`'s
valid range and round-constant semantics differ from a shift amount and
have not been investigated. The RV32 AES-32 family
(`aes32dsi`/`aes32dsmi`/`aes32esi`/`aes32esmi`) also remains fully
unattempted - each needs a new three-GPR-plus-2-bit-`bs`-immediate shape,
distinct from both this slice's plain three-GPR forms and `aes64ks1i`'s
prospective two-GPR-plus-immediate one. Once those two new-shape families
are addressed, GEN-05's remaining scope is atomic, CSR, remaining vector,
and broader FP, with no single named next item.

Acceptance gate satisfied: all six mnemonics have real encoder support via
the existing generic three-register R-type and two-register unary paths
(zero new match arms, only six table rows) plus a one-line addition to the
existing `Rv64_only` gate list; matching real-GNU-as agreement confirmed
on RV64 and correct rejection confirmed on RV32; a normalization dispatch
reusing `r_type_gpr_form`/`unary_gpr_form` and the `Req_any` machinery
across three distinct groups within one slice (two new extension mappings,
one new but genuinely reusable parametrized `Req_xlen`-wrapped test
helper); a persisted, offline-replayed differential corpus entry each with
real GNU agreement; admission-matrix promotion; and a full `make asm-ci`
pass - the same measured-Pass discipline every other GEN-05/GAS-04
promotion used, with every affected pinned count in the repository's own
regression suite updated and re-verified rather than left stale.

##### GEN-05 continuation: RISC-V AES-64 `aes64ks1i` (Claude)

Task / status / owner: GEN-05 aes64ks1i sub-slice / done; GEN-05 overall /
still implementing / Claude. Unlike every prior GEN-05 slice this session,
this one could not be a mechanical table-row addition to existing shared
machinery - it needed a genuinely new immediate shape.

Scope manifest and obligations: `aes64ks1i` is AES-64's first key-schedule
helper, RV64-only, imported by `rv64_zk`/`rv64_zkn`/`rv64_zkne` alongside
primary `rv64_zknd` - the same four-way group `aes64ks2` already
established, reused verbatim (no new import group). Its own shape is
`rd`, `rs1`, and a real, syntax-visible 4-bit immediate `rnum` (bits
[23:20]) with a fixed 8-bit prefix (bits[31:24] = `0x31`), superficially
the same category as `rori`/`roriw`'s shift-amount shape - but `rnum`'s
semantically valid range (0-10) is narrower than its 4-bit field's full
capacity (0-15): confirmed against real `riscv64-linux-gnu-as` 2.44 that
rnum 0/1/8/9/10 assemble but 11/15/16/-1 are all rejected outright
("Improper rnum immediate"), not merely encoded differently. The existing
generic `i_desc`/`shamt_bits` encoder path only checks a field's raw bit
width, not a narrower semantic subrange, so reusing it unchanged would
have made this project's own assembler silently more permissive than real
GNU as for reserved round numbers - a genuine, measurable discrepancy this
project's rigor (every slice cross-validates real-GNU-as negative cases)
does not tolerate elsewhere. Rather than complicate the shared path with a
mnemonic-specific range check, `aes64ks1i` got its own dedicated,
explicitly-validated match arm (`Opcode.Aes64ks1i, [a; b; imm]`) that
folds `rnum` to a concrete value, validates it against `[0, 10]`, and
constructs `Lowered.I` directly with the composed `imm12` (`0x310 lor
rnum`) and `shamt_bits = None` - bypassing the generic `i_desc` table
entirely, so zero risk to `Slli`/`Srli`/`Srai`/`Rori`/`Roriw`. On the norm
side, `shamt_gpr_form` (previously hardcoded to `rori`/`roriw`'s own
"shamt"/"shamtw"/"shamtd" naming) gained new optional `?operand_name`/
`?field_name` parameters, defaulting to the prior behavior (zero risk to
`rori`/`roriw`'s own dispatch), so `aes64ks1i` could reuse it with
riscv-opcodes' own "rnum" field name instead of a misleading "shamt" one -
the normalized model only records the field's raw 4-bit width, not the
encoder's narrower semantic range, the same "note but don't enforce at
this layer" treatment `sltiu`'s own sign-vs-compare distinction already
gets.

Real, measured findings: hand-verified the composed-immediate formula
(`0x310 lor rnum`) against this project's own `--dump-bytes` output for
rnum 0 and 10 before any corpus wiring, then confirmed against real GNU
`as` (RV64 2.44) with `-march=..._zknd`: `aes64ks1i a0, a1, 0` and
`aes64ks1i a0, a1, 10` assemble byte-identically to this project's own
output (`13 95 05 31` for rnum=0, `13 95 a5 31` for rnum=10, little-endian
= `0x31059513` / `0x31a59513` respectively). Cross-checked
negatively on RV64: real GNU as rejects rnum 11, 15, 16, and -1, all with
the message "Improper rnum immediate"; this project's own dedicated match
arm rejects the same four values via its `[0, 10]` range check, falling
through to the generic "wrong operands" diagnostic. Cross-checked
negatively on RV32: real `riscv32-linux-gnu-as` rejects `aes64ks1i`
outright as an unrecognized opcode (genuinely absent, not merely
extension-gated), matching this project's own `` `Rv64_only `` rejection.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt-check`; `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 134 to 135 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that all 134 pre-existing cases are
byte-for-byte unchanged and exactly the 1 expected new case_id was added);
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin" make
asm-isa-difficult-check asm-test`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target).

Results and artifact links: 3 new `isa-norm-riscv` checks (`test_aes64ks1i`,
against its own real, verbatim-extracted riscv64.jsonl record, explicitly
asserting the four-way `Req_any` and the unsigned 4-bit "rnum"-named
immediate operand); a new dedicated `test_aes64ks1i_domain` check (not
folded into `test_shamt_domain`, since that check hardcodes the "shamt"
operand key literally, and `aes64ks1i`'s own key is "rnum"). A real
`asm-isa-difficult-regen` run against the now-135-entry corpus reproduced
all 135 cases with `verdict = Pass`, including the 1 new one, with every
one of the 134 pre-existing cases confirmed byte-for-byte unchanged
(ignoring only the git-rev-embedded `ours.tool_label`).
`asm-isa-difficult-check`/`asm-test` both pass; `make asm-ci` passes in
full (all stages, including the cross-smoke tri-state, characterize,
melange opt-in, and js-portable legs). `Isa_family_admission`'s pinned
totals moved exactly as expected: RV64 promoted-support 163->167, blocked
961->957 (RV32 unaffected - no RV32 record at all); `isa-norm-accounting`'s
RV64 total moved 193->197 (+4, matching `aes64ks2`'s own four-way
import-duplicate group verbatim; RV32 unaffected at 152) and the
`isa-norm-jsonl` real-form round-trip count moved 363->367 (+4), all
pinned `repo_tests.ml` expectations updated and re-verified passing on the
first attempt (computed from first principles before running, not
adjusted after a failure). `tools-test`, `tools-integration`,
`tools-boundary`, `asm-fmt-check`, `asm-purity`, `asm-js-portable`,
`tools-isa-inventory-diff`, `tools-gasxref-diff` all pass unchanged
otherwise.

Unknowns, exceptions and follow-up task IDs: with this slice, the RV32
AES-32 family (`aes32dsi`/`aes32dsmi`/`aes32esi`/`aes32esmi`) is now the
only remaining NAMED Zk/Zkn/Zks item - each needs a new
three-GPR-plus-2-bit-`bs`-immediate shape (`rd`/`rs1`/`rs2` plus a real
2-bit byte-select immediate), combining this slice's own narrow-immediate
lesson (a field wider than the semantically valid range, needing explicit
validation) with a three-register base rather than `aes64ks1i`'s
two-register one - a fourth distinct operand shape this project has not
yet built, on top of the three-GPR, two-GPR-unary, and
two-GPR-plus-narrow-immediate ones already established. Once that family
is addressed, GEN-05's remaining scope is atomic, CSR, remaining vector,
and broader FP, with no single named next item.

Acceptance gate satisfied: `aes64ks1i` has real encoder support via a new,
minimal, explicitly-validated match arm (zero changes to the shared
`i_desc`/`shamt_bits` path, so zero risk to `Slli`/`Srli`/`Srai`/`Rori`/
`Roriw`); matching real-GNU-as agreement confirmed on RV64 including the
exact 0-10 valid-range boundary (not just the field's raw bit width) and
correct rejection confirmed on RV32; a normalization dispatch reusing a
newly-generalized `shamt_gpr_form` (backward-compatible optional
parameters, zero risk to `rori`/`roriw`'s own dispatch); a persisted,
offline-replayed differential corpus entry with real GNU agreement;
admission-matrix promotion; and a full `make asm-ci` pass - the same
measured-Pass discipline every other GEN-05/GAS-04 promotion used, with
every affected pinned count in the repository's own regression suite
updated and re-verified rather than left stale.

##### GEN-05 continuation: RISC-V AES-32 `aes32dsi`/`aes32dsmi`/`aes32esi`/`aes32esmi` (Claude)

Task / status / owner: GEN-05 aes32dsi/dsmi/esi/esmi sub-slice / done;
GEN-05 overall / still implementing / Claude - this closes the entire
named Zk/Zkn/Zks AES/SHA scope surveyed this session.

Scope manifest and obligations: these four mnemonics are AES-32's own
round functions, RV32-only (no RV64 record at all - confirmed: real
riscv64-linux-gnu-as rejects all four as unrecognized opcodes). Their
group structure is the RV32 mirror of `aes64ds`/`aes64dsm`'s and
`aes64es`/`aes64esm`'s own: `aes32dsi`/`aes32dsmi` are rooted in a primary
`rv32_zknd` (three-way Req_any: `rv32_zknd`/`rv32_zk`/`rv32_zkn`);
`aes32esi`/`aes32esmi` are rooted in a disjoint primary `rv32_zkne`
(three-way Req_any: `rv32_zkne`/`rv32_zk`/`rv32_zkn`, no `rv32_zknd`
membership - hand-verified, not assumed). The real new shape here: `bs` is
a genuine, syntax-visible 2-bit immediate at bits[31:30], sitting directly
ABOVE the 5-bit fixed selector that would otherwise occupy `word_r`'s own
7-bit `funct7` span (bits[31:25]) for a plain three-register form. Unlike
`aes64ks1i`'s `rnum` (a field wider than its semantically valid range), `bs`
uses its FULL 2-bit range (0-3) - confirmed against real
`riscv32-linux-gnu-as` 2.43.1 that all four `bs` values assemble for every
mnemonic and `bs = 4` is rejected purely for overflowing the 2-bit field
width, not any narrower reserved subset - so this slice needed no extra
semantic-range validation beyond the field's own width. Since `bs` and the
fixed 5-bit selector together span exactly `word_r`'s existing 7-bit
`funct7` argument, this reuses `Lowered.R`/`word_r` completely unchanged by
composing them into one 7-bit value at lowering time (`(bs lsl 5) lor
base`) inside a dedicated match arm - zero new `Lowered` variants, four new
`base` values folded into that composed `funct7` rather than a plain
`r_desc` table entry (`aes32dsi = 0x15`, `aes32dsmi = 0x17`, `aes32esi =
0x11`, `aes32esmi = 0x13`). On the norm side, a genuinely new
`r_type_imm_gpr_form` function was added - the three-GPR analogue of
`shamt_gpr_form`'s two-GPR-plus-immediate one, both now sharing the same
generalized field/operand-naming approach - plus two new
`feature_of_extension` mappings (`rv32_zknd`, `rv32_zkne`).

Real, measured findings: hand-computed the composed-`funct7` formula
against this project's own `--dump-bytes` output for representative
mnemonic/`bs` pairs before any corpus wiring, then confirmed against real
GNU `as` (RV32 2.43.1) with `-march=..._zknd_zkne` across all 16
mnemonic-x-`bs`-value combinations: `aes32dsi a0, a1, a2, 0` ->
`0x2ac58533`, `aes32dsi ..., 1` -> `0x6ac58533`, `aes32dsmi ..., 2` ->
`0xaec58533`, `aes32esi ..., 3` -> `0xe2c58533`, `aes32esmi ..., 1` ->
`0x66c58533` - all matching this project's own output exactly. Cross-checked
negatively: real GNU as rejects `bs = 4` as "Improper bs immediate" on all
four mnemonics, and rejects all four mnemonics outright on RV64 as
unrecognized opcodes.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt`/`asm-fmt-check`
(a real formatting nit in the new `r_type_imm_gpr_form` function - lines
too wide for the pinned `ocamlformat` width - was caught by
`asm-fmt-check` and fixed with `asm-fmt`'s auto-promote before the rest of
the gate ran); `make asm-purity`; `make asm-js-portable`; `make
tools-isa-inventory-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 135 to 139 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that all 135 pre-existing cases are
byte-for-byte unchanged and exactly the 4 expected new case_ids - all
RV32 - were added); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-check asm-test`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target).

Results and artifact links: 12 new `isa-norm-riscv` checks (`test_aes32dsi`/
`test_aes32dsmi`/`test_aes32esi`/`test_aes32esmi`, via a new
`test_r_type_imm_gpr_any_rv32` helper, against their own real,
verbatim-extracted riscv32.jsonl records, explicitly asserting each of the
two distinct three-way `Req_any` groups); a new RV32-only entry-count check
plus a dedicated `test_aes32_domain` check (not folded into
`test_shamt_domain`/`test_aes64ks1i_domain`, since those hardcode
different operand-key/arity shapes). A real `asm-isa-difficult-regen` run
against the now-139-entry corpus reproduced all 139 cases with
`verdict = Pass`, including the 4 new ones, with every one of the 135
pre-existing cases confirmed byte-for-byte unchanged (ignoring only the
git-rev-embedded `ours.tool_label`). `asm-isa-difficult-check`/`asm-test`
both pass; `make asm-ci` passes in full (all stages, including the
cross-smoke tri-state, characterize, melange opt-in, and js-portable legs).
`Isa_family_admission`'s pinned totals moved exactly as expected: RV32
promoted-support 132->144, blocked 937->925 (RV64 unaffected - no RV64
record for any of the four); `isa-norm-accounting`'s RV32 total moved
152->164 (+12: four mnemonics x 3 import-duplicate records each; RV64
unaffected at 197) and the `isa-norm-jsonl` real-form round-trip count
moved 367->379 (+12), all pinned `repo_tests.ml` expectations updated and
re-verified passing on the first attempt (computed from first principles
before running, not adjusted after a failure - the formatting fixup was
cosmetic, not a count error). `tools-test`, `tools-integration`,
`tools-boundary`, `asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`,
`tools-gasxref-diff` all pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: this closes the last named
Zk/Zkn/Zks item from this session's survey - every AES/SHA mnemonic across
all four operand shapes built this session (two-GPR unary, three-GPR
plain, two-GPR-plus-narrow-immediate, three-GPR-plus-narrow-immediate) is
now admitted on both profiles wherever riscv-opcodes has a record for it.
GEN-05's remaining scope has no single named next item: atomic, CSR,
remaining vector, and broader FP families each still need their own
shape/requirement survey before a next concrete sub-slice can be named,
the same way this session's earlier self-selected slices (clmul/clmulh,
xperm4/xperm8, and the entire Zknh/Zk AES/SHA arc) each started from a
fresh `isa-inventory norm-accounting` survey rather than an inherited
follow-up.

Acceptance gate satisfied: all four mnemonics have real encoder support
via a new, minimal dedicated match arm reusing `Lowered.R`/`word_r`
completely unchanged (zero new lowered-instruction shapes, four new
composed-`funct7` base values); matching real-GNU-as agreement confirmed
across all 16 mnemonic-x-`bs`-value combinations spot-checked on RV32 and
correct rejection confirmed on both the field-overflow case and RV64; a
normalization dispatch via a new but genuinely reusable
`r_type_imm_gpr_form` function (the three-GPR sibling of the existing
`shamt_gpr_form`) plus two new extension mappings; a persisted,
offline-replayed differential corpus entry each with real GNU agreement;
admission-matrix promotion; and a full `make asm-ci` pass - the same
measured-Pass discipline every other GEN-05/GAS-04 promotion used, with
every affected pinned count in the repository's own regression suite
updated and re-verified rather than left stale.

##### GEN-05 continuation: RISC-V Zicsr `csrrw`/`csrrs`/`csrrc`/`csrrwi`/`csrrsi`/`csrrci` (Claude)

Task / status / owner: GEN-05 csrrw/csrrs/csrrc/csrrwi/csrrsi/csrrci
sub-slice / done; GEN-05 overall / still implementing / Claude -
self-selected from a fresh `isa-inventory norm-accounting` survey now that
the top-unhandled-name list is dominated by vector-crypto/vector-bitmanip
mnemonics (`vandn.vv`, `vbrev8.v`, `vrol.vv`, `vsha2ch.vv`, etc.) requiring
an entirely new vector register class this project has not built. CSR
(`rv_zicsr`, 13 records total) was chosen instead as the smallest bounded
remaining family.

Scope manifest and obligations: these six mnemonics are Zicsr's CSR access
forms, XLEN-independent (identical syntax on both profiles) and NOT
import-duplicated - a single `rv_zicsr` record per mnemonic, so a plain
`Req_feature`, no `Req_any` group. This is a first for this session: every
prior slice needed at least one `Req_any` group. `csrrw`/`csrrs`/`csrrc`
are register-source forms whose real GAS text operand order - `[rd, csr,
rs1]` - genuinely differs from riscv-opcodes' own `encoding.fields`/
`operands` declaration order, `[rd, rs1, csr]` (confirmed against real
`riscv32-linux-gnu-as`: `csrrw a0, mstatus, a1` assembles to the SAME bit
pattern as the fields-order `rd`/`rs1`/`csr`, just written with `csr`
before `rs1` in source text). `csr` is a real 12-bit UNSIGNED address
(0-4095) - unlike every prior I-type immediate this project encodes, which
was signed - and rather than adding new bit-masking machinery, the
dedicated match arm writes each `csr` value's own SIGNED 12-bit two's-
complement equivalent (subtracting 4096 when >= 2048, e.g. `mhartid =
0xf14 = 3860 -> -236`) into the existing `Lowered.I`/`word_i` path
unchanged, since that path's own field-masking already operates on raw
two's-complement bit patterns and produces identical encoded bits either
way (confirmed against real GNU as: `csrrw a0, 0xf14, a1` -> `f1459573`).
`csrrwi`/`csrrsi`/`csrrci` are immediate-source forms with NO register
operand besides `rd` - `zimm5` (a real 5-bit unsigned immediate, 0-31;
real GNU as rejects 32+ as "improper CSRxI immediate") reuses the exact
bit position (bits[19:15]) a GPR number would occupy in `rs1`, since
`word_i`'s own encoding is bit-identical either way, so this also needed
zero new lowered-instruction shapes. On the norm side, two genuinely new
normalization functions were added: `csr_reg_form` (the three-operand
`rd`/`csr`/`rs1` shape, with the GAS-vs-riscv-opcodes operand-order
mismatch documented explicitly in a fact) and `csr_imm_form` (`rd`/`csr`/
`zimm5`), plus one new `feature_of_extension` mapping (`rv_zicsr`).

Real, measured findings: hand-verified the signed-wraparound formula
against this project's own `--dump-bytes` output for `csr = 0x300`
(mstatus) and `csr = 0xf14` (mhartid, exercising the > 2047 wraparound)
before any corpus wiring, then confirmed against real GNU `as` (RV32
2.43.1, RV64 2.44): `csrrw`/`csrrs`/`csrrc`/`csrrwi`/`csrrsi`/`csrrci`
with `csr = 0x300` all assemble byte-identically to this project's own
output on both profiles (`73 95 05 30` / `73 a5 05 30` / `73 b5 05 30` /
`73 d5 02 30` / `73 e5 02 30` / `73 f5 02 30`), and `csrrw a0, 0xf14, a1`
matches too (`73 95 45 f1` = `0xf1459573`). Cross-checked negatively: real
GNU as rejects `csr = 4096` as "improper CSR address" and `zimm5 = 32` as
"improper CSRxI immediate" - both boundaries matched exactly by this
project's own dedicated match-arm validation (`csr` 0-4095, `zimm5` 0-31).

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
`cd asm && opam exec -- dune build @runtest`; `make tools-test`; `make
tools-integration`; `make tools-boundary`; `make asm-fmt`/`asm-fmt-check`
(formatting nits across three files - two long inline `let` bindings in
the new encoder match arms and two test files - were caught by
`asm-fmt-check`; the first `asm-fmt` pass left one file still
non-conformant, needing a second `asm-fmt` invocation before
`asm-fmt-check` passed clean); `make asm-purity`; `make asm-js-portable`;
`make tools-isa-inventory-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make tools-gasxref-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 139 to 151 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `ours.tool_label`, that all 139 pre-existing cases are
byte-for-byte unchanged and exactly the 12 expected new case_ids - 6
mnemonics x 2 profiles - were added); `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-isa-difficult-check asm-test`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin"
make asm-ci` (full CI target).

Results and artifact links: 18 new `isa-norm-riscv` checks (`test_csrrw`/
`test_csrrs`/`test_csrrc` via a new `test_csr_reg` helper,
`test_csrrwi`/`test_csrrsi`/`test_csrrci` via a new `test_csr_imm` helper,
against their own real, verbatim-extracted riscv32.jsonl records,
explicitly asserting the plain `Req_feature` and the reordered `rd, csr,
rs1`/`rd, csr, zimm5` rendering); two new entry-count and domain checks
(not folded into any prior R-type/shamt domain check, since this family's
own operand key/count/order combination is unique). A real
`asm-isa-difficult-regen` run against the now-151-entry corpus reproduced
all 151 cases with `verdict = Pass`, including the 12 new ones, with every
one of the 139 pre-existing cases confirmed byte-for-byte unchanged
(ignoring only the git-rev-embedded `ours.tool_label`).
`asm-isa-difficult-check`/`asm-test` both pass; `make asm-ci` passes in
full (all stages, including the cross-smoke tri-state, characterize,
melange opt-in, and js-portable legs). `Isa_family_admission`'s pinned
totals moved exactly as expected: RV32 promoted-support 144->150, blocked
925->919; RV64 promoted-support 167->173, blocked 957->951;
`isa-norm-accounting`'s totals moved 164->170 (RV32) / 197->203 (RV64) -
the FIRST slice this session where every profile gains exactly 6 records
(one per mnemonic), since none are import-duplicated, unlike every prior
slice's x2/x3/x4 multiplier - and the `isa-norm-jsonl` real-form
round-trip count moved 379->391 (+12), all pinned `repo_tests.ml`
expectations updated and re-verified passing on the first attempt
(computed from first principles before running, not adjusted after a
failure - the formatting fixups were cosmetic, not count errors).
`tools-test`, `tools-integration`, `tools-boundary`, `asm-purity`,
`asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all
pass unchanged otherwise.

Unknowns, exceptions and follow-up task IDs: the GAS pseudo-op aliases
(`csrr`/`csrw`/`csrs`/`csrc`/`csrwi`/`csrsi`/`csrci` - 7 more mnemonics,
each a `rd`-or-`rs1`-omitting shorthand for one of the six real
instruction-forms just admitted) remain unattempted, a natural next
continuation of this same family. GEN-05's other remaining named scope -
atomic (`rv_a`/`rv64_a`, 22 records total), remaining vector (`rv_v` and
its crypto/bitmanip extensions, 375+ records, needs a new vector register
class), and broader FP (`rv_f`/`rv_d`/`rv_q`/`rv_zfh`, ~124 records
combined) - still has no single concrete next item picked; this slice
itself was self-selected from survey rather than inherited, the same way
`clmul`/`clmulh` and `xperm4`/`xperm8` were earlier in the session.

Acceptance gate satisfied: all six mnemonics have real encoder support via
two new, minimal, dedicated match arms reusing `Lowered.I`/`word_i`
completely unchanged (zero new lowered-instruction shapes); matching
real-GNU-as agreement confirmed on both profiles including the CSR-address
wraparound case and both immediate-range boundaries (`csr` and `zimm5`);
a normalization dispatch via two new but genuinely reusable functions
(`csr_reg_form`/`csr_imm_form`), the session's first slice needing no
`Req_any` group at all; a persisted, offline-replayed differential corpus
entry each with real GNU agreement; admission-matrix promotion; and a full
`make asm-ci` pass - the same measured-Pass discipline every other
GEN-05/GAS-04 promotion used, with every affected pinned count in the
repository's own regression suite updated and re-verified rather than
left stale.

##### GEN-05 continuation: RISC-V Zicsr pseudo-ops `csrr`/`csrw`/`csrs`/`csrc`/`csrwi`/`csrsi`/`csrci` (Claude)

Task / status / owner: GEN-05 csrr/csrw/csrs/csrc/csrwi/csrsi/csrci
sub-slice / done; GEN-05 overall / still implementing / Claude - the
explicitly-named follow-up from the immediately preceding `csrrw`/`csrrs`/
`csrrc`/`csrrwi`/`csrrsi`/`csrrci` milestone: these 7 mnemonics are GAS's
own pseudo-op aliases for the six real CSR instruction-forms just admitted,
each omitting whichever operand (`rd` or `rs1`) real hardware doesn't need.

Scope manifest and obligations: riscv-opcodes exports each of these 7 as a
`kind: pseudo-op` record (not `instruction-form`) with its own
`relationships`/`specializes-reference` pointing back at the real
`csrr{w,s,c}`/`csrr{w,s,c}i` record it aliases - `requirement_of` still
works unchanged since these records carry their own
`provenance.extension = rv_zicsr` directly. Three distinct operand shapes
were needed, none reusable from the base forms' own `csr_reg_form`/
`csr_imm_form` (both of which assume 3 operands): `csrr rd, csr` (GAS's
read-only alias for `csrrs rd, csr, x0` - `[rd, csr]`, riscv-opcodes' own
`encoding.fields`/`operands` order already matches GAS syntax here, since
there is no `rs1` to reorder around); `csrw`/`csrs`/`csrc csr, rs1`
(write/set/clear-only aliases for `csrrw`/`csrrs`/`csrrc x0, csr, rs1` -
`[csr, rs1]`, csr FIRST, again differing from riscv-opcodes' own `[rs1,
csr]` field order, the same GAS-vs-riscv-opcodes mismatch the base
register-source forms had); and `csrwi`/`csrsi`/`csrci csr, zimm5`
(write/set/clear-only aliases for the `*i` forms - `[csr, zimm5]`,
riscv-opcodes' own order already matches GAS syntax here too). On the
encoder side, three new dedicated match arms were added
(`Opcode.Csrr`/`Csrw|Csrs|Csrc`/`Csrwi|Csrsi|Csrci`), each fixing the
omitted register to literal `0` (`rd = 0` for the write/set/clear forms,
`rs1 = 0` for the read form) and reusing the exact same `csr`-address
signed-two's-complement encoding as the base forms - factored out into one
shared `signed_csr` helper this slice, replacing the inline duplicate
formula each of the two base-form match arms had carried since the prior
milestone. On the norm side, three new shape functions were added
(`csr_read_form`, `csr_write_form`, `csr_write_imm_form`), plus a small
`csr_immediate_operand` helper factoring out the `csr` operand definition
shared by all five CSR shape functions (the two base-form ones and these
three new ones).

Real, measured findings: verified real GNU-as's exact operand order for
all 7 aliases before writing any code (`riscv32-linux-gnu-as
-march=rv32i_zicsr -mabi=ilp32`): `csrr a0, 0x300` -> `30002573` (same
bits as `csrrs a0, mstatus, zero`); `csrw 0x300, a1` -> `30059073`;
`csrs 0x300, a1` -> `3005a073`; `csrc 0x300, a1` -> `3005b073`;
`csrwi 0x300, 5` -> `3002d073`; `csrsi 0x300, 5` -> `3002e073`;
`csrci 0x300, 5` -> `3002f073` - each matching the corresponding
`csrr{w,s,c}[i] {x0 or zero}, csr, {rs1 or zimm5 or none}` bit pattern
exactly. This project's own `asm.exe --dump-bytes` reproduced all 7 byte-
for-byte identically on both RV32 and RV64 (Zicsr is XLEN-independent).
Cross-checked negatively: `csrr a0, 4096` and `csrwi 0x300, 32` are both
rejected by this project's dedicated match arms (`csr`/`zimm5` out of
range), matching the same boundaries the base forms already enforced.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
real-toolchain smoke test via `riscv32-linux-gnu-as`/`objdump` and this
project's own `asm.exe --dump-bytes`, both directions (positive bytes and
negative range-rejection); `make tools-test`; `make tools-integration`
(first run intentionally left `repo_tests.ml`'s pinned counts stale to read
off the real new numbers, then hard-coded them, then re-ran clean); `make
tools-boundary`; `make asm-fmt`/`asm-fmt-check` (one nit in the new
`test_csrr`/`test_csr_write` helpers, fixed by a single `asm-fmt` pass);
`make asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin:/usr/local/riscv64-linux-gnu-toolchain/bin"
make tools-gasxref-diff` (both no-op); same `PATH` prefix for
`make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 151 to 165 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `gas.tool_label`/`ours.tool_label`, that all 151
pre-existing cases are byte-for-byte unchanged and exactly the 14 expected
new case_ids - 7 mnemonics x 2 profiles - were added); `make
asm-isa-difficult-check asm-test`; `make asm-ci` (full CI target,
backgrounded).

Results and artifact links: 7 new `isa-norm-riscv` unit tests (`test_csrr`
via its own body, `test_csrw`/`test_csrs`/`test_csrc` via a new
`test_csr_write` helper, `test_csrwi`/`test_csrsi`/`test_csrci` via a new
`test_csr_write_imm` helper), each against its own real, verbatim-extracted
riscv32.jsonl pseudo-op record, asserting the plain `Req_feature` and the
correct 2-operand rendering per shape. Three new entry-count and domain
checks in `test_isa_gen_difficult.ml` (`test_csrr_domain`,
`test_csr_write_domain`, `test_csr_write_imm_domain`), plus 14 new corpus
entries (`csrr_entries` through `csrci_entries`, `0x300`/mstatus by the
same convention the base forms used). `Isa_family_admission`'s pinned
totals moved: RV32 promoted-support 150->157, blocked 919->912; RV64
promoted-support 173->180, blocked 951->944 (all 14 new normalized records
now credited, none left in the "normalized-only" bucket);
`isa-norm-accounting`'s totals moved 170->177 (RV32) / 203->210 (RV64) -
another slice where every profile gains exactly 7 records (one per
mnemonic), since none of the 7 pseudo-op records are import-duplicated -
and the `isa-norm-jsonl` real-form round-trip count moved 391->405 (+14),
all pinned `repo_tests.ml` expectations updated and re-verified passing.
`tools-test`, `tools-integration`, `tools-boundary`, `asm-purity`,
`asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all
pass; `asm-isa-difficult-check`/`asm-test` both pass; `make asm-ci` passes
in full.

Unknowns, exceptions and follow-up task IDs: this closes every Zicsr
mnemonic in the checked-in riscv-opcodes export (13 records total: 6 real
instruction-forms plus these 7 pseudo-ops) - no follow-up remains within
Zicsr itself. GEN-05's other remaining named scope - atomic (`rv_a`/
`rv64_a`, 22 records total), remaining vector (`rv_v` and its crypto/
bitmanip extensions, 375+ records, needs a new vector register class), and
broader FP (`rv_f`/`rv_d`/`rv_q`/`rv_zfh`, ~124 records combined) - still
has no single concrete next item picked; whichever is tackled next will
need its own fresh survey/scoping the same way CSR itself was self-selected
two milestones ago.

Acceptance gate satisfied: all 7 mnemonics have real encoder support via
three new, minimal, dedicated match arms plus a shared `signed_csr` helper
(also now used by the two pre-existing base-form match arms, removing their
prior inline duplication); matching real-GNU-as agreement confirmed on
both profiles for every mnemonic, including both immediate-range
boundaries; a normalization dispatch via three new but genuinely reusable
shape functions (`csr_read_form`/`csr_write_form`/`csr_write_imm_form`)
plus a shared `csr_immediate_operand` helper; a persisted, offline-replayed
differential corpus entry each with real GNU agreement; admission-matrix
promotion; and a full `make asm-ci` pass - the same measured-Pass
discipline every other GEN-05/GAS-04 promotion used, with every affected
pinned count in the repository's own regression suite updated and
re-verified rather than left stale.

##### GEN-05 continuation: RISC-V Zaamo `amoswap`/`amoadd`/`amoxor`/`amoand`/`amoor`/`amomin`/`amomax`/`amominu`/`amomaxu`/`sc`/`lr` on `.w`/`.d` (Claude)

Task / status / owner: GEN-05 Zaamo atomic-memory-operation family /
done; GEN-05 overall / still implementing / Claude - self-selected after
Zicsr closed, per the same survey discipline CSR itself was picked with:
atomic (`rv_a`/`rv64_a`, 22 records) was the smallest still-unadmitted
bounded family, ahead of the remaining vector (375+ records, needs a new
register class) and broader FP (~124 records) scope.

Scope manifest and obligations: 22 `kind: instruction-form` records total
- 9 `amoOP.w` mnemonics plus `sc.w`/`lr.w` (11 records, `rv_a`, both
profiles) and the identical 9 `amoOP.d` plus `sc.d`/`lr.d` (11 records,
`rv64_a`, RV64-only). This is the first GEN-05 family whose GAS syntax
uses a real memory group (`(rs1)`) rather than a plain register or
immediate third operand, and the first where the record's own `aq`/`rl`
fields are real, independently encodable bits that this slice deliberately
does not expose as operands - only GAS's bare canonical (aq=0,rl=0)
spelling is normalized/encoded, per the plan's section 5.2 "canonical
spelling first ... decorators ... as separately identified cases" policy.
Two shapes were needed: `amo_form`/`amo3_desc` (three-GPR-plus-memory:
`rd, rs2, (base)`, covering all 9 `amoOP` mnemonics plus `sc` on both
widths) and `lr_form`/`lr_desc` (two-operand: `rd, (base)`, `rs2`'s field
fixed to 0 and not modeled as an operand, the same omission convention
`csr_write_form` uses for its implicit-x0 register).

Real, measured findings: verified real GNU-as's exact funct5 assignment
and operand order for all 11 `.w` mnemonics before writing any code
(`riscv32-linux-gnu-as -march=rv32ia -mabi=ilp32`): `amoswap.w a0, a1,
(a2)` -> `08b6252f`, `amoadd.w` -> `00b6252f`, `amoxor.w` -> `20b6252f`,
`amoand.w` -> `60b6252f`, `amoor.w` -> `40b6252f`, `amomin.w` ->
`80b6252f`, `amomax.w` -> `a0b6252f`, `amominu.w` -> `c0b6252f`,
`amomaxu.w` -> `e0b6252f`, `sc.w` -> `18b6252f`, `lr.w` -> `1006252f` -
every funct7 (aq=rl=0) matches `funct5 << 2` for the RISC-V ISA manual's
own funct5 assignment exactly. Confirmed `.d`'s funct3 (3, not `.w`'s 2)
against `riscv64-linux-gnu-as -march=rv64ia -mabi=lp64`: `amoswap.d` ->
`08b6352f`, `lr.d` -> `1006352f`, `sc.d` -> `18b6352f`. Confirmed the
memory operand carries no real offset field: `amoadd.w a0, a1, 4(a2)` is
rejected ("illegal operands"), enforced in the encoder via a `zero_offset`
guard on the folded constant rather than silently dropping a nonzero one.
Confirmed the `.aq`/`.rl`/`.aqrl` mnemonic-suffix decorators GAS accepts
on all 22 (`amoadd.w.aq a0, a1, (a2)` -> `04b6252f`, setting the aq bit)
are out of this slice's scope - rejected by this project's parser as an
unrecognized instruction, which is the correct behavior for a decorator
not yet implemented, not a regression. This project's own `asm.exe
--dump-bytes` reproduced all 11 `.w` plus 3 representative `.d` bytes
exactly. Decode support (`lower_instruction`'s `decode`) only recognizes
the aq=rl=0 bit pattern (`f7 land 0x3 = 0`), consistent with never
emitting the other pattern; a set aq/rl bit is left undecoded rather than
silently mis-rendered.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build
@all`; real-toolchain smoke test via `riscv32-linux-gnu-as`/
`riscv64-linux-gnu-as`/`objdump` and this project's own `asm.exe
--dump-bytes`, covering every `.w` mnemonic, three `.d` mnemonics, the
nonzero-offset rejection, and the `.aq` suffix rejection; `make
tools-test` (one `isa-gen-difficult` self-consistency check failed until
the new `_entries` lists were added to `test_isa_gen_difficult.ml`'s own
sum, then passed clean); `make tools-integration` (first run intentionally
left `repo_tests.ml`'s pinned counts stale to read off the real new
numbers - 11/22 exactly, matching the two profiles' own record counts -
then hard-coded them, then re-ran clean); `make tools-boundary`; `make
asm-fmt`/`asm-fmt-check` (several nits in the new encoder/test code, fixed
by a single `asm-fmt` pass); `make asm-purity`; `make asm-js-portable`;
`make tools-isa-inventory-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin:/usr/local/riscv64-linux-gnu-toolchain/bin"
make tools-gasxref-diff` (no-op); same `PATH` prefix for `make
asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 165 to 198 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `gas.tool_label`/`ours.tool_label`, that all 165
pre-existing cases are byte-for-byte unchanged and exactly the 33 expected
new case_ids - 22 `.w`-group entries across both profiles plus 11
RV64-only `.d`-group entries - were added, every one `verdict = Pass`);
`make asm-isa-difficult-check asm-test`; `make asm-ci` (full CI target,
backgrounded).

Results and artifact links: 2 new `isa-norm-riscv` unit tests
(`test_amoadd_w`, `test_lr_w`, each against its own real, verbatim-
extracted riscv32.jsonl record, representative of `amo_form`/`lr_form`
since every other mnemonic in the family shares one of these two shapes
and only funct5/funct3 differ), asserting the operand list, syntax
rendering, and the new `-aq-rl-not-modeled` diagnostic. Two new domain
checks in `test_isa_gen_difficult.ml` (`test_amo_domain`,
`test_lr_domain`) covering all 22 corpus entries, plus the 22 new entries
themselves (`amoswap_w_entries` through `lr_d_entries`).
`Isa_family_admission`'s pinned totals moved: RV32 promoted-support
157->168, blocked 912->901; RV64 promoted-support 180->202, blocked
944->922 (all 33 new normalized records now credited); `isa-norm-
accounting`'s totals moved 177->188 (RV32) / 210->232 (RV64), and the
`isa-norm-jsonl` real-form round-trip count moved 405->438 (+33), all
pinned `repo_tests.ml` expectations updated and re-verified passing.
`tools-test`, `tools-integration`, `tools-boundary`, `asm-purity`,
`asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all
pass; `asm-isa-difficult-check`/`asm-test` both pass; `make asm-ci` passes
in full.

Unknowns, exceptions and follow-up task IDs: this closes every Zaamo
mnemonic that fits the two operand shapes built (all 22 records in the
checked-in export) under GAS's bare canonical spelling. The `.aq`/`.rl`/
`.aqrl` mnemonic-suffix decorators (real, independently encodable bits on
every one of these 22 records) remain an explicit, named follow-up - not
silently dropped, flagged via each form's own `-aq-rl-not-modeled`
diagnostic - since supporting them needs new textual-decorator parsing
machinery this slice does not add. GEN-05's other remaining named scope -
remaining vector (`rv_v` and its crypto/bitmanip extensions, 375+
records, needs a new vector register class) and broader FP (`rv_f`/
`rv_d`/`rv_q`/`rv_zfh`, ~124 records combined) - still has no single
concrete next item picked; whichever is tackled next will need its own
fresh survey/scoping the same way CSR and Zaamo itself were self-selected.

Acceptance gate satisfied: all 22 mnemonics have real encoder support via
two new, minimal, dedicated match arms (`amo3_desc`/`lr_desc`) reusing the
existing `Lowered.R`/`word_r` path unchanged; matching real-GNU-as
agreement confirmed for every `.w` mnemonic and three representative `.d`
ones, plus the nonzero-offset and `.aq`-suffix rejection boundaries; a
normalization dispatch via two new, genuinely reusable shape functions
(`amo_form`/`lr_form`) with an explicit diagnostic for the deliberately
unmodeled aq/rl bits; a persisted, offline-replayed differential corpus
entry each with real GNU agreement; admission-matrix promotion; and a
full `make asm-ci` pass - the same measured-Pass discipline every other
GEN-05/GAS-04 promotion used, with every affected pinned count in the
repository's own regression suite updated and re-verified rather than
left stale.

##### GEN-05 continuation: RISC-V F/D floating-point loads/stores `flw`/`fld`/`fsw`/`fsd` (Claude)

Task / status / owner: GEN-05 F/D floating-point load/store sub-slice /
done; GEN-05 overall / still implementing / Claude - self-selected after
Zaamo closed: broader FP (`rv_f`/`rv_d`/`rv_q`/`rv_zfh`, ~124 records) is
smaller and more bounded than the remaining vector scope (375+ records,
needs a new register class), and within FP, `flw`/`fld`/`fsw`/`fsd` were
the cheapest next increment - all four are *already fully implemented by
the encoder* (`f_load_desc`/`f_store_desc`, wired since before this
consumption effort began), so this slice closes only the missing
normalization/corpus/admission side, with no encoder change at all.

Scope manifest and obligations: 4 `kind: instruction-form` records -
`flw`/`fsw` (`rv_f`, both profiles) and `fld`/`fsd` (`rv_d`, both
profiles - F/D are not XLEN-specific, unlike Zaamo's `.w`/`.d` split).
Two new shapes: `f_load_form` (I-type, single-run `imm12`, byte-for-byte
{!i_type_imm_form}'s own immediate shape except `rd` is `fpr()` not
`gpr()`) and `f_store_form` (S-type, the identical `imm12hi`/`imm12lo`
split {!sw_form} uses, except the stored value is `fpr()`). `feature_of_extension`
gained an `"rv_d" -> Req_feature "riscv:d"` entry (only `"rv_f"` existed
before, from the earlier bare-arithmetic slice).

Real, measured findings: verified real GNU-as's exact bytes for all four
mnemonics before writing any normalization code (`riscv32-linux-gnu-as
-march=rv32ifd -mabi=ilp32d`, `riscv64-linux-gnu-as -march=rv64ifd
-mabi=lp64d`): `flw fa0, 8(a1)` -> `0085a507`, `fsw fa0, 8(a1)` ->
`00a5a427`, `fld fa0, 8(a1)` -> `0085b507`, `fsd fa0, 8(a1)` ->
`00a5b427`, identical on both profiles. This project's own `asm.exe
--dump-bytes` reproduced all four exactly - expected, since the encoder
side was already implemented, but confirmed rather than assumed. Also
confirmed the precision-suffix march convention {!f_arith_configuration_for}
already established generalizes correctly to loads/stores: `-march=rv32imf`
correctly rejects `fld`/`fsd` ("extension \`d' required"), while
`-march=rv32imd` accepts all four (D implies F), so the existing "f"/"d"
precision parameter needed no new configuration function.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build
@all`; real-toolchain smoke test via `riscv32-linux-gnu-as`/
`riscv64-linux-gnu-as`/`objdump` and this project's own `asm.exe
--dump-bytes` for all four mnemonics on both profiles, plus the
`rv32imf`-rejects-`fld`/`rv32imd`-accepts-all-four march probe; `make
tools-test`; `make tools-integration` (first run intentionally left
`repo_tests.ml`'s pinned counts stale to read off the real new numbers -
4 per profile exactly, matching the four records - then hard-coded them,
then re-ran clean); `make tools-boundary`; `make asm-fmt`/`asm-fmt-check`
(a few line-length nits, fixed by a single `asm-fmt` pass); `make
asm-purity`; `make asm-js-portable`; `make tools-isa-inventory-diff`;
`PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin:/usr/local/riscv64-linux-gnu-toolchain/bin"
make tools-gasxref-diff` (no-op); same `PATH` prefix for `make
asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 198 to 206 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `gas.tool_label`/`ours.tool_label`, that all 198
pre-existing cases are byte-for-byte unchanged and exactly the 8 expected
new case_ids - 4 mnemonics x 2 profiles - were added, every one
`verdict = Pass`); `make asm-isa-difficult-check asm-test`; `make asm-ci`
(full CI target, backgrounded).

Results and artifact links: 2 new `isa-norm-riscv` unit tests (`test_flw`,
`test_fsw`, each against its own real, verbatim-extracted riscv32.jsonl
record, representative of `f_load_form`/`f_store_form` since `fld`/`fsd`
share the identical shape and only the requirement/width differ), asserting
the operand list (value as `Riscv_fpr`, base as `Riscv_gpr`, offset as the
expected immediate shape) and syntax rendering. One new domain check in
`test_isa_gen_difficult.ml` (`test_f_ldst_domain`) covering all 8 corpus
entries, plus the 8 entries themselves (`flw_entries` through
`fsd_entries`). `Isa_family_admission`'s pinned totals moved: RV32
promoted-support 168->172, blocked 901->897; RV64 promoted-support
202->206, blocked 922->918 (all 8 new normalized records now credited);
`isa-norm-accounting`'s totals moved 188->192 (RV32) / 232->236 (RV64),
and the `isa-norm-jsonl` real-form round-trip count moved 438->446 (+8),
all pinned `repo_tests.ml` expectations updated and re-verified passing.
`tools-test`, `tools-integration`, `tools-boundary`, `asm-purity`,
`asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all
pass; `asm-isa-difficult-check`/`asm-test` both pass; `make asm-ci` passes
in full.

Unknowns, exceptions and follow-up task IDs: this closes `flw`/`fld`/
`fsw`/`fsd` - the only F/D records whose encoder support already existed
complete. The rest of FP - scalar sign-injection (`fsgnj`/`fsgnjn`/
`fsgnjx`), min/max, sqrt, the fused multiply-add family (`fmadd`/`fmsub`/
`fnmadd`/`fnmsub`), `fclass`, `fmv.w.x`/`fmv.x.w`, single-precision
`feq.s`/`fle.s`/`flt.s`, and the `fcvt.s.w`/`fcvt.s.wu`/`fcvt.w.s`/
`fcvt.wu.s` conversions - remain unencoded new work, not just a
normalization gap; whichever of those (or the remaining vector scope) is
tackled next will need its own fresh survey/scoping the same way CSR,
Zaamo and this slice were self-selected.

Acceptance gate satisfied: all 4 mnemonics have real encoder support
(pre-existing, confirmed rather than assumed) via two new, genuinely
reusable normalization shapes (`f_load_form`/`f_store_form`); matching
real-GNU-as agreement confirmed on both profiles for every mnemonic,
plus the D-implies-F march boundary; a persisted, offline-replayed
differential corpus entry each with real GNU agreement; admission-matrix
promotion; and a full `make asm-ci` pass - the same measured-Pass
discipline every other GEN-05/GAS-04 promotion used, with every affected
pinned count in the repository's own regression suite updated and
re-verified rather than left stale.

##### GEN-05 continuation: RISC-V F/D general sign-injection `fsgnj.s`/`fsgnjn.s`/`fsgnjx.s`/`fsgnj.d`/`fsgnjn.d`/`fsgnjx.d` (Claude)

Task / status / owner: GEN-05 F/D sign-injection sub-slice / done; GEN-05
overall / still implementing / Claude - self-selected after `flw`/`fld`/
`fsw`/`fsd` closed: the encoder already implemented `fneg.s`/`fneg.d`/
`fmv.d` (real hardware's `fsgnjn`/`fsgnj` aliases with `rs1` forced equal
to `rs2`), but its own code comment flagged the general two-distinct-
register form sharing that same opcode word as "not evidenced and not
implemented" - the cheapest next increment, since it only needed a small
encoder extension plus a new normalization shape, not a wholly new
register class the way the vector scope would.

Scope manifest and obligations: 6 `kind: instruction-form` records -
`fsgnj.s`/`fsgnjn.s`/`fsgnjx.s` (`rv_f`) and `fsgnj.d`/`fsgnjn.d`/
`fsgnjx.d` (`rv_d`), all XLEN-independent, both profiles. `rv_zfh`'s
`.h` and `rv_q`'s `.q` siblings exist in the same source export but are
out of scope (half/quad precision, not modeled by this project at all).
Encoder: added a `f_sgnj3_desc` table (funct3 selects
fsgnj/fsgnjn/fsgnjx, funct7 selects S/D) and a matching `[a; b; c]`
lowering arm identical in shape to `f_arith_desc`'s, but with no rounding-
mode field (this family's funct3 is a fixed per-mnemonic selector baked
into the record's own encoding mask, not a rounding mode read from an
implicit operand). Decode: `f_r_name` now always resolves the
sign-injection group to its general name; the caller downgrades to
`fneg.s`/`fneg.d`/`fmv.d` only when the decoded `rs1 = rs2`, inverting
the previous priority (which rejected the general form outright whenever
the registers differed) while leaving every pre-existing alias-decode
byte pattern unchanged. Normalization: new `f_sgnj_form` (3 `fpr()`
operands, no `rm`, byte-for-byte `f_arith_form`'s shape minus the
rounding-mode operand and its facts).

Real, measured findings: verified real GNU-as's exact bytes for all six
mnemonics with three genuinely distinct FP registers before writing any
encoder code (`riscv64-linux-gnu-as -march=rv64imafd`, also cross-checked
on `riscv32-linux-gnu-as -march=rv32imafd`, byte-identical on both
profiles): `fsgnj.s fa0, fa1, fa2` -> `20c58553`, `fsgnjn.s` ->
`20c59553`, `fsgnjx.s` -> `20c5a553`, `fsgnj.d` -> `22c58553`,
`fsgnjn.d` -> `22c59553`, `fsgnjx.d` -> `22c5a553` - confirming funct3 in
{0,1,2} selects fsgnj/fsgnjn/fsgnjx and funct7 0x10/0x11 selects S/D,
matching the source export's own fixed-bits mask (`0xfe00707f`) exactly.
This project's own `asm.exe --dump-disasm=diagnostic` reproduced all six
bytes exactly, and a `fneg.s`/`fneg.d`/`fmv.d` (`rs1 = rs2`) round-trip
alongside them confirmed the decode-side alias/general split still picks
the pseudo names correctly after inverting `f_r_name`'s priority.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build
@all`; real-toolchain smoke test via `riscv32-linux-gnu-as`/
`riscv64-linux-gnu-as`/`objdump` for all six mnemonics plus a
`fneg`/`fneg.d`/`fmv.d` alias round-trip, and this project's own
`asm.exe --dump-disasm=diagnostic`; `make tools-test`; `make
tools-integration` (first run intentionally left `repo_tests.ml`'s
pinned counts stale to read off the real new numbers - 6 per profile
exactly, matching the six non-import-duplicated records - then
hard-coded them, then re-ran clean); `make tools-boundary`; `make
asm-fmt`/`asm-fmt-check` (a few line-length nits, fixed by a single
`asm-fmt` pass); `make asm-purity`; `make asm-js-portable`; `make
tools-isa-inventory-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin:/usr/local/riscv64-linux-gnu-toolchain/bin"
make tools-gasxref-diff` (no-op); same `PATH` prefix for `make
asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 206 to 218 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `gas.tool_label`/`ours.tool_label`, that all 206
pre-existing cases are byte-for-byte unchanged and exactly the 12
expected new case_ids - 6 mnemonics x 2 profiles - were added, every one
`verdict = Pass`); `make asm-isa-difficult-check asm-test`; `make asm-ci`
(full CI target, backgrounded, exit 0).

Results and artifact links: 1 new `isa-norm-riscv` unit test function
(`test_fsgnj`, iterating all six mnemonics against their own real,
verbatim-extracted riscv32.jsonl records), asserting the requirement
(`riscv:f`/`riscv:d`), the 3-FPR-operand shape with no `rm`, and syntax
rendering. One new domain check in `test_isa_gen_difficult.ml`
(`test_f_sgnj_domain`) covering all 12 corpus entries (distinct `ft0`/
`ft1`/`ft2` registers, flagged via a new `distinct-source-registers` rule
id to distinguish them from the pre-existing `rs1 = rs2` alias corpus),
plus the 12 entries themselves (`fsgnj_s_entries` through
`fsgnjx_d_entries`). `Isa_family_admission`'s pinned totals moved: RV32
promoted-support 172->178, blocked 897->891; RV64 promoted-support
206->212, blocked 918->912 (all 12 new normalized records now credited).
`isa-norm-accounting`'s totals moved 192->198 (RV32) / 236->242 (RV64),
and the `isa-norm-jsonl` real-form round-trip count moved 446->458 (+12),
all pinned `repo_tests.ml` expectations updated and re-verified passing.
`tools-test`, `tools-integration`, `tools-boundary`, `asm-purity`,
`asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all
pass; `asm-isa-difficult-check`/`asm-test` both pass; `make asm-ci` passes
in full.

Unknowns, exceptions and follow-up task IDs: this closes the general
sign-injection form; `rv_zfh`'s `.h` and `rv_q`'s `.q` siblings remain
out of scope (this project models only single/double precision). The
rest of scalar FP - min/max, sqrt, the fused multiply-add family
(`fmadd`/`fmsub`/`fnmadd`/`fnmsub`), `fclass`, `fmv.w.x`/`fmv.x.w`,
single-precision `feq.s`/`fle.s`/`flt.s`, and the `fcvt.s.w`/
`fcvt.s.wu`/`fcvt.w.s`/`fcvt.wu.s` conversions - remain unencoded new
work, not just a normalization gap; whichever of those (or the remaining
vector scope) is tackled next will need its own fresh survey/scoping the
same way CSR, Zaamo, `flw`/`fld`/`fsw`/`fsd` and this slice were
self-selected.

Acceptance gate satisfied: all 6 mnemonics have real, newly-added encoder
support verified byte-for-byte against real `riscv32-linux-gnu-as`/
`riscv64-linux-gnu-as` output (including the alias/general decode-side
priority inversion, re-verified not to disturb the pre-existing `fneg.s`/
`fneg.d`/`fmv.d` byte patterns) via one new, genuinely reusable
normalization shape (`f_sgnj_form`); a persisted, offline-replayed
differential corpus entry each with real GNU agreement; admission-matrix
promotion; and a full `make asm-ci` pass - the same measured-Pass
discipline every other GEN-05/GAS-04 promotion used, with every affected
pinned count in the repository's own regression suite updated and
re-verified rather than left stale.

##### GEN-05 continuation: RISC-V F/D `fmin.s`/`fmax.s`/`fmin.d`/`fmax.d` (Claude)

Task / status / owner: GEN-05 F/D min/max sub-slice / done; GEN-05
overall / still implementing / Claude - self-selected after the general
sign-injection form closed: `fmin`/`fmax` share the identical opcode
family and record shape as `fsgnj`/`fsgnjn`/`fsgnjx` (a fixed funct7 per
precision, funct3 selecting the specific operation, no rounding mode),
so it reused the exact same normalization/encoder pattern the previous
slice established and was the next cheapest increment before the
genuinely new shapes (fused multiply-add, `fclass`, `fmv.w.x`/`fmv.x.w`)
require.

Scope manifest and obligations: 4 `kind: instruction-form` records -
`fmin.s`/`fmax.s` (`rv_f`) and `fmin.d`/`fmax.d` (`rv_d`), all
XLEN-independent, both profiles. Encoder: added a `f_minmax_desc` table
(funct3 0/1 selects min/max, funct7 0x14/0x15 selects S/D) and a matching
`[a; b; c]` lowering arm, byte-for-byte `f_sgnj3_desc`'s shape; decode
added the four `(f3, f7)` combinations to `f_r_name`'s fallback match (no
alias collision to invert this time - `fmin`/`fmax` share no opcode word
with any pre-existing pseudo-mnemonic). Normalization: new
`f_minmax_form`, byte-for-byte `f_sgnj_form`'s shape (3 `fpr()` operands,
no `rm`).

Real, measured findings: verified real GNU-as's exact bytes for all four
mnemonics with three genuinely distinct FP registers before writing any
encoder code (`riscv64-linux-gnu-as -march=rv64imafd`, also cross-checked
on `riscv32-linux-gnu-as -march=rv32imafd`, byte-identical on both
profiles): `fmin.s fa0, fa1, fa2` -> `28c58553`, `fmax.s fa0, fa1, fa2`
-> `28c59553`, `fmin.d fa0, fa1, fa2` -> `2ac58553`, `fmax.d fa0, fa1,
fa2` -> `2ac59553` - confirming funct3 in {0,1} selects fmin/fmax and
funct7 0x14/0x15 selects S/D, matching the source export's own
fixed-bits mask (`0xfe00707f`) exactly. This project's own `asm.exe
--dump-disasm=diagnostic` reproduced all four bytes exactly.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build
@all`; real-toolchain smoke test via `riscv32-linux-gnu-as`/
`riscv64-linux-gnu-as`/`objdump` for all four mnemonics, and this
project's own `asm.exe --dump-disasm=diagnostic`; `make tools-test`;
`make tools-integration` (first run intentionally left `repo_tests.ml`'s
pinned counts stale to read off the real new numbers - 4 per profile
exactly, matching the four non-import-duplicated records - then
hard-coded them, then re-ran clean); `make tools-boundary`; `make
asm-fmt`/`asm-fmt-check` (a few line-length nits, fixed by a single
`asm-fmt` pass); `make asm-purity`; `make asm-js-portable`; `make
tools-isa-inventory-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin:/usr/local/riscv64-linux-gnu-toolchain/bin"
make tools-gasxref-diff` (no-op); same `PATH` prefix for `make
asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 218 to 226 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `gas.tool_label`/`ours.tool_label`, that all 218
pre-existing cases are byte-for-byte unchanged and exactly the 8 expected
new case_ids - 4 mnemonics x 2 profiles - were added, every one
`verdict = Pass`); `make asm-isa-difficult-check asm-test`; `make asm-ci`
(full CI target, backgrounded, exit 0).

Results and artifact links: 1 new `isa-norm-riscv` unit test function
(`test_fminmax`, iterating all four mnemonics against their own real,
verbatim-extracted riscv32.jsonl records), asserting the requirement
(`riscv:f`/`riscv:d`), the 3-FPR-operand shape with no `rm`, and syntax
rendering. One new domain check in `test_isa_gen_difficult.ml`
(`test_f_minmax_domain`) covering all 8 corpus entries (a new
`min-max-select` rule id, distinct from `fsgnj`'s
`distinct-source-registers` since there is no pseudo-alias to
disambiguate from here), plus the 8 entries themselves (`fmin_s_entries`
through `fmax_d_entries`). `Isa_family_admission`'s pinned totals moved:
RV32 promoted-support 178->182, blocked 891->887; RV64 promoted-support
212->216, blocked 912->908 (all 8 new normalized records now credited).
`isa-norm-accounting`'s totals moved 198->202 (RV32) / 242->246 (RV64),
and the `isa-norm-jsonl` real-form round-trip count moved 458->466 (+8),
all pinned `repo_tests.ml` expectations updated and re-verified passing.
`tools-test`, `tools-integration`, `tools-boundary`, `asm-purity`,
`asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all
pass; `asm-isa-difficult-check`/`asm-test` both pass; `make asm-ci` passes
in full.

Unknowns, exceptions and follow-up task IDs: this closes `fmin`/`fmax`.
The rest of scalar FP - sqrt, the fused multiply-add family (`fmadd`/
`fmsub`/`fnmadd`/`fnmsub`), `fclass`, `fmv.w.x`/`fmv.x.w`,
single-precision `feq.s`/`fle.s`/`flt.s`, and the `fcvt.s.w`/
`fcvt.s.wu`/`fcvt.w.s`/`fcvt.wu.s` conversions - remain unencoded new
work, not just a normalization gap; whichever of those (or the remaining
vector scope) is tackled next will need its own fresh survey/scoping the
same way CSR, Zaamo, `flw`/`fld`/`fsw`/`fsd`, `fsgnj`/`fsgnjn`/`fsgnjx`
and this slice were self-selected.

Acceptance gate satisfied: all 4 mnemonics have real, newly-added encoder
support verified byte-for-byte against real `riscv32-linux-gnu-as`/
`riscv64-linux-gnu-as` output via one new, genuinely reusable
normalization shape (`f_minmax_form`); a persisted, offline-replayed
differential corpus entry each with real GNU agreement; admission-matrix
promotion; and a full `make asm-ci` pass - the same measured-Pass
discipline every other GEN-05/GAS-04 promotion used, with every affected
pinned count in the repository's own regression suite updated and
re-verified rather than left stale.

##### GEN-05 continuation: RISC-V F/D `fsqrt.s`/`fsqrt.d`/`fclass.s`/`fclass.d` (Claude)

Task / status / owner: GEN-05 F/D sqrt/classify sub-slice / done; GEN-05
overall / still implementing / Claude - self-selected after `fmin`/`fmax`
closed: `fsqrt` reuses the arithmetic family's own implicit-dynamic-
rounding shape (minus a second FP operand), and `fclass` reuses the
plain-GPR-result shape `fmv.x.d` already established, so both were the
next cheapest increment before the fused multiply-add family and
`fmv.w.x`/`fmv.x.w` (which need a genuinely new R4-type or new
operand-shape work).

Scope manifest and obligations: 4 `kind: instruction-form` records -
`fsqrt.s`/`fclass.s` (`rv_f`) and `fsqrt.d`/`fclass.d` (`rv_d`), all
XLEN-independent, both profiles. Encoder: added `f_sqrt_desc` (funct7
0x2c/0x2d selects S/D, `rs2` fixed to a selector, funct3 a genuine
rounding mode) reusing `f_to_f_desc`'s own `(funct3, funct7, rs2)` shape
but as a new table and lowering arm, plus `f_class_desc` (funct7
0x70/0x71, `rs2` fixed, funct3 = 1 a fixed identity bit) as a *separate*
table from the pre-existing `f_to_i_desc` (see the deliberate-omission
note below), each with its own lowering arm and both added to the
decode-side `f_r_name`/fallback tables. Normalization: new
`f_sqrt_form` (`f_arith_form`'s own shape minus `rs2`) and `f_class_form`
(`rd` a GPR, `rs1` FP, no `rm`).

Real, measured findings: verified real GNU-as's exact bytes for all four
mnemonics before writing any encoder code (`riscv64-linux-gnu-as
-march=rv64imafd`, cross-checked on `riscv32-linux-gnu-as
-march=rv32imafd`, byte-identical on both profiles): `fsqrt.s fa0, fa1`
-> `5805f553` (funct7 = 0x2c, funct3 = 7 = dyn), `fsqrt.d fa0, fa1` ->
`5a05f553` (funct7 = 0x2d), `fclass.s a0, fa1` -> `e0059553` (funct7 =
0x70, funct3 = 1), `fclass.d a0, fa1` -> `e2059553` (funct7 = 0x71) -
matching the source export's own fixed-bits masks exactly. Separately,
while designing `fclass`'s table placement, discovered and verified a
real, pre-existing latent gap unrelated to this slice's own new
mnemonics: the encoder's existing `f_to_i_desc`-keyed lowering arm that
accepts an explicit trailing rounding-mode operand (added for
`fcvt.l.d x22, f10, rtz`-style spellings) is keyed only on
`Option.is_some (f_to_i_desc op)`, with no per-mnemonic check for
whether that mnemonic's own funct3 is actually a rounding mode - so it
also (wrongly) accepts `fmv.x.d a0, fa1, rtz`, silently encoding it with
funct3 forced to 1 and producing bytes (`e2059553`) byte-identical to
`fclass.d`'s own real encoding. Confirmed against real GNU as that this
spelling is illegal (`riscv64-linux-gnu-as`: "illegal operands"), and
confirmed this project's own `asm.exe` currently accepts it
(`--dump-lowered-ast` shows `[riscv64.fmv.x.d]` for that malformed
input). This finding is why `fclass.s`/`fclass.d` were deliberately kept
in their own new `f_class_desc` table, dispatched only through a plain
2-operand lowering arm - not added to `f_to_i_desc` - so this slice does
not reproduce or compound the existing gap; the gap itself is not fixed
here (pre-existing, unrelated to any mnemonic this slice admits, and
fixing it would mean auditing every `f_to_i_desc` member's real
rounding-mode eligibility, a separate bounded task). This project's own
`asm.exe --dump-disasm=diagnostic` reproduced all four new mnemonics'
bytes exactly, and re-confirmed `fmv.x.d`'s own (legal-spelling)
round-trip is unaffected by these additions.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build
@all`; real-toolchain smoke test via `riscv32-linux-gnu-as`/
`riscv64-linux-gnu-as`/`objdump` for all four mnemonics plus the
`fmv.x.d a0, fa1, rtz` illegal-syntax probe, and this project's own
`asm.exe --dump-disasm=diagnostic`/`--dump-lowered-ast`; `make
tools-test`; `make tools-integration` (first run intentionally left
`repo_tests.ml`'s pinned counts stale to read off the real new numbers -
4 per profile exactly, matching the four non-import-duplicated records -
then hard-coded them, then re-ran clean); `make tools-boundary`; `make
asm-fmt`/`asm-fmt-check` (a few line-length nits, fixed by a single
`asm-fmt` pass); `make asm-purity`; `make asm-js-portable`; `make
tools-isa-inventory-diff`; `PATH="$PATH:/usr/local/riscv32-linux-gnu-toolchain/bin:/usr/local/riscv64-linux-gnu-toolchain/bin"
make tools-gasxref-diff` (no-op); same `PATH` prefix for `make
asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 226 to 234 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `gas.tool_label`/`ours.tool_label`, that all 226
pre-existing cases are byte-for-byte unchanged and exactly the 8 expected
new case_ids - 4 mnemonics x 2 profiles - were added, every one
`verdict = Pass`); `make asm-isa-difficult-check asm-test`; `make asm-ci`
(full CI target, backgrounded, exit 0).

Results and artifact links: 2 new `isa-norm-riscv` unit test functions
(`test_fsqrt`, `test_fclass`, each against real, verbatim-extracted
riscv32.jsonl records), asserting the requirement (`riscv:f`/`riscv:d`),
the 2-operand shape (FP/FP with implicit `rm` for `fsqrt`; GPR/FP with no
`rm` for `fclass`), and syntax rendering. Two new domain checks in
`test_isa_gen_difficult.ml` (`test_f_sqrt_domain`, `test_f_class_domain`)
covering all 8 corpus entries, plus the 8 entries themselves
(`fsqrt_s_entries` through `fclass_d_entries`). `Isa_family_admission`'s
pinned totals moved: RV32 promoted-support 182->186, blocked 887->883;
RV64 promoted-support 216->220, blocked 908->904 (all 8 new normalized
records now credited). `isa-norm-accounting`'s totals moved 202->206
(RV32) / 246->250 (RV64), and the `isa-norm-jsonl` real-form round-trip
count moved 466->474 (+8), all pinned `repo_tests.ml` expectations
updated and re-verified passing. `tools-test`, `tools-integration`,
`tools-boundary`, `asm-purity`, `asm-js-portable`,
`tools-isa-inventory-diff`, `tools-gasxref-diff` all pass;
`asm-isa-difficult-check`/`asm-test` both pass; `make asm-ci` passes in
full.

Unknowns, exceptions and follow-up task IDs: this closes `fsqrt`/
`fclass`. A real, pre-existing latent encoder gap was found and
documented but deliberately not fixed in this slice: `f_to_i_desc`'s
explicit-rounding-mode-override lowering arm accepts an illegal trailing
rounding-mode operand on `fmv.x.d` (and would on any future mnemonic
added to that same table whose funct3 is not actually a rounding mode),
silently producing bytes that collide with a different real instruction's
encoding; real GNU as rejects the malformed spelling outright. Fixing
this needs auditing every `f_to_i_desc` member's real rounding-mode
eligibility and either splitting the table or adding a per-mnemonic
allow-list to the override arm - a separate, bounded follow-up, not
part of this admission. The rest of scalar FP - the fused multiply-add
family (`fmadd`/`fmsub`/`fnmadd`/`fnmsub`, a genuinely new R4-type shape),
`fmv.w.x`/`fmv.x.w`, single-precision `feq.s`/`fle.s`/`flt.s`, and the
`fcvt.s.w`/`fcvt.s.wu`/`fcvt.w.s`/`fcvt.wu.s` conversions - remain
unencoded new work; whichever of those (or the remaining vector scope) is
tackled next will need its own fresh survey/scoping the same way CSR,
Zaamo, `flw`/`fld`/`fsw`/`fsd`, `fsgnj`/`fsgnjn`/`fsgnjx`, `fmin`/`fmax`
and this slice were self-selected.

Acceptance gate satisfied: all 4 mnemonics have real, newly-added encoder
support verified byte-for-byte against real `riscv32-linux-gnu-as`/
`riscv64-linux-gnu-as` output via two new, genuinely reusable
normalization shapes (`f_sqrt_form`/`f_class_form`); a persisted,
offline-replayed differential corpus entry each with real GNU agreement;
admission-matrix promotion; and a full `make asm-ci` pass - the same
measured-Pass discipline every other GEN-05/GAS-04 promotion used, with
every affected pinned count in the repository's own regression suite
updated and re-verified rather than left stale, plus a real latent
encoder gap discovered along the way, verified against real GNU as, and
explicitly not reproduced by this slice's own new code.

##### GEN-05 continuation: RISC-V F/D fused multiply-add `fmadd`/`fmsub`/`fnmsub`/`fnmadd` (Claude)

Task / status / owner: GEN-05 F/D fused-multiply-add sub-slice / done; GEN-05
overall / still implementing / Claude - self-selected after `fsqrt`/`fclass`
closed: the fused multiply-add family was the next named remaining item in
scalar FP, and unlike every prior GEN-05 FP slice it needed genuinely new
encoder machinery rather than reusing the existing OP-FP `Lowered.R`/`word_r`
R-type path, since RISC-V's R4-type instructions carry a fourth real register
operand.

Scope manifest and obligations: 8 `kind: instruction-form` records -
`fmadd.s`/`fmsub.s`/`fnmsub.s`/`fnmadd.s` (`rv_f`) and `fmadd.d`/`fmsub.d`/
`fnmsub.d`/`fnmadd.d` (`rv_d`), all XLEN-independent, both profiles. Unlike
every other OP-FP mnemonic this project encodes, R4-type's top 7 bits split
into a 5-bit `rs3` and a 2-bit `fmt` selector (00 = S, 01 = D) rather than one
fixed `funct7`, and each mnemonic gets its own base opcode (`0x43`/`0x47`/
`0x4b`/`0x4f` for `fmadd`/`fmsub`/`fnmsub`/`fnmadd`) instead of sharing
OP-FP's `0x53`. Added a new `Lowered.R4` constructor (`name`, `opcode`,
`fmt`, `funct3`, `rd`, `rs1`, `rs2`, `rs3`), a `word_r4` encoder function
placing `rs3`/`fmt` at bits `31:27`/`26:25` (the same bit span `word_r`'s
`funct7` argument already covers, just split differently), a matching
decode-side `f_r4_name` table keyed on `(opcode, fmt)`, and a new decode
branch for the four R4-type opcodes (which needed no priority contest with
the existing OP-FP `0x53` decode arm, since they are genuinely distinct
opcodes). Normalization: new `f_fma_form`, `f_arith_form`'s own shape
(`rd`/`rs1`/`rs2` FPRs plus an implicit dynamic-rounding `rm`) extended with
a fourth `rs3` FPR operand; like `f_arith_form` and `f_sqrt_form`, this
claims only the bare dynamic-rounding spelling, not an explicit `rne`/`rtz`/
other rounding-mode operand.

Real, measured findings: verified real GNU-as's exact bytes for all eight
mnemonics before writing any encoder code (`riscv64-linux-gnu-as
-march=rv64imafdc`, cross-checked on `riscv32-linux-gnu-as`, byte-identical
on both profiles): `fmadd.s fa0, fa1, fa2, fa3` -> `68c5f543`, `fmsub.s ...`
-> `68c5f547`, `fnmsub.s ...` -> `68c5f54b`, `fnmadd.s ...` -> `68c5f54f`,
and the `.d` siblings identical except `fmt` bit 25 set (`6ac5f543`/
`6ac5f547`/`6ac5f54b`/`6ac5f54f`); decoded these by hand bit-for-bit
(`rs3 = bits[31:27] = 13 = fa3`, `fmt = bits[26:25]`, `rs2 = bits[24:20]`,
`rs1 = bits[19:15]`, `rm = bits[14:12]`, `rd = bits[11:7]`, `opcode =
bits[6:0]`) to confirm the field layout before implementing `word_r4`, and
separately confirmed the explicit-rounding-mode override still decodes
correctly at the byte level even though this slice's own normalization does
not claim it as syntax (`fmadd.s fa0, fa1, fa2, fa3, rtz` -> `68c59543`,
funct3 = 1 = rtz; `fnmadd.d ..., rdn` -> `6ac5a543`, funct3 = 2 = rdn) -
matching the source export's own `26..25=`/`6..2=` fixed-bits masks exactly.
This project's own `asm.exe --dump-disasm=diagnostic` reproduced all eight
new mnemonics' bytes exactly on both profiles, and a canonical-disassembly
round-trip (`--dump-disasm=canonical` re-fed through `--dump-bytes`)
confirmed byte-for-byte re-assembly identity.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
real-toolchain smoke test via `riscv32-linux-gnu-as`/`riscv64-linux-gnu-as`/
`objdump` for all eight mnemonics plus the explicit-rounding-mode-suffix
probe, and this project's own `asm.exe --dump-disasm=diagnostic`/
`--dump-disasm=canonical`/`--dump-bytes`; `make tools-test` (first run
intentionally left `test_isa_gen_difficult.ml`'s `all`-equals-sum-of-lengths
self-consistency check stale to confirm the expected failure, then updated
it); `make tools-integration` (first run intentionally left `repo_tests.ml`'s
pinned counts stale to read off the real new numbers, then hard-coded them,
then re-ran clean); `make tools-boundary`; `make asm-fmt`/`asm-fmt-check`
(ocamlformat reformatted the new verbatim-extracted JSON test literals,
re-verified the reformatted strings still parse and every check still
passes); `cd asm && opam exec -- dune build @runtest`; same `PATH` prefix
for `make asm-isa-difficult-regen` (grew
`asm/fixtures/isa-difficult/cases.jsonl` from 234 to 250 entries; confirmed
record-by-record, ignoring only the git-rev-embedded `gas.tool_label`/
`ours.tool_label`, that all 234 pre-existing cases are byte-for-byte
unchanged and exactly the 16 expected new case_ids - 8 mnemonics x 2
profiles - were added, every one `verdict = pass`); `make asm-ci` (full CI
target, backgrounded, exit 0).

Results and artifact links: 1 new `isa-norm-riscv` unit test function
(`test_fma`, against all 8 real, verbatim-extracted riscv32.jsonl records),
asserting the requirement (`riscv:f`/`riscv:d`), the 5-operand shape
(`rd`/`rs1`/`rs2`/`rs3` FPRs plus implicit `rm`), and syntax rendering. One
new domain check in `test_isa_gen_difficult.ml` (`test_f_fma_domain`)
covering all 16 corpus entries, plus the 16 entries themselves
(`fmadd_s_entries` through `fnmadd_d_entries`). `Isa_family_admission`'s
pinned totals moved: RV32 promoted-support 186->194, blocked 883->875; RV64
promoted-support 220->228, blocked 904->896 (all 16 new normalized records
now credited). `isa-norm-accounting`'s totals moved 206->214 (RV32) /
250->258 (RV64), and the `isa-norm-jsonl` real-form round-trip count moved
474->490 (+16), all pinned `repo_tests.ml` expectations updated and
re-verified passing. `tools-test`, `tools-integration`, `tools-boundary` all
pass; `dune build @runtest` passes; `make asm-ci` passes in full.

Unknowns, exceptions and follow-up task IDs: this closes the fused
multiply-add family. The rest of scalar FP - `fmv.w.x`/`fmv.x.w`,
single-precision `feq.s`/`fle.s`/`flt.s`, and the `fcvt.s.w`/`fcvt.s.wu`/
`fcvt.w.s`/`fcvt.wu.s` conversions - remains open, along with the
previously-flagged `f_to_i_desc` rounding-mode-override latent gap
(unrelated to this slice, not reproduced by it, still not fixed); whichever
of those (or the remaining vector scope) is tackled next will need its own
fresh survey/scoping the same way every prior GEN-05 sub-slice this session
was self-selected.

Acceptance gate satisfied: all 8 mnemonics have real, newly-added encoder
support - including a genuinely new `Lowered.R4`/`word_r4` codec path, not
just a new desc-table entry on the existing R-type machinery - verified
byte-for-byte against real `riscv32-linux-gnu-as`/`riscv64-linux-gnu-as`
output via a new, genuinely reusable normalization shape (`f_fma_form`); a
persisted, offline-replayed differential corpus entry each with real GNU
agreement; admission-matrix promotion; and a full `make asm-ci` pass - the
same measured-Pass discipline every other GEN-05/GAS-04 promotion used, with
every affected pinned count in the repository's own regression suite
updated and re-verified rather than left stale.

##### GEN-05 continuation: RISC-V F/D comparisons `feq.s`/`fle.s`/`flt.s`/`feq.d`/`fle.d`/`flt.d` (Claude)

Task / status / owner: GEN-05 F/D comparison sub-slice / done; GEN-05
overall / still implementing / Claude - self-selected after the fused
multiply-add family closed: a fresh survey found the encoder already had a
`f_cmp_desc` table implementing `flt.s`/`feq.d`/`fle.d`/`flt.d` (added in an
earlier, unrelated pass, evidenced by their presence in the `Opcode.t`
listing) with no normalization/corpus/admission ever built for them, plus
two sibling mnemonics (`feq.s`/`fle.s`) missing from that table entirely -
the cheapest remaining scalar-FP increment, needing only two new encoder
entries rather than a new operand shape.

Scope manifest and obligations: 6 `kind: instruction-form` records -
`feq.s`/`fle.s`/`flt.s` (`rv_f`) and `feq.d`/`fle.d`/`flt.d` (`rv_d`), all
XLEN-independent, both profiles. Encoder: added `Feq_s`/`Fle_s` to
`Opcode.t` and to `f_cmp_desc` (funct3 2/0 at funct7 `0x50`, the same
group `flt.s`'s pre-existing `(1, 0x50)` entry already occupies), plus
matching decode-side `f_r_name` fallback-table entries and an
`f_shape_of_name` match-arm extension (`"feq.s"`/`"fle.s"` added to the
existing `"feq.d" | "fle.d" | "flt.d" | "flt.s"` arity-3/no-`rm` group); no
new lowering arm was needed since the existing `f_cmp_desc`-keyed arm
already dispatches generically on `Option.is_some (f_cmp_desc op)`.
Normalization: new `f_cmp_form` (`rd` a GPR `Out`, `rs1`/`rs2` FPRs `In`, no
`rm` operand at all - the mirror image of `f_fma_form`'s all-FPR shape).

Real, measured findings: verified real GNU-as's exact bytes for all six
mnemonics before writing any encoder code (`riscv64-linux-gnu-as
-march=rv64imafdc`, cross-checked on `riscv32-linux-gnu-as`, byte-identical
on both profiles): `feq.s a0, fa1, fa2` -> `a0c5a553`, `fle.s a0, fa1, fa2`
-> `a0c58553`, `flt.s a0, fa1, fa2` -> `a0c59553`, and the `.d` siblings
identical except funct7 `0x51` (`a2c5a553`/`a2c58553`/`a2c59553`) -
matching the source export's own `26..25=`/`31..27=`/`14..12=` fixed-bits
masks exactly. This project's own `asm.exe --dump-disasm=diagnostic`
reproduced all six mnemonics' bytes exactly on both profiles, and a
canonical-disassembly round-trip (`--dump-disasm=canonical` re-fed through
`--dump-bytes`) confirmed byte-for-byte re-assembly identity, including for
the four mnemonics whose encoder support pre-dated this slice.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
real-toolchain smoke test via `riscv32-linux-gnu-as`/`riscv64-linux-gnu-as`/
`objdump` for all six mnemonics, and this project's own `asm.exe
--dump-disasm=diagnostic`/`--dump-disasm=canonical`/`--dump-bytes`; `make
tools-test` (first run intentionally left `test_isa_gen_difficult.ml`'s
`all`-equals-sum-of-lengths self-consistency check stale, then updated it);
`make tools-integration` (first run intentionally left `repo_tests.ml`'s
pinned counts stale to read off the real new numbers, then hard-coded
them, then re-ran clean); `make tools-boundary`; `make asm-fmt`/
`asm-fmt-check` (ocamlformat reformatted the new verbatim-extracted JSON
test literals; re-verified the reformatted strings still parse and every
check still passes); `cd asm && opam exec -- dune build @runtest`; same
`PATH` prefix for `make asm-isa-difficult-regen` (grew
`asm/fixtures/isa-difficult/cases.jsonl` from 250 to 262 entries; confirmed
record-by-record, ignoring only the git-rev-embedded `gas.tool_label`/
`ours.tool_label`, that all 250 pre-existing cases are byte-for-byte
unchanged and exactly the 12 expected new case_ids - 6 mnemonics x 2
profiles - were added, every one `verdict = pass`); `make asm-ci` (full CI
target, backgrounded, exit 0).

Results and artifact links: 1 new `isa-norm-riscv` unit test function
(`test_fcmp`, against all 6 real, verbatim-extracted riscv32.jsonl
records), asserting the requirement (`riscv:f`/`riscv:d`), the 3-operand
shape (`rd` GPR, `rs1`/`rs2` FPRs, no `rm`), and syntax rendering. One new
domain check in `test_isa_gen_difficult.ml` (`test_f_cmp_domain`) covering
all 12 corpus entries, plus the 12 entries themselves (`feq_s_entries`
through `flt_d_entries`). `Isa_family_admission`'s pinned totals moved: RV32
promoted-support 194->200, blocked 875->869; RV64 promoted-support
228->234, blocked 896->890 (all 12 new normalized records now credited).
`isa-norm-accounting`'s totals moved 214->220 (RV32) / 258->264 (RV64), and
the `isa-norm-jsonl` real-form round-trip count moved 490->502 (+12), all
pinned `repo_tests.ml` expectations updated and re-verified passing.
`tools-test`, `tools-integration`, `tools-boundary` all pass; `dune build
@runtest` passes; `make asm-ci` passes in full.

Unknowns, exceptions and follow-up task IDs: this closes every named scalar
FP comparison. The rest of scalar FP - `fmv.w.x`/`fmv.x.w` and the
`fcvt.s.w`/`fcvt.s.wu`/`fcvt.w.s`/`fcvt.wu.s` conversions - remains open,
along with the previously-flagged `f_to_i_desc` rounding-mode-override
latent gap (unrelated to this slice, not reproduced by it, still not
fixed); whichever of those (or the remaining vector scope) is tackled next
will need its own fresh survey/scoping the same way every prior GEN-05
sub-slice this session was self-selected.

Acceptance gate satisfied: all 6 mnemonics have real encoder support
(2 newly added, 4 pre-existing but never before normalized/admitted)
verified byte-for-byte against real `riscv32-linux-gnu-as`/
`riscv64-linux-gnu-as` output via a new, genuinely reusable normalization
shape (`f_cmp_form`); a persisted, offline-replayed differential corpus
entry each with real GNU agreement; admission-matrix promotion; and a full
`make asm-ci` pass - the same measured-Pass discipline every other
GEN-05/GAS-04 promotion used, with every affected pinned count in the
repository's own regression suite updated and re-verified rather than left
stale.

##### GEN-05 continuation: RISC-V F `fmv.x.w`/`fmv.w.x` (Claude)

Task / status / owner: GEN-05 F bit-move sub-slice / done; GEN-05 overall /
still implementing / Claude - self-selected after the comparison family
closed: `fmv.x.w`/`fmv.w.x` are the single-precision bit-for-bit moves
`fmv.x.d` already established the shape for, and the last named scalar-FP
item that fits an already-designed shape rather than needing genuinely new
operand-shape work (unlike the `w`/`s` conversions, which remain open).

Scope manifest and obligations: 2 `kind: instruction-form` records, both
`rv_f`-only (single precision has no RV32/RV64 split - the "w"/"s" in the
name means single-precision word, not RV32), XLEN-independent, both
profiles. Encoder: `fmv.x.w` shares its `(funct7 = 0x70, rs2 = 0)` group
with `fclass.s` (funct3 = 1) and `fmv.x.d`'s own `f_to_i_desc`-adjacent
group at `0x71`, so - following the same reasoning that kept `fclass.s`/
`fclass.d` out of `f_to_i_desc` - it was added to a new, separate
`f_mv_x_w_desc` table (funct3 = 0) with its own plain 2-operand lowering
arm, rather than into `f_to_i_desc` where `fmv.x.d` itself lives, so it is
never reachable through that table's documented explicit-rounding-mode-
override latent bug. `fmv.w.x` goes the other direction (`rd` FP, `rs1` a
GPR) at its own `funct7 = 0x78` group, shared by no other mnemonic in this
table; since `i_to_f_desc` (where the shape naturally belongs) has no
override lowering arm at all, `fmv.w.x` was added there directly with no
bug-avoidance table split needed. Normalization: two new forms,
`f_mv_x_w_form` (`rd` a GPR `Out`, `rs1` FP `In`, no `rm`) and
`f_mv_w_x_form` (`rd` FP `Out`, `rs1` a GPR `In`, no `rm`) - the `w`/`s`
conversions this pair sits next to in the source export still have no
normalization shape at all, so neither could be reused verbatim.

Real, measured findings: verified real GNU-as's exact bytes for both
mnemonics before writing any encoder code (`riscv64-linux-gnu-as
-march=rv64imafdc`, cross-checked on `riscv32-linux-gnu-as`, byte-identical
on both profiles): `fmv.x.w a0, fa1` -> `e0058553` (funct7 = 0x70, funct3 =
0, matching `fclass.s`'s own group with a different funct3), `fmv.w.x fa0,
a1` -> `f0058553` (funct7 = 0x78) - matching the source export's own
`31..27=`/`26..25=`/`14..12=` fixed-bits masks exactly. Confirmed the
illegal `fmv.x.w a0, fa1, rtz` spelling is rejected both by real GNU as
("illegal operands") and by this project's own `asm.exe`
(`error[riscv64.lower]: no fmv.x.w form takes these operands`), proving the
new `f_mv_x_w_desc` table split successfully avoids reproducing
`f_to_i_desc`'s known latent bug for this new mnemonic. This project's own
`asm.exe --dump-disasm=diagnostic` reproduced both mnemonics' bytes exactly
on both profiles, a canonical-disassembly round-trip
(`--dump-disasm=canonical` re-fed through `--dump-bytes`) confirmed
byte-for-byte re-assembly identity, and `fmv.x.d`'s own (legal-spelling)
round-trip was re-confirmed unaffected by these additions.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
real-toolchain smoke test via `riscv32-linux-gnu-as`/`riscv64-linux-gnu-as`/
`objdump` for both mnemonics plus the `fmv.x.w a0, fa1, rtz` illegal-syntax
probe, and this project's own `asm.exe --dump-disasm=diagnostic`/
`--dump-lowered-ast`/`--dump-disasm=canonical`/`--dump-bytes`; `make
tools-test` (first run intentionally left `test_isa_gen_difficult.ml`'s
`all`-equals-sum-of-lengths self-consistency check stale, then updated it);
`make tools-integration` (first run intentionally left `repo_tests.ml`'s
pinned counts stale to read off the real new numbers, then hard-coded
them, then re-ran clean); `make tools-boundary`; `make asm-fmt`/
`asm-fmt-check` (ocamlformat reformatted the new verbatim-extracted JSON
test literals; re-verified the reformatted strings still parse and every
check still passes); `cd asm && opam exec -- dune build @runtest`; same
`PATH` prefix for `make asm-isa-difficult-regen` (grew
`asm/fixtures/isa-difficult/cases.jsonl` from 262 to 266 entries; confirmed
record-by-record, ignoring only the git-rev-embedded `gas.tool_label`/
`ours.tool_label`, that all 262 pre-existing cases are byte-for-byte
unchanged and exactly the 4 expected new case_ids - 2 mnemonics x 2
profiles - were added, every one `verdict = pass`); `make asm-ci` (full CI
target, backgrounded, exit 0).

Results and artifact links: 2 new `isa-norm-riscv` unit test functions
(`test_fmv_x_w`, `test_fmv_w_x`, against real, verbatim-extracted
riscv32.jsonl records), asserting the requirement (`riscv:f`), the
2-operand shape in each direction, and syntax rendering. One new domain
check in `test_isa_gen_difficult.ml` (`test_fmv_w_domain`) covering both
new corpus entry pairs (`fmv_x_w_entries`, `fmv_w_x_entries`).
`Isa_family_admission`'s pinned totals moved: RV32 promoted-support
200->202, blocked 869->867; RV64 promoted-support 234->236, blocked
890->888 (both new normalized records now credited). `isa-norm-accounting`'s
totals moved 220->222 (RV32) / 264->266 (RV64), and the `isa-norm-jsonl`
real-form round-trip count moved 502->506 (+4), all pinned `repo_tests.ml`
expectations updated and re-verified passing. `tools-test`,
`tools-integration`, `tools-boundary` all pass; `dune build @runtest`
passes; `make asm-ci` passes in full.

Unknowns, exceptions and follow-up task IDs: this closes `fmv.x.w`/
`fmv.w.x`. The only scalar FP left unclaimed is the `w`/`s` conversions
(`fcvt.s.w`/`fcvt.s.wu`/`fcvt.w.s`/`fcvt.wu.s`), which - unlike this slice -
have no existing normalization shape to reuse and would need one built from
scratch (the `i_to_f_desc`/`f_to_i_desc` encoder tables already partially
cover them, but `Isa_norm_riscv` has never modeled either direction's shape
before). The previously-flagged `f_to_i_desc` rounding-mode-override latent
gap remains unrelated to this slice, not reproduced by it, and still not
fixed. Whichever of those (or the remaining vector scope) is tackled next
will need its own fresh survey/scoping the same way every prior GEN-05
sub-slice this session was self-selected.

Acceptance gate satisfied: both mnemonics have real, newly-added encoder
support (one in a new, bug-avoiding table; one added directly to an
already-safe existing table) verified byte-for-byte against real
`riscv32-linux-gnu-as`/`riscv64-linux-gnu-as` output via two new
normalization shapes (`f_mv_x_w_form`/`f_mv_w_x_form`); a persisted,
offline-replayed differential corpus entry each with real GNU agreement;
admission-matrix promotion; and a full `make asm-ci` pass - the same
measured-Pass discipline every other GEN-05/GAS-04 promotion used, with
every affected pinned count in the repository's own regression suite
updated and re-verified rather than left stale.

##### GEN-05 continuation: RISC-V F `fcvt.w.s`/`fcvt.wu.s`/`fcvt.s.w`/`fcvt.s.wu` (Claude)

Task / status / owner: GEN-05 F word/single-precision conversion sub-slice /
done; GEN-05 overall / still implementing / Claude - self-selected as the
last named scalar-FP item flagged open by the previous `fmv.x.w`/`fmv.w.x`
writeup: unlike every recent scalar-FP slice, this needed a normalization
shape built entirely from scratch rather than reusing one.

Scope manifest and obligations: 4 `kind: instruction-form` records, all
`rv_f`-only (single precision, XLEN-independent - no `.d` sibling, no RV32/
RV64 split), both profiles. Encoder: `fcvt.s.w` (`i_to_f_desc`, funct7 =
0x68, rs2 = 0) and the RV64-only `fcvt.s.l`/double-precision conversions
already existed from an earlier, pre-isa-consumption pass (CompCert's own
codegen needs), but had never been wired into `Isa_norm_riscv`/
`Isa_family_admission`/`Isa_gen_difficult` at all - confirmed via `grep
fcvt` across all three returning nothing before this slice. `fcvt.s.wu` was
added to the same `i_to_f_desc` table (funct7 = 0x68, rs2 = 1, alongside the
pre-existing `fcvt.s.w`/`fcvt.s.l` entries at rs2 = 0/2); `fcvt.w.s`/
`fcvt.wu.s` were added to `f_to_i_desc` (funct7 = 0x60, rs2 = 0/1) beside
the pre-existing `fcvt.w.d`/`fcvt.wu.d`/`fcvt.l.d` group at funct7 = 0x61 -
no bug-avoidance table split needed here (unlike `fmv.x.w`/`fclass.s`)
because `fcvt.w.s`/`fcvt.wu.s`'s own funct3 genuinely is the dynamic
rounding mode, not a fixed selector colliding with another mnemonic;
confirmed by real GNU as accepting `fcvt.w.s a0, fa1, rtz` as legal syntax
(funct3 changes from `dyn`=7 to `rtz`=1), exactly the shape `fcvt.w.d`'s own
already-safe use of that lowering arm has. Normalization: two new shapes
built from scratch, `f_cvt_w_s_form` (`rd` a GPR `Out`, `rs1` FP `In`, `rm`
implicit dynamic-rounding, covering `fcvt.w.s`/`fcvt.wu.s`) and
`f_cvt_s_w_form` (`rd` FP `Out`, `rs1` a GPR `In`, same implicit `rm`,
covering `fcvt.s.w`/`fcvt.s.wu`) - `f_sqrt_form`'s own implicit-dynamic-
rounding shape, but with mixed register classes across `rd`/`rs1` instead
of both FP.

Real, measured findings: verified real GNU-as's exact bytes for all four
mnemonics (plus the double-precision and `.l`/`.lu` RV64-only siblings, to
confirm scope boundaries) before writing any encoder code
(`riscv64-linux-gnu-as -march=rv64gc`/`riscv32-linux-gnu-as -march=rv32gc`,
`objdump -M no-aliases`): `fcvt.s.w fa0, a1` -> `d005f553`, `fcvt.s.wu fa0,
a1` -> `d015f553`, `fcvt.w.s a0, fa1` -> `c005f553`, `fcvt.wu.s a0, fa1` ->
`c015f553`, `fcvt.w.s a0, fa1, rtz` -> `c0059553` - byte-identical on both
profiles, confirming these are XLEN-independent (unlike `fcvt.s.l`/
`fcvt.l.s`, which real GNU as rejects on `riscv32-linux-gnu-as` with
"unrecognized opcode", confirming that boundary was correctly left out of
scope). Extracted the real source records for all four mnemonics verbatim
from the checked-in `isa-db/export/riscv_opcodes/riscv32.jsonl` (record IDs
`riscv-opcodes:rv_f:fcvt.w.s@L17`, `:fcvt.wu.s@L18`, `:fcvt.s.w@L24`,
`:fcvt.s.wu@L25`) rather than hand-authoring test JSON. This project's own
`asm.exe --dump-disasm=diagnostic`/`--dump-bytes` reproduced all four
mnemonics' bytes exactly on both profiles (including the explicit `rtz`
override spelling), matching real GNU as byte-for-byte.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
real-toolchain smoke test via `riscv32-linux-gnu-as`/`riscv64-linux-gnu-as`/
`objdump` for all four mnemonics plus the `rtz`-override and RV32-illegal-
`.l`/`.lu` probes, and this project's own `asm.exe --dump-disasm=diagnostic`/
`--dump-bytes`; `make tools-test` (first run intentionally left
`test_isa_gen_difficult.ml`'s `all`-equals-sum-of-lengths self-consistency
check stale, then updated it); `make tools-integration` (first run
intentionally left `repo_tests.ml`'s pinned counts stale to read off the
real new numbers, then hard-coded them, then re-ran clean); `make
tools-boundary`; `make asm-fmt`/`asm-fmt-check` (also picked up one
pre-existing, unrelated formatting drift in `isa_gen_oracle.ml`; re-verified
the reformatted files still parse and every check still passes); `cd asm &&
opam exec -- dune build @runtest`; same `PATH` prefix for `make
asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl` from
266 to 274 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `gas.tool_label`/`ours.tool_label`, that all 266
pre-existing cases are byte-for-byte unchanged and exactly the 8 expected
new case_ids - 4 mnemonics x 2 profiles - were added, every one `verdict =
pass`); `make asm-ci` (full CI target, backgrounded, exit 0).

Results and artifact links: 2 new `isa-norm-riscv` unit test functions
(`test_fcvt_w_s`, `test_fcvt_s_w`, against real, verbatim-extracted
riscv32.jsonl records for all four mnemonics), asserting the requirement
(`riscv:f`), the mixed-register-class 2-operand-plus-implicit-`rm` shape in
each direction, and syntax rendering. One new domain check in
`test_isa_gen_difficult.ml` (`test_f_cvt_w_s_domain`) covering all four new
corpus entry lists (`fcvt_w_s_entries`, `fcvt_wu_s_entries`,
`fcvt_s_w_entries`, `fcvt_s_wu_entries`). `Isa_family_admission`'s pinned
totals moved: RV32 promoted-support 202->206, blocked 867->863; RV64
promoted-support 236->240, blocked 888->884 - straight from
blocked to promoted-support since these four records never normalized at
all before this commit, leaving `normalized_only` unchanged at 20/30.
`isa-norm-accounting`'s totals moved 222->226 (RV32) / 266->270 (RV64), and
the `isa-norm-jsonl` real-form round-trip count moved 506->514 (+8), all
pinned `repo_tests.ml` expectations updated and re-verified passing.
`tools-test`, `tools-integration`, `tools-boundary` all pass; `dune build
@runtest` passes; `make asm-ci` passes in full.

Unknowns, exceptions and follow-up task IDs: this closes every scalar FP
mnemonic named as open in every prior GEN-05 F/D writeup this session -
arithmetic, sign-injection, min/max, sqrt/class, fused multiply-add,
comparisons, bit-moves, and now the word/single-precision conversions.
Remaining named scope: double-precision-involving conversions
(`fcvt.d.w`/`fcvt.d.wu`/`fcvt.w.d`/`fcvt.wu.d`/`fcvt.s.d`/`fcvt.d.s`, and the
RV64-only long conversions `fcvt.l.d`/`fcvt.s.l`/etc.) already have encoder
support from the earlier pre-isa-consumption pass but - like this slice
before today - have never been wired into the norm/admission/corpus layer;
not scoped or attempted here. The previously-flagged `f_to_i_desc`
rounding-mode-override latent gap remains unrelated to this slice, not
reproduced by it (confirmed: `fcvt.w.s`/`fcvt.wu.s`'s own funct3 genuinely
is the rounding mode, not a fixed selector, so the override arm is correct
here, not a bug), and still not fixed. The large remaining vector extension
track (375+ records, needing a new vector register class) remains
unscoped.

Acceptance gate satisfied: all four mnemonics have real encoder support
(three newly added, one pre-existing) verified byte-for-byte against real
`riscv32-linux-gnu-as`/`riscv64-linux-gnu-as` output via two new
normalization shapes (`f_cvt_w_s_form`/`f_cvt_s_w_form`); a persisted,
offline-replayed differential corpus entry each with real GNU agreement;
admission-matrix promotion; and a full `make asm-ci` pass - the same
measured-Pass discipline every other GEN-05/GAS-04 promotion used, with
every affected pinned count in the repository's own regression suite
updated and re-verified rather than left stale.

##### GEN-05 continuation: RISC-V D `fcvt.w.d`/`fcvt.wu.d`/`fcvt.d.w`/`fcvt.d.wu`/`fcvt.s.d`/`fcvt.d.s` (Claude)

Task / status / owner: GEN-05 D conversion sub-slice / done; GEN-05 overall
/ still implementing / Claude - self-selected as the double-precision-
involving conversion family the previous `fcvt.w.s`/`fcvt.wu.s`/`fcvt.s.w`/
`fcvt.s.wu` writeup flagged still open.

Scope manifest and obligations: 6 `kind: instruction-form` records, all
`rv_d`-only (D extension, XLEN-independent - the D extension has no RV32/
RV64 split), both profiles. Encoder: all six already had full support from
the earlier, pre-isa-consumption pass (CompCert's own codegen needs) -
`fcvt.d.w`/`fcvt.d.wu` in `i_to_f_desc`, `fcvt.w.d`/`fcvt.wu.d` in
`f_to_i_desc` (alongside the RV64-only `fcvt.l.d`), `fcvt.s.d`/`fcvt.d.s` in
`f_to_f_desc` - confirmed via `grep fcvt` across `Isa_norm_riscv`/
`Isa_family_admission`/`Isa_gen_difficult` returning nothing for any of the
six before this slice, exactly like `fcvt.s.w`/`fcvt.s.l` before the
previous slice. No encoder changes needed at all this time. Normalization:
`fcvt.w.d`/`fcvt.wu.d` were added directly to the previous slice's own
`f_cvt_w_s_mnemonics` list/`f_cvt_w_s_form` (identical shape and dynamic-
rounding default - `f_to_i_desc`'s funct3 = 7 for both - `requirement_of`
distinguishes `riscv:d` from `riscv:f` automatically from each record's own
extension, no new code needed). Two genuinely new forms: `f_cvt_d_w_form`
(`fcvt.d.w`/`fcvt.d.wu`, `rd` FP `Out`/`rs1` GPR `In` like `f_cvt_s_w_form`,
but real hardware's "always exact" rne=0 default instead of dyn=7, since a
32-bit integer always converts to double exactly) and `f_cvt_f_f_form`
(`fcvt.s.d`/`fcvt.d.s`, `rd`/`rs1` both FP, no GPR at all - `fcvt.s.d`
narrowing keeps the dynamic default, `fcvt.d.s` widening gets the same
always-exact rne default as `f_cvt_d_w_form`'s pair).

Real, measured findings: verified real GNU-as's exact bytes for all six
mnemonics before writing any encoder code (none was needed) or norm code
(`riscv64-linux-gnu-as -march=rv64gc`/`riscv32-linux-gnu-as -march=rv32gc`,
`objdump -M no-aliases`): `fcvt.d.w fa0, a1` -> `d2058553`, `fcvt.d.wu fa0,
a1` -> `d2158553`, `fcvt.w.d a0, fa1` -> `c205f553`, `fcvt.wu.d a0, fa1` ->
`c215f553`, `fcvt.s.d fa0, fa1` -> `4015f553`, `fcvt.d.s fa0, fa1` ->
`42058553`, and `fcvt.w.d a0, fa1, rtz` -> `c2059553` (confirming the
explicit-rounding-mode-override path already works for this pair, exactly
like `fcvt.w.d`'s pre-existing RV64-only sibling `fcvt.l.d`) - byte-
identical on both profiles, matching the pre-existing `i_to_f_desc`/
`f_to_i_desc`/`f_to_f_desc` table entries exactly, confirming no encoder
work was needed. This project's own `asm.exe --dump-bytes` reproduced all
seven probes' bytes exactly on both profiles.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
real-toolchain smoke test via `riscv32-linux-gnu-as`/`riscv64-linux-gnu-as`/
`objdump` for all six mnemonics plus the `fcvt.w.d ..., rtz` override probe,
and this project's own `asm.exe --dump-bytes`; `make tools-test` (first run
intentionally left `test_isa_gen_difficult.ml`'s `all`-equals-sum-of-lengths
self-consistency check stale, then updated it); `make tools-integration`
(first run intentionally left `repo_tests.ml`'s pinned counts stale to read
off the real new numbers, then hard-coded them, then re-ran clean); `make
tools-boundary`; `make asm-fmt`/`asm-fmt-check` (ocamlformat reformatted the
new verbatim-extracted JSON test literals; re-verified the reformatted
strings still parse and every check still passes); `cd asm && opam exec --
dune build @runtest`; same `PATH` prefix for `make asm-isa-difficult-regen`
(grew `asm/fixtures/isa-difficult/cases.jsonl` from 274 to 286 entries;
confirmed record-by-record, ignoring only the git-rev-embedded
`gas.tool_label`/`ours.tool_label`, that all 274 pre-existing cases are
byte-for-byte unchanged and exactly the 12 expected new case_ids - 6
mnemonics x 2 profiles - were added, every one `verdict = pass`); `make
asm-ci` (full CI target, backgrounded, exit 0).

Results and artifact links: 3 new `isa-norm-riscv` unit test functions
(`test_fcvt_w_d`, `test_fcvt_d_w`, `test_fcvt_f_f`, against real, verbatim-
extracted riscv32.jsonl records for all six mnemonics), asserting the
requirement (`riscv:d`), the mixed- or matched-register-class 2-operand-
plus-implicit-`rm` shape in each direction, and syntax rendering. One new
domain check in `test_isa_gen_difficult.ml` (`test_f_cvt_w_d_domain`)
covering all six new corpus entry lists, including the new
`implicit-exact-rounding` rule-id tag distinguishing the always-exact
default pair from the dynamic-rounding one. `Isa_family_admission`'s
pinned totals moved: RV32 promoted-support 206->212, blocked 863->857; RV64
promoted-support 240->246, blocked 884->878 - straight from blocked to
promoted-support since these six records never normalized at all before
this commit, leaving `normalized_only` unchanged at 20/30.
`isa-norm-accounting`'s totals moved 226->232 (RV32) / 270->276 (RV64), and
the `isa-norm-jsonl` real-form round-trip count moved 514->526 (+12), all
pinned `repo_tests.ml` expectations updated and re-verified passing.
`tools-test`, `tools-integration`, `tools-boundary` all pass; `dune build
@runtest` passes; `make asm-ci` passes in full.

Unknowns, exceptions and follow-up task IDs: this closes every named F/D
scalar conversion mnemonic - both the word/single-precision pair from the
previous slice and this slice's double-precision pair, plus the float-to-
float precision converts. Every scalar F/D mnemonic flagged open across
every prior GEN-05 writeup this session is now closed. The
previously-flagged `f_to_i_desc` rounding-mode-override latent gap remains
unrelated to this slice, not reproduced by it, and still not fixed. The
RV64-only long conversions are only partially encoder-supported - `fcvt.l.d`
and `fcvt.s.l` already exist (used by an earlier, pre-isa-consumption pass),
but `fcvt.lu.d`/`fcvt.d.l`/`fcvt.d.lu`/`fcvt.l.s`/`fcvt.lu.s`/`fcvt.s.lu` do
not, and unlike every conversion mnemonic closed this session and the
previous one, would need genuinely new encoder table entries, not just
norm/admission/corpus wiring - confirmed via real GNU-as probes this
session (`fcvt.s.l`/`fcvt.l.s`/`fcvt.s.lu`/`fcvt.lu.s` all assemble on
`riscv64-linux-gnu-as`, all four rejected as unrecognized opcodes on
`riscv32-linux-gnu-as`, confirming they are genuinely RV64-only, not just
unimplemented here). That family and the large remaining vector extension
track (375+ records, needing a new vector register class) are the only
scope left named for GEN-05.

Acceptance gate satisfied: all six mnemonics have real, pre-existing
encoder support verified byte-for-byte against real `riscv32-linux-gnu-as`/
`riscv64-linux-gnu-as` output via one reused and two new normalization
shapes (`f_cvt_w_s_form` extended, `f_cvt_d_w_form`/`f_cvt_f_f_form` new); a
persisted, offline-replayed differential corpus entry each with real GNU
agreement; admission-matrix promotion; and a full `make asm-ci` pass - the
same measured-Pass discipline every other GEN-05/GAS-04 promotion used,
with every affected pinned count in the repository's own regression suite
updated and re-verified rather than left stale.

##### GEN-05 continuation: RISC-V RV64 long conversions `fcvt.l.d`/`fcvt.lu.d`/`fcvt.d.l`/`fcvt.d.lu`/`fcvt.l.s`/`fcvt.lu.s`/`fcvt.s.l`/`fcvt.s.lu` (Claude)

Task / status / owner: GEN-05 RV64-only long-conversion sub-slice / done;
GEN-05 overall / still implementing / Claude - self-selected as the family
the previous `fcvt.w.d`/`fcvt.wu.d`/`fcvt.d.w`/`fcvt.d.wu`/`fcvt.s.d`/
`fcvt.d.s` writeup flagged still open, and only partially encoder-supported
(unlike every other scalar conversion closed this session).

Scope manifest and obligations: 8 `kind: instruction-form` records, all
RV64-only - `fcvt.l.d`/`fcvt.lu.d`/`fcvt.d.l`/`fcvt.d.lu` under `rv64_d`,
`fcvt.l.s`/`fcvt.lu.s`/`fcvt.s.l`/`fcvt.s.lu` under `rv64_f` - with no
RV32 counterpart at all (`riscv32.jsonl` does not contain these records;
confirmed via a direct grep over the checked-in export before starting).
Encoder: only `fcvt.l.d` (`f_to_i_desc`, funct7=0x61/rs2=2) and `fcvt.s.l`
(`i_to_f_desc`, funct7=0x68/rs2=2) already existed from the earlier
pre-isa-consumption pass; the other 6 needed genuinely new `Opcode.t`
variants and table entries - `Fcvt_lu_d` (f_to_i_desc, 0x61/3), `Fcvt_l_s`/
`Fcvt_lu_s` (f_to_i_desc, 0x60/2 and 0x60/3), `Fcvt_d_l`/`Fcvt_d_lu`
(i_to_f_desc, 0x69/2 and 0x69/3), `Fcvt_s_lu` (i_to_f_desc, 0x68/3) - plus
extending the existing `(Fcvt_l_d | Fmv_x_d | Fcvt_s_l), _ when xlen <> 64`
lowering guard to cover all 8 new/existing long-conversion opcodes, and
extending `f_shape_of_name`/`f_r_name` (decode) to cover every new
funct7/rs2 pair. Normalization: no new shapes needed at all - `fcvt.l.d`/
`fcvt.lu.d`/`fcvt.l.s`/`fcvt.lu.s` (rd GPR, rs1 FP, dynamic rounding) were
added directly to the previous slices' own `f_cvt_w_s_mnemonics` list;
`fcvt.s.l`/`fcvt.s.lu` (rd FP, rs1 GPR, dynamic rounding) to
`f_cvt_s_w_mnemonics`. `fcvt.d.l`/`fcvt.d.lu` needed the same
`f_cvt_s_w_mnemonics` shape too, NOT `f_cvt_d_w_form`'s always-exact one -
real hardware only treats word-to-double and single-to-double as "always
exact" (a 32-bit value always fits a double's 52-bit mantissa); a 64-bit
long does not, so `fcvt.d.l`/`fcvt.d.lu` keep the family's usual dynamic
default, confirmed by measurement before assuming otherwise. Also added
`rv64_d`/`rv64_f` to `feature_of_extension` (`Req_all [Req_xlen 64;
Req_feature "riscv:d"/"riscv:f"]`, the same `rv64_a` pattern already
established) since no RISC-V FP mnemonic before this slice needed an
XLEN-gated F/D feature.

Real, measured findings: verified real GNU-as's exact bytes for all 8
mnemonics, their bare-spelling rounding-mode default, and RV32 rejection,
before writing any encoder code (`riscv64-linux-gnu-as -march=rv64gc`,
`riscv32-linux-gnu-as -march=rv32gc`, `objdump -M no-aliases`): `fcvt.lu.d
a0, fa1` -> `c235f553`, `fcvt.d.l fa0, a1` -> `d225f553`, `fcvt.d.lu fa0,
a1` -> `d235f553`, `fcvt.l.s a0, fa1` -> `c025f553`, `fcvt.lu.s a0, fa1` ->
`c035f553`, `fcvt.s.lu fa0, a1` -> `d035f553` - all rejected as
"unrecognized opcode" on `riscv32-linux-gnu-as`, confirming genuinely
RV64-only. A first attempt got `fcvt.lu.d`'s operand order backwards
(`fcvt.lu.d fa0, a1` instead of `fcvt.lu.d a0, fa1` - it converts double to
an unsigned long, so `rd` is the GPR, not `rs1`); real GNU as's "illegal
operands" error caught this before any encoder code was written. Bit-field
decoding every bare-spelling word (via a small Python script, not by hand)
confirmed `fcvt.d.l`/`fcvt.d.lu`'s bare funct3 = 7 (dynamic), not 0 (exact)
like `fcvt.d.w`/`fcvt.d.wu` - the design decision to reuse
`f_cvt_s_w_mnemonics` rather than `f_cvt_d_w_mnemonics` was made only after
this measurement, not assumed from the mnemonic's naming symmetry alone.
This project's own `asm.exe --dump-disasm=diagnostic`/`--dump-bytes`
reproduced all 8 mnemonics' bytes exactly on RV64, and correctly rejected
all 8 on RV32 with `error[riscv32.lower]: ... is available only when XLEN
is 64`, matching real GNU as's own rejection.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
real-toolchain smoke test via `riscv32-linux-gnu-as`/`riscv64-linux-gnu-as`/
`objdump` for all 8 mnemonics (plus the corrected `fcvt.lu.d` operand order
and the RV32-rejection probes), a standalone Python bit-field decode of
every bare-spelling word to confirm each one's rounding-mode default before
choosing its normalization shape, and this project's own `asm.exe
--dump-disasm=diagnostic`/`--dump-bytes` on both riscv32/riscv64 targets;
`make tools-test` (first run intentionally left `test_isa_gen_difficult.ml`'s
`all`-equals-sum-of-lengths self-consistency check stale, then updated it);
`make tools-integration` (first run intentionally left `repo_tests.ml`'s
pinned counts stale to read off the real new numbers, then hard-coded
them, then re-ran clean); `make tools-boundary`; `make asm-fmt`/
`asm-fmt-check` (ocamlformat reformatted the new verbatim-extracted JSON
test literals; re-verified the reformatted strings still parse and every
check still passes); `cd asm && opam exec -- dune build @runtest`; same
`PATH` prefix for `make asm-isa-difficult-regen` (grew
`asm/fixtures/isa-difficult/cases.jsonl` from 286 to 294 entries; confirmed
record-by-record, ignoring only the git-rev-embedded `gas.tool_label`/
`ours.tool_label`, that all 286 pre-existing cases are byte-for-byte
unchanged and exactly the 8 expected new case_ids - one per mnemonic,
RV64 only, no RV32 counterpart - were added, every one `verdict = pass`);
`make asm-ci` (full CI target, backgrounded, exit 0).

Results and artifact links: 2 new `isa-norm-riscv` unit test functions
(`test_fcvt_l_d`, `test_fcvt_l_s`, against real, verbatim-extracted
riscv64.jsonl records for all 8 mnemonics - these records exist only in
`riscv64.jsonl`, confirmed), asserting the `Req_all [Req_xlen 64;
Req_feature ...]` requirement, the mixed-register-class 2-operand-plus-
implicit-dynamic-`rm` shape in each direction, and syntax rendering. One
new domain check in `test_isa_gen_difficult.ml` (`test_f_cvt_l_domain`)
covering all 8 new corpus entry lists, asserting every one targets
`Riscv64` only and keeps the dynamic-rounding tag (never the always-exact
one `fcvt.d.w`/`fcvt.d.wu`/`fcvt.d.s` use). `Isa_family_admission`'s pinned
totals moved: RV64 promoted-support 246->254, blocked 878->870 - straight
from blocked to promoted-support since these 8 records never normalized at
all before this commit; RV32's own counts are unaffected (these records do
not exist in `riscv32.jsonl`, unlike every other conversion family closed
this session). `isa-norm-accounting`'s RV64 total moved 276->284 (RV32
unaffected, still 232), and the `isa-norm-jsonl` real-form round-trip count
moved 526->534 (+8, one per mnemonic since RV64-only), all pinned
`repo_tests.ml` expectations updated and re-verified passing. `tools-test`,
`tools-integration`, `tools-boundary` all pass; `dune build @runtest`
passes; `make asm-ci` passes in full.

Unknowns, exceptions and follow-up task IDs: this closes every named
scalar RISC-V F/D conversion mnemonic in the checked-in export - word,
double-precision, and now RV64-only long. No further scalar F/D conversion
scope remains named. The previously-flagged `f_to_i_desc` rounding-mode-
override latent gap remains unrelated to this slice, not reproduced by it,
and still not fixed. A separate, smaller, not-yet-scoped gap: `i_to_f_desc`
has no explicit-rounding-mode-override lowering arm at all (only
`f_to_i_desc` does), so this project's own encoder cannot currently accept
an explicit `rm` operand on any `i_to_f_desc`-mapped mnemonic (`fcvt.d.w`,
`fcvt.d.wu`, `fcvt.d.l`, `fcvt.d.lu`, `fcvt.s.w`, `fcvt.s.wu`, `fcvt.s.l`,
`fcvt.s.lu`, `fmv.w.x`) even though real GNU as accepts one on every
dynamic-rounding member of that list (confirmed: `fcvt.d.l fa0, a1, rtz`
assembles on real GNU as to `d2259553`); this predates every conversion
slice this session (was never in scope for any of them, since none of
their difficult-corpus entries exercise an explicit rounding-mode operand)
and remains a separate, bounded follow-up, not a regression from this
work. The large remaining vector extension track (375+ records, needing a
new vector register class) is now the only scope left named for GEN-05.

Acceptance gate satisfied: all 8 mnemonics have real encoder support (6
newly added, 2 pre-existing) verified byte-for-byte against real
`riscv32-linux-gnu-as`/`riscv64-linux-gnu-as` output (including correct
RV32 rejection) via two extended, pre-existing normalization shapes
(`f_cvt_w_s_mnemonics`/`f_cvt_s_w_mnemonics` - no new shape code needed); a
persisted, offline-replayed differential corpus entry each with real GNU
agreement; admission-matrix promotion; and a full `make asm-ci` pass - the
same measured-Pass discipline every other GEN-05/GAS-04 promotion used,
with every affected pinned count in the repository's own regression suite
updated and re-verified rather than left stale.

##### GEN-05 continuation: RISC-V V `vsetvl` (Claude)

Task / status / owner: GEN-05 vector-extension entry-point sub-slice / done;
GEN-05 overall / still implementing / Claude - self-selected per the plan's
instruction to proceed to vector extensions after every named scalar F/D
scope closed. The rv_v family has 375 records plus 11 rv_v_aliases and
several hundred more across the rv_zv* vector-crypto extensions, and almost
all of them need a genuine vector register class this project's encoder
does not have; `vsetvl`/`vsetvli`/`vsetivli` are the family's only members
with no vector-register operand at all, and among those three `vsetvl` is
the only one whose operands are plain GPRs with ordinary numeric-immediate-free
syntax - `vsetvli`/`vsetivli` both need GAS's own non-numeric
`e<SEW>,m<LMUL>,ta|tu,ma|mu` vtype operand-list syntax, a real text-frontend
extension out of scope for a single-slice entry point.

Scope manifest and obligations: 1 `kind: instruction-form` record
(`riscv-opcodes:rv_v:vsetvl@L13`), identical on both riscv32.jsonl and
riscv64.jsonl (confirmed via a direct grep over the checked-in export before
starting), no `$import`/`$pseudo_op` duplication (`relationships` is empty
on both). Encoding is a genuine R-type shape - opcode `0x57` (OP-V, entirely
unused by this project before this slice; OP-FP is the distinct `0x53`),
funct3 `0x7`, funct7 `0x40` - so `r_type_gpr_form`/`r_desc`
(`riscv_family_encode.ml`'s existing `op, [a; b; c] when Option.is_some
(r_desc op)` lowering arm) apply completely unchanged: no new lowering arm,
no new codec path, no new text-frontend parsing at all, since the generic
mnemonic-plus-comma-separated-operand-list parser already handles any
three-plain-register instruction. Only additions: a new `Opcode.t` variant
`Vsetvl` (name/`all`/`r_desc`/`r_name` table entries), a new `"rv_v" ->
Req_feature "riscv:v"` case in `feature_of_extension`, and `"vsetvl"` added
to `r_type_mnemonics` - the cheapest possible addition pattern this project
has, cheaper even than `min`/`minu`/`max`/`maxu`'s own plain single-extension
R-type slice, since no new shamt/immediate/memory operand kind was involved.

Real, measured findings: verified real GNU-as's exact bytes before writing
any encoder code (`riscv64-linux-gnu-as` 2.44 `-march=rv64iv`,
`riscv32-linux-gnu-as` 2.43.1 `-march=rv32iv`, both `-mno-relax`,
`objdump -M no-aliases`): `vsetvl a0, a1, a2` -> `80c5f557` and
`vsetvl a0, zero, a2` -> `80c07557`, byte-identical on both profiles - `v`
alone (no `f`/`d`) suffices for real GNU as to accept the mnemonic, so no
architectural F/D dependency was assumed or modeled for this one
instruction. Bit-field-decoded the word by hand before writing `r_desc`:
funct7 `(word >> 25) & 0x7f = 0x40`, funct3 `(word >> 12) & 0x7 = 7`, opcode
`word & 0x7f = 0x57`. This project's own `asm.exe --dump-bytes`/
`--dump-disasm=diagnostic` reproduced both words exactly on both `riscv32`
and `riscv64` targets, including the round-trip decode back to
`vsetvl x10, x11, x12` / `vsetvl x10, x0, x12`.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build @all`;
real-toolchain smoke test via `riscv32-linux-gnu-as`/`riscv64-linux-gnu-as`/
`objdump` (both profiles, plus a manual bit-field decode of the resulting
word) before writing any encoder code; this project's own `asm.exe
--dump-bytes`/`--dump-disasm=diagnostic` on both `riscv32`/`riscv64`
targets; `make tools-test`; `make tools-integration` (first run
intentionally left `repo_tests.ml`'s pinned counts stale to read off the
real new numbers - `isa-norm-accounting` 232/284 -> 233/285,
`isa-family-admission` promoted-support 212/254 -> 213/255 and blocked
857/870 -> 856/869, `isa-norm-jsonl` round-trip 534 -> 536 - then hard-coded
them, then re-ran clean); `make tools-boundary`; `cd asm && opam exec --
dune build @runtest` (1529 checks passed); `make asm-fmt`/`asm-fmt-check`
(ocamlformat reformatted the new domain-check closure; re-verified the
reformatted check still passes); same `PATH` prefix for
`make asm-isa-difficult-regen` (grew `asm/fixtures/isa-difficult/cases.jsonl`
from 294 to 296 entries; confirmed record-by-record, ignoring only the
git-rev-embedded `gas.tool_label`/`ours.tool_label`, that all 294
pre-existing cases are byte-for-byte unchanged and exactly the 2 expected
new case_ids - one per profile - were added, every one `verdict = pass`);
`make asm-isa-difficult-check`; `make asm-ci` (full CI target, backgrounded,
exit 0).

Results and artifact links: 1 new `isa-norm-riscv` unit test
(`test_vsetvl`, against the real, verbatim-extracted riscv64.jsonl record -
identical in riscv32.jsonl, confirmed - reusing the existing
`test_r_type_gpr` helper unchanged), asserting the plain `Req_feature
"riscv:v"` requirement (no `Req_any`), the three-plain-GPR-operand shape,
and `rd, rs1, rs2` syntax rendering. One new domain check in
`test_isa_gen_difficult.ml` (`test_vsetvl_domain`) covering both new corpus
entries, asserting the `a0, a1, a2` operand triple, the `v-enabled` rule
tag, and a `-march=...v`-suffixed configuration. `Isa_family_admission`'s
pinned totals moved: RV32 promoted-support 212->213, blocked 857->856; RV64
promoted-support 254->255, blocked 870->869 - straight from blocked to
promoted-support on both profiles, since this record never normalized at
all before this commit. `isa-norm-accounting`'s RV32/RV64 totals moved
232->233 and 284->285. `isa-norm-jsonl`'s real-form round-trip count moved
534->536 (+2, one per profile). `tools-test`, `tools-integration`,
`tools-boundary` all pass; `dune build @runtest` passes (1529 checks);
`make asm-ci` passes in full.

Unknowns, exceptions and follow-up task IDs: this closes only `vsetvl`
itself. `vsetvli`/`vsetivli` remain a named, separate follow-up - both need
a genuinely new text-frontend construct (GAS's own comma-separated
`e<SEW>,m<LMUL>,ta|tu,ma|mu` vtype spelling is not a register, a bare
numeric immediate, or a memory operand, so `parse_one`/`parse_operands` in
`riscv_family.ml` cannot represent it as today's `Operand.t` without a new
variant and matching normalization/encoder work) before they can reuse this
slice's `r_desc`/`r_type_gpr_form` discipline. The remaining 373 rv_v
records and every rv_zv* vector-crypto record remain unclaimed and need an
actual vector register class (`v0`-`v31`), vector-length/mask-operand
syntax, and segment/stride/indexed addressing modes this project's encoder
does not model yet - a substantially larger design effort than any single
GEN-05 slice so far, and explicitly out of scope for this entry-point slice.

Acceptance gate satisfied: `vsetvl` has real encoder support verified
byte-for-byte against real `riscv32-linux-gnu-as`/`riscv64-linux-gnu-as`
output on both profiles via the fully reused `r_type_gpr_form`/`r_desc`
path (no new shape code); a persisted, offline-replayed differential corpus
entry per profile with real GNU agreement; admission-matrix promotion; and
a full `make asm-ci` pass - the same measured-Pass discipline every other
GEN-05/GAS-04 promotion used, with every affected pinned count in the
repository's own regression suite updated and re-verified rather than left
stale.

##### GEN-05 continuation: RISC-V V `vsetvli`/`vsetivli` (Claude)

Task / status / owner: GEN-05 vector-extension vtype-keyword-list sub-slice
/ done; GEN-05 overall / still implementing / Claude - the two named
follow-ups flagged open by the `vsetvl` writeup above.

Scope manifest and obligations: 2 `kind: instruction-form` records
(`riscv-opcodes:rv_v:vsetvli@L12`, `riscv-opcodes:rv_v:vsetivli@L11`),
each identical on both riscv32.jsonl and riscv64.jsonl (confirmed via a
direct grep before starting), no `$import`/`$pseudo_op` duplication
(`relationships` empty on both, same as `vsetvl`). Before writing any
encoder code, real GNU as was used to establish the actual grammar GAS
accepts for the trailing "vtype" operand list - this was not assumed from
the ISA manual's canonical spelling alone: any subset of four independent
keyword categories (SEW `e8`/`e16`/`e32`/`e64`, LMUL `m1`/`m2`/`m4`/`m8`/
`mf2`/`mf4`/`mf8`, tail policy `ta`/`tu`, mask policy `ma`/`mu`) may be
given, each at most once, in strict category order, with omitted
categories defaulting to `e8`/`m1`/`tu`/`mu`; specifying zero keywords, or
keywords out of order, is "illegal operands" on real GNU as (`vsetvli a0,
a1, m1, e32` and `vsetvli a0, a1, ma, ta` both rejected; `vsetvli a0, a1,
ta` alone - skipping SEW/LMUL entirely - accepted as `e8,m1,ta,mu`).

The key design finding, made before writing any frontend code: this
grammar needs **no text-frontend/parser change at all**. Every bare
keyword (`e32`, `m1`, `ta`, `ma`, ...) already parses through
`riscv_family.ml`'s existing generic bare-identifier fallback into
`Operand.Sym (Symbol s)` - the same path any undefined mnemonic or label
reference takes - so the entire feature reduces to (1) a new
`Opcode.t`-level lowering match arm accepting a variable-length operand
list (`a :: b :: (_ :: _ as tail)`, arity 3-6) and (2) a small
category-classifying/bit-composing function over the tail's symbol names,
both purely in `riscv_family_encode.ml`. The previous writeup's
description of this as "a real text-frontend extension" was wrong in
that specific sense - it is a lowering-layer feature, not a
parser/lexer one - though still a genuinely new construct compared to
every fixed-arity match arm this project had before it.

The second key finding: both instructions' architecturally distinctive
bit patterns - `vsetvli`'s forced bit31=0 and `vsetivli`'s forced
bits[31:30]=0b11 - need **no new codec path or bit-masking machinery**
either. `vsetvli`'s composed vtype value (0-223, always < 2048) simply
never sets bit11 of a plain signed-12-bit `Lowered.I` immediate, so
bit31=0 falls out of ordinary two's-complement encoding automatically;
`vsetivli`'s vtype-1024 (always in [-1024,-801]) is a genuine negative
12-bit two's-complement value whose top two bits are always `11`, so
bits[31:30]=0b11 falls out the same way - exactly the trick
`signed_csr` already established for CSR's own unsigned-field-through-a-
signed-path reuse, just discovered independently by hand-decoding a real
GNU as word before writing any code, not assumed by analogy.

Real, measured findings: verified real GNU-as's exact bytes for every
tested keyword and combination before writing any encoder code
(`riscv64-linux-gnu-as` 2.44 `-march=rv64iv`, `riscv32-linux-gnu-as`
2.43.1 `-march=rv32iv`, both `-mno-relax`, `objdump -M no-aliases`,
several bare-word bit-field decodes via a small Python script): all four
SEW values, all seven LMUL values, both tail-policy and mask-policy
options individually and combined, in-order subsets skipping earlier
categories (`vsetvli a0, a1, ta` alone, `vsetvli a0, a1, m2, ta`), and
both `vsetivli`'s boundary AVL values (`vsetivli a0, 31, e64, m8` and
`vsetivli a0, 5, m2`). This project's own `asm.exe --dump-bytes`
reproduced all 7 measured combinations exactly on `riscv64`, and
correctly rejected both out-of-order/no-keyword negative controls with
`error[riscv64.lower]: no vsetvli form takes these operands`, matching
real GNU as's own "illegal operands" rejection in spirit (a structural
rejection category, not the same error text - this project's own
rejection-category convention).

Normalization models each record's own flat riscv-opcodes field (a
single 11-bit `zimm11` for `vsetvli`, a 10-bit `zimm10` plus 5-bit
`zimm5` for `vsetivli`) as one `vtype`/`uimm` operand each, explicitly
documenting in an `Inferred` fact that GAS's real spelling is a keyword
decomposition of that field rather than a numeral - the encoder, not the
normalized model, owns interpreting the keyword syntax, the same
division of labor `csr_reg_form` already uses for `csr`'s own numeric-
vs-symbolic spelling. The generated-corpus renderer needed no change
either: `Isa_gen_render.render_line` already joins operand values with
`", "` regardless of whether a value itself contains embedded commas, so
storing the whole literal spelling `"e32, m1, ta, ma"` as the `vtype`
operand's single value renders the canonical six-token GAS line from a
three-element `operands` list.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build
@all`; real-toolchain smoke tests via `riscv32-linux-gnu-as`/
`riscv64-linux-gnu-as`/`objdump` for every keyword/combination/rejection
case above, plus a standalone Python bit-field decode of several bare
words to confirm the vtype bit-composition formula before writing
`vtype_token`/`vtype_value_of`; this project's own `asm.exe --dump-bytes`
on `riscv64` for all 7 positive combinations and both negative controls;
`make tools-test`; `make tools-integration` (first run intentionally left
`repo_tests.ml`'s pinned counts stale to read off the real new numbers -
`isa-norm-accounting` 233/285 -> 235/287, `isa-family-admission`
promoted-support 213/255 -> 215/257 and blocked 856/869 -> 854/867,
`isa-norm-jsonl` round-trip 536 -> 540 - then hard-coded them, then
re-ran clean); `make tools-boundary`; `cd asm && opam exec -- dune build
@runtest` (1549 checks passed); `make asm-fmt`/`asm-fmt-check`
(ocamlformat reformatted the new multi-line record literals and a long
guard clause; re-verified the reformatted code still passes); same `PATH`
prefix for `make asm-isa-difficult-regen` (grew
`asm/fixtures/isa-difficult/cases.jsonl` from 296 to 300 entries;
confirmed record-by-record, ignoring only the git-rev-embedded
`gas.tool_label`/`ours.tool_label`, that all 296 pre-existing cases are
byte-for-byte unchanged and exactly the 4 expected new case_ids - one per
mnemonic per profile - were added, every one `verdict = pass`); `make
asm-isa-difficult-check`; `make asm-ci` (full CI target, backgrounded,
exit 0).

Results and artifact links: 4 new `isa-norm-riscv` unit test checks
(`test_vsetvli`, `test_vsetivli`, against the real, verbatim-extracted
riscv64.jsonl records - identical in riscv32.jsonl, confirmed), asserting
the plain `Req_feature "riscv:v"` requirement, each record's own operand
widths/field names, and `rd, rs1, vtype`/`rd, uimm, vtype` syntax
rendering. One new domain check in `test_isa_gen_difficult.ml`
(`test_vsetvli_domain`) covering all 4 new corpus entries, asserting the
exact operand name/value lists (including the embedded-comma `vtype`
value) and the `vtype-keyword-list` rule tag. `Isa_family_admission`'s
pinned totals moved: RV32 promoted-support 213->215, blocked 856->854;
RV64 promoted-support 255->257, blocked 869->867 - straight from blocked
to promoted-support on both profiles for both mnemonics, since neither
record ever normalized at all before this commit. `isa-norm-accounting`'s
RV32/RV64 totals moved 233->235 and 285->287. `isa-norm-jsonl`'s
real-form round-trip count moved 536->540 (+4, two mnemonics x two
profiles). `tools-test`, `tools-integration`, `tools-boundary` all pass;
`dune build @runtest` passes (1549 checks); `make asm-ci` passes in full.

Unknowns, exceptions and follow-up task IDs: this closes every V
instruction whose operands are plain GPRs, an immediate, or this
keyword-list vtype spelling - `vsetvl`, `vsetvli`, `vsetivli`, the whole
of V's "configuration-setting" instruction group. No further named
follow-up remains for that group. The remaining 373 rv_v records (actual
vector loads/stores/arithmetic) and every rv_zv* vector-crypto record
still need an actual vector register class (`v0`-`v31`), a vector-length/
mask-operand model, and segment/strided/indexed addressing this project's
encoder does not have yet - unclaimed, and substantially larger than any
GEN-05 slice completed so far; GEN-06 still has no single named next
item within this project.

Acceptance gate satisfied: `vsetvli`/`vsetivli` both have real encoder
support verified byte-for-byte against real `riscv32-linux-gnu-as`/
`riscv64-linux-gnu-as` output on both profiles across every tested
keyword/subset/ordering combination, via a genuinely new but minimal
variable-arity lowering path reusing the *existing* `Lowered.I`/`word_i`
codec unchanged; a persisted, offline-replayed differential corpus entry
per mnemonic per profile with real GNU agreement; admission-matrix
promotion; and a full `make asm-ci` pass - the same measured-Pass
discipline every other GEN-05/GAS-04 promotion used, with every affected
pinned count in the repository's own regression suite updated and
re-verified rather than left stale.

##### GEN-05 continuation: RISC-V V `vadd.vv`/`vadd.vx`/`vadd.vi` (Claude)

Task / status / owner: GEN-05 vector-extension entry-point-into-real-
vector-arithmetic sub-slice / done; GEN-05 overall / still implementing /
Claude - self-selected after `vsetvl`/`vsetvli`/`vsetivli` closed V's
entire configuration-setting group, per that writeup's own explicit
follow-up naming the ~373 remaining `rv_v` records as the next unclaimed
scope. Rather than attempt that whole space at once, this slice scopes
down to the single cheapest real vector-register-operand family: OP-V's
plain `vadd.vv`/`vadd.vx`/`vadd.vi` (vector-vector, vector-scalar,
vector-immediate integer add), chosen specifically to stand up the vector
register class itself as a bounded, verifiable first step rather than as
a design task attempted in the abstract.

Scope manifest and obligations: 3 `kind: instruction-form` records
(`riscv-opcodes:rv_v:vadd.vv@L260`, `:vadd.vx@L213`, `:vadd.vi@L306`),
each identical on both riscv32.jsonl and riscv64.jsonl (confirmed via
direct grep), no `$import`/`$pseudo_op` duplication (`relationships`
empty on all three, same as every other rv_v record admitted so far).

Real, measured findings: before writing any encoder code, real GNU as's
exact bytes were established for every operand form and both rejection
classes (`riscv64-linux-gnu-as` 2.44 `-march=rv64gv`, `objdump -M
no-aliases`, plus a hand bit-field decode of several words to confirm the
composition formula): `vadd.vv v1, v2, v3` -> `022180d7` (unmasked) and
`vadd.vv v1, v2, v3, v0.t` -> `002180d7` (masked - only the vm bit at
bit25 differs); `vadd.vx v1, v2, a0`/`, v0.t` -> `022540d7`/`002540d7`;
`vadd.vi v1, v2, 5`/`, -5`/`, 15, v0.t` -> `0222b0d7`/`022db0d7`/
`0027b0d7`. Confirmed real GNU as rejects `vadd.vi v1, v2, 16` and `, -17`
("bad value for vector immediate field, value must be -16...15"),
`vadd.vv v1, v2, v32` and `v1, v2` and `v1, v2, v3, v1.t` (all "illegal
operands" - `v32` is out of range, arity-2 is missing an operand, and the
mask suffix must spell the literal register `v0`, not any other vector
register). This project's own `asm.exe --dump-bytes` reproduced every one
of the 7 positive combinations exactly on `riscv64`, and rejected every
one of the 5 negative controls with `error[riscv64.lower]: no <mnemonic>
form takes these operands` - the same structural-rejection convention
established for every prior GEN-05 slice.

The key design finding: the word's top 7 bits split into a 6-bit funct6
(distinguishing `vadd`/`vsub`/... - `0x00` for `vadd`) and a 1-bit vm
mask-select (bit25) - together exactly the same 7-bit span any other
R-type instruction's `funct7` already occupies. This means no new codec
path was needed at all: all three mnemonics reuse the *existing*
`Lowered.R`/`word_r` path unchanged, computing `funct7 = (funct6 lsl 1)
lor vm` (1 for unmasked, 0 for masked) exactly the way `signed_csr`/
`vsetivli`'s own bit-reuse tricks already established the pattern of
"encode a structurally different field by finding the two's-complement/
bit-composition value that happens to match" for this project. `vadd.vi`'s
5-bit signed immediate similarly needs no new bit-masking machinery -
masking with `0x1f` (`Int64.logand v 0x1fL`) produces the correct 5-bit
two's-complement field directly.

The second key design finding: GAS's bare `v0`-`v31` register spelling and
the trailing `v0.t` mask-suffix marker both needed **zero frontend/parser
changes**. A new `Reg.t` constructor `V of int` was added (mirroring the
existing `X`/`F` split for GPRs/FPRs) with a `numbered "v" (fun n -> V n)`
case in `Reg.find`, and since `riscv_family.ml`'s `parse_one` already
resolves any bare identifier generically through `Reg.find` with no
register-class-specific logic, `v0`-`v31` parse correctly with no changes
to `riscv_family.ml` at all - the same "already-generic text frontend"
finding `vsetvli`'s keyword tokens produced. The `v0.t` mask suffix
similarly needed no new parsing: since `.` is a legal identifier-extra
character in this project's lexical profile (shared with `vadd.vv`'s own
mnemonic spelling and RISC-V's `sext.b`/`orc.b`/... instruction names),
`v0.t` lexes as one `Ident` token, `Reg.find "v0.t"` returns `None` (no
register named that), and it falls through to the existing generic
bare-identifier-to-`Operand.Sym` fallback - exactly the same path
`vsetvli`'s `e32`/`m1`/`ta`/`ma` keywords already take. The whole feature
is therefore: one new `Reg.t` constructor, one `vreg`/`is_v0t` helper
pair, and six new lowering match arms (masked/unmasked x three
mnemonics), no lexer/parser changes.

Normalization required one genuinely new addition: `Isa_norm_model`'s
`register_class` type gained a `Riscv_vec` case (alongside the existing
`Riscv_gpr`/`Riscv_fpr`/x86 cases), with a matching `vreg ()` constructor
in `Isa_norm_riscv` mirroring `gpr ()`/`fpr ()`. `vadd.vv`'s three
operands are modeled as three `Riscv_vec` registers; `vadd.vx` mixes one
`Riscv_gpr` (`rs1`) with two `Riscv_vec`; `vadd.vi` models the immediate
as a real signed 5-bit field (`simm5`, matching riscv-opcodes' own field
name) alongside two `Riscv_vec` registers. All three forms carry an
`Inferred` fact noting GAS's optional trailing `, v0.t` mask operand is
left to the encoder, unmodeled here - the same "GAS syntax nuance owned
by the encoder, not the normalized model" division of labor `vsetvli`'s
keyword-list fact already established. `Isa_norm_jsonl`'s
`register_class_to_json`/`_of_json` gained a matching `"riscv_vec"` case.

Implementation commit: (this change).

Source snapshots and input hashes: riscv-opcodes
`7afd3dc8772909d8c94ceeb208467cff93896396` (unchanged; reads the existing
checked-in export only).

Tool versions and exact commands: `cd asm && opam exec -- dune build
@all`; real-toolchain smoke tests via `riscv64-linux-gnu-as`/`objdump` for
all 7 positive combinations and all 5 negative controls above, cross-
checked against this project's own `asm.exe --dump-bytes`/exit-code
behavior for the same 12 cases; `make tools-test`; `make
tools-integration` (first run intentionally left `repo_tests.ml`'s pinned
counts stale to read off the real new numbers - `isa-norm-accounting`
235/287 -> 238/290, `isa-norm-jsonl` round-trip 540 -> 546 - then
predicted the `isa-family-admission` deltas by the same "straight from
blocked to promoted-support, one record per profile per mnemonic, no
`Req_any`" pattern established for `vsetvl` (promoted-support 215/257 ->
218/260, blocked 854/867 -> 851/864) and confirmed the prediction correct
on the very next run); `make tools-boundary`; `cd asm && opam exec --
dune build @runtest`; `make asm-fmt`/`asm-fmt-check` (ocamlformat
reformatted a couple of multi-line literals/match clauses; re-verified
clean); `PATH`-prefixed `make asm-isa-difficult-regen` (grew
`asm/fixtures/isa-difficult/cases.jsonl` from 300 to 306 entries;
confirmed via a Python diff script, ignoring only the git-rev-embedded
`gas.tool_label`/`ours.tool_label` fields, that all 300 pre-existing
cases are byte-for-byte unchanged and exactly the 6 expected new
`case_id`s - one per mnemonic per profile - were added, every one
`verdict = pass` on both `riscv32-linux-gnu-as`/`riscv64-linux-gnu-as`);
`make asm-isa-difficult-check`; `make asm-ci` (full CI target,
backgrounded, exit 0).

Results and artifact links: 3 new `isa-norm-riscv` unit tests
(`test_vadd_vv`, `test_vadd_vx`, `test_vadd_vi`, against real, verbatim-
extracted riscv64.jsonl records - identical in riscv32.jsonl, confirmed),
asserting the plain `Req_feature "riscv:v"` requirement, `rd, rs2, rs1`/
`rd, rs2, simm5` syntax rendering, and each operand's register class/
immediate width. One new domain check in `test_isa_gen_difficult.ml`
(`test_vadd_domain`) covering all 6 new corpus entries, asserting the
exact operand name/value lists and the `vector-register-operands` rule
tag (distinct from the configuration-setting group's
`vtype-keyword-list` tag). `Isa_family_admission`'s pinned totals moved:
RV32 promoted-support 215->218, blocked 854->851; RV64 promoted-support
257->260, blocked 867->864 - straight from blocked to promoted-support on
both profiles for all three mnemonics. `isa-norm-accounting`'s RV32/RV64
totals moved 235->238 and 287->290. `isa-norm-jsonl`'s real-form
round-trip count moved 540->546 (+6, three mnemonics x two profiles).
`tools-test`, `tools-integration`, `tools-boundary` all pass; `dune build
@runtest` passes; `make asm-ci` passes in full.

Unknowns, exceptions and follow-up task IDs: decode-side (word-to-text
disassembly) support was deliberately not added for any of the three
mnemonics, matching the precedent already set for `vsetvli`/`vsetivli`/
CSR - the generic `r_name`-keyed decode path assumes all three R-type
register fields are the same GPR-castable class and no mask/immediate
overlay, neither of which holds here; a `Lowered.pp` debug-printer case
was added for correctness (used by `test/snippets/snippet_ast.ml`'s dump
path) but the real `decode` function's `word -> instruction` direction
was not extended. This remains a real, not-yet-closed gap for a future
slice, same as the configuration-setting group's. The vector register
class (`Reg.V`, `Riscv_vec`) is now real infrastructure any future rv_v
slice can reuse directly. The remaining scope is still large: ~370
further `rv_v` records (other arithmetic/logic ops, vector loads/stores,
reductions, permutes, mask-register ops) and every `rv_zv*` vector-crypto
extension, most of which will additionally need a vector-length/mask
*operand* model (as opposed to the mask-suffix-as-fact treatment used
here), and vector loads/stores will need segment/strided/indexed
addressing this project's encoder does not have yet; GEN-06 still has no
single named next item.

Acceptance gate satisfied: `vadd.vv`/`vadd.vx`/`vadd.vi` all have real
encoder support verified byte-for-byte against real `riscv64-linux-gnu-as`
output across every tested masked/unmasked/boundary/rejection
combination, via a new vector register class reusing the *existing*
`Lowered.R`/`word_r` codec unchanged; a persisted, offline-replayed
differential corpus entry per mnemonic per profile with real GNU
agreement; admission-matrix promotion; and a full `make asm-ci` pass -
the same measured-Pass discipline every other GEN-05 promotion used, with
every affected pinned count in the repository's own regression suite
updated and re-verified rather than left stale.

### MOD — Behavior-preserving component extraction

Scope: x86/RISC-V family implementation organization and form descriptors.
Owner: unassigned. Stage: S5. Prerequisite: GAS/GEN evidence for extracted
forms — S3 supplies it for RISC-V M, since `mul` is in the pilot; x87 is not
in the pilot and waits on S4.

Investigate shared type/helper dependencies and x86 alternative ordering.
For RISC-V compare composable explicit dispatch with gradual per-form codecs;
the current two-alternative wrapper is not a full form registry.

- [ ] MOD-01 Record before/after public types, codec/form IDs, bytes,
  diagnostics and default behavior; select M and x87 extraction boundaries.
- [ ] MOD-02 Extract shared types/helpers and M/x87 component contributions
  within existing family libraries; compose deterministically.
- [ ] MOD-03 Add stable form descriptors/source mappings and combined
  overlap/priority checks without generating production bytes from ISA JSON.
- [ ] MOD-04 Run relevant six-profile regressions, purity and portability
  checks; report any deliberate public identity migration separately.

Exit: extraction changes organization while preserving the recorded behavior.
Feature selection is FEAT's separate acceptance gate.

### FEAT — Feature policy and public configuration

Scope: feature vocabulary, dependency/conflict rules, configuration APIs,
source-local state, encode/decode/layout enforcement and bindings.
Owner: unassigned. Stage: S6. Dependencies: MOD and reviewed GEN/NORM mappings.

Investigate compatibility defaults; native versus project versus GNU feature
names; configuration arguments versus configured encoder values; direct AST
bypasses; local directives; multi-unit state; strict versus inspection decode.

- [ ] FEAT-01 Record the API/state decision and default compatibility manifest;
  distinguish recognized, partial, enabled and complete support.
- [ ] FEAT-02 Implement validated feature sets and dependency/conflict rules,
  with explicit unknown-name/version errors and observable effective config.
- [ ] FEAT-03 Thread configuration through text, normalized/lowered AST,
  encode, pseudo expansion, relaxation, padding and decode paths.
- [ ] FEAT-04 Expose API/CLI and portable binding configuration; preserve old
  entry points as default wrappers and document local directive policy.
- [ ] FEAT-05 Prove enabled/disabled M and x87, a dependency case, scope
  push/pop, per-unit isolation and defaults; ensure disabled forms cannot
  be emitted by alternate assembly entry points or layout decisions.

Exit: configuration is enforced throughout the pipeline and public
interfaces, with stable unmet-feature diagnostics and regression evidence.

## Closure and evidence rules

- [ ] CLOSE-01 Reconcile all selected records and source/form/configuration
  relationships; every unknown/deferral has a task, reason and reopening gate.
- [ ] CLOSE-02 Run the pinned capture → normalization → generation → GNU →
  comparison workflow; verify deterministic artifacts and offline replay.
- [ ] CLOSE-03 Review all promoted support slices and regressions, tool gaps,
  unresolved two-source work and source-update procedures before a new-source
  scope decision. Do not close this by blanket-deferring difficult families.

For each completed task record:

```text
Task / status / owner:
Scope manifest and obligations:
Implementation commit:
Source snapshots and input hashes:
Tool versions and exact commands:
Results and artifact links:
Unknowns, exceptions and follow-up task IDs:
Acceptance gate satisfied:
```

Keep generated coverage separate from this hand-maintained status file.
Coverage rows should identify source record, normalized form, configuration,
recipe, obligation, intended/observed encoding, oracle outcome,
implementation expectation and comparison verdict. Report the full source
denominator as well as the promoted-support denominator. A drop in coverage
requires explanation; changing a denominator is a scope change.

If a work package needs more than a focused checklist and investigation,
move its brief into `.ai/isa-consumption/<package>.md` at activation time.
Link it here and retain a single authoritative status entry. Do not create
empty subplans for every extension; create a family task when its missing
rules, scope and acceptance obligations can be stated concretely.

## Investigation evidence log

| Date | Action | Result |
|---|---|---|
| 2026-09-05 | Read recent commits, producer/adapters/exports, OCaml inventory consumer, family encoders, pipeline and oracle scaffolding | Review recorded in plan sections 2–6 |
| 2026-09-05 | Count checked-in JSONL records, kinds, native names, x86 spaces and ISA_SET labels | Baseline in plan section 2.2 |
| 2026-09-05 | `python3 -m unittest discover -s isa-db/tests -t isa-db` | 47 passed, 20.509 seconds |
| 2026-09-05 | `make tools-isa-db-cross-validate` | 2,493 / 2,781 / 974 / 1,017 manifest rows matched |
| 2026-09-05 | Count 32-bit-labeled records with fixed compressed low bits; assemble `c.zext.b a0` using RV64 GAS 2.44 | 31 RV32 / 29 RV64 records affected; GAS emitted `61 9d`, two bytes |
| 2026-09-05 | Independent re-verification: recompute every export count, kind breakdown, distinct-name count, x86 space/ISA_SET breakdown, export byte size and family line count; re-run both S0 commands and the `c.zext.b` probe | All reproduced exactly (47 tests in 20.369 s; 2493 / 2781 / 974 / 1017 rows); no figure corrected |
| 2026-09-05 | Break the 31/29 width counts down per extension file; check for the reverse 32-labelled-as-16 direction | Every record in every affected file is affected, so the counts are exact rather than lower bounds; no reverse mislabel today, but width is file-scoped and `$import` inherits it — recorded in CAP-01 |
| 2026-09-05 | Diff coarse against resolved XED native names in both profiles | Delta is entirely coarse-only: `nop2`–`nop9` in x86-64, plus `jrcxz` in x86-32; resolved introduces no name |
| 2026-09-05 | Inspect the `jrcxz` coarse record, the coarse reader's `_MODE_TOKENS`, and `asm/fixtures/isa-inventory/x86_32/manifest.txt` | `PATTERN … eamode64 … FORCE64()` and ISA_SET `LONGMODE` yield vacuously true applicability; 1 of 191 64-bit-flavoured coarse x86-32 records leaks; the wrong row is already checked in; opened CAP-06 |
| 2026-09-05 | Close the RISC-V gap in the existing GAS frontier runtime group (`fbe16a5`, `0db61e0`) | Closed: `gas_xref_cmd.ml` maps both RISC-V profiles to `runtime/riscV`; one `runtime-vararg` case landed per profile (2 → 3, aarch64 parity). Corpus 473 → 483 files, manifest 474 → 484 lines, frontier 51 → 53 cases. Surfaced a real frontier gap: `and` with an immediate is unimplemented, so both cases sit in "beyond M1" (22 → 24, 0 differ). Documented in `asm/docs/corpus.md` Follow-ups |
| 2026-09-05 | Validate that migration independently: `make tools-gasxref-diff`, `asm-test`, `tools-test`, `tools-integration`, `tools-boundary`, `asm-purity` | All pass. Regen reproduced the committed corpus byte-identically (54 generated, 53 frontier cases) and left the tree clean; `gas-xref check` matches 482 files. Two steps the migration needed beyond the plan: refreshing the `gas-xref-check` characterization snapshot (`0db61e0`), and declaring jsont/bytesrw in the tool-dependency purity audit (`4b65ead`) — the latter pre-existing Phase D debt that `asm-purity` surfaced, not caused by this change |
| 2026-09-05 | Close the `runtime-vararg` frontier gap (`1fc873f`) | It was three gaps, not one, and all had to land together: R-type-with-immediate I-type aliases (`imm_alias`), FP ABI register names (`Reg.f_aliases`), and RISC-V-only section-end padding to the section alignment. The third is target-specific — rounding every section up regardless of target was tried and broke 12 agreeing cases — so it entered as `ENCODE.pad_section_to_alignment`, mirroring `merge_fill`'s one-target-diverges shape. Both cases now agree byte-for-byte: `31 agree, 0 differ, 22 beyond M1`. Measurements in `asm/docs/corpus.md` Follow-ups |
| 2026-09-05 | Validate that closure independently: `asm-test`, `tools-gasxref-diff`, `asm-purity`, `asm-js-portable`, `tools-test`, `tools-integration` | All pass. Corpus unchanged and still reproducing byte-identically (54 generated, 53 frontier cases), so the change is on our side of the comparison only |
| 2026-09-05 | Probe the installed RV32 assembler and compare Zcb acceptance across the version skew | 2.43.1 in `/usr/local/riscv32-linux-gnu-toolchain/bin`, which `.devcontainer/Dockerfile:6` puts on `PATH`; `Target.toolprefix` supplies the binary-name prefix, not the location, so a shell without that `PATH` entry fails the RISC-V legs outright. RV64 and host are 2.44; both accept `c.zext.b`, so the skew must be probed per extension, not assumed |
| 2026-09-05 | Implement and validate NORM-01 (`Isa_source_record`, `Isa_norm_model`, `Isa_norm_riscv`, `Isa_norm_xed`); fetch the seven pilot records verbatim from the checked-in exports to ground the design and tests | 19 `isa-norm-riscv` + 13 `isa-norm-xed` checks pass against real captured data; `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check` all pass; see the NORM-01 milestone writeup above |
| 2026-09-05 | While validating NORM-01, ran `make asm-fmt-check` and found three pre-existing files (`isa_db_cross_validate.ml`, `isa_inventory_xed.ml`, `test_isa_inventory_xed.ml`) already failed it, unrelated to this change - confirmed by reverting the NORM-01 files and re-running `asm-fmt-check` on an otherwise-untouched tree | Pre-existing formatting drift, not caused by NORM-01; reformatted as a separate preceding commit so `asm-fmt-check` is green again without mixing an unrelated fix into the NORM-01 commit |
| 2026-09-05 | Grepped the checked-in riscv32/riscv64 exports to confirm `add`/`addi`/`sub`/`mul`'s field shapes (`variable_fields`) and extensions match exactly across the intended R-type/I-type mnemonic lists before writing a dispatch on them | Every one of 29 (riscv32) / 34 (riscv64) mnemonics is exactly `[rd,rs1,rs2]` or `[rd,rs1,imm12]`; extensions used are exactly `rv_i`, `rv_m`, `rv64_i`, `rv64_m` |
| 2026-09-05 | Grepped the checked-in x86_32/x86_64 xed_resolved exports for `MOV`/`ADD` iforms, then the vendored XED datafiles, to find genuine register/register and register/immediate legacy forms for the GEN-01 x86 pilot | `ADD_GPRv_GPRv_01`/`_03` and `MOV_GPRv_GPRv_89`/`_8B` are the two decodable directions of reg,reg add/mov; `MOV_GPRv_IMMz` mirrors the already-normalized `ADD_GPRv_IMMz`. Discovered `encoding.operands` (REG0/REG1/IMM0 with `rw`/`lookupfn_name`/`oc2`) is present in the checked-in export but was not decoded by `Isa_source_record` - the existing `ADD_GPRv_IMMz` comment's operand facts were externally verified, not record-derived; extended the decoder to close that gap |
| 2026-09-05 | Implement and validate NORM-02 (RISC-V R-type/I-type generic helpers, XED `two_operand_gprv_form`, `Isa_norm_accounting`, a pinned `repo_tests.ml` regression, and the `isa-inventory norm-accounting` CLI subcommand) | 30 `isa-norm-riscv` + 24 `isa-norm-xed` unit checks pass; accounting reports 29/1089, 40/1154, 7/7887, 7/10571 normalized-vs-diagnosed across the four exports with zero unaccounted records; `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity` all pass; see the NORM-02 milestone writeup above |
| 2026-09-05 | Read isa-db/schema's `applicability`/`relationships` definitions and grepped real x86_64/riscv32 exports for non-trivial values before designing NORM-03's types | `applicability` really is a three-valued `all`/`any`/`mode(equals\|not_equals)` tree (7464 unconditional / 3107 mode64-gated in x86_64); riscv-opcodes' `provenance."relationship-resolution"` carries exact (265)/missing (23)/ambiguous (5) outcomes with a `candidates` list; XED never populates it |
| 2026-09-05 | While wiring `applicability` into `Isa_norm_xed.requirement_of`, found `xed_provenance.mode_restriction : string option` silently decoded to `None` for 113 real x86_64 BASE+mode64 records (the JSON field is a string *or* an integer XED mode id), so those records fell through to a misleading `Req_unknown "unmapped XED extension: BASE"` | Real latent bug, not just a modeling gap; fixed by driving the requirement from `applicability` (correctly typed regardless of the raw fact's JSON shape) instead of re-deriving it from `mode_restriction`; covered by a new synthetic regression test since none of the seven already-normalized pilot iforms happen to be mode64-gated |
| 2026-09-05 | Implement and validate NORM-03 (`Req_mode`/`Req_xlen` in `Isa_norm_model`, `applicability`/`relationship-resolution` decode in `Isa_source_record`, `rv64_i`/`rv64_m` now `Req_xlen`/`Req_all` instead of `Req_unknown`) | 33 `isa-norm-riscv` + 25 `isa-norm-xed` unit checks pass, including three relationship-decode checks (exact/ambiguous/missing) against verbatim riscv32.jsonl records and one mode64-requirement regression; NORM-02's accounting counts unchanged byte-for-byte (29/1089, 40/1154, 7/7887, 7/10571); `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity` all pass; see the NORM-03 milestone writeup above |

| 2026-09-05 | Read jsont's `Object`/`Case`/`Json` module signatures and the existing `Isa_source_record`/`Isa_db_jsonl` codecs to choose a design for NORM-04's normalized-form codec | Chose hand-written `to_json`/`of_json` over `Jsont.json` (matching `Isa_source_record`'s existing generic-JSON style) over `Object.case_mem`, because `requirement` and `syntax_token` are self-recursive sum types and the codebase had no prior JSON-encoding (write-direction) code to follow either way |
| 2026-09-05 | Implement and validate NORM-04 (`Isa_norm_jsonl`, a constructor-complete synthetic round-trip suite, and a real-data round-trip regression in `repo_tests.ml`) | 8 new `isa-norm-jsonl` unit checks pass; all 83 real forms NORM-02/NORM-03 normalize from the four checked-in exports round-trip through `encode_line`/`decode_line` unchanged (pinned count matches NORM-02/03's 29+40+7+7); `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity` all pass; see the NORM-04 milestone writeup above |

| 2026-09-05 | Implement and validate NORM-05 (`Isa_source_snapshot_diff`: `diff`/`load`/`diff_files`/`report_lines`, with SHA-256 fingerprints per plan §3.5) and recheck offline boundaries after adding it | 16 new `isa-source-snapshot-diff` unit checks pass (synthetic added/removed/unchanged/changed plus duplicate-id and bad-line rejection); `repo_tests.ml` self-diffs all four real checked-in exports with zero drift and every id (1089/1154/7887/10571) unchanged; `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity` all pass unchanged otherwise - closing S2, see the NORM-05 milestone writeup above |

| 2026-09-05 | Read `Gnu_tools.mli` (existing GAS-invocation/version-probing surface) and the root Makefile's `asm-fixtures-check`/`asm-gas-xref-check`/`asm-test`/`asm-ci` rules before designing GAS-01's schema and frozen names | `Gnu_tools` already exposes everything GAS-02 will need (`try_assemble`'s `gas_outcome`, `version_line`, relocation/disasm readers) - GAS-01's `artifact` type is deliberately generic enough to hold either side's run without duplicating that surface; the `asm-<thing>-check`/`-regen` naming convention and `asm-test`'s exact prerequisite list are what `make_target`/`joins_prerequisite_of` pin |
| 2026-09-05 | Implement and validate GAS-01 (`Isa_generated_case`: case/artifact/verdict schema, frozen tier/CLI/Make names) | 18 new `isa-generated-case` unit checks pass, pinning every frozen string and covering all eight verdict rows with a representative observation; `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity` all pass unchanged otherwise; see the GAS-01 milestone writeup above |

| 2026-09-05 | Ran `dune exec tool/asm.exe -- --target x86_64 --dump-codec /tmp/empty.s` and hand-read `riscv_family_encode.ml`'s R-type/I-type opcode tables and `x86_family_encode.ml`'s `alu_rm_r_codec`/`alu_r_rm_codec`/`Add -> 0` extension assignment, to ground GEN-01's per-family enumeration method | x86 `--dump-codec` gives 104 lines, one labelled alternative per form, confirming plan §2.5's claim directly; RISC-V's `Add -> Some (0x33, 0, 0x00)`/`Sub -> Some (0x33, 0, 0x20)`/`Mul -> Some (0x33, 0, 0x01)`/`Addi -> Some (0x13, 0, 0, None)` match isa-db's own mask/value exactly, confirming the hand-read table is a real, table-driven, one-per-mnemonic encoder rather than a wrapper placeholder |
| 2026-09-05 | Implement and validate GEN-01 (`Isa_gen_pilot`: the frozen 9-entry RISC-V + 12-entry x86 pilot manifest, mandatory-obligation responsibility map, and a `repo_tests.ml` grounding check normalizing every entry's real record) | 13 new `isa-gen-pilot` unit checks and 21 new `repo_tests.ml` grounding checks pass (every pilot entry's real record normalizes to exactly the manifest's declared `form_id`, including `addw` on riscv64 only); `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity` all pass unchanged otherwise; see the GEN-01 milestone writeup above |

| 2026-09-05 | Empirically probed real GNU `as` (RV32 2.43.1, RV64/x86 2.44) with hand-written `.s` snippets for every GEN-01 x86 pilot form, to ground GAS-02's canonical operand choice and observed-form check before trusting either | `add %reg,%reg` always assembles to opcode 0x01 (never 0x03) regardless of operand order; `mov %reg,%reg` always to 0x89 (never 0x8B); `mov $imm,%reg` always to 0xB8+reg (never 0xC7) - all three confirmed reachable ONLY with a memory operand instead (`add (%rdx),%ecx` -> 0x03; `mov (%rdx),%ecx` -> 0x8B; `movl $imm,(%rdx)` -> 0xC7); `add $imm,%eax` uses the accumulator-special opcode 0x05 rather than the general 0x81, confirming EAX/RAX must be avoided in the pilot's canonical case |
| 2026-09-05 | Implement and validate GAS-02 (`Gnu_tools.try_assemble_with_args`, `Isa_gen_render`, `Isa_gen_case_build`, `Isa_gen_oracle`, `Isa_generated_cmd`, wired as `isa-generated regen`/`make asm-isa-generated-regen` per GAS-01's frozen names) | 56 new toolchain-free unit checks pass; a real run against the cross binutils assembles and byte-checks all 21 pilot cases, reproducing the probed findings above as three explained `DIFFERENT-FORM` results (`ADD_GPRv_GPRv_03`, `MOV_GPRv_GPRv_8B`, `MOV_GPRv_IMMz`) and 18 exact matches; `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity` all pass unchanged otherwise; see the GAS-02 milestone writeup above |

| 2026-09-05 | Implement and validate GAS-03 (`Isa_generated_corpus`'s JSONL codec/`replay`, `Gnu_tools.try_assemble_with_args` extended to return the raw `Tool_process.result`, `Isa_gen_oracle.run` now also returning a real `Isa_generated_case.artifact`, `Isa_generated_cmd.regen` persisting `asm/fixtures/isa-generated/cases.jsonl`, and `Check_cmd.isa_generated_check` wired as `isa-generated check`/`make asm-isa-generated-check`, now an `asm-test` prerequisite) | 28 new `isa-generated-corpus` unit checks pass; a real `asm-isa-generated-regen` run committed the 21-entry corpus, reproducing GAS-02's own measured 18-PASS/3-DIFFERENT-FORM/0-reject split exactly; `make asm-isa-generated-check` and `make asm-test` both pass with every cross-toolchain directory stripped from `PATH`, proving the tier-1 gate is genuinely toolchain-free; four manual controls (tampered byte, deleted record, injected stale record, deleted corpus file) were each caught with a specific diagnostic and the corpus was restored and reverified clean afterward; `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity`, `tools-gasxref-diff`, `tools-isa-inventory-diff`, `asm-js-portable` all pass unchanged otherwise; see the GAS-03 milestone writeup above |

| 2026-09-05 | Probed `tool/asm.exe` by hand against every GEN-01 pilot's rendered source (`--target <t> --fixed-base 0x0 --dump-bytes`), before writing `Isa_gen_ours`/`Isa_gen_verdict`, to ground the "ours" comparison and relocation guard on real behavior rather than assumption | All 9 RISC-V + 4 x86 register/register `add` cases assemble and byte-match GAS exactly; the other 8 x86 cases reject with `Missing_size_suffix` (`mov`/any immediate form needs an explicit AT&T suffix our parser does not infer, unlike GAS); confirmed via `x86_64-linux-gnu-as` that the suffixed and unsuffixed spellings assemble to IDENTICAL bytes, proving this is a parse-only gap, not a missing encoder alternative; confirmed via a real `call foo` snippet that `objdump -r` reports a genuine `R_RISCV_CALL_PLT` relocation, grounding the relocation-guard's detection logic in real GNU output |
| 2026-09-05 | Implement and validate GAS-04 (`Isa_gen_ours`, `Isa_gen_verdict`, `tool/asm.exe --dump-bytes`, the `.text`-relocation guard in `Isa_gen_oracle.run`, `Isa_generated_corpus` schema v2 with `ours`/`verdict`, and the `asm-build` prerequisite on `asm-isa-generated-regen`) | 41 new toolchain-free unit checks pass; a real `asm-isa-generated-regen` run against all 21 pilot cases reproduced 13 Pass / 8 Frontier_gap / 0 Regression / 0 Byte_mismatch / 0 Unexpected_relocation, byte-identical across two runs; `make asm-isa-generated-check`/`make asm-test` both pass with every cross-toolchain directory stripped from `PATH`; three manual mutation controls against the real committed corpus (wrong "ours" byte, mislabeled verdict, drifted `gas.argv`) were each caught with a specific diagnostic and the corpus was restored and reverified clean afterward; `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity`, `asm-js-portable`, `tools-gasxref-diff`, `tools-isa-inventory-diff` all pass unchanged otherwise; see the GAS-04 milestone writeup above |
| 2026-09-06 | Probed real GNU `as` by hand for `.option rvc; sw a0, 0(a1)` versus the same line bracketed in `.option norvc`, and for a mixed `c.addi`/`sw`/`add`/`c.addi` sequence on both RV32 2.43.1 and RV64 2.44, before designing GEN-03's difficult corpus and padding regression | Leaving RVC enabled around a plain `sw`/`add` line makes GAS silently substitute the 2-byte compressed form (`c.sw` -> `88 c1`) - a real, separate, unimplemented form here, confirming `.option norvc` bracketing is required for a fair comparison; the mixed sequence assembles identically on both tools/profiles (`05 05 23 a0 a5 00 33 06 b5 00 7d 15`) with no inserted padding, confirming RISC-V's two-byte (not four-byte) instruction alignment requirement needs no new layout code |
| 2026-09-06 | Implement and validate GEN-03's remaining scope (`Isa_gen_difficult`, `Isa_gen_drive` extracted from `isa_generated_cmd.ml`, `Isa_difficult_cmd`, `Check_cmd.isa_difficult_check`, the new `asm/fixtures/isa-difficult/` corpus, `Isa_family_admission` promotion, and the mixed-stream regression in `test_targets.ml`) | 111 new `isa-gen-difficult` unit checks and 20 new `repo_tests.ml` grounding checks pass; a real `asm-isa-difficult-regen` run produced 20 cases (8 sw + 4 beq + 8 c.addi) all `verdict = Pass`, reproduced byte-identically across two runs; `asm-isa-difficult-check`/`asm-test` pass with every cross-toolchain directory stripped from `PATH`; `Isa_family_admission`'s pinned RV32/RV64 normalized-only/promoted-support totals moved exactly as expected (25->22/4->7, 35->32/5->8); re-running `asm-isa-generated-regen` confirmed the `Isa_gen_drive` extraction is behavior-preserving against GEN-01's frozen pilot (only the git-rev-embedded `ours` tool_label differed, so that corpus was left uncommitted via `git checkout --`); `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all pass unchanged otherwise; see the GEN-03 milestone writeup above |

| 2026-09-06 | Hand-verified `sh2add`/`sh3add`'s riscv-opcodes mask/value against expected little-endian bytes for `a0,a1,a2` before writing any encoder table entry, then confirmed both this project's `--dump-bytes` output and real GNU `as` (RV32 2.43.1, RV64 2.44) agree, before implementing GEN-05's Zba scale-family continuation | Expected `33 c5 c5 20`/`33 e5 c5 20` matched exactly on all three (isa-db mask/value, this assembler, real GNU `as`) on both profiles |
| 2026-09-06 | Implement and validate GEN-05's Zba `sh2add`/`sh3add` sub-slice (`riscv_family_encode.ml`'s R-type table entries, `Isa_norm_riscv.r_type_mnemonics`, `Isa_gen_difficult`'s generalized `zba_shadd_entry`, `Isa_family_admission` promotion, matching `test_targets.ml`/`isa-norm-riscv`/`isa-gen-difficult` tests, and `repo_tests.ml`'s three pinned-count updates) | 266 `isa-gen-difficult` checks and all `isa-norm-riscv`/`test_targets.ml` checks pass; a real `asm-isa-difficult-regen` run against the new 24-entry corpus reproduced all 24 cases `Pass` (4 new + 20 unchanged), byte-identical across two runs; `asm-isa-difficult-check`/`asm-test` both pass with every cross-toolchain directory stripped from `PATH`; `Isa_family_admission`'s pinned RV32/RV64 promoted-support/blocked totals moved exactly as expected (16->18/1053->1051, 17->19/1107->1105); `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all pass; see the GEN-05 continuation milestone above |

| 2026-09-06 | Grepped every `rv_zbb`/`rv_zbkb`/`rv_zk`/`rv_zkn`/`rv_zks`/`rv64_zbb`-family record in both checked-in riscv-opcodes profiles before choosing GEN-05's next Zbb sub-slice | `andn`/`orn`/`xnor` are each listed identically under five different extension files (same mask/value, different `provenance.extension`) - a real OR-requirement-across-extensions case `Isa_norm_riscv.requirement_of` cannot express yet (single-extension read); `min`/`minu`/`max`/`maxu` have exactly one record each, single-extension (`rv_zbb`), so chosen instead as the clean next slice and `andn`/`orn`/`xnor` recorded as a named blocker needing `Req_any` |
| 2026-09-06 | Hand-verified `min`/`minu`/`max`/`maxu`'s riscv-opcodes mask/value against expected little-endian bytes for `a0,a1,a2` before writing any encoder table entry, then confirmed both this project's `--dump-bytes` output and real GNU `as` (RV32 2.43.1, RV64 2.44) agree | Expected `33 c5 c5 0a`/`33 d5 c5 0a`/`33 e5 c5 0a`/`33 f5 c5 0a` matched exactly on all three (isa-db mask/value, this assembler, real GNU `as`) on both profiles |
| 2026-09-06 | Implement and validate GEN-05's Zbb `min`/`minu`/`max`/`maxu` sub-slice (`riscv_family_encode.ml`'s R-type table entries, `Isa_norm_riscv`'s `rv_zbb` feature mapping and mnemonic list, `Isa_gen_difficult`'s `zbb_r_type_entry` generator, `Isa_family_admission` promotion, a generalized `test_r_type_gpr` helper covering all seven R-type mnemonics, and `repo_tests.ml`'s three pinned-count updates) | 307 `isa-gen-difficult` checks (up from 266) and all `isa-norm-riscv`/`test_targets.ml` checks pass; a real `asm-isa-difficult-regen` run against the new 32-entry corpus reproduced all 32 cases `Pass` (8 new + 24 unchanged), byte-identical across two runs; `asm-isa-difficult-check`/`asm-test` both pass with every cross-toolchain directory stripped from `PATH`; `Isa_family_admission`'s pinned RV32/RV64 promoted-support/blocked totals moved exactly as expected (18->22/1051->1047, 19->23/1105->1101); `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all pass; see the GEN-05 Zbb continuation milestone above |

| 2026-09-06 | Grepped `sh1add.uw`/`sh2add.uw`/`sh3add.uw` in both checked-in riscv-opcodes profiles before choosing GEN-05's next Zba sub-slice, and hand-verified their riscv64.jsonl mask/value against expected little-endian bytes for `a0,a1,a2`, then confirmed both this project's `--dump-bytes` output and real GNU `as` 2.44 agree | Zero matches in `riscv32.jsonl`, one match each (single-extension `rv64_zba`) in `riscv64.jsonl` - no import-duplication blocker, unlike `andn`/`orn`/`xnor`/`rol`/`ror` (the last two confirmed to share the identical five-extension shape while surveying candidates), so chosen as the next clean slice; expected `3b a5 c5 20`/`3b c5 c5 20`/`3b e5 c5 20` matched exactly on all three (isa-db mask/value, this assembler, real GNU `as`) |
| 2026-09-06 | Implement and validate GEN-05's Zba `sh1add.uw`/`sh2add.uw`/`sh3add.uw` sub-slice (`riscv_family_encode.ml`'s opcode-0x3b R-type table entries and RV64-only guard, `Isa_norm_riscv`'s `rv64_zba` feature mapping and mnemonic list plus a new `test_r_type_gpr_rv64` unit-test helper, `Isa_gen_difficult`'s RV64-only `zba_shadd_entry` reuse, `Isa_family_admission` promotion guarded to `Target.Riscv64`, and `repo_tests.ml`'s pinned-count updates) | 317 `isa-gen-difficult` checks (up from 307) and all `isa-norm-riscv`/`test_targets.ml` checks pass, including matched RV64-only rejection on both real GNU `as` and this project's own assembler; a real `asm-isa-difficult-regen` run against the new 35-entry corpus reproduced all 35 cases `Pass` (3 new + 32 unchanged, confirmed record-by-record byte-identical ignoring only the git-rev `ours.tool_label`) across two runs; `asm-isa-difficult-check`/`asm-test` both pass with every cross-toolchain directory stripped from `PATH`; `Isa_family_admission`'s pinned RV64 promoted-support/blocked totals moved exactly as expected (22->26/1101->1098, RV32 unaffected at 22/1047); `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity`, `asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff` all pass; see the GEN-05 Zba `*.uw` continuation milestone above |

| 2026-09-06 | Re-confirmed `andn`/`orn`/`xnor`/`rol`/`ror` are exported identically under five extension files each in both checked-in riscv-opcodes profiles (same mask/value, `provenance.extension` in `{rv_zbb, rv_zbkb, rv_zk, rv_zkn, rv_zks}`), and inspected the four import records' own JSON before designing `Req_any` | The primary `rv_zbb` record has `kind: "instruction-form"` and empty `relationships`; each of the other four is `kind: "import"` with `relationships: [{kind: "imports", target: "riscv-opcodes:rv_zbb:<name>@L.."}]` and a matching `relationship-resolution` `status: "exact"` - real structural data distinguishing primary from alias, but only pairwise (importer -> one target), not a full five-way set any single record can read off itself; `Req_any` needs a small hand-verified table, not a cross-record join |
| 2026-09-06 | Hand-computed expected little-endian bytes for `andn`/`orn`/`xnor`/`rol`/`ror a0, a1, a2` from the riscv-opcodes mask/value, matched this project's own `--dump-bytes` output, then confirmed against real GNU `as` (RV32 2.43.1, RV64 2.44) with `-march=rv{32,64}im_zbb -mabi={ilp32,lp64} -mno-relax` | Expected `33 f5 c5 40`/`33 e5 c5 40`/`33 c5 c5 40`/`33 95 c5 60`/`33 d5 c5 60` matched exactly on all three (isa-db mask/value, this assembler, real GNU `as`) on both profiles |
| 2026-09-06 | Implement and validate GEN-05's Zbb `andn`/`orn`/`xnor`/`rol`/`ror` sub-slice (`Isa_norm_riscv`'s `alternative_extensions_by_mnemonic`/`requirement_of_any`/`requirement_of_mnemonic`, the four new `feature_of_extension` entries, `riscv_family_encode.ml`'s five new R-type table entries, `Isa_gen_difficult`'s five new entry lists, `Isa_family_admission` promotion, new `isa-norm-riscv`/`isa-gen-difficult` tests, and `repo_tests.ml`'s pinned-count updates) | 94 `isa-norm-riscv` checks (up from 77, including a check that the `rv_zbkb` import record and the `rv_zbb` primary record normalize to the identical `Req_any`) and 368 `isa-gen-difficult` checks (up from 317: 21 added by hand, 30 from the pre-existing `test_no_entry_uses_x0` automatically covering the new entries) all pass; a real `asm-isa-difficult-regen` run against the new 69-entry corpus (was 59) reproduced all 69 cases `Pass` (10 new + 59 unchanged, confirmed record-by-record byte-identical ignoring only the git-rev `ours.tool_label`) across two runs; `asm-isa-difficult-check`/`asm-test` both pass with every cross-toolchain directory stripped from `PATH`; `Isa_family_admission`'s pinned RV32/RV64 promoted-support/blocked totals moved exactly as expected (22->47/1047->1022, 26->51/1098->1073 - each mnemonic's `Req_any` promotes all five underlying extension-membership records, not one, so this slice moves 25 records per profile); `isa-norm-accounting`'s paired totals moved 42->67/56->81 and the `isa-norm-jsonl` real-form round-trip count moved 116->166, all pinned `repo_tests.ml` expectations updated and re-verified passing; `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check`, `asm-purity`, `asm-planted`, `asm-js-portable`, `tools-isa-inventory-diff`, `tools-gasxref-diff`, and the full `asm-ci` target all pass; see the GEN-05 `Req_any` continuation milestone above |

No implementation task above is complete merely because S0's existing tests
passed. The compressed-width finding is deliberately still an open CAP-01
implementation item, and the XED mode leak an open CAP-06 one. (Both are
closed now - see the CAP-01/CAP-06 milestone above; this note predates that
closure and is kept as a reminder that a stage's own gate must be checked
before crediting it, not because CAP-01/CAP-06 are still open.)
