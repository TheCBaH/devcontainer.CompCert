# ISA consumption work tracker — phase 2

Plan: [isa-consumption-plan.md](isa-consumption-plan.md). This file is the
status authority. Phase 1 (S0–S7) is done; its full milestone and evidence log
is in git history: `git show f4b93e4:.ai/isa-consumption-tracker.md`.

The machine-checked authority for *what* is unadmitted is the residual ledger
(`asm/tools/lib/isa_residual_ledger.ml`, `make tools-isa-residual-ledger`) and
the family-admission report (`compcert_tools.exe isa-inventory
family-admission`). This tracker orders and records the work; it never
restates live counts except as dated before/after evidence.

States: `not-started`, `investigating`, `ready`, `implementing`,
`validating`, `done`, `blocked` (name the dependency and next action). `done`
requires the acceptance evidence in plan section 8.

## Baseline (2026-09-25, `f4b93e4`)

| Profile | Records | Promoted | Blocked |
|---|---:|---:|---:|
| RV32 | 1,089 | 734 | 335 |
| RV64 | 1,154 | 783 | 341 |
| x86-32 | 7,887 | 1,022 | 6,854 |
| x86-64 | 10,571 | 1,030 | 9,536 |

Phase-2 goal: blocked → only `oracle-unavailable` residue on RISC-V, and the
x86 ledger worked down in the plan section 6 order.

## Status

| ID | Work package | State | Depends on | Next action |
|---|---|---|---|---|
| INF-01 | Promotion credit from committed passing cases | done | — | — |
| INF-02 | Operand-vocabulary normalization, construct-keyed blockers | done | — | Generic operand-driven normalization moves into INF-05R/INF-05X |
| INF-03 | Generated difficult-corpus entries from normalized forms | not-started | INF-02 | — |
| INF-04 | Batched, sharded, incremental GAS regeneration | done | — | — |
| INF-05R | RISC-V form-table encoder (DEC-RV-TABLE) | investigating | INF-02 | Write the decision record |
| INF-05X | x86 form-row encoder (DEC-X86-TABLE) | investigating | INF-02 | Write the decision record |
| INF-06 | Feature on every table row; retrofit admitted forms | not-started | INF-05* | — |
| DEC-X86-MODE16 | 16-bit-only forms in the `x86_32` export | not-started | — | Count them; decide `.code16` vs out of scope. Also covers REX.W/GPR64 records the `x86_32` export carries (e.g. `CVTSI2SD_XMMsd_GPR64q`), which 32-bit mode cannot encode |
| DEC-X86-SUFFIX | Size-suffix inference for x86 mnemonics | needs owner decision | — | GAS infers the operand size from a register operand (`add $1000000, %ecx`); ours rejects unsuffixed mnemonics by design (`test_targets.ml` "x86 refuses to guess an operand size"). Blocks the pilot's ADD_GPRv_IMMz / MOV_GPRv_GPRv_89 / MOV_GPRv_IMMz (x86-64) credit |
| FREE-01 | Cases for normalized-only / GAS-generatable records | done (RISC-V); x86 blocked | DEC-X86-SUFFIX, DEC-X86-MODE16 | x86 residue needs the two decisions below |
| FREE-02 | Credit x86 forms already encoded for CompCert | ready | INF-02 helps | Enumerate encoder `Opcode`s without a normalized form |
| GEN-05-RV-BASE | RISC-V base-integer remainder | done except `fence` | — | `fence` needs a flag-set operand domain in `Isa_norm_model` |
| GEN-05-RV-ZBA | `add.uw`, `slli.uw`, `zext.w` | ready | — | — |
| GEN-05-RV-FP | fcsr pseudos, `fmv.x.d`/`fmv.d.x`, Zfh/Zfhmin, Q, Zfa, Zfbfmin | ready | INF-05R helps | fcsr pseudos and `fmv.*.d` first |
| GEN-05-RV-MISC | Zimop, Zicbo, Zicfiss/Zicfilp, Zihintntl, Zifencei, Zicntr; Zilsd | not-started | INF-05R | — |
| GEN-05-RV-ATOMIC | Zabha, Zacas, Zawrs; Zalasr | not-started | — | — |
| GEN-05-RV-PRIV | H, S, system, Svinval, Sdext, Ssctr; Smrnmi | not-started | INF-05R | Revise ledger gate (section "Ledger corrections") |
| GEN-05-RV-C | Compressed remainder and Zc* sub-extensions | implementing | — | `c.li`/`c.lui`/`c.addi16sp`/`c.addi4spn`/`c.andi`/shifts/`c.addiw`/`c.nop`/`c.j` |
| GEN-05-X86-INT | Legacy integer, string, BMI/LZCNT/POPCNT/ADX/MOVBE, CMOV | not-started | INF-05X, FREE-02 | — |
| GEN-05-X86-X87 | Full x87 | not-started | FREE-02 | — |
| GEN-05-X86-SIMD | MMX, SSE*/SSE4.2/SSE4a remainders, AES/PCLMUL/SHA/GFNI, 3DNow | not-started | INF-05X | — |
| GEN-05-X86-VEX | AVX/AVX2 remainder, VSIB, FMA, F16C, FMA4/XOP, VNNI etc. | not-started | INF-05X | — |
| GEN-05-X86-EVEX | EVEX machinery, then AVX-512/FP16/BF16/AVX10.2 families | not-started | GEN-05-X86-VEX | — |
| GEN-05-X86-APX | REX2, r16–r31, map-4, NDD, NF, CCMP/CTEST | not-started | GEN-05-X86-INT, EVEX machinery | — |
| GEN-05-X86-AMX | Tile registers and AMX families | not-started | GEN-05-X86-EVEX | — |
| GEN-05-X86-SYSTEM | 58 small system/vendor families | not-started | INF-05X | — |

