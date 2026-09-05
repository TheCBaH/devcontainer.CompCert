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

### Phase A - RISC-V: adopt the upstream producer (steps 1-4, 6 done)

1. **Done.** `isa-db/adapters/riscv_opcodes/upstream.py` `sys.path`-injects
   the vendored `upstream/src` and calls `create_inst_dict` **per extension
   file** (not one `"rv*"` call), so per-file `origin`/provenance tracking
   is unchanged.
2. **Done.** `reader.py` now resolves each `variable_fields` name via
   upstream's own `arg_lut` into a real `{name, lsb, width}` field entry,
   appended alongside the constant-bit `"bits[hi:lo]"` fields our own parser
   already emitted (those keep their name - arg_lut only names *variable*
   operands, constant bits have no source-given name to recover).
3. **Done**, and it already earned its keep: `test_riscv_opcodes_upstream.py`
   asserts `encoding.mask`/`encoding.value` against upstream's `mask`/`match`
   for every plain-instruction record in the vendored tree (1235 records,
   checked > 1000 fixed_bits comparisons) and caught a second real bug on
   its first run - `_FIELD_RE` didn't recognize binary literals
   (`29..25=0b10111`, four `rv32_zkn*` AES instructions), so that field
   silently fell through to `operands` instead of contributing to
   mask/value. Fixed by parsing values with `int(raw, 0)` (matching
   upstream's own base-0 `int()` call) instead of hand-rolling hex-vs-decimal
   detection.
4. **Done.** `$import` and `$pseudo_op` records now use
   `_encoding_from_upstream` (upstream's resolved `mask`/`match` plus
   arg_lut-resolved fields) as their `encoding`, while `reader.py` still
   parses the `$import`/`$pseudo_op` line itself for the `kind`,
   `relationships`, and `provenance` a plain lookup into `instr_dict` would
   lose. Falls back to the previous behavior (opaque for imports, hand-parsed
   fixed_bits for pseudo-ops) only if upstream's dict doesn't contain a
   matching key - not expected to trigger against the current vendored
   checkout, but keeps the adapter from raising if a future snapshot ever
   disagrees.
5. **Done.** `isa-db/adapters/riscv_opcodes/reference.py`'s `operand_vocab`
   ingests the arg_lut operand-name vocabulary, exported as
   `isa-db/export/riscv_opcodes/arg-lut.jsonl` (one `{name, lsb, width}`
   entry per line, sorted by name, plus `source`/`snapshot`). This reads
   `upstream.arg_lut()` (the live dict `create_inst_dict` itself consults)
   after processing every extension file `reader.py` iterates over, rather
   than re-parsing `arg_lut.csv` directly: the raw CSV alone is missing six
   names riscv-opcodes' own `constants.py` hardcodes at import time (the
   "mop"/"c_mop_t" fields - none are CSV rows), so a naive re-parse would
   under-report the vocabulary real instruction records resolve against.
   `csrs.csv`/`csrs32.csv`/`causes.csv` remain un-ingested, per the original
   "consider... as optional" phrasing - no concrete consumer has asked for
   them yet. `tests/test_riscv_opcodes_reference.py` cross-checks the export
   against both known-good bit ranges (`sh1add`'s `rd`/`rs1`/`rs2`) and an
   independent from-scratch re-parse of the raw CSV (asserting the export is
   a strict superset with matching bit ranges).
6. **Confirmed.** `compat_entries_for_profile`'s contract is unchanged; all
   pre-existing tests in `isa-db/tests/test_riscv_opcodes_reader.py` pass
   unmodified (plus one new pinning test for the binary-literal fix), and
   `make tools-isa-inventory-diff` still reproduces the checked-in
   `asm/fixtures/isa-inventory/*` manifests exactly.

### Phase B - XED: attempt the stronger upstream-reader path (spike first)

**Spiked 2026-09-05: outcome 3, the anticipated likelier one.** The
`just-prep` `xed_mbuild.py` target is real (`valid_targets` at line 1022;
the `pysrc/README.md` describing it is genuine vendored upstream content,
not a local edit - confirmed via `git log`/`git blame` inside the
submodule), and `pysrc/xed_to_db.py` (also genuine, real upstream code) is
exactly the `gen_setup`/`read_xed_db.xed_reader_t`-based stronger path the
design doc described. But `mfile.py just-prep` itself requires importing a
sibling `mbuild` package (Intel's separate build-support library,
`genutil.find_dir('mbuild')`) that is **not vendored in this repo** -
`.gitmodules` vendors only `intelxed/xed`, never `intelxed/mbuild` - and is
not installed (`python3 -c 'import mbuild'` fails `ModuleNotFoundError` in
this container). So the stronger path is blocked on a new, un-vendored
upstream dependency, not on missing generated data files as such.

1. **Done.** Ran the spike above; see the finding.
2. Not attempted - blocked by (1)'s finding, not by anything in this step.
3. **Done, this is the outcome.** Leaving the current coarse block-scan
   adapter as XED's depth ceiling. Vendoring `intelxed/mbuild` as a new
   submodule would lift this, but that is itself a new vendoring decision
   (a new `.gitmodules` entry, a new pinned commit, a new license to check)
   that deserves its own explicit ask rather than being bundled into this
   spike's go-ahead - not attempted here.
4. Unaffected: nothing changed in `adapters/xed/reader.py`, so the existing
   Phase-A-manifest regression tests (`tests/test_xed_reader.py`) remain
   exactly what they were.

### Phase C - JSON export and schema v2

1. **Done.** `isa-db/export/writer.py` (+ `regen.py` CLI entry point): one
   JSON Lines file per (source, profile) -
   `isa-db/export/riscv_opcodes/{riscv32,riscv64}.jsonl`,
   `isa-db/export/xed/{x86_32,x86_64}.jsonl` - each line one
   `SourceRecord.to_dict()` via stdlib `json.dumps(..., sort_keys=True)`,
   sorted deterministically by `record_id`. `adapters/{riscv_opcodes,xed}/
   reader.py` each gained a `source_records_for_profile` filter (file-level
   for riscv-opcodes, applicability-level for XED) to produce these.
2. **Not done, and turned out to be unnecessary.** `schema/
   source_record.schema.v1.json`'s `encoding.fixed_bits` branch already
   requires exactly the `{name, lsb, width}` field shape Phase A's
   arg_lut-backed fields produce - Phase A changed what populates `fields`/
   `provenance.operands`, not the record's shape, so v1 already validates
   the richer output unmodified. No v2 cut needed unless a future change
   (e.g. a real Phase B, or LLVM) changes the shape itself.
3. **Decided (2026-09-05, user sign-off): check in.** The four `export/
   *.jsonl` files are committed. `isa-db/tests/test_export.py`'s
   `TestCheckedInExportUpToDate` is this project's own diff-check (fails if
   `python3 -m export.regen`'s output disagrees with what's committed) -
   playing `tools-isa-inventory-diff`'s role for this slice, still run only
   by `python3 -m unittest discover -s isa-db/tests -t isa-db`, not wired
   into `asm-ci` (unchanged boundary, `isa-db/README.md`).

