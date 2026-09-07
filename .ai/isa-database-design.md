Investigation and proposed ISA database boundary — 2026-09-05.

**Recommendation:** build an independent ISA database producer with separate
source adapters and one versioned, form-oriented artifact format. Use LLVM
for assembler syntax, operands, aliases, and feature predicates across the
six profiles; retain XED for detailed x86 forms and riscv-opcodes for RISC-V
encodings; use QEMU as complementary decoder and execution evidence.
CompCert's assembler repository should consume a pinned artifact and attach
its own implementation/corpus/verification results. A mnemonic inventory
should be a generated view of that database.

This follows up [the sourcing survey](isa-inventory-sources.md) and audits
the implementation described in [the inventory schema](../asm/docs/isa-inventory.md).
It is an investigation and implementation plan, not a new generator or a
change to the existing manifest contract. No upstream repository is added
as a project dependency by this investigation.

The distinction between source coverage and architectural completeness is
essential: LLVM, XED, and QEMU describe their respective implementations and
configurations. Their union is a useful reference universe; their agreement
is evidence. Neither constitutes a complete normative ISA specification or
a proof of instruction semantics. Similarly, assembler acceptance, decoder
recognition, and execution support are three different claims.

The inspected revisions and experiments are reproducible:

| Source | Revision | Work performed |
|---|---|---|
| Vendored XED | `0bcb6237345c5066726dcc08b3d87928df3b5b26` | Read current importer, data, upstream reader/build configuration, and manifests |
| Vendored riscv-opcodes | `7afd3dc8772909d8c94ceeb208467cff93896396` | Read importer and upstream parser; extracted `sh1add` with upstream code |
| LLVM current checkout | `3efd20d463e1b1210d2ff07cd79b68d6fa215f24` | Shallow/sparse clone; inspected TableGen schema, JSON emitter, matcher, and all four target directories |
| LLVM 19.1.7 | `cd708029e0b2869e80abe31ddb175f7c35361f90` | Shallow tag fetch and sparse temporary worktree; actual matched-version ARM JSON extraction |
| QEMU | `ff1d2d19d7e24893e2012d879f8e73077e17b9bd` | Shallow/sparse clone; ran upstream decoder generator over all 21 ARM/RISC-V decode files; inspected x86 tables and C feature guards |

Temporary material lives under `/tmp/isa-sources.0b0fWr` for this session.
The report's source links point to persistent repository paths or pinned
upstream revisions, so its conclusions do not depend on that directory
surviving. Existing uncommitted XED/CI work was already present, and further
XED edits appeared during the investigation; the observations below distinguish
the initial snapshot from the subsequent mode-filter correction.

**What the current XED import actually does.** The call chain is
[`compcert_tools.ml`](../asm/tools/bin/compcert_tools.ml) →
[`Isa_inventory_cmd.regen`](../asm/tools/lib/isa_inventory_cmd.ml) →
[`Isa_inventory_xed.entries_for_target`](../asm/tools/lib/isa_inventory_xed.ml).
`Repo.isa_data_xed` points to the vendored checkout's `datafiles/` directory.
The command obtains the checkout's `HEAD`, generates each target, rejects an
empty result, and writes `manifest.txt` and `summary.txt`.

The working-tree importer reads root `.txt` files as synthetic extension
`base`, then recursively reads `.txt` files under each top-level directory.
Nested `amd/amdxop` remains grouped under `amd`. A brace-delimited block
with an `ICLASS` contributes a lowercased name. Blocks can contain multiple
`PATTERN` lines; applicability is ORed over those lines, then over blocks
sharing the same `(mnemonic, extension)`. Operand forms are discarded.
No-pattern blocks default to both modes. Directory names, not XED's
`EXTENSION` or `ISA_SET` fields, become manifest extensions.

The two importers already share an output format and regeneration plumbing.
Their source-specific entry types and parsers remain separate. Thus the
comments saying the ingestion formats could not be unified are not an
obstacle to a common database: retain separate parsers, unify their output
model and validation. The current shared command record is a small existing
example of that separation.

Schema version 1 is a per-target text file, with five `key:value` header
lines and tab-separated records:

```text
schema-version:1
target:x86_64
source:xed
source-commit:0bcb6237345c5066726dcc08b3d87928df3b5b26
source-license:Apache-2.0
```

