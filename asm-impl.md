# Review of assembler implementation at `3b93ae570811afa39306cdbd953f8a1c9150fab2`

## Verdict

**Changes requested.** The prior review's entry routing, buried ladder traversal,
padding disassembly, corpus discovery, and observation-export issues have been
addressed. The current revision still accepts and emits incorrect data and x86-64
instruction encodings, silently models NOBITS sections as initialized PROGBITS,
while its relocation oracle still falls short of the approved evidence contract.

## Findings

### P1 — Constant data initializers are silently truncated instead of range-checked

`asm/driver/pipeline.ml:276-295`

The constant path converts the expression to a signed `int64` and writes the low
`width` bytes. It never checks the declared `Bitpattern (width * 8)` range. As
a result, `.byte 256` becomes `00` and `.long 4294967296` becomes
`00 00 00 00` with no diagnostic. Conversely, a valid 64-bit bit pattern such
as `.quad 0xffffffffffffffff` is rejected because it does not fit signed
`int64`.

Validate constants against the same logical bit-pattern range used for fixups
before masking them into the container. Add boundary tests for each supported
width, including the accepted negative half, accepted unsigned half, and one
value immediately outside each end.

### P1 — The accepted x86-64 `mov r, imm` form emits and decodes invalid results

`asm/targets/x86_family/x86_family.ml:1596-1612`

This codec always emits a 32-bit immediate, even when `REX.W` selects a 64-bit
`B8+rd` instruction. For `movq $1, %rax; ret`, the assembler emits
`48 b8 01 00 00 00 c3`: hardware treats `B8` with `REX.W` as taking an
eight-byte immediate, so the following `ret` is consumed as immediate data and
the instruction stream is malformed.

The decoder also ignores `REX.B` when reconstructing the opcode-embedded
register. `movl $1, %r8d` emits `41 b8 01 00 00 00` but diagnostic
disassembly reports `movl $1, %eax`; canonical reassembly therefore loses the
REX prefix and is not byte-exact.

Use an imm64 field for the actual 64-bit form (or reject that form until
implemented), and include `REX.B` in the decoded register number. Add GNU byte
and canonical round-trip tests for both examples.

### P1 — NOBITS input is accepted and silently converted to initialized bytes

`asm/driver/directives.ml:24-35,87-95`

`section_of_args` still ignores the third `.section` argument, and the
shorthand `.bss` is normalized as an ordinary writable section. With the new
data lowering, this is now directly observable: `.bss; g:; .long 1` lowers to
a `.bss` segment containing `01 00 00 00`. Likewise,
`.section ..., "aw", @nobits` is treated as PROGBITS.

This contradicts both the approved plan and
`asm/docs/contracts.md:424-430`, which say that `.bss` and
`@nobits`/`%nobits` must be rejected with `lower.nobits-section` until M3.
Parse the section type, reject both spellings and the shorthand, and add the
required negative tests.

### P1 — x86 advertises symbolic `.quad` but has no 64-bit data fixup

`asm/targets/x86_family/x86_family.ml:2200-2212`,
`asm/lib/target_intf/target.ml:243`,
`asm/driver/pipeline.ml:297-325`

`data_widths` accepts `.quad`, but `data_fixup` accepts only four-byte
initializers. On x86-64, the ordinary pointer initializer `.quad g` therefore
fails with `lower.data: no absolute relocation for a 8-byte data initializer`.
The plan explicitly requires an x86-64 `Abs64` kind.

The target API also dropped the planned `modifier:string option` parameter, and
the generic lowering stores the original modified expression. This prevents a
target from selecting a data relocation from a modifier and returning the
unwrapped expression, which the ARM/AArch64 data paths will need. Restore that
contract while adding `Abs64`, and cover symbolic `.long` and `.quad`
initializers through binding and relocation observation.

### P1 — Relaxation's two-point probe does not prove section-relative invariance

`asm/lib/image/image.ml:195-230`

The previous absolute-target bug was changed to evaluate at bases zero and
`0x10000000`, then infer a coefficient of one from the difference. The
expression language contains multiplication, division, shifts, and bitwise
operators, so equality at two samples is not proof that the expression is affine.
For example, with a same-section symbol `s` at offset zero,
`s + s * (s - 0x10000000)` evaluates to zero at base zero and moves by exactly
the probe at the probe base, but it is not base-relative at any general bind
address. It can therefore select a short rung during planning that fails when
bound.

Replace sampling with a structural/affine analysis that proves the target is a
same-section location with base coefficient exactly one. Expressions that cannot
be proved must remain undecidable and select the longest rung. Add a nonlinear
regression using the literal probe value.

### P2 — Relocation classification is not driven by the measured oracle contract

`asm/test/differential/test_differential.ml:650-696,754-768`

The classifier is hardcoded in OCaml and accepts only `target`, `kind_name`,
`role`, `defined`, and `same_section`; it does not consume `binding` or
`visibility`. There are no checked-in `oracle/reloc-class.txt` artifacts.
Consequently a binding or visibility regression cannot independently change the
classification and fail the test as required by the approved O1 contract.

Additionally, `Non_normalizable` is appended to `problems` even though the
plan and the adjacent comment say it belongs solely to the post-link byte path.
Load the measured per-case classification artifacts, key the comparison by the
full semantic observation, and route non-normalizable expressions without
record-for-record failure.

## Verification performed

- `git diff --check` — passed.
- `make asm-test` — passed.
- `make asm-ci` from an isolated archive of the reviewed commit — passed.
- Focused CLI checks confirmed:
  - `.byte 256` and `.long 4294967296` silently become zero bytes;
  - x86-64 `.quad g` is rejected;
  - `.bss; g:; .long 1` becomes initialized bytes;
  - `movl $1, %r8d` decodes as `%eax`;
  - `movq $1, %rax` emits only four immediate bytes.