## Work package briefs

### INF-01 — credit from evidence

- [x] Build the promoted set from `asm/fixtures/isa-generated/` and
  `asm/fixtures/isa-difficult/` records with a `Pass` verdict, excluding
  negatives, keyed by `(target, form_id, lookup_key)`.
- [x] Derive `Gas_generatable` from the same corpora (non-passing positive
  cases) instead of re-listing `Isa_gen_pilot`/`Isa_gen_difficult` entries.
- [x] Delete `promoted_case_part1`–`part7`.
- [x] Gate: `family-admission` and `residual-ledger` output byte-identical to
  the baseline; `make tools-integration` passes locally (the ARM 4.14 leg
  is covered by CI; the large literal match that broke it is gone).

Finding: a bare `Pass` over-credits one pilot record, `ADD_GPRv_GPRv_03`
(GAS assembles its canonical spelling as the `01` form). Pilot cases
therefore credit only with a `Matches_normalized_encoding` finding;
difficult-corpus `Different_observed_form` findings are artifacts of the
leading-byte check (mandatory prefixes, branch plus filler) and a
byte-identical `Pass` credits there. The module shrank from 1,966 to ~200
lines. Adding credit for a new form now needs only its committed case.

### INF-02 — operand vocabulary and construct-keyed blockers

- [x] Inventory the distinct XED operand facts in the resolved exports
  (register lookup names, memory widths, immediate kinds, visibility, `BCRC`,
  VSIB, tuple type, EVEX/VEX/XOP/REX2 space markers) with record counts.
  x86-64: 31,496 operands over 90 lookup functions (`MASK1` 3,863, `XMM_R3`
  1,568, ...), 76 `oc2` widths, visibility DEFAULT 29,452 / SUPPRESSED 1,436
  / IMPLICIT 600; spaces evex 6,775, legacy 1,956, vex 1,664, xop 176.
- [x] Map each to a construct (`Isa_construct`): register class by lookup
  prefix, `mem:<oc2>`, `imm:<oc2>`, visible implicit registers, and encoding
  constructs (space/map, VL, W1, opmask, zeroing, broadcast/rounding/SAE,
  VSIB, is4, REX2, APX EVEX/NDD/NF/SCC, branch displacement, lock).
  SUPPRESSED operands are side effects and need no syntax.
- [x] "Known" is measured, not listed: the union of constructs of records
  that normalize today. A record with no normalizer rule is blocked by its
  first unknown construct, or `no-rule:known-constructs`.
- [x] RISC-V: one construct per `variable_fields` name plus `len16`;
  unknown fields are reported by name.
- [x] Per-construct histogram (`needed`, `sole`) in `family-admission`;
  repo test checks construct blockers cover exactly the rule-less records.
- Deferred by decision: operand-driven *generic normalization* (per-iform
  arms only as overrides) lands with the table encoders (INF-05R/INF-05X),
  since a generic normal form is only useful with a generic encoder and
  generated cases. No normalizer output changed here.

