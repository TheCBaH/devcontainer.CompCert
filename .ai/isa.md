# Plan: going deep on XED and riscv-opcodes before anything else

Scope decision (2026-09-05, user direction): prioritize depth on the two
sources already vendored and already consumed - XED and riscv-opcodes -
over breadth (LLVM, QEMU, ARM/AArch64 coverage). This plan says how to get
real depth out of those two, how the result is represented as JSON, and how
the rest of the project (`asm/tools`, tests) would actually consume it.
It follows [`isa-database-design.md`](isa-database-design.md) (the
independent-producer recommendation) and the `isa-db/` prototype that
implements its first slice (commits `7f53b50`, `e931c03`).

## Where the prototype currently tops out

`isa-db/adapters/{xed,riscv_opcodes}/reader.py` are both regression-tested
for exact parity with the checked-in `asm/fixtures/isa-inventory/*` manifests,
but both re-derive facts from raw text with a hand-rolled parser, which caps
their depth and already produced one real bug (compressed RISC-V
instructions mislabeled `width_bits: 32`, fixed in `e931c03`):

- **riscv-opcodes adapter**: correctly computes constant-bit mask/value
  (cross-checked against `sh1add`'s known-good `0xfe00707f`/`0x20002033`),
  but treats operand tokens (`rd`, `rs1`, `imm12hi`, ...) as opaque names in
  `provenance.operands` - it never resolves *where* those operands live in
  the encoding, and it has no built-in over/under-specification validation.
  `csrs.csv`, `csrs32.csv`, `causes.csv`, `arg_lut.csv` (all present in the
  vendored checkout, see below) are not read at all.
- **XED adapter**: the same coarse `ICLASS`/`PATTERN`-block scan the
  existing OCaml importer uses - no operand forms, no IFORM expansion, and
  (documented in every record's `unresolved` list) `UDELETE` is not honored.

## New finding: riscv-opcodes ships its own authoritative producer

The vendored `asm/vendor/isa-data/riscv-opcodes/upstream/src/riscv_opcodes/`
package is riscv-opcodes' *own* generator - the one that produces its
project's `instr_dict.json` and all its HDL/C header outputs. Its core,
`create_inst_dict` in `shared_utils.py`, already does exactly what our
adapter reimplements by hand, plus real operand resolution via
`arg_lut.csv`, plus validation (`validate_bit_range`, over/under-
specification checks, `$import`/`$pseudo_op` cross-file resolution with
mismatch detection). Verified in this session, directly against the vendored
checkout, with **zero** third-party Python dependencies (only stdlib plus
the package's own local `.constants`/`.resources` modules):

```python
import sys
sys.path.insert(0, "asm/vendor/isa-data/riscv-opcodes/upstream/src")
from riscv_opcodes.shared_utils import create_inst_dict

create_inst_dict(["rv_zba"], include_pseudo=False)["sh1add"]
# {'encoding': '0010000----------010-----0110011',
#  'variable_fields': ['rd', 'rs1', 'rs2'],
#  'extension': ['rv_zba'],
#  'match': '0x20002033', 'mask': '0xfe00707f'}    # matches our own ground truth exactly
```

Also verified: `nop` (rv_i's `$pseudo_op`) resolves to a fully concrete
encoding (`match: 0x13, mask: 0xffffffff`, `variable_fields: []` - upstream
does the specialization for you); `clmul`/`clmulh` under `rv_zbkc`'s
`$import` resolve to their real encoding attributed to the *importing*
file; and a full `create_inst_dict(["rv*"], include_pseudo=True,
warn_overlap=True)` run produces 1048 instructions in ~0.2s. `resource_root()`
(in `resources.py`) is specifically written to find `extensions/`/`*.csv`
two directories up from the package when it isn't co-located (the installed-
wheel layout) - which is exactly this vendored git-checkout's layout - so
this works against the submodule as checked out, with no build step.

`parse.py` (the `python3 -m riscv_opcodes` entry point) additionally imports
`c_utils`/`chisel_utils`/`go_utils`/`latex_utils`/`rust_utils`/`sverilog_utils`/
`svg_utils` at module scope - **do not** import `parse`; import
`riscv_opcodes.shared_utils` directly (as above) to avoid pulling in output
backends we don't need and haven't checked for their own dependencies.

**No equivalent verification exists yet for XED.** `read_xed_db.py`'s own
imports (`patterns`, `slash_expand`, `genutil`, `opnd_types`, `opnds`,
`cpuid_rdr`, `map_info_rdr`) are all local `pysrc/` modules, which is a
promising sign, but `isa-database-design.md` explicitly says that path "was
inspected, not run through a complete XED generation," and it likely needs
`xed_mbuild.py`-generated aggregate inputs (`all-dec-instructions.txt`,
`all-state.txt`) that don't exist in this vendored checkout yet. Treat XED's
stronger path as unverified until a dedicated spike says otherwise - don't
assume it is as low-risk as riscv-opcodes' turned out to be.

## Phased plan

### Phase A - RISC-V: adopt the upstream producer (ready now, low risk)

1. Add an `isa-db/adapters/riscv_opcodes/upstream.py` that `sys.path`-injects
   the vendored `upstream/src` and calls `create_inst_dict` **per extension
   file** (not one `"rv*"` call) so today's per-file `origin`/provenance
   tracking survives unchanged.
2. Import `arg_lut` directly from `riscv_opcodes.constants` (the same table
   `create_inst_dict` already consults) to turn each `variable_fields` name
   into a real `{name, lsb, width}` field entry - replacing both the
   placeholder `"bits[hi:lo]"` names our own parser emits for constant bits
   *and* the complete absence of variable-field entries today.
3. Add an exhaustive regression test: for every RISC-V instruction (not just
   `sh1add`), assert our adapter's `encoding.mask`/`encoding.value` equal
   upstream's `mask`/`match` exactly. This replaces today's two spot-checks
   with full coverage, for free, since upstream already computed the answer.
4. Keep our own `imports`/`specializes` relationship modeling *in addition
   to* (not instead of) upstream's resolution: upstream silently produces a
   fully concrete encoding for `nop`/`clmul` with no trace of the
   `$pseudo_op`/`$import` line that produced it - exactly the "disappear
   during normalization" loss `isa-database-design.md` warns about. Keep
   parsing those two directive lines ourselves for provenance, and use
   upstream's dict only for the resolved encoding.
5. Lower priority, do after the above: ingest `arg_lut.csv` itself as a
   small shared "operand vocabulary" table (name -> canonical bit range),
   and consider `csrs.csv`/`csrs32.csv`/`causes.csv` as optional auxiliary
   reference data (CSR addresses/names, trap cause codes) - useful, but not
   instruction-inventory data, so sequence it after encoding work, not
   before.
6. Acceptance: `compat_entries_for_profile`'s external contract is
   unchanged, so all four existing manifest-parity regression tests
   (`isa-db/tests/test_riscv_opcodes_reader.py`) must keep passing unmodified
   throughout this phase.

### Phase B - XED: attempt the stronger upstream-reader path (spike first)

1. Timebox a spike: try to run `pysrc/gen_setup.py`/`read_xed_db.xed_reader_t`
   against the vendored `datafiles/` tree as-is. Find out concretely whether
   it needs `xed_mbuild.py`-generated aggregate inputs that aren't present,
   and if so, whether generating them needs anything beyond this vendored
   checkout (extra Python packages, network access, a full XED build).
2. If it runs cleanly standalone: mirror Phase A's shape - a thin wrapper
   invoking the upstream reader, mapping resolved forms (ICLASS, IFORM/
   UNAME, operand access/visibility, attributes, evaluated pattern, CPUID)
   into a new `encoding: {"kind": "x86_encoding", ...}` tagged-union branch
   (x86 has no single fixed-width mask, per `isa-database-design.md`'s
   X86InstrFormats.td discussion - this branch doesn't exist yet and needs
   its own design once real data is in hand). Honor `UDELETE`.
3. If it needs inputs/tooling not present here (the likelier outcome per the
   design doc's own caution): write down that finding and leave the current
   coarse block-scan adapter as XED's depth ceiling. Do not quietly relax
   the `unresolved` notes to make partial coverage look complete.
4. Either outcome: the existing Phase-A-manifest regression tests are the
   floor. Whatever Phase B produces must be a superset of today's coverage,
   never a silent replacement that loses information the coarse scan had.

### Phase C - JSON export and schema v2

1. Add an `isa-db/export/` writer: one JSON Lines file per (source,
   profile) - e.g. `isa-db/export/riscv_opcodes/riscv64.jsonl`,
   `isa-db/export/xed/x86_64.jsonl` - each line one `SourceRecord.to_dict()`
   via stdlib `json.dumps` (no serialization library needed), sorted
   deterministically by `record_id` so diffs stay reviewable.
2. Cut `schema/source_record.schema.v2.json` once Phase A's richer,
   arg_lut-backed field names land. Leave `v1` alone as a record of what the
   first slice actually produced - don't rewrite history in place.
3. **Needs your sign-off, not a unilateral call:** check the generated
   JSONL into git (mirrors today's `manifest.txt`/`summary.txt` convention -
   works fully offline, diffable, but a large diff on every upstream bump),
   or regenerate on demand from `sources.lock.json` (closer to
   `isa-database-design.md`'s "producer CI proves repeatable output"
   framing, but nothing here works offline until the producer has run). If
   asked to pick: check in, and add an isa-db-local `export-diff` script
   mirroring `tools-isa-inventory-diff`'s check-clean-working-tree pattern -
   still kept out of `asm-ci`, per `isa-db/README.md`'s existing boundary.

### Phase D - consumption in `asm/tools` (OCaml side)

1. `yojson` 2.2.2 is already present in this project's opam switch
   (confirmed via `opam list`), just unused by `asm/tools` today - no new
   dependency needs adding to the switch, only to `asm/tools/lib/dune`'s
   existing library stanza when this phase starts.
2. First consumption step, deliberately low-risk - **cross-validation, not
   replacement**: a new `asm/tools` check reads the checked-in JSONL from
   Phase C and asserts every `(mnemonic, extension)` row in the checked-in
   `asm/fixtures/isa-inventory/*/manifest.txt` has a matching isa-db source
   record for that profile. This is strictly stronger evidence than today's
   `tools-isa-inventory-diff`, which only proves the OCaml generator is
   reproducible against itself, not that its output agrees with an
   independently-sourced dataset.
3. Later, only once Phases A-C have run long enough to be trusted: consider
   having `Isa_inventory_xed`/`Isa_inventory_riscv` read the JSONL directly
   instead of re-parsing `datafiles/`/`extensions/` from scratch, collapsing
   today's two independent parsers (an OCaml one that reimplements parsing,
   and a Python one that also reimplements parsing) into one producer plus
   one consumer. This is a separate, bigger decision - do not fold it into
   Phase D's first step.
4. Do not wire any of Phase D into `asm-ci` until the checked-in JSONL
   exists and the cross-validation check has run clean outside CI at least
   once.

### Explicitly out of scope for this plan

LLVM and QEMU adapters, and ARM/AArch64 coverage generally - unchanged from
`isa-db/README.md`'s existing scope note. Revisit only after Phases A-D
above land, per the priority decision this plan opened with.

## Open decisions needing sign-off before implementation

1. Adopt riscv-opcodes' own `create_inst_dict` as the RISC-V adapter's
   encoding source of truth (Phase A) - a soft dependency on that vendored
   package's internal (non-public, no compatibility guarantee) function,
   though pinned and reproducible like everything else in `isa-db/`.
2. Whether to spend the Phase B spike now, or leave XED at its current
   coarse-scan ceiling until a concrete downstream need (e.g. an
   operand-boundary test generator) justifies the added complexity.
3. Checked-in JSONL vs. regenerate-on-demand (Phase C).
4. How far Phase D should go: cross-validation only, or eventually
   replacing the OCaml importers outright.
