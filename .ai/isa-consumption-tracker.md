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
| S1 Capture fidelity | not-started | CAP-01: fix and verify C/Zc width inference; CAP-06: fix XED coarse mode applicability; define native capture contract |
| S2 OCaml model | not-started | NORM-01: worked-example types and normalized dump contract |
| S3 Differential pilots | not-started | GAS-01 + GEN-01: freeze exact pilot forms and obligations |
| S4 Difficult forms | not-started | GEN-02: family admission and capability matrix |
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

- [ ] CAP-01 Correct the measured 31 RV32 / 29 RV64 compressed-width labels
  by deriving width **per record** from that record's own encoding, not per
  extension file; a corrected filename predicate does not satisfy this, and
  the `$import` path must not inherit the importing file's width. The
  expected diff is exact and complete (plan section 3.1). Establish encoding
  invariants and independent GAS examples.
- [ ] CAP-02 Specify native schema/envelope versions, deterministic ordering,
  provenance, unknown fields and compatibility exports.
- [ ] CAP-03 Preserve required XED/RISC-V native facts without canonical
  feature or GAS syntax interpretation in Python.
- [ ] CAP-04 Verify actual source/dependency commits and input hashes;
  detect dirty or stale snapshots and resolve/index native references.
- [ ] CAP-05 Add negative validation controls and fresh-process regeneration
  evidence; preserve or explain compatibility manifest differences. Build on
  the existing `test_export.py::TestCheckedInExportUpToDate` freshness gate
  rather than a second one, and state explicitly whether its deliberate
  outside-`asm-ci` boundary changes (plan section 3.5).
- [ ] CAP-06 Fix the XED coarse mode-applicability leak: `jrcxz` must leave
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

### NORM — OCaml interpretation and observable representation

Scope: typed source decoders, shared model, source-specific rules, normalized
JSONL and accounting. Owner: unassigned. Stages: S2, S7.

Investigate `sw`/`beq` reconstruction, compressed constraints, floating
register classes, XED widths/visibility, native feature requirements and
stable form identity. Compare a small typed model with a fully generic
expression model using actual examples; choose only the abstractions used.

- [ ] NORM-01 Freeze minimum types and example normalized records for the
  plan's worked examples; label inferred versus upstream facts.
- [ ] NORM-02 Implement source-specific decoding and complete record
  accounting, with actionable unknown-construct diagnostics.
- [ ] NORM-03 Implement three-valued requirements and exact/ambiguous/missing
  relationship outcomes; preserve one-to-many and many-to-one mappings.
- [ ] NORM-04 Export and round-trip deterministic normalized JSONL with
  source/rule references and schema versions.
- [ ] NORM-05 Establish offline library/tool boundaries and snapshot-update
  mapping reports; inventory compatibility remains a separate view.

Exit: all selected records accounted for; pilot examples fully interpreted;
unknown constraints cannot produce positive cases. No runtime assembler
dependency on source databases or host tools.

### GAS — Common oracle runner and reproducible artifacts

Scope: generation orchestration, GNU invocation, byte/image comparison,
failure reduction, artifact storage and CI tiers. Owner: unassigned.
Stages: S3, relocation path in S4, reproducibility in S7.

Investigate reuse of `Gnu_tools`, `gas_xref_cmd`, `oracle_cmd` and offline
differential tests; establish case boundaries and actual installed GNU
capabilities. Choose exact object comparison only for relocation-free cases.

- [ ] GAS-01 Freeze case/artifact/verdict schema and proposed CLI/Make
  targets, including which existing CI leg each of plan section 5.4's three
  tiers lands on under the repository's `-check`/`-regen` convention. A
  tier-one check must stay toolchain-free and must not transitively require
  building the whole assembler. Record the RV32 2.43.1 / RV64 2.44 GAS skew
  as a tool-version dimension of the coverage matrix, distinct from any
  architectural difference between the two profiles.
- [ ] GAS-02 Implement explicit profile/tool configuration and capability
  probes, GNU artifacts, exact bytes and observed-form checks.
- [ ] GAS-03 Replay committed cases offline without producer/toolchain
  dependencies; reject unexplained missing cases or tools in required tiers.
- [ ] GAS-04 Demonstrate wrong-byte, wrong-form and unexpected-relocation
  controls, plus actionable minimal failure reproduction.
- [ ] GAS-05 Add controlled linked-image comparison for symbolic/multi-unit
  cases, with section/symbol/fixup evidence and matching relaxation policy.

Exit: the four-profile pilots pass and each planted failure is caught;
later linked suites cannot pass by masking relocation bytes.

### GEN — Architecture recipes and finite coverage obligations

Scope: concrete operand domains, syntax rendering, form selection and
family-by-family coverage. Owner: unassigned. Stages: S3–S4, S7.

Investigate each family's syntax/encoding choices before admitting it.
Start with the proposed RISC-V base/M and x86 legacy pilot. Survey remaining
captured families early so unresolved EVEX/vector/system forms are counted.

- [ ] GEN-01 Commit exact pilot source/form IDs, supported configurations,
  mandatory cases and boundary obligations before implementing recipes.
  Blocked until the manifest's implementation side has a stated enumeration
  method per family — `--dump-codec` where alternatives are one-per-form,
  a recorded hand reading of the encoder otherwise (plan section 2.5 rules
  out a single authority, and RISC-V's two wrapper alternatives are not a
  form registry). The method is part of what gets reviewed, not a detail.
- [ ] GEN-02 Maintain a full family admission matrix: normalized-only,
  GAS-generatable, promoted support, oracle-unavailable, or specific blocker.
- [ ] GEN-03 Implement RISC-V load/store, branch and compressed recipes,
  with split-bit transforms, legal domains and explicit compression policy.
- [ ] GEN-04 Implement x86 addressing and x87 recipes, width/order rules
  and intended-versus-GAS-selected encoding checks.
- [ ] GEN-05 Admit further FP/atomic/CSR/bit-manipulation/vector families in
  bounded slices; give every remaining family a concrete task and evidence.
- [ ] GEN-06 Add aliases, pseudos and negatives as distinct coverage classes;
  record deterministic seeds, budgets and unsatisfied obligations.

Exit: every admitted form meets its finite policy; no mismatch is excused
by frontier status; unimplemented forms and oracle gaps remain visible.
“Recipe exists” is not “our assembler supports this extension”.

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
| 2026-09-05 | Close the RISC-V gap in the existing GAS frontier runtime group | Closed: `gas_xref_cmd.ml` now maps both RISC-V profiles to `runtime/riscV`; one `runtime-vararg` case landed per profile (2 → 3, aarch64 parity), both assembling cleanly. See `.ai/riscv-migrate.md` |
| 2026-09-05 | Probe the installed RV32 assembler and compare Zcb acceptance across the version skew | 2.43.1 at `/usr/local/riscv32-linux-gnu-toolchain/bin`, reached via `Target.toolprefix`, not on the default `PATH`; RV64 and host are 2.44; both accept `c.zext.b`, so the skew must be probed per extension, not assumed |

No implementation task above is complete merely because S0's existing tests
passed. The compressed-width finding is deliberately still an open CAP-01
implementation item, and the XED mode leak an open CAP-06 one.