Each row has `mnemonic`, `extension`, `compcert-emitted`, `gcc-emitted`,
`state`, `deferral-reason`, and `promotion-trigger`. Rows are sorted by
mnemonic and extension. The first two fields are generated; emitted/state
fields are `unknown`, and the last two are `-`. Summary counts are grouped
by extension and state. Its emitted counts of zero mean there are zero
known-positive rows, not that the compilers emit no instructions.
The contract is documented in [isa-inventory.md](../asm/docs/isa-inventory.md);
there is no independent machine-readable schema validator for these rows.

At the start of inspection, the working-tree artifacts contained:

| Profile | Rows | Distinct source names |
|---|---:|---:|
| x86_32 | 2,493 | 1,815 |
| x86_64 | 2,788 | 1,982 |
| riscv32 | 974 | Not measured separately |
| riscv64 | 1,017 | Not measured separately |

These are `(name, source-group)` counts, not encoding-form counts. ARM and
AArch64 have no current inventory generator. RISC-V ignores `$import`
relations, includes `$pseudo_op` names, excludes `unratified/`, and filters
files by `rv_`, `rv32_`, or `rv64_` prefixes. Those choices define its actual
coverage boundary; they should be explicit selection policy in a future
database rather than disappear during normalization.

At final reinspection, the concurrent XED mode correction had reduced x86_64
to 2,781 rows / 1,975 distinct names by removing the seven invalid legacy-only
entries discussed below; x86_32 remained unchanged.

The current use is a reproducibility check. In the root
[`Makefile`](../Makefile), `tools-isa-inventory` builds the tool and regenerates
the artifacts, and `tools-isa-inventory-diff` requires a clean Git status for
their directory. It is included in `asm-ci`, and the working-tree
[`asm.yml`](../.github/workflows/asm.yml) also invokes it. It does not test
architectural completeness: a consistently wrong parser and its checked-in
output can pass this gate. A dirty upstream checkout can also be labeled
with its unchanged `HEAD`, because the generator records the commit without
checking upstream cleanliness.

There is no inventory-reading path in `asm/targets`, the production codec,
or the codec test library. The assembler's OCaml targets still define their
own parsing, lowering, encoding, and decoding. Its
[`Target_encode.TARGET`](../asm/lib/target_intf/target_encode.ml) boundary
already distinguishes `Surface`, `Instruction`, and `Lowered`; a database
consumer should respect that distinction. GNU byte comparison and QEMU
execution belong to the separate
[fixture-oracle pipeline](../asm/docs/fixture-oracle.md). Corpus emission and
implementation-state joins described as Phase B have not been implemented.

Several XED findings affect the new schema and adapter:

- **Source grouping is not an ISA feature.** In root `xed-isa.txt`, 628
  blocks say `EXTENSION: BASE`, but 600 others use 18 different extension
  labels, including SSE2 (149), X87 (136), MMX (90), and SSE (62). All are
  currently grouped as `base`. Preserve the path/group as provenance, and
  separately preserve `EXTENSION`, `ISA_SET`, and CPUID requirements.
  XED's reader defaults an absent `ISA_SET` to `EXTENSION`; follow upstream
  evaluation rather than inventing directory-based feature inference.
- **Mode is a constraint, not absence of a token.** The initial importer
  overlooked `mode16`/`mode32` and incorrectly included `bound`, `popa`,
  `popad`, `popfd`, `pusha`, `pushad`, and `pushfd` under x86_64. The source
  defines `mode16 = MODE=0`, `mode32 = MODE=1`, `mode64 = MODE=2`, and
  `not64 = MODE!=2`. During this investigation, the working tree gained
  the corresponding exclusion and a PUSHA regression test; that correction
  is existing concurrent work, not an edit made by this report. A future
  adapter should evaluate explicit mode constraints per form, including
  the distinction between execution mode and effective address/operand size.
- **ICLASS is not a complete assembly spelling.** Names such as `REP_MOVSB`
  or `MOV_CR` identify XED classes. GNU/LLVM spellings, prefixes, suffixes,
  and aliases need their own syntax records. Lowercasing does not establish
  an equivalence between dialects.
- **Scanning all text is not evaluating an XED build.** Selection through
  `files.cfg`, state macros, continuations, compound pattern/operand forms,
  `UDELETE`, and version replacement are handled by upstream tooling. The
  current coarse importer explicitly does not honor `UDELETE`. Retaining
  unknown restrictions is preferable to defaulting them to supported.

These observations come from the pinned
[XED data](../asm/vendor/isa-data/xed/upstream/datafiles/xed-isa.txt),
[mode definitions](../asm/vendor/isa-data/xed/upstream/datafiles/xed-state-bits.txt),
[upstream reader](../asm/vendor/isa-data/xed/upstream/pysrc/read_xed_db.py), and
[build configuration handling](../asm/vendor/isa-data/xed/upstream/xed_mbuild.py).
The exact source syntax should remain confined to the XED adapter.