Headline (2026-09-25): records without a normalizer rule that need only
known constructs — RV32 290/331, RV64 309/341, x86-32 1,739/6,842, x86-64
1,777/9,524. Top x86-64 constructs by sole-missing records: `evex-map2`
341, `evex-vl128` 250, `evex-vl256` 222, `vex-w1` 196, `reg:mmx` 182,
`evex-map5` 141, `evex-map3` 107, `is4` 84, `mem:vv` 83, `mem:zd` 69,
`evex-map6` 68, `lock` 57, `branch-displacement` 48. APX (`evex-map4`
2,318 needed) is never sole-missing: it needs map4 + APX EVEX together.
Note: the admitted zmm subset's records carry `MASK1`, so `evex-opmask`
counts as known; masking is an obligation on already-credited records.

### INF-03 — generated cases

- [ ] Per-domain obligation generators (registers, immediates, memory,
  masks/broadcast when they exist) and AT&T / GNU RISC-V renderers.
- [ ] Configuration from the form's feature → GAS spelling mapping.
- [ ] Hand entries in `Isa_gen_difficult` remain for labels, relocations and
  layout-sensitive forms; generated entries must not duplicate them.
- [ ] Gate: regenerating an already-admitted family from generated entries
  reproduces its existing verdicts (same or superset obligations).

### INF-04 — scalable regeneration

- [x] ~~Batch cases per GAS invocation~~ — replaced by decision: cases are
  sharded over forked workers (`Tool_parallel`) instead. Each case still
  runs its own `as`/`objdump`/`objcopy`/`asm.exe`, so recorded artifacts
  (argv, exit status, diagnostics) are exactly a single-case run's and a
  failing case is always reported under its own id; multi-case batches
  could not reproduce per-case artifacts faithfully.
- [x] Per-case cost removed: the toolchain probe and `as --version` are
  resolved once per target, the `ours` git label once per run, the export
  once per file, and `asm.exe` runs from `_build` (falling back to
  `dune exec` only when unbuilt) instead of `opam exec -- dune exec`.
- [x] GAS diagnostics record the scratch path as `case.s`, so regeneration
  is deterministic apart from the `ours` git-revision label.
- [x] Incremental by default: a committed record's GAS artifact is reused
  when case, argv and `as` version label are unchanged
  (`Isa_gen_oracle.reuse`); `ours` always re-runs.
  `COMPCERT_TOOLS_REGEN=full` re-runs everything; `COMPCERT_TOOLS_JOBS`
  sets the worker count.
- [ ] Sharding committed artifacts by profile/ledger row: not needed at the
  current size (3.5 MB, 3,375 cases); revisit when generated cases land
  (INF-03).
- [x] Gate (2026-09-25, 8 cores): full regen of 3,375 cases 12m22s → 24 s
  sequential, 6.3 s parallel, 2.9 s incremental; all three outputs
  byte-identical to each other and to the committed corpus modulo the
  `ours` label and the old scratch path. A planted corrupt GAS byte was
  reported as `BYTE-MISMATCH` under its case id. Pilot regen unchanged.

### INF-05R / INF-05X — table-driven encoders

Write the decision record first (alternatives: keep per-mnemonic
constructors; generated checked-in table; hand-maintained table), covering
the oracle-independence argument, how generated OCaml is regenerated and
reviewed, ARM/js_of_ocaml/Melange compile limits for large tables, decode
priority and collision testing against hand-written alternatives, and which
forms stay hand-written (fixups, relaxation, selection, compressed subsets).

- [ ] DEC-RV-TABLE recorded; RISC-V table encoder/decoder lands with one
  family (suggest Zimop: 42 records, GPR-only) and no byte changes elsewhere.
- [ ] DEC-X86-TABLE recorded; x86 row encoder lands with one legacy family,
  then one VEX family, with no byte changes elsewhere.
- [ ] Both: `make asm-js-portable`, `make asm-purity`, all six target
  profiles' regressions, and codec checks pass.

### INF-06 — features everywhere

- [ ] Every table row names a feature; the feature has a GAS spelling and a
  recorded probe.
- [ ] Retrofit already-admitted hand-written extensions (F, D, A, V, Zb*,
  Zk*, Zv*, SSE*, AVX*, AVX-512) into components, behavior-preserving, with
  enabled/disabled/dependency cases through text and AST paths.

### FREE-01 / FREE-02 — credit what already works

- [x] FREE-01 RISC-V: cases for all 30 normalized-only records (`rv_i` 13,
  `rv_m` 7, `rv64_i` 5, `rv64_m` 5). The M division/high-multiply forms were
  never actually implemented (only `mul`/`mulw`/`remu` were); `Riscv_ext_m`
  now lists all RV32M/RV64M forms and the decoder reads the same table.
