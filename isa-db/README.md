# ISA database producer (prototype, XED + riscv-opcodes only)

This is build-out phase 1/2 of the independent ISA database producer
recommended by [`.ai/isa-database-design.md`](../.ai/isa-database-design.md):
a source-qualified "source record" layer over instruction-set data, kept
separate from and more detailed than the `manifest.txt`/`summary.txt`
mnemonic inventory in [`asm/docs/isa-inventory.md`](../asm/docs/isa-inventory.md).

Scope of this slice, by explicit decision: **XED and riscv-opcodes only.**
LLVM and QEMU adapters (the design doc's phases 3-4) are not started here.
Do not add them to this directory without first re-reading the design doc's
phased plan; each new source is its own adapter plus its own worked-example
regression tests, not an extension of the existing two.

This is a standalone Python project, deliberately with **zero third-party
dependencies** (stdlib only - no `pytest`, no `jsonschema`; neither was
available in this environment, and the design doc itself says production
assembler libraries should not acquire producer build dependencies). It is
not wired into `asm-ci` or the root `Makefile`: per the design doc, producer
CI is a separate concern from this repo's ordinary, offline, toolchain-free
checks.

## Layout

- `schema/source_record.schema.v1.json` - JSON Schema (draft 2020-12) for a
  source record. Documentation-grade: there is no `jsonschema` dependency
  here, so `normalize/schema_check.py` checks only the required top-level
  shape it describes, not the full schema.
- `sources.lock.json` - pins the two vendored submodule commits this slice
  reads, matching `git -C asm/vendor/isa-data/<name>/upstream rev-parse HEAD`
  at the time this slice was written.
- `normalize/model.py` - the shared, source-agnostic pieces: the source
  record shape, the `fixed_bits`/`opaque` encoding tagged union, the mode
  applicability expression (`all`/`any`/`mode`) and its evaluator, and JSON
  serialization helpers.
- `adapters/xed/reader.py` - reads the vendored XED `datafiles/` tree
  (content-based block recognition, exactly like
  `asm/tools/lib/isa_inventory_xed.ml`) into block-level source records, and
  a `compat_entries` view that reproduces that OCaml module's
  `(mnemonic, extension, applies_32, applies_64)` output exactly (verified by
  `tests/test_xed_reader.py` against the checked-in
  `asm/fixtures/isa-inventory/{x86_32,x86_64}/manifest.txt`).
- `adapters/riscv_opcodes/reader.py` - reads the vendored riscv-opcodes
  `extensions/` files (ratified only, `rv_`/`rv32_`/`rv64_`-prefixed, per
  `asm/tools/lib/isa_inventory_riscv.ml`) into per-line source records,
  including `$import` and `$pseudo_op` as explicit typed relationships
  (`imports` / `specializes`) rather than folding them into a plain mnemonic
  list, plus a `compat_entries` view verified the same way against
  `asm/fixtures/isa-inventory/{riscv32,riscv64}/manifest.txt`.

## What this slice deliberately does not do

- No reconciliation/mapping layer across sources (there is only one source
  per architecture family so far - XED for x86, riscv-opcodes for RISC-V -
  so there is nothing to reconcile yet).
- No JSON Lines export or SQLite convenience database - `normalize/model.py`
  exposes `to_dict()`/`to_json()` on a source record, but nothing here
  writes `export/`.
- No general typed expression algebra (`feature`, `xlen`, `opaque`
  requirement kinds beyond x86's `mode`) - RISC-V source records currently
  carry their extension name as a plain string, not yet a `feature`
  applicability node, since a second source (LLVM) is what actually forces
  that generalization; adding it speculatively here would be exactly the
  kind of premature abstraction the design doc's own "preserve facts before
  reconciling" principle warns against building ahead of need.
- No consumer change in `asm/tools`: `Isa_inventory_xed`/`Isa_inventory_riscv`
  are untouched, and remain the source of truth for the committed
  `asm/fixtures/isa-inventory/` manifests.

## Running the tests

```sh
python3 -m unittest discover -s isa-db/tests -t isa-db
```

The tests read the vendored submodules directly (`asm/vendor/isa-data/...`),
so they need `git submodule update --init` to have been run, the same
precondition `asm/`'s own isa-inventory tooling already has.
