# The whole-ISA instruction/extension inventory

This is the schema for the "Parallel track: whole-ISA instruction and
extension inventory" section of `.ai/asm_plan.md` and item 2 of `next.md`'s
"Next steps" — step 2 of the pilot named in `.ai/isa-inventory-sources.md`
("Suggested pilot"). Read that survey first; this document only defines the
*format* the pilot's two vendored sources feed into, not where they came
from.

Do not confuse this with `asm/docs/riscv-inventory.md`, which is a narrower,
already-existing document scoped to Milestone 5's CompCert corpus. This
document's inventory is normative per architecture — every mnemonic the
reference source recognizes, whether or not CompCert or gcc ever emit it —
where `riscv-inventory.md` is scoped to what Milestone 5 actually measured.

## Why a schema document before a generator

`.ai/asm_plan.md`'s own description of this track specifies five things an
entry must carry (extension/level, CompCert/gcc-emitted, implementation
state, deferral reason, promotion trigger) but not a file format. Fixing the
format here, against the two vendored sources
(`asm/vendor/isa-data/riscv-opcodes`, `asm/vendor/isa-data/xed`) before
writing the generator, follows the same discipline `asm/docs/contracts.md`
already applies to the pipeline's other boundary formats: the format is
frozen and reviewable independent of the tool that produces it.

## Two sourcing phases, not one

The five required fields split into two groups with very different sourcing
difficulty, and the schema keeps that split explicit rather than pretending
both are available from day one:

- **Phase A — mnemonic and extension, from the vendored sources alone.**
  `riscv-opcodes`' `extensions/<name>` files and XED's
  `datafiles/<extension>/*-isa.xed.txt` files already are, one line/record
  per mnemonic, a normative machine-readable list. Producing this half of
  the inventory needs nothing beyond the two submodules already vendored —
  no cross toolchain, no CompCert build, no corpus regen.
- **Phase B — CompCert-/gcc-emitted, from the Milestone 5 corpora.** This is
  *not* currently derivable from what M5 already publishes:
  `asm/fixtures/corpus/*/​<target>/manifest.txt` records a `generated-sha256`
  of each corpus file's compiler output, not its content, so today there is
  no checked-in record of *which mnemonics* CompCert/gcc actually emitted.
  Producing this half needs a new, cross-toolchain-gated instrumentation
  step alongside `classify-c-<target>`/`classify-c-gcc-<target>` that
  additionally collects the mnemonic set seen across the corpus and
  publishes it as its own checked-in artifact (see "Follow-up: sourcing
  Phase B" below) — the same `*-regen` (needs toolchain) /
  `*-check` (does not) split every other corpus artifact already uses.
  Implementation state (opcode defined / lowered / encoded / decoded /
  byte-checked) is also Phase B in practice: it means walking this
  project's own target modules, not the vendored data, and is deferred for
  the same reason.

Until Phase B tooling lands, every entry's `compcert-emitted`/`gcc-emitted`/
`state` fields are literally the string `unknown` — an explicit placeholder,
not a silent gap, per `.ai/asm_plan.md`'s own "explicit deferral, not a
silent gap" rule for this track. A generator that only ever produces Phase A
is still a complete, valid inventory under this schema; Phase B tightens it
in place rather than changing its shape.

## File layout

One file per target, alongside the existing per-target corpus outputs:

```
asm/fixtures/isa-inventory/<target>/manifest.txt
asm/fixtures/isa-inventory/<target>/summary.txt
```

`<target>` is one of the six profiles (`x86_32`, `x86_64`, `arm`, `aarch64`,
`riscv32`, `riscv64`). RISC-V's source is already split by XLEN applicability
in the upstream data itself (`rv_*` extension files apply to both
`riscv32`/`riscv64`, `rv32_*`/`rv64_*` to one only), so no additional
filtering step is needed to produce two separate target files from the one
submodule. XED's data is not split by `x86_32`/`x86_64` as cleanly (most
extensions apply to both, some are 64-bit-mode-only) — see "Open question:
x86 mode applicability" below.

## `manifest.txt` format