- [ ] FREE-01 x86: the 6 SSE/SSE2 normalized-only records are 64-bit-only
  (REX.W / GPR64) forms in the `x86_32` export → DEC-X86-MODE16. Of the 5
  GAS-generatable I86 records, ADD_GPRv_GPRv_03 and MOV_GPRv_GPRv_8B need
  GAS's `{load}` pseudo-prefix (not parsed by ours), MOV_GPRv_IMMz on
  x86-32 has no GAS spelling without one, and the rest need
  DEC-X86-SUFFIX.
- [ ] FREE-02: list x86 encoder `Opcode`s (e.g. `Mov`, `Lea`, `Push`, `Pop`,
  `Call`, `Jmp`, `Ret`, `Imul`, `Mul`, `Div`, `Neg`, `Not`, `Shl`/`Shr`/
  `Sar`/`Ror`/`Rcr`/`Shld`, `Setcc`, `Cmov`, `Movzx`, `Movsx`, `Dec`, `Ud2`,
  `Sahf`, the 13 x87 forms) whose XED iforms are not normalized; add
  normalizer rules and cases. Encoder changes only where GAS disagrees.

### RISC-V families

Remaining names at baseline (both profiles unless noted):

- **GEN-05-RV-BASE**: `rv_i` `auipc lui jal j jr beqz bnez bgez blez bltz
  bgtz bgt bgtu ble bleu bge bgeu blt bltu bne lb lbu lh lhu lw sb sh ecall
  ebreak scall sbreak fence fence.tso pause`; `rv64_i` `ld lwu sd slli srli
  srai slliw srliw sraiw`; `rv32_i` shift-immediates (6). Branches need the
  label/controlled-offset recipe from `beq`; `lui`/`auipc` use numeric
  immediates only (no relocation).
- **GEN-05-RV-ZBA**: `add.uw` (R-type), `slli.uw` (6-bit shamt), `zext.w`
  (alias of `add.uw` with `x0`).
- **GEN-05-RV-FP**: `rv_f` `frcsr frflags frrm fscsr fsflags fsflagsi fsrm
  fsrmi`; `rv64_d` `fmv.x.d fmv.d.x`; then `rv_zfh`/`rv64_zfh`,
  `rv_zfhmin`/`rv_d_zfhmin`/`rv_q_zfhmin`, `rv_q`/`rv64_q`, the six Zfa files
  (`fli.*` needs its constant-table syntax), `rv_zfbfmin`.
- **GEN-05-RV-MISC**: `rv_zimop` (42), `rv_zicbo` (address-only and
  `prefetch.*` offset-multiple-of-32 shapes), `rv_zicfiss`, `rv_zicfilp`,
  `rv_zihintntl`, `rv_zifencei`, `rv_zicntr`/`rv32_zicntr`;
  `rv32_zilsd` is oracle-unavailable (GAS: unknown extension `zilsd`).
- **GEN-05-RV-ATOMIC**: `rv_zabha` (18), `rv_zacas`/`rv64_zacas`,
  `rv_zabha_zacas` (reuse the `.aq`/`.rl` shape), `rv_zawrs`; `rv_zalasr` is
  oracle-unavailable (GAS: unknown extension `zalasr`).
- **GEN-05-RV-PRIV**: `rv_h`/`rv64_h`, `rv_s`, `rv_system`, `rv_svinval`,
  `rv_svinval_h`, `rv_sdext`, `rv_ssctr`; `rv_smrnmi` is oracle-unavailable
  (GAS: unrecognized `mnret`).
- **GEN-05-RV-C**: `rv_c` `c.addi16sp c.addi4spn c.andi c.j c.li c.lui c.nop`;
  `rv64_c` `c.addiw c.slli c.srai c.srli`; `rv32_c` (7, incl. `c.jal`);
  `rv_c_d`, `rv32_c_f`, `rv_zcb`/`rv64_zcb`, `rv_zcmp`, `rv_zcmt`,
  `rv_zcmop`, `rv_c_zihintntl`, `rv_c_zicfiss`, `rv32_zclsd` (shadowed
  extension on RV32; probe GAS, which lacks `zilsd`).

### x86 families

Work order and scope are in plan section 6. Before starting each, take the
INF-02 construct histogram for its ledger row and admit machinery in order of
records unlocked. Each EVEX machinery increment (opmask, zeroing, broadcast,
rounding/SAE, disp8*N, registers 16–31, 128/256 lengths, k-register ops)
lands with its own small family, positive and negative cases.