For a stronger XED adapter, drive the pinned upstream input-aggregation path
and use `pysrc/gen_setup.py` / `read_xed_db.xed_reader_t` on its
`all-dec-instructions.txt`, `all-state.txt`, width/type, map, and CPUID inputs.
This reader expands compound records into forms and generates missing
IFORMs. Preserve ICLASS, IFORM/UNAME where available, operand access and
visibility, attributes, modes, and the evaluated pattern. Pin the mbuild
dependency and generation options too. The reader is an internal API, so
wrap it behind adapter tests and compare counts against upstream output;
do not declare it a permanently stable interchange format. This path was
inspected, not run through a complete XED generation during this investigation.

**LLVM's useful import boundary is evaluated TableGen records.** Parsing
`.td` with regular expressions loses class inheritance, `multiclass`/`defm`
expansion, conditional definitions, and computed values. Use a matching
`llvm-tblgen --dump-json` first. Its JSON has an explicit version and class
index, references and DAGs, unresolved values, bit arrays, and source
locations. A record such as ARM `ADDri` includes both the template and
instantiation locations, which is useful provenance.
See the [JSON backend documentation](https://llvm.org/docs/TableGen/BackEnds.html#json-reference)
and the inspected [JSON emitter](https://github.com/llvm/llvm-project/blob/3efd20d463e1b1210d2ff07cd79b68d6fa215f24/llvm/lib/TableGen/JSONBackend.cpp).

Import at least the following record categories, rather than treating every
`Instruction` record as an accepted source instruction:

| LLVM records/data | Database use |
|---|---|
| `Instruction`, `InstructionEncoding`, alternate encodings | Source forms, encoding descriptions, sizes, decoder namespaces and hooks |
| `AsmString`, operand DAGs, tied/implicit operands, operand classes | Syntax templates and form operand model |
| `InstAlias`, `MnemonicAlias`, relevant `TokenAlias` | Explicit syntax/alias relations, predicates, and dialect restrictions |
| `Predicate`, `AssemblerPredicate`, `SubtargetFeature` | Source feature identities, assembler requirement expressions, implication edges |
| `isPseudo`, `isCodeGenOnly`, `isAsmParserOnly` | Separate internal pseudos, assembler pseudos, and concrete forms |
| Parser/encoder/decoder method names | Evidence that part of the record needs target-specific procedural handling |

The [target schema](https://github.com/llvm/llvm-project/blob/3efd20d463e1b1210d2ff07cd79b68d6fa215f24/llvm/include/llvm/Target/Target.td)
explicitly distinguishes codegen-only encodings from parser-only pseudos.
The [assembler matcher](https://github.com/llvm/llvm-project/blob/3efd20d463e1b1210d2ff07cd79b68d6fa215f24/llvm/utils/TableGen/AsmMatcherEmitter.cpp)
filters codegen-only records, selects dialects, validates syntax, and also
processes aliases. Follow that behavior for an assembler-coverage view;
do not simply drop every `isPseudo` record or equate the first token of
`AsmString` with a literal mnemonic. For example, the extracted ARM template
contains condition/flag substitutions, and x86 supports syntax variants.
Handwritten `AsmParser` handling still means TableGen alone is not the full
acceptance language; record that limitation and validate syntax with `llvm-mc`.

`Predicates` is also used for instruction selection. Keep those source facts,
but derive assembler feature requirements from predicates marked for the
assembler and their `AssemblerCondDag`. Preserve `all_of`, `any_of`, and
negation; follow feature implications with cycle checking. Non-assembler
predicates and arbitrary C++ conditions must not become guessed CPU features.
Keep hardware requirements, mode restrictions, compiler-selection preferences,
and runtime validity checks in separate fields or constraint contexts.

Current RISC-V definitions provide a useful example: `SH1ADD` inherits
`HasStdExtZba`, while `SH1ADD_UW` additionally requires RV64. Other bitmanip
forms use an alternative requirement, Zbb **or** Zbkb. Retain those formulas,
including source-native identifiers and version data when provided, rather
than reducing them to one extension string.
See [RISCVInstrInfoZb.td](https://github.com/llvm/llvm-project/blob/3efd20d463e1b1210d2ff07cd79b68d6fa215f24/llvm/lib/Target/RISCV/RISCVInstrInfoZb.td)
and [RISCVFeatures.td](https://github.com/llvm/llvm-project/blob/3efd20d463e1b1210d2ff07cd79b68d6fa215f24/llvm/lib/Target/RISCV/RISCVFeatures.td).

Encoding normalization needs architecture adapters inside the LLVM adapter.
Fixed-width `Inst` bits can supply fixed masks and operand bit references;
JSON bit arrays are least-significant-bit first. Preserve unresolved bits
and transforms. Do not equate array length with instruction length: the
actual ARM `tADDi8` extraction has a 32-element `Inst` but `Size = 2`.
Thumb halfword ordering and instruction byte order need explicit tests.
LLVM x86 instead carries opcode, map, form, prefix, REX/VEX/EVEX and operand
encoding information; a single fixed-width mask cannot represent that ISA.
See [X86InstrFormats.td](https://github.com/llvm/llvm-project/blob/3efd20d463e1b1210d2ff07cd79b68d6fa215f24/llvm/lib/Target/X86/X86InstrFormats.td).

Actual LLVM extraction results put useful limits on the proposal:

- No TableGen executable was initially installed. Debian LLVM 19.1.7 packages
  were downloaded and extracted only into the temporary directory.
- That executable rejected the current LLVM checkout at the newer
  `!listflatten` operator. A source SHA plus an arbitrary system TableGen is
  not a reproducible build recipe.
- With matching `llvmorg-19.1.7` sources, a full ARM JSON dump succeeded:
  56,035,518 bytes; 4,496 `Instruction` records, 833 `InstAlias`, 164
  `MnemonicAlias`, 226 `SubtargetFeature`, and 110 `Predicate` records.
  There are 3,681 non-codegen records with nonempty assembly strings; that
  deliberately simple diagnostic filter is not an assembler acceptance count.
  The process used approximately 2.35 GiB maximum RSS.
- The matched full RISC-V JSON attempt was killed with signal 9, and the
  environment's OOM-kill counter recorded a kill. No RISC-V JSON result was
  produced. Full AArch64 and x86 JSON extraction was not attempted afterward.

Start the prototype with JSON on one target at a time, cache the dumps, and
budget memory in producer CI. If the measured full-target costs remain too
high, add a small pinned TableGen backend that emits only relevant records
and their dependency closure, incrementally. This avoids constructing the
generic emitter's complete JSON object, though TableGen still needs memory
to parse and evaluate records. This is a measured reason for a later backend,
not a reason to build a second TableGen parser or silently omit vector/pseudo
definitions to make extraction smaller.

**QEMU's useful import boundary is the decodetree parser's resolved model.**
The inspected generator has no JSON-output mode, but its Python objects
already carry file/line, width, fixed mask/value, undefined and field masks,
formats, arguments, and field-extraction expressions. A thin version-pinned
exporter can use those objects after normal validation. Use one subprocess
per decoder invocation because the script has mutable module globals.
Preserve the group tree as well as the flat pattern list.
See [decodetree.py](https://github.com/qemu/qemu/blob/ff1d2d19d7e24893e2012d879f8e73077e17b9bd/scripts/decodetree.py).

Use [ARM's Meson decoder invocations](https://github.com/qemu/qemu/blob/ff1d2d19d7e24893e2012d879f8e73077e17b9bd/target/arm/tcg/meson.build)
and [RISC-V's invocations](https://github.com/qemu/qemu/blob/ff1d2d19d7e24893e2012d879f8e73077e17b9bd/target/riscv/meson.build)
as the explicit file/width/dispatch manifest. `t16.decode` and
`insn16.decode` use 16 bits; the other inspected files use 32. ARM includes
unconditional, shared NEON, and no-coprocessor files beyond the original
survey's list; RISC-V includes four vendor decoder files in addition to
`insn16`/`insn32`. File presence alone does not establish applicability to
one of this project's profiles.

The upstream generator successfully validated all 21 files, exposing 5,264
pattern records. Selected counts illustrate why names must not be primary keys:

| File | Patterns | Distinct translator names |
|---|---:|---:|
| `a32.decode` | 266 | 245 |
| `a64.decode` | 1,161 | 732 |
| `t16.decode` | 87 | 69 |
| `t32.decode` | 310 | 259 |
| `sve.decode` | 947 | 821 |
| `sme.decode` | 651 | 376 |
| `sme-fa64.decode` | 16 | 2 |
| `insn16.decode` | 77 | 56 |
| `insn32.decode` | 802 | 800 |

These counts include decoder specializations and control/catchall handling;
they are not counts of architectural instructions. A QEMU name denotes a
translator entry point, can recur with different layouts, and may cover
multiple operand sizes or instructions. Never lowercase it and assume an
assembler mnemonic, or replace every underscore with a dot.

Preserve ordered overlap groups: after a matching pattern's translator
returns false, the decoder can try another pattern. Preserve field
concatenation, sign extension, constants, context parameters, and
`!function` references. A fixed-mask match is only a necessary bit test when
translator checks remain. The [decodetree specification](https://www.qemu.org/docs/master/devel/decodetree.html)
defines both field transformations and fallback behavior.

Feature tagging cannot be inferred from file names. For example,
`sve.decode` contains forms guarded by SVE2/SME alternatives in
[`translate-sve.c`](https://github.com/qemu/qemu/blob/ff1d2d19d7e24893e2012d879f8e73077e17b9bd/target/arm/tcg/translate-sve.c).
RISC-V's `sh1add` guard comes from macro-generated translator functions with
`REQUIRE_ZBA` in
[`trans_rvb.c.inc`](https://github.com/qemu/qemu/blob/ff1d2d19d7e24893e2012d879f8e73077e17b9bd/target/riscv/tcg/insn_trans/trans_rvb.c.inc),
not its decode line. Dispatch may impose additional mode/context checks.
In a first adapter, export these handler/guard references and mark unresolved
requirements explicitly. Normalize a tested subset of guard macros and
their definitions; a C AST/preprocessor pass can improve coverage later,
but cannot automatically turn arbitrary C control flow into a complete
architectural specification.

QEMU x86 is more useful than the original survey suggests. The current
[`decode-new.h`](https://github.com/qemu/qemu/blob/ff1d2d19d7e24893e2012d879f8e73077e17b9bd/target/i386/tcg/decode-new.h)
defines `X86OpEntry` with operand kinds/sizes, feature, prefix and validity
fields. [`decode-new.c.inc`](https://github.com/qemu/qemu/blob/ff1d2d19d7e24893e2012d879f8e73077e17b9bd/target/i386/tcg/decode-new.c.inc)
contains opcode tables and `X86_OP_ENTRY*` / `cpuid(...)` macros alongside
procedural group decoders and unconverted entries. It still is not
decodetree. Defer this adapter until XED+LLVM x86 works; then use a focused
preprocessed/AST or instrumented-table exporter that retains procedural gaps.
QEMU x86 execution remains independently useful before any table import.

Two cross-source experiments establish a concrete normalization target:

| Form | Extracted result | Implication |
|---|---|---|
| RISC-V `sh1add` | Both vendored riscv-opcodes' parser and QEMU's parser yield mask `0xfe00707f`, value `0x20002033`; QEMU fields are `rd[11:7]`, `rs1[19:15]`, `rs2[24:20]` | A simple fixed-width join can be mechanical; feature/mode claims remain separately sourced |
| A32 add immediate | LLVM 19 `ADDri` and current QEMU `ADD_rri` both yield mask `0x0fe00000`, value `0x02800000` | Matching masks are candidate evidence, not sufficient equivalence: LLVM presents `mod_imm`, while QEMU exposes `imm8` and a rotation transform |
| A64 `ADD_i` | Two QEMU records have mask `0x7fc00000`, values `0x11000000` and `0x11400000`; the latter uses `shl_12` on the immediate | The same translator name must retain both patterns and different operand transformations |

These are parser/data comparisons, not execution checks. The A32 comparison
intentionally spans an older LLVM release and current QEMU, with revisions
recorded above; it does not claim complete agreement between those releases.

**The proposed common contract should preserve facts before reconciling them.**
Use canonical JSON Lines files validated by JSON Schema, with an optional
derived SQLite database for querying. JSON Lines permits streaming, stable
reviewable diffs, and consumption from OCaml without exposing any upstream
parser. SQLite is a convenience artifact, not the canonical byte identity.
Give this artifact its own schema name/version; do not reinterpret existing
`manifest.txt` schema version 1 in place.

The minimal logical entities are:

| Entity | Required purpose/data |
|---|---|
| Source snapshot | Repository URL, commit, selected inputs and hashes, build options, adapter/producer revision, tool identity, file license notices, declared omissions |
| Source record | Source-qualified identity, record kind, native name, path/locations, raw reference or payload hash, extracted facts and unresolved constructs |
| Instruction form | Architecture, execution state, width/XLEN constraints, operands, encoding variant, applicability expression, references supporting each claim |
| Syntax or alias | Dialect, mnemonic/template, operand arrangement, prefix/suffix rules, target form(s), operand mapping or expansion, conditions |
| Feature | Native namespace/id/version, optional reviewed canonical mapping, implication and incompatibility relations |
| Relationship | Alias-of, expands-to, specializes, equivalent-encoding, overlaps, or conflicting claim; mapping evidence and resolution status |
| Extraction diagnostics | Input/read/emitted/rejected counts, unsupported constructs, missing guards, unmatched records, and coverage boundary |

A QEMU decoder pattern is a source record even when its mapping to one or
more architectural forms is unresolved. An LLVM internal pseudo also remains
a source record, but does not inflate concrete-instruction counts. Keep
one-to-many and many-to-one relationships. Name equality is only a candidate
join; a reviewed form mapping must account for mode, size, encoding,
operand constraints/transforms, and feature requirements. Do not drop
disagreements or interpret absence from an incomplete source as unsupported.

Use source-qualified IDs for source entities and separate stable canonical
IDs for reconciled forms. Keep snapshot revisions separate from logical
identity. Named TableGen records are good native IDs; anonymous TableGen
numbers and line numbers are not stable across updates. Derive anonymous
identities from semantic content and maintain explicit migration mappings
where identities change. QEMU IDs need file/decoder plus pattern identity
and a disambiguator; the translator name alone demonstrably collides.

Requirements need a typed expression such as `all`, `any`, `not`, feature,
mode/XLEN comparison, operand constraint, and `opaque` source expression.
Evaluation is three-valued: true, false, unknown. An empty known requirement
means unconditional; an unknown requirement must never mean unconditional.
Represent an OR of complete form conditions when producing a mnemonic view,
not a bag of features that accidentally requires all alternatives at once.

Architecture metadata must separate x86 execution mode from address and
operand size, ARM A32/T32/A64 state from profile labels, and RISC-V XLEN from
encoding width. Explicit instruction-byte serialization is separate from
abstract bit numbering and data endianness. Keep privileged/context-dependent
forms in the reference universe with their restrictions; profile projections
decide which are applicable.

An encoding is a tagged union: initially `fixed_bits`, `x86_encoding`, or
`opaque`. For fixed bits, specify width, mask/value, field fragments,
signedness, transformations, and additional validity constraints. For x86,
retain structured maps/prefixes/opcodes/ModRM/immediates as the adapter learns
them; otherwise retain a source-native expression with explicit partial
coverage. Do not force all sources into a 32-bit mask or promise to synthesize
encoders from opaque descriptions. Use hexadecimal strings for wide masks and
values so JavaScript/JSON number precision cannot corrupt them.

For example, a proposed QEMU source record could carry the following shape
(illustrative schema design, not an artifact produced by an implemented adapter):

```json
{
  "record_id": "qemu:riscv:insn32:sh1add",
  "kind": "decode-pattern",
  "snapshot": "qemu@ff1d2d19d7e24893e2012d879f8e73077e17b9bd",
  "origin": {"path": "target/riscv/insn32.decode", "line": 768},
  "native_name": "sh1add",
  "architecture": "riscv",
  "encoding": {
    "kind": "fixed_bits",
    "width_bits": 32,
    "mask": "0xfe00707f",
    "value": "0x20002033",
    "fields": [
      {"name": "rd", "lsb": 7, "width": 5},
      {"name": "rs1", "lsb": 15, "width": 5},
      {"name": "rs2", "lsb": 20, "width": 5}
    ]
  },
  "applicability": {"kind": "opaque", "source_ref": "trans_sh1add"},
  "extraction": {"bits": "complete", "applicability": "unresolved"}
}
```

Even though source inspection identifies `REQUIRE_ZBA`, a decode-only adapter
must not claim to have resolved the complete translator/dispatch conditions.
A later guard adapter can add a sourced feature claim. A canonical relation
can connect this record to riscv-opcodes and LLVM records without rewriting
their source-native facts.

CompCert-/gcc-emitted, implementation status, deferral reason, promotion
trigger, and project test results should live in a **consumer-owned overlay**,
keyed to artifact form/syntax IDs and an artifact digest. They are not ISA
facts and should not make the independent database specific to this assembler.
Prefer separate capability/evidence dimensions for parsed, lowered, encoded,
decoded, byte-compared, and executed; a single linear state loses information.
Corpus observations also need compiler version/options, target profile,
corpus identity, form/operand evidence where possible, and test provenance.
Absence from a measured corpus means “not observed in that corpus,” not
“this compiler never emits it.”

The standalone producer can begin with the following layout:

```text
isa-db/
  schema/                   # JSON Schema plus semantic invariants
  sources.lock.json          # source SHAs, selections, tools, adapter versions
  adapters/{xed,llvm,qemu,riscv_opcodes}/
  normalize/                # typed facts, expressions, encodings, diagnostics
  mappings/                 # reviewed aliases/features/forms, with provenance
  tests/                    # upstream fixtures and real cross-source cases
  export/                   # deterministic JSONL; optional SQLite and reports
  dist/                     # release manifest, records, relations, notices
```

Python is a practical initial choice for the producer because QEMU, XED,
and riscv-opcodes expose Python tooling and LLVM already emits JSON. The
artifact contract, not the producer language, should be the consumer boundary.
A small LLVM C++ backend can be confined to that adapter if memory measurements
justify it. Production assembler libraries should not acquire those build
dependencies.

The release manifest should hash every data file and identify the source
lock, producer, schema, mapping policy, extraction limitations, and tool
configuration. Sort records deterministically; strip temporary path prefixes;
keep wall-clock timestamps out of content identity; normalize archive metadata.
Check clean pinned source trees or record actual input hashes. Source/tool
updates should produce a review report covering additions/removals, changed
constraints, alias changes, and unresolved mappings, not just a new row count.

License provenance needs more granularity than today's single header. The
inspected LLVM files say `Apache-2.0 WITH LLVM-exception`; XED uses Apache-2.0.
QEMU is mixed: `scripts/decodetree.py` and `target/arm/tcg/a64.decode` have
LGPL-2.1-or-later notices, while `target/riscv/insn32.decode` has a
GPL-2.0-or-later notice. Preserve per-input notices and identify adapter code
separately from data provenance. The survey's blanket “GPLv2” and its claim
that reference-only consumption settles redistribution should not be used
as the artifact's licensing model. This records source notices, not a legal
conclusion about the license of generated data.

The consumer change should be small: pin an artifact version and SHA-256,
validate it, generate the familiar target inventory views, then join the
local overlay. During migration, retain a compatibility exporter for the
existing version-1 shape, including legacy source grouping, and review
deliberate corrections separately. Do not squeeze several independent source
snapshots into its single `source`/`source-commit` header. A new multi-source
view must use its own versioned contract.

Fetching/building upstream sources belongs to producer release/update CI.
This repository's ordinary check should use committed or pre-fetched pinned
artifact data and work offline, validating digests, schema, joins, and generated
views. Cross compilers, GNU tools, `llvm-mc`, and QEMU belong to the existing
toolchain-gated regeneration/execution path. Keep the artifact required in
the same tool/test dependency boundary as today's inventory, not in the
production assembler build. Remove source submodules only after all current
consumers have migrated.

The artifact can then strengthen verification in distinct steps:

1. Check coverage against a declared profile and source universe, reporting
   mapped concrete forms, aliases, unresolved mappings, and explicit deferrals.
   A recognized mnemonic must not imply that every operand form is implemented.
2. Generate constrained operand-boundary cases for supported fixed-width
   forms, including register limits, immediate ranges/alignment, implicit
   operands, and applicable mode/feature combinations. Keep unresolved forms
   visible with a reason they cannot yet generate tests.
3. Assemble concrete syntax with this assembler and GNU/LLVM; compare bytes
   only after fixing encoding choices or accounting for equivalent encodings,
   relaxation, relocations, and aliases. Check external decode of emitted bytes
   and local decode of independently generated bytes. A local round trip alone
   permits a shared encoder/decoder bug.
4. Exercise selected nonprivileged forms in the existing QEMU harness with
   explicit CPU features and observable results. A decoder match does not
   establish runtime acceptance, and runtime acceptance does not establish
   correct results. Keep instruction execution and exception evidence distinct.
5. Record evidence with artifact/form ID, concrete operands, bytes, mode,
   tool versions, and outcome. Changes to a form or its constraints invalidate
   the appropriate evidence. This extends differential testing; it does not
   extend CompCert's existing formal theorem automatically.

Build the producer incrementally, with concrete acceptance criteria:

1. Freeze a small schema and source lock around real examples: XED PUSHA and
   a multi-form vector instruction; LLVM ARM `ADDri` and aliases; QEMU A64
   `ADD_i`'s two encodings; RISC-V `sh1add`, its RV64 `.uw` relative, `nop`,
   and an imported extension relation. Preserve unknowns and typed relations.
   Acceptance: all four adapters can describe these examples without loss
   being hidden by mnemonic deduplication.
2. Extract XED and riscv-opcodes into source records and produce a compatibility
   view. Honor upstream evaluation and record intentional differences from
   current manifests. Add regression checks for source traversal, mode
   filtering, feature tags, deletions, pseudo/import relations, and form counts.
3. Complete LLVM ARM/AArch64 syntax/feature imports and QEMU ARM decoder export.
   Start with ARM, whose full JSON extraction succeeded here. Preserve QEMU
   overlap/dispatch information and unresolved gates. Acceptance: exact
   reproducibility, input accounting, and reviewed cross-source form mappings.
4. Complete LLVM RISC-V and x86, selecting a filtered backend if full JSON
   exceeds CI resources; retain their architecture-specific encoding models.
   QEMU RISC-V is a cheap additional decoder source. Defer QEMU x86 table
   extraction until a concrete verification gap justifies its extra complexity.
5. Publish the first pinned database artifact from the independent project,
   add a consumer/import check here, and reproduce existing inventory views.
   Acceptance: ordinary repository CI requires no upstream clones or TableGen;
   producer CI proves repeatable output and validates referential integrity.
6. Add corpus/form and implementation overlays, then generated differential
   tests through existing oracle gates. Acceptance: an intentionally planted
   mode, operand-width, or encoding error produces an independent failure;
   unknown/unsupported evidence never silently counts as verified coverage.

The following commands show the extraction boundary, including a correction
to the survey's sparse recipe: LLVM needs shared include definitions such as
`llvm/TableGen/SearchableTable.td`, not just the target directories. Use a
fresh temporary directory; substitute the revisions above or a reviewed
`sources.lock.json` update for the placeholders in an automated producer.

```sh
isa_work=$(mktemp -d /tmp/isa-db-investigation.XXXXXX)
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/llvm/llvm-project.git "$isa_work/llvm-project"
git -C "$isa_work/llvm-project" sparse-checkout set \
  llvm/include llvm/lib/Target/X86 llvm/lib/Target/ARM \
  llvm/lib/Target/AArch64 llvm/lib/Target/RISCV \
  llvm/lib/TableGen llvm/utils/TableGen
git -C "$isa_work/llvm-project" rev-parse HEAD

git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/qemu/qemu.git "$isa_work/qemu"
git -C "$isa_work/qemu" sparse-checkout set \
  scripts target/arm target/riscv target/i386 tests/decode docs/devel
git -C "$isa_work/qemu" rev-parse HEAD

# Requires a TableGen binary matched to the checked-out source revision.
cd "$isa_work/llvm-project"
llvm-tblgen --dump-json -I llvm/include -I llvm/lib/Target/ARM \
  llvm/lib/Target/ARM/ARM.td -o "$isa_work/ARM.json"

# Upstream QEMU validation/generation, with no QEMU binary build required.
python3 "$isa_work/qemu/scripts/decodetree.py" --output-null \
  "$isa_work/qemu/target/arm/tcg/a64.decode"
python3 "$isa_work/qemu/scripts/decodetree.py" --output-null -w 16 \
  "$isa_work/qemu/target/riscv/insn16.decode"
```

These are inspection commands that resolve current heads, not a release
recipe: the producer must fetch/check out and verify exact locked commits.
The sparse source recipe is sufficient for a matching existing TableGen
binary; building TableGen itself needs its CMake/support dependencies as well.
The actual initial current-LLVM sparse checkout occupied about 106 MiB and
QEMU about 20 MiB. Additional LLVM headers, the shallow release tag, and the
release worktree increased temporary usage. Full-history monorepo estimates
in the original survey are not useful estimates for this workflow.

For reproducible decoder-model inspection, this minimal Python probe uses
the pinned upstream script. Run it in a fresh process per input. It is a
diagnostic prototype, not the proposed complete exporter: in particular it
does not serialize the overlap tree, fields, or translator guards.

```python
import importlib.util
import sys
from pathlib import Path

qemu = Path(sys.argv[1])
decode_file = Path(sys.argv[2])
width = int(sys.argv[3])
spec = importlib.util.spec_from_file_location(
    "decodetree", qemu / "scripts/decodetree.py"
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
sys.argv = ["decodetree", "--output-null", "-w", str(width), str(decode_file)]
try:
    module.main()
except SystemExit as result:
    if result.code != 0:
        raise
for pattern in module.allpatterns:
    print(pattern.name, pattern.file, pattern.lineno, pattern.width,
          hex(pattern.fixedmask), hex(pattern.fixedbits))
```

Validation in this investigation consisted of source tracing, successful
QEMU upstream generation for all 21 inputs, matched LLVM ARM extraction,
and the two cross-source mask comparisons above. No production assembler
code was changed by this work, no inventory regeneration was run over the
user's working files, and no full project test suite or whole-ISA semantic
verification is claimed.