Header lines first (`key:value`, one per line, matching
`asm/fixtures/corpus/*/manifest.txt`'s own header convention), then one
record line per mnemonic entry. Header:

```
schema-version:1
target:<target>
source:<riscv-opcodes|xed>
source-commit:<sha of asm/vendor/isa-data/<source>/upstream>
source-license:<SPDX id, e.g. BSD-3-Clause or Apache-2.0>
```

Record line, tab-separated fields, alphabetically-sorted by `mnemonic` then
`extension` for a stable diff:

```
mnemonic:<lowercase mnemonic as spelled by the source>	extension:<source's own extension/table identifier>	compcert-emitted:<yes|no|unknown>	gcc-emitted:<yes|no|unknown>	state:<undefined|opcode-defined|lowered|encoded|decoded|byte-checked|unknown>	deferral-reason:<free text, or ->	promotion-trigger:<free text, or ->
```

Field notes:

- `mnemonic` — the source's own spelling, lowercase. `riscv-opcodes` already
  lowercases; XED's `ICLASS:` lines are uppercase and must be lowercased on
  ingestion so RISC-V and x86 entries are directly comparable.
- `extension` — `riscv-opcodes`: the `extensions/<name>` filename verbatim
  (`rv_i`, `rv32_zbb`, `rv64_zba`, `rv_zicsr`, ...). XED: the
  `datafiles/<extension>/` directory name verbatim (`avx512f`, `avx-vnni`,
  `apx-f`, ...). Never renamed or normalized to this project's own
  vocabulary — a reviewer must be able to `grep` the source tree for the
  exact string.
- `$pseudo_op` lines in `riscv-opcodes` (a pseudo-instruction expressed as a
  macro over a real one, e.g. `zext.h.rv32` over `pack`) get their own
  record with the pseudo-mnemonic as `mnemonic` and the *defining*
  extension file's name as `extension` (not the extension of the
  instruction it expands to) — pseudo-instructions are still something this
  project's parser must accept as an assembler mnemonic.
- `deferral-reason`/`promotion-trigger` are `-` for any entry with
  `compcert-emitted:yes` or `gcc-emitted:yes` (never deferred — M5 already
  requires these), and required (non-`-`) for any entry with `state` other
  than `byte-checked`/`encoded`/`decoded`/`lowered`/`opcode-defined` once
  Phase B lands. While Phase B is unimplemented and the field reads
  `unknown`, `deferral-reason`/`promotion-trigger` stay `-` — an `unknown`
  is a tooling gap, not a deferral decision, and the two must not be
  conflated.

## `summary.txt` format

Plain counts, matching the shape of `asm/fixtures/corpus/*/summary.txt`:

```
target:<target>
total:<n>
by-extension:<extension>:<n>            # one line per extension, sorted
by-state:<state>:<n>                    # one line per state value, sorted
compcert-emitted:<n>
gcc-emitted:<n>
```

## Generation and the diff-gate

Once implemented, the generator is one more `asm/tools` subcommand
(`compcert-tools isa-inventory <regen|check>`, or per-source subcommands
`isa-inventory-riscv`/`isa-inventory-xed` if the two sources' ingestion
turns out not to share enough code to unify — decide this when writing the
generator, not here) following the same generate-then-diff-gate pattern
`tools-matrix`/`tools-matrix-diff` and `tools-oracle-diff`/
`tools-gasxref-diff` already establish in the root `Makefile`: `regen`
overwrites the checked-in files, `check` (or the diff-gate CI target)
requires `git status --porcelain` to come back empty against them, so the
inventory cannot silently drift from the vendored submodules' pinned
commits. Phase A generation needs only the two submodules and is safe to run
as part of `asm-ci`; Phase B's corpus-derived fields, once implemented, stay
on the toolchain-gated `*-oracle`/`*-regen` side of that split like every
other corpus artifact, with a toolchain-free `*-check` counterpart.

## Follow-up: sourcing Phase B

Concretely, Phase B needs `corpus_classify_cmd.ml`/
`corpus_classify_gcc_cmd.ml` (or a sibling) to additionally walk each
generated `.s` file's parsed AST — which the pipeline already builds, since
`classify-c-<target>` runs `--dump-source-ast` — and collect the set of
mnemonics used, publishing it as a new checked-in artifact (e.g.
`asm/fixtures/corpus/mnemonics/<target>.txt`, one mnemonic per line) rather
than reusing today's hash-only manifest. The `isa-inventory` generator would
then read that artifact the same toolchain-free way it reads the vendored
submodules. This is deliberately not attempted in this pass — see `next.md`.

## Open question: x86 mode applicability

XED's per-extension CPUID/ISA-set data (`cpuid.xed.txt`) records which
extensions require 64-bit mode, but not a clean `x86_32` vs. `x86_64` split
matching this project's own two x86 targets. Whether every XED entry should
be duplicated into both `x86_32`/`x86_64` manifests by default (with a
mode-restricted subset marked `state:undefined` and a fixed deferral reason
on `x86_32` where it is genuinely inapplicable, e.g. `apx-f`) or whether
mode applicability needs its own schema field is left for whoever writes the
x86 generator to decide against the real data, not speculated here.