## Ledger corrections to make with the relevant slice

- `RES-RV-PRIV`: the reopening gate asks for a privilege-mode requirement
  predicate. Assembly does not depend on privilege mode (GAS encodes `hfence.*`,
  `sret`, `sfence.vma` under `-march` alone), so the gate should require only
  per-extension feature mappings and probes.
- `RES-X86-SYSTEM`: same reasoning; privileged forms are oracle-unavailable
  only where GAS rejects them, not because they are privileged.
- Record `oracle-unavailable` with probe evidence for Zalasr, Zilsd and
  Smrnmi rather than leaving them blocked.

## Lessons from phase 1 to apply on every slice

- Assemble the exact spelling with real GAS on both RISC-V profiles (or both
  x86 modes) before writing the encoder arm, and derive split/permuted
  immediates from `arg-lut` bit ranges, not from the field order.
- GAS compresses opportunistically under `c`, including `nop` → `c.nop`;
  baseline cases omit `c`, and compressed cases avoid uncompressed filler.
- GAS accepts aliases that are not source records (`add a0, a1, 7` is
  `addi`); verify every negative against GAS instead of assuming rejection.
- A mnemonic may occur in several extension files; check per-profile
  ownership (`Req_any` for imports, shadowing across `rv32_*`/`rv64_*`).
- Offline replay must fail on any recorded hard-failure verdict; never commit
  a `byte_mismatch` case as a pass.
- Byte-register and REX interactions need cases in both x86 modes; phase 1
  found spurious-REX and dropped-REX.B/X decode bugs this way.
- Large literal `match` expressions break the 32-bit ARM OCaml 4.14 backend;
  shape generated tables accordingly.
- Tier-two regeneration takes seconds since INF-04 but still needs the
  cross toolchains and stays off `asm-ci`.

## Evidence record template

```text
Task / status / owner:
Scope (families, records, profiles) and obligations:
GAS probes (tool, version, spelling, result):
Implementation commit(s):
Commands run and results:
Counts before -> after (promoted, blocked per profile; ledger rows changed):
Unknowns, exceptions, follow-up task IDs:
```

## Evidence log

| Date | Task | Result |
|---|---|---|
| 2026-09-25 | Phase-2 baseline | `make tools-isa-residual-ledger` and `family-admission` at `f4b93e4`: counts in the baseline table; ledger owns all blocked records |
| 2026-09-25 | GAS capability probe | `x86_64-linux-gnu-as` 2.44 accepts APX (r16, `{nf}`, NDD), EVEX mask/zeroing/broadcast, AVX10.2 `vminmaxps`, AMX `tdpbssd`, FMA, VSIB, XOP, MMX, 3DNow `femms`, `fadds 4(%rsp)`. RISC-V 2.44/2.43.1 accept Zfh, Zfa, Q, Zabha, Zacas, Zawrs, Zimop, Zcb, Zcmp, Zcmt, Zcmop, Zfbfmin, H, Zicbom, Zicfiss, Ssctr; reject Zalasr, Zilsd (RV32), `mnret` (Smrnmi) |
| 2026-09-25 | INF-01 | Credit read from corpora; `family-admission` and `residual-ledger` byte-identical to `f4b93e4`; `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check` pass |
| 2026-09-25 | INF-02 | Construct-keyed blockers and histogram in `family-admission`; counts unchanged; `tools-test`, `tools-integration`, `tools-boundary`, `asm-fmt-check` pass |
| 2026-09-25 | INF-04 | difficult regen 12m22s → 6.3 s full / 2.9 s incremental, output identical; `family-records` listing added; `tools-test`, `tools-integration`, `tools-boundary`, `asm-isa-difficult-check`, `asm-fmt-check` pass |
| 2026-09-25 | FREE-01 (RISC-V) + GEN-05-RV-BASE | Promoted RV32 734→796, RV64 783→858; blocked RV32 335→293, RV64 341→296; normalized-only 20/30→0; round-trip 3,635→3,722; difficult corpus 3,375→3,582 cases, all pass. GAS 2.44/2.43.1 probes: branch pseudos, `scall`/`sbreak`, `fence.tso`, `pause` (needs `zihintpause`). Fixed: bare `fence` encoded as `fence rw,w`; now `fence iorw,iorw` with general pred/succ sets. Shadow guard: `rv32_zilsd` `ld`/`sd` stay blocked. `asm-ci`, `asm-js-portable`, `asm-purity`, tools suites pass |
