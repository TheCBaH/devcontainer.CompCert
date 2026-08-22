# Status: Milestone 4 closed, Milestone 5 under way

Verified 2026-08-21/22 against HEAD `124c101` ("asm: CompCert runtime
helpers as ordinary fixture inputs") plus this session's own uncommitted
work (the M5 browser-harness item below, and one characterization-snapshot
fix — see "M4 follow-ups"). Canonical roadmap: `.ai/asm_plan.md` §12.

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

## Next

M5's remaining scope is corpus-growth work (grow instruction/directive
coverage against the four generated CompCert corpora, add relaxation/
veneers/literal pools only when a focused fixture exposes the need, keep
the disassembler synchronized, track codec escape hatches, generate and
classify the broader corpora with checked-in provenance manifests) —
continuous practice to apply as new corpus items are picked up, not a
second discrete deliverable. Point future planning at
`.ai/asm_plan.md:2065-2081` for the specific bullets.
