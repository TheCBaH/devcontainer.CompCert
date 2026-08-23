# Status: Milestone 4 closed, Milestone 5 under way

Verified 2026-08-21/22 against HEAD `124c101` ("asm: CompCert runtime
helpers as ordinary fixture inputs") plus that session's own uncommitted
work (the M5 browser-harness item below, and one characterization-snapshot
fix — see "M4 follow-ups"). That work later landed (see `git log`: the
x86_64 `test/c/` corpus classify-c / SIB / SSE2 / octal-escape commits).
Canonical roadmap: `.ai/asm_plan.md` §12.

**2026-08-23 session (uncommitted at time of writing):** closed
corpus.md's own "actually assemble this corpus, not just parse it"
follow-up — see "Actually assembling the x86_64 corpus" below, under
Milestone 5.

This file follows the convention M3's closure established: an
"already done" section per milestone (do not re-derive), a follow-ups
section for scope decisions made along the way, and a "next milestone"
pointer. It supersedes any earlier, informally-numbered content this file
may have carried — the prior "next milestone" text some sessions referenced
(a CompCert `Asm.program` adapter) is canonical **Milestone 8**, not M4/M5;
its items 1-2 (multi-arch `compcert-lib`, the adapter itself) already landed
(commit `a3fedcf`) ahead of M4's close, as a deliberate resequencing.

## Milestone 4 — already done, do not re-derive

**Status: exit criterion met (2026-08-21).** All 9 bullets
(`.ai/asm_plan.md:2034-2058`) confirmed done by direct code inspection, and
the full verification checklist below passes clean.

| # | Bullet | Evidence |
|---|---|---|
| 1 | `plan_image`/`bind_image`, address validation, fixups, segment materialization, permissions | `asm/lib/image/image.ml:614` (`plan_image`), `:1275` (`bind_image`), validation `:1288-1325`, fixup patching `:1250`/`:1461`, segment materialization `:154-161`/`:1472-1484` |
| 2 | Browser-friendly manifest, no typed arrays/bigarrays, native/jsoo/melange equality | `asm/driver/portable.ml:224-248` (`bytes : string`); multi-segment (`.text`/`.data`/`.bss`) equality via `asm/test/cram/manifest_dump.t` + `asm/test/cram/dune`'s `ASM_BACKEND` indirection, run by `make asm-js-portable`/`asm-js` |
| 3 | Freestanding ABI-generator mode | `asm/test/oracle/abi_gen.ml`/`abi_gen_main.ml`/`abi_gen_text.ml`, invoked by `tools/asm-helpers.sh` |
| 4 | Result-block ABI (v3) adopted by selected tests | `global_ldst`, `i64_divmod` manifests: `abi-version: 3`/`expected-value:N`/`observation:N` (`asm/docs/exec-abi-v3.md`) |
| 5 | CompCert runtime helpers as ordinary fixture inputs | `asm/fixtures/compcert-3.17/i64_divmod/x86_32/{i64_sdiv,i64_smod,i64_udivmod}.s`, byte-verified vs. `modules/CompCert/runtime/x86_32/i64_*.S`, via `Corpus.Compiled`/`Preexisting` in `asm/tools/lib/corpus.ml` |
| 6 | QEMU generalized to multi-segment (RX/R/RW/zero-fill) | `asm/test/oracle/exec.ml:174-202` (`manifest_of_image`), exercised by `cross_data`/`cross_bss` on all six targets |
| 7 | External-executor protocol, separate subprocess | `asm/docs/exec-abi-v1.md`/`exec-abi-v3.md`; `asm/helpers/*`, `tools/asm-helpers.sh`; `asm/test/oracle/qemu_user.ml:240-256` (`fork`/`execvp`); `Makefile:559-561` states neither helper reachable from `asm-test`/`asm-ci` |
| 8 | Bounded opt-in QEMU trace | `asm/test/oracle/exec.ml:309-324` (`maybe_trace`, `ASM_QEMU_TRACE`); `qemu_user.ml:200-206` (`trace_cap = 64*1024`) |
| 9 | Expect tests: segment maps, entry/export, result-block | `asm/test/image/test_image.ml:785-798`, `asm/test/cram/manifest_dump.t`, `asm/test/oracle/test_record.ml:425-437` |

### End-to-end verification (2026-08-21/22, this session)

```
make asm-ci                    # full aggregate gate (fmt/build/test/purity/
                                # planted/melange-optin/js-portable/
                                # characterize/cross-smoke-selftest/...)
make asm-fixture-oracle        # all six targets - x86_32, x86_64, arm,
                                # aarch64, riscv32, riscv64
make asm-exec                  # 4 profiles x 10 cases, 0 blocked, 0 failures
                                # (includes asm-abi-conform as a prerequisite:
                                # v1/v2/v3 legs all pass)
make asm-js                    # native/jsoo/melange three-build equality
make asm-purity / asm-planted  # covered by asm-ci
(cd asm && opam exec -- dune runtest --force)   # clean
git diff --exit-code -- asm/fixtures/compcert-3.17   # clean, every target
```

All green. `riscv32`/`riscv64`'s Rocq/CompCert rebuild needed several
retries purely due to this sandbox's tight host memory (`cfrontend/
SimplExprproof.v` is a known memory-heavy proof file) — reducing
`COMPCERT_JOBS` and retrying succeeded; not a code issue, and unrelated to
any change in this session or in `124c101`.

## M4 follow-ups (scope decisions, recorded so they aren't re-litigated)

- **ABI v3 adoption is deliberately partial (option b scope)**: only
  `global_ldst` and the new `i64_divmod` fixture use ABI v3.
  `args_arith`/`direct_call`/`cond_select`/`loop` stay on v1, untouched.
- **RISC-V's v3 helper path exists but has no fixture using it**: the
  generator (`tools/asm-helpers.sh`'s `build_riscv 3`) and
  `asm-abi-conform`'s v3 leg already exercise it end-to-end. No RISC-V
  *fixture* was added under v3, matching M4's exit criterion, which is
  explicitly scoped to the four legacy profiles (x86-32, x86-64, ARM,
  AArch64) — RISC-V is a bonus, not a gap.
- **A stale characterization snapshot was found and fixed**: `124c101`
  landed the `i64_divmod` fixture (which enlarges the whole
  `asm/fixtures/compcert-3.17` tree `fixture-check-all` characterizes) but
  did not re-run `tools/dev/characterize.sh record`, so `make
  asm-characterize-verify` failed with 17 differing files against a stale
  snapshot. Fixed this session by re-running `characterize.sh record`;
  `asm/tools/test/data/characterization/**` now matches HEAD. This is a
  pure regeneration of committed test-fixture snapshots, not a behavior
  change.

## Milestone 5 — under way

`.ai/asm_plan.md:2060-2084`. Most of M5's bullets are open-ended, continuous
engineering practice applied as future corpus work proceeds (growing
instruction/directive coverage against the four generated CompCert corpora,
keeping the disassembler synced, tracking codec escape hatches, reviewing
generic-EDSL extensions) — not a single implementable feature, and not
started as a discrete task.

**The one fully scoped, self-contained deliverable — done this session**:

> "Add the deferred real-browser harness for the already validated in-memory
> API; run representative parser, encoder, linker, and multi-segment image
> fixtures without Node or POSIX polyfills."

Deferred since M0 (`.ai/asm_plan.md:1426-1465`, §11.6) "until the image APIs
and broader assembler slices have stabilized" — M4's close is that
stabilization point.

### What landed

- `asm/test/dump/smoke_fixtures.ml` (new library) — `manifest_dump.ml`'s
  multi-segment fixture and rendering logic, extracted into a real,
  importable library (an executable's modules cannot be linked by another
  executable) so both `manifest_dump.ml` and the new browser smoke harness
  consume the exact same source rather than a copy. `manifest_dump.t`'s
  cram baseline stayed byte-identical after the refactor (verified).
- `asm/test/browser/{smoke.ml,smoke_native.ml,smoke_jsoo.ml,dune,
  harness.html,run_harness.mjs,package.json}` (new) — one representative
  parser+encoder case (`Test_dump_inputs.x86_64`) and one representative
  linker+multi-segment-image case (`Smoke_fixtures`), combined into one
  short deterministic summary string, exercised through native OCaml,
  js_of_ocaml (`Js_of_ocaml.Js.export`, gated `js_of_ocaml`/
  `js_of_ocaml-ppx`), and Melange (compiled directly by `melange.emit`, no
  wrapping library — a module cannot belong to both a library stanza and a
  `melange.emit` stanza in the same file).
- `tools/asm-browser-harness.sh` (new) — provisions Playwright/Chromium at
  run time (never baked into `.devcontainer/Dockerfile`: no `COPY` in that
  build context, and a root-built image would put Chromium in a cache path
  the runtime user can't see), with `PLAYWRIGHT_BROWSERS_PATH` pinned
  repo-local (`.playwright-browsers/`) so install time and launch time
  agree by construction; builds the native/jsoo/Melange smoke artifacts by
  explicit Dune target (never alias closure); bundles the Melange CommonJS
  output into a browser-loadable IIFE via `esbuild` (done in the shell
  script, not a Dune rule — a Dune action's working directory is its own
  `_build` counterpart, not the repo root); stages all three artifacts plus
  a captured native baseline as siblings in a generated, gitignored
  `asm/test/browser/_work/` directory (the three build outputs live in
  three different `_build` trees and can't be referenced by relative
  `<script src>` paths otherwise); runs the Playwright driver.
- `harness.html` sets `document.title = 'PENDING'` and installs
  `window.onerror`/`unhandledrejection` handlers *before* loading either
  bundle, so a load-time or runtime exception produces a terminal `FAIL`
  instead of hanging; `run_harness.mjs` waits for a genuine terminal title
  (not merely non-empty) with a bounded 15s timeout, and captures
  console/page errors regardless of outcome.
- `Makefile`: new `asm-js-browser: asm-js` target (deliberately *not* also
  depending on `asm-melange` — the wrapper's own explicit
  `ASM_MELANGE=true dune build` step already covers what's needed, and a
  second overlapping `@all` build would only contend with `asm-js`'s own
  builds under `make -j`). Separate target, not a fourth `ASM_BACKEND` cram
  leg: the cram mechanism is built around one synchronous process's stdout
  diffed against a committed transcript, and a real browser run is a
  heavier async multi-step lifecycle the other cram files have no reason to
  acquire — same category of extra-environment-cost work as
  `asm-melange`/`asm-compcert-adapter-test`, which are likewise excluded
  from `asm-ci`/`asm-test`.
- `.github/workflows/asm.yml`'s `three-build` job: its `make asm-js` step
  was **replaced** with `make asm-js-browser` (not appended as a second
  step — `asm-js-browser` already depends on `asm-js`, so appending would
  repeat the whole three-build equality gate before ever launching
  Chromium).
- `.gitignore`: `.playwright-browsers/`, `asm/test/browser/node_modules/`,
  `asm/test/browser/_work/`.

### Verified this session (not just implemented)

- `make asm-js-browser` exits 0; the driver's printed `title`/`#result` show
  `PASS` — jsoo's and Melange's bundles both matched the captured native
  baseline inside a real headless-Chromium page.
- Melange's CommonJS `jsoo_exports`/module-export semantics were confirmed
  directly: `Js.export`'s target (`jsoo_exports = module.exports ||
  globalThis`) resolves to the *requiring module's own* `module.exports`
  under Node's `require`, not a real global — a naive `node -e` sanity
  check is the wrong tool for testing this; a `vm.createContext` sandbox
  with no `module` global (mimicking a browser `<script>` tag) confirmed the
  jsoo bundle correctly sets a true global there, matching what
  `harness.html`'s `<script src>` loading actually does.
- Three negative checks, run for real (not just described): (1) a corrupted
  baseline produces `FAIL: ... does not match native baseline` and exit 1;
  (2) a thrown exception inside a bundle's entry point produces `FAIL:
  exception: ...` in ~0.3s (not a 15s timeout) and exit 1; (3) a missing
  `<script>` tag (undefined global) likewise fails fast with a clear
  `TypeError` message. All three prove the pass/fail signal is load-bearing.
- `npm audit` on the pinned `playwright`/`esbuild` versions: 0
  vulnerabilities (bumped from an initial draft's pinned versions after
  `npm audit` flagged a Playwright browser-download SSL-verification
  advisory and an esbuild dev-server advisory — the latter doesn't apply to
  this one-shot CLI usage, but both were bumped to patched releases anyway
  since it was zero-cost).

### `corpus classify-c` — first corpus-growth increment (2026-08-22)

Landed `compcert-tools corpus classify-c`/`corpus check`
(`asm/tools/lib/corpus_classify_cmd.{ml,mli}`, `asm/docs/corpus.md`): compiles
CompCert's own `test/c/` suite (24 files) for x86_64 and classifies each
generated `.s` against this project's parser, publishing a checked-in,
independently checkable `asm/fixtures/corpus/c/x86_64/{manifest.txt,
summary.txt}`. `check` re-verifies source/shared-header hashes, the live
`modules/CompCert` HEAD (refusing a dirty checkout first), and both files'
canonical byte-for-byte rendering — all without a cross toolchain. All new
logic (parsing, rendering, publish/rollback across all four failure shapes,
dirty-checkout and revision-mismatch handling, the full `check` pipeline
against a fake repo) is covered by hermetic tests plus one integration test
against the real `asm.exe`; `dune build @tools/runtest` and `dune build
@all` are both clean.

**Also this session**: built the x86_64 fixture compiler
(`tools/compcert-fixture-setup.sh x86_64`, not the full `all` six-target
`asm-cross-setup` — this increment needs only x86_64) and ran
`make asm-corpus-classify-c-x86_64` for real. Committed
`asm/fixtures/corpus/c/x86_64/{manifest.txt,summary.txt}` and wired
`asm-corpus-check-c` into `asm-ci`. Result: **2 of 24 accepted, 22
rejected** — overwhelmingly `%xmm*` register operands ("unknown register")
and one unsupported memory-operand shape ("cannot parse operand"); see
`summary.txt` and `asm/docs/corpus.md`. This is real M5 corpus evidence, not
a tooling bug — triaging these 22 into concrete instruction/addressing-mode
work is the natural next corpus-growth step.

### x86: base-less scaled-index (SIB) memory operands — fixed this session (2026-08-22)

The 9 "cannot parse operand" rejections above were all one gap: AT&T
`disp(,index,scale)` — a SIB memory operand with no base register
(`leaq 0(,%rcx,8), %rdi`), GCC/CompCert's array-index address idiom. Not a
pure parser fix: `asm/targets/x86_family/x86_family.ml` gained three new
`parse_one_operand` cases (additive — `Mem.t.base` was already
`Reg.t option` and the pretty-printer already handled it), but
`asm/targets/x86_family/x86_family_encode.ml` needed a real encoder/decoder
fix — `disp_form_of` was picking `D_none`/`D_8` for a base-less operand
where real x86 requires a mandatory disp32 (SIB.base=101 + mod=00 is a
reserved escape), and no codec alternative existed to decode it; added
`sib-nobase-disp32`, modeled on the existing `disp32-norm` RIP-relative
alternative, prioritized ahead of the generic `sib-disp0`/`sib-disp8`/
`sib-disp32` forms to resolve the bit-pattern overlap. Also found and fixed,
as part of the same shared codec path, a **pre-existing** sign-extension bug
in `sym_disp`'s decode (`Fixup` carries no signedness of its own): a
negative disp32 was redisplaying as its unsigned 32-bit magnitude (e.g.
`4294967295` instead of `-1`) on both the new SIB form and the existing
RIP-relative one — bytes were always correct, only the disassembly text was
wrong. Fixed via `Codec.sign_extend`, covering both cases at once.

Verified: `dune build @all`/`dune runtest` green (including `Codec.check`'s
self-test and the promoted `asm/test/cram/asm_dump.t` codec-structure
baseline); byte-for-byte match against the real, installed
`x86_64-linux-gnu-as`/`objdump` for both corpus-evidenced snippets (checked
by hand, not yet a permanent differential fixture — see
`asm/docs/corpus.md`'s Follow-ups for why the existing `snippet_ast.ml`
corpus doesn't fit); `make asm-corpus-classify-c-x86_64` re-run for real,
**accepted count 2 → 7 of 24**, and the "cannot parse operand" reason is
gone from `summary.txt` entirely — some of the 9 previously-blocked files
now hit a *different*, real, previously-masked rejection instead (mostly
`%xmm*`), which is expected and correctly attributed by the fix's own scope.

### x86_64 `test/c/` corpus closed to 24/24 parse acceptance (2026-08-22)

Three fixes, closing every remaining rejection from the 7/24 baseline above:

- **A general octal string-escape** (`\NNN`, 1-3 digits, GAS's actual
  behavior confirmed against real `x86_64-linux-gnu-as`: greedy up to 3
  digits, stops at the first non-octal character, a value over `0o377`
  truncates to its low byte) in `asm/lib/asm_syntax/lexer.ml`'s
  `scan_string`, replacing the old special-cased `\0` branch. New
  `asm/test/lib/asm_syntax/{dune,test_lexer.ml}` — a lexer-level test
  library, since nothing downstream renders a decoded string's *content*
  (`Source_ast.pp` prints a directive's arguments from their source span,
  not the token payload), so this is the one place a wrong decoded byte
  would otherwise pass every corpus/expect test unnoticed.
- **`%r8b`-`%r15b`** (8-bit REX-extended sub-registers): one register-table
  line (`X86_family_encode.Reg.extended_regs 8 "b"` in
  `asm/targets/x86_64/x86_64_encode.ml`) — `reg_at`/ModR/M/REX.B selection
  already generalize by `(width, num)`, so no encoder logic changed.
  `aes.c` needed this *and* the octal-escape fix together: its
  `%r8b`/`%r9b`/`%r10b` uses sit past the line-18 lexer error that was
  masking them, exactly the kind of masking the SIB fix (above) already
  established as expected — re-running `classify-c` after each fix, not
  only once at the end, is what caught it.
- **A previously-undiscovered fourth parse gap**, found only by re-running
  `classify-c` after the first two fixes landed: `sha1.c`'s
  `leal -1894007588(%esi,%r10d,1), %eax` — a negative-displacement,
  base+index+scale SIB memory operand, the one shape
  `asm/docs/corpus.md`'s own Follow-ups had already flagged as "no existing
  parser pattern covers it... fix if and when a fixture needs it." One
  additive `parse_one_operand` case in `x86_family.ml`, mirroring the
  existing positive-displacement and base-less-negative-displacement cases.
- **`%xmm0`-`%xmm15` and the SSE2 scalar-float instruction family**
  (`addsd`/`subsd`/`mulsd`/`divsd`/`addss`/`subss`/`mulss`/`divss`/
  `comisd`/`comiss`/`xorpd`/`movapd`/`cvtsd2ss`/`cvtss2sd`/`movsd`/`movss`/
  `cvtsi2sd`/`cvtsi2ss`/`cvttsd2si`) — CompCert's x86_64 double/float
  codegen, the largest of the four and the reason this increment needed a
  design review (three rounds; two structural bugs the review caught before
  implementation: a self-contradictory single-alt/multi-prefix table
  design, and missing operand-class validation). Landed as:
  - `Reg.t` reused with `width = 128` as the xmm class marker (no parallel
    `Xmm` type) — `reg_at`/`retype`/`reg_field`/`rm_of` already key purely
    on `(width, num)`, so this is free.
  - Five new `Lowered.t` constructors (`Sse_binop_r_rm`, `Sse_mov_r_rm`,
    `Sse_mov_rm_r`, `Cvtsi2f_r_rm`, `Cvtf2i_r_rm`) and ~11 `C.alt` codec
    forms, grouped by mandatory-prefix byte (`F2`/`F3`/`66`/none) per alt —
    *not* one alt per mnemonic and *not* one alt spanning every mnemonic,
    since REX has to sit between the mandatory prefix and `0F` and a table
    whose selected prefix changes per entry can't express that.
    `prefixes_codec`/`prefixes_of` are untouched; the SSE path builds its
    own `asz, mandatory, REX, 0F, opcode, rm` sequence, reusing
    `prefixes_of`'s value computation for the `asz`/REX pieces.
  - Explicit operand-class validation in `lower_instruction` (a new
    `` `Sse_operand_class`` error, e.g. `addsd %eax, %xmm0` is rejected, not
    silently encoded as if `%eax` were `%xmm0`) and a parse-time rejection
    of an xmm register used as a memory base/index
    (`` `Xmm_in_memory_operand``, in `x86_family.ml` — protects every
    instruction with a memory operand, not only the new SSE ones).
  - Disassembler integration in `instruction_of_lowered` and
    `Instruction.pp`'s no-suffix group (these are fixed SSE mnemonics with
    no AT&T size suffix — GAS never writes `addsdl`).
  - Every encoding, including the `asz`+REX+mandatory-prefix ordering case
    (`movsd (%eax), %xmm8` → `67 f2 44 0f 10 00`) and a REX-extended xmm
    pair (`addsd %xmm8, %xmm9` → `f2 45 0f 58 c8`), was checked byte-for-byte
    against the real, installed `x86_64-linux-gnu-as`/`objdump` (binutils
    2.44) before being written into `x86_family_encode.ml`'s comments or
    `test/targets/test_targets.ml`'s expect blocks.

**Also this session**: discovered mid-implementation that the xmm
register-table addition alone already brought `classify-c` to 24/24, since
`--dump-source-ast` never reaches `simplify_instruction` (mnemonic validity
is a later-phase check) — confirmed by finding `movzbl`/`movslq`/`setl`/
`sete` already silently un-checked throughout this corpus. Surfaced this to
the user before building the full SSE encoder rather than assuming either
"stop, the number is already hit" or "build it anyway"; user chose to build
the full encoder, since SSE floating-point coverage is real, durable value
independent of this one corpus-classification number. `asm/docs/corpus.md`
now states this scope distinction explicitly (24/24 is parse-level only;
actually assembling this corpus needs `movzbl`/`movslq`/`setcc`/etc. and a
non-`--dump-source-ast` runner — a separate, larger follow-up, not started).

Verified: `dune build @all`/`dune runtest --force` green, including
`Codec.check`'s self-test on both x86_32 and x86_64 (`none` — no new
ambiguity) and the promoted `asm_dump.t`/`gas_frontier.t` cram baselines;
14 new `test/targets/test_targets.ml` expect tests (positive round-trips
per mandatory-prefix group, the `asz`+REX case, both `cvtsi2sd`/`cvttsd2si`
GPR widths, a RIP-relative binop memory operand, and three negative
operand-class tests) plus 7 new lexer expect tests, all promoted from real
tool output, not hand-typed; `make asm-fmt-check` clean. Re-ran
`compcert-tools corpus classify-c` for real (after building just the x86_64
fixture compiler, `tools/compcert-fixture-setup.sh x86_64`): **24 of 24
accepted, 0 rejected.** Committed the regenerated
`asm/fixtures/corpus/c/x86_64/{manifest.txt,summary.txt}`.

One real implementation pitfall worth recording for future codec work: a
classic OCaml `if cond then e1 else e2 @ e3` precedence trap — without
explicit parens around the whole `if`-expression, `@ e3` was parsed as part
of the `else` branch rather than as a sibling appended after it, silently
dropping 11 new alts from x86_64's codec (they were reachable only when
`M.rex_allowed = false`, i.e. never on x86_64) while `Codec.check` stayed
green throughout, because the alts were syntactically well-formed, just
absent from the list that mattered. Caught by comparing an `encode`-time
"which alts did this choice actually try" trace against the expected count,
not by any static check.

### Actually assembling the x86_64 corpus (2026-08-23)

Closed `asm/docs/corpus.md`'s own Follow-up: "actually assemble this
corpus, not just parse it." Ran the full `parse -> simplify -> lower ->
encode -> plan_image` pipeline (`asm.exe`'s default invocation, not
`--dump-source-ast`) over all 24 generated `.s` files from
`modules/CompCert/test/c/`, iteratively, fixing every real gap found:

- `.ascii`/`.asciz`/`.string` directives (`asm/driver/directives.ml` -
  target-independent, reuses `Directive.Data { width = 1; ... }` rather than
  a new constructor).
- An unsigned 64-bit `.quad` literal (`0x8000000000000000` and friends -
  `asm/driver/pipeline.ml`, `Bigint.to_uint64_opt` as a fallback where
  `to_int64_opt` rejects the bit pattern as too large for signed int64;
  target-independent).
- A 64-bit absolute data relocation, `Abs64`, for `.quad symbol`
  (`x86_family_encode.ml`'s `fixup_kind`/`data_fixup` - x86-64 only,
  `.quad`'s width-8 case was simply unimplemented before).
- `movzbl`/`movsbl`/`movslq` (zero-/sign-extending move: `0F B6/B7/BE/BF`
  plus `movslq`'s own `0x63`), `sete`/`setl`/etc. (`0F 90+cc`, ModR/M reg
  field fixed at 0), the general group-2 shift/rotate forms (`0xC1 ib` and
  `0xD3`, beyond M4's shift-by-1-only `0xD1`), `orl`/`orq`/`andq`/`xorq` in
  the operand shapes this corpus needs, TEST's own immediate form (`0xF7
  /0 id`), the two-operand `imul $imm,reg` form (`0x69`/`0x6B`).
- 8-bit register-to-register/register-to-memory `mov` (opcode `0x88`/`0x8A`
  - a genuinely different opcode byte from `0x89`/`0x8B`, not a width
    variant of them; removed the M1-era blanket rejection). This surfaced a
    real, previously-latent encoding bug while fixing it: `%spl`/`%bpl`/
    `%sil`/`%dil` need an *empty* REX prefix to be selected over the legacy
    `%ah`/`%ch`/`%dh`/`%bh` encoding this project's register table has no
    representation for at all, and `prefixes_of` was not forcing one -
    `movb %sil, 7(%rdi)` would previously have encoded as `%dh`, silently
    wrong, the moment 8-bit reg/mem mov was ever built. Fixed in the same
    `prefixes_of` change that added the two new opcodes.

Every new encoding was checked byte-for-byte against the real, installed
`x86_64-linux-gnu-as`/`objdump` (binutils) before being written down, most
now captured as permanent `test/targets/test_targets.ml` expect tests
(promoted from real tool output, not hand-typed) rather than only the
one-off manual checks the fix session used. `asm/docs/corpus.md` records
the full list and the still-open scope (a committed "assemble" manifest -
`classify-c`'s parse-only manifest was *not* extended to this stage, so
there is nothing yet that regenerates or CI-checks this result the way
`asm-corpus-check-c` does for parsing).

**Verified, not just implemented:** `dune build @all`/`dune runtest --force`
clean (including the promoted `asm_dump.t` codec-structure baseline and 8
new expect tests); `Codec.check` reports no ambiguity on x86_32 or x86_64;
`make asm-fixture-oracle-x86_64` and `-x86_32` (the full hand-picked-fixture
differential/QEMU-execution suite, unrelated to this corpus) both stayed
fully green with zero fixture drift (`git diff --exit-code -- asm/fixtures/
compcert-3.17` clean both times) - proving the new encoder paths did not
perturb any previously oracle-verified encoding; `make asm-purity
asm-planted` clean. Re-ran the full 24-file pipeline after every fix, not
only at the end. **Result: all 24 files now reach `plan_image` cleanly**;
the only remaining stops are `image.undefined` for libc functions
(`malloc`/`atoi`/`printf`/`cos`/`memcmp`/...) and CompCert-test-suite-file
externs (`i`/`p`/`data`/`arch_big_endian`) this single-TU corpus does not
also compile - both expected per `.ai/asm_plan.md` §2.2 (no libc) and the
narrow scope of `test/c/` alone (not the whole suite), not real gaps.

**Uncommitted at time of writing** — changed files: `asm/driver/
directives.ml`, `asm/driver/pipeline.ml`, `asm/targets/x86_family/
x86_family_encode.ml`, `asm/test/cram/asm_dump.t`, `asm/test/targets/
test_targets.ml`, `asm/docs/corpus.md`.

## Next

M5's remaining scope is corpus-growth work (grow instruction/directive
coverage against the four generated CompCert corpora, add relaxation/
veneers/literal pools only when a focused fixture exposes the need, keep
the disassembler synchronized, track codec escape hatches, generate and
classify the broader corpora with checked-in provenance manifests) —
continuous practice to apply as new corpus items are picked up, not a
second discrete deliverable. Point future planning at
`.ai/asm_plan.md:2065-2081` for the specific bullets.

Concrete next steps, per `asm/docs/corpus.md`'s Follow-ups (updated this
session):

- A committed "assemble" manifest/summary mirroring `classify-c`'s, with
  its own `corpus assemble-c` subcommand and a manifest format that
  distinguishes "blocked on an undefined external symbol" (expected) from a
  real encoding gap - the pipeline-level check itself is done (above), only
  the checked-in, CI-regenerable/re-verifiable artifact is still missing.
- A symbolic base-less-SIB displacement (parser-only, masked by an unrelated
  lexer error in `gas-xref`'s `helper-helper` fixture), a negative-
  displacement three-register SIB form (unevidenced, fix on demand), a
  permanent GNU-`as` differential fixture for the base-less-SIB and SSE
  forms (both currently hand-verified only, though the new M5 forms above
  now have expect-test coverage), and extending `classify-c` (and the new
  assemble-level check) to the other five targets and CompCert's other
  three test suites.