### Phase D - consumption in `asm/tools` (OCaml side)

1. **Done.** `opam install jsont bytesrw` (jsont's own text (de)serialization
   needs the separate `bytesrw` depopt - `jsont` alone only defines
   codec-agnostic object/array maps). Both added to `asm/tools/lib/dune`'s
   `libraries` stanza and to `.devcontainer/devcontainer.json`'s opam
   package list, so a fresh container build already has them.
   `ppx_yojson_conv_lib`/`yojson` remain installed but unused, as before.
2. **Done - cross-validation, not replacement.**
   `asm/tools/lib/isa_db_jsonl.ml{,i}` is the `jsont` codec (record_id,
   source, kind, native_name, provenance.{extension,group} only - every
   other member is skipped by jsont's default). `Isa_db_cross_validate.check`
   reads each checked-in `asm/fixtures/isa-inventory/<target>/manifest.txt`
   and the matching `isa-db/export/<source>/<target>.jsonl`, and asserts
   every manifest `(mnemonic, extension)` row has a matching isa-db record
   (one-directional - isa-db's richer records, e.g. `$import` relations,
   are not required to have a manifest counterpart). Exposed as
   `compcert-tools isa-inventory cross-validate` and exercised by
   `asm/tools/test/repo/repo_tests.exe` (needs the real repository root to
   reach `isa-db/export/`, which lives outside `asm/`'s own dune workspace -
   same reason every other repo-root check lives in that executable
   instead of a `runtest` rule). Verified it actually detects a mismatch
   (temporarily dropped one exported record, confirmed the check reports it
   and exits 1, then restored the file) before trusting the "all matched"
   result on real data.
3. Not attempted this pass - still a separate, bigger decision per the
   original plan.
4. **Superseded by how this landed:** the check runs inside
   `repo_tests.exe`, which `tools-integration` already builds and runs, and
   `tools-integration` is already one of `asm-ci`'s targets - so Phase D is
   now exercised by `asm-ci` as a side effect of step 2's placement, not a
   separate decision to wire it in. This precondition (run clean outside CI
   at least once) was satisfied first: `make tools-integration` was run
   manually and passed (2493/2781/974/1017 manifest rows matched across the
   four profiles) before this was reported done.

### Explicitly out of scope for this plan

LLVM and QEMU adapters, and ARM/AArch64 coverage generally - unchanged from
`isa-db/README.md`'s existing scope note. Revisit only after Phases A-D
above land, per the priority decision this plan opened with.

## Open decisions - all resolved 2026-09-05

1. **Resolved: yes** (already landed, `c17355a`). Adopt riscv-opcodes' own
   `create_inst_dict` as the RISC-V adapter's encoding source of truth
   (Phase A) - a soft dependency on that vendored package's internal
   (non-public, no compatibility guarantee) function, though pinned and
   reproducible like everything else in `isa-db/`.
2. **Resolved: spend it now.** Result: blocked on the un-vendored `mbuild`
   package - see Phase B's finding above. XED stays at its coarse-scan
   ceiling; vendoring `intelxed/mbuild` is a distinct, not-yet-asked
   decision.
3. **Resolved: check in.** See Phase C step 3.
4. **Resolved: cross-validation only** for this pass. See Phase D step 2 -
   replacing the OCaml importers outright remains explicitly future work.

### Follow-ups this pass surfaced (not decided, not started)

- Vendoring `intelxed/mbuild` as a new submodule, to unblock Phase B's
  stronger XED path (a new `.gitmodules` entry/pinned commit/license check -
  its own ask, per Phase B's finding).
- Whether to promote `isa-db-cross-validate` out of `repo_tests.exe` into
  its own named Makefile target (e.g. `tools-isa-db-cross-validate`) for
  standalone invocation, now that it is exercised via `tools-integration`/
  `asm-ci` - purely a convenience/discoverability question, not a behavior
  change; not done here to avoid speculative scope beyond what Phase D
  step 2 asked for.
