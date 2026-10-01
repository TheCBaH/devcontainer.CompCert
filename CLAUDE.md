# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository overview

This repo is the **CompCert extractor**: a devcontainer and build tooling that
configures, builds and proof-checks [CompCert](https://compcert.org/) (vendored
as the `modules/CompCert` submodule), and repackages its extracted OCaml sources
as a plain dune library or a redistributable archive, so that everything after
the extraction needs no Rocq. Its output is the set of release artifacts
described below; downstream projects consume only those, never this source tree.

CompCert itself is not free software (non-commercial use only — see
`modules/CompCert/LICENSE`); this repo's own `LICENSE` covers only the
devcontainer and build tooling, not `modules/CompCert`.

The retargetable assembler is no longer here. It lives in
[TheCBaH/rivet](https://github.com/TheCBaH/rivet), and its CompCert integration
in [TheCBaH/rivet-compcert](https://github.com/TheCBaH/rivet-compcert), which
pins this repo's release artifacts. The tag `pre-split` marks the last commit
that still held the assembler. Do not add assembler code here.

A fresh clone needs `git submodule update --init` (for `modules/CompCert`).

## Common commands

All of these need Rocq/opam, so run them in the devcontainer.

- `make compcert` — configure and build CompCert (proof + `ccomp`) for the
  native architecture.
- `make compcert-check-proof` — recheck the proof with `coqchk`/`rocqchk`.
- `make compcert-test` — run CompCert's own test suite.
- `make compcert-extraction-archive` then `make compcert-build-from-archive`
  — the Rocq-free split build: extract once (needs Rocq), then build `ccomp`
  from the archived sources alone (plain OCaml).
- `make compcert-lib-build` / `make compcert-lib-run ARGS=-version` — sync
  CompCert's sources into `compcert-lib/` (a standalone dune project, not
  committed) and build/run it as an ordinary OCaml library + driver.
- `make compcert-export-archive` / `make compcert-export-run ARGS=-version`
  — package `compcert-lib/` plus CompCert's `LICENSE` into
  `compcert-export.tar.gz`, buildable with just `dune build`, no clone or
  Rocq required.
- `tools/compcert-export-archive-all.sh <target>` — the per-target export
  tarball (see below), for one of `x86_32 x86_64 arm aarch64 riscv32 riscv64`.
- `tools/compcert-cross-smoke.sh [<target>|all]` — build CompCert as a cross
  compiler and run `test/cross-smoke/hello.c` under QEMU; a target whose
  compiler or emulator is missing is skipped, not failed.
- `make compcert-cross-smoke-selftest` — assert that script's OK/FAIL/SKIP
  reporting without building anything (needs the x86_32 cross gcc and
  `qemu-i386`).

## Architecture

- `modules/CompCert` is the vendored upstream submodule; nothing there should
  be treated as part of this repo's own tooling.
- `compcert-lib/` and `compcert-export/` are generated/synced trees (not
  committed — see `.gitignore`), rebuilt from CompCert's extracted sources via
  `tools/modorder`'s link order. The set of files copied is exactly what
  CompCert links into `ccomp`, not everything under CompCert's source
  directories (some of which don't even build under dune, e.g. stale `.mli`s for
  long-removed code).
- `driver/Driver.ml` (CompCert's CLI entry point) is excluded from the
  library and copied to `bin/main.ml`, so the library is just the compiler,
  with the CLI kept separate. The per-target export library is `compcert_<t>`
  and is `(wrapped false)`.
- `tools/compcert-targets.sh` is the hand-owned target table (configure target,
  toolchain prefix, QEMU binary and sysroot, extra `ccomp` arguments). It is
  the single place the scripts read targets from.

### The artifact contract

A release tag `v<compcert-version>-<n>` (`-rc<k>` for a prerelease) publishes
`compcert-export-<t>.tar.gz` and `compcert-asm-<t>.tar.gz` for each of the six
targets, plus `SHA256SUMS` and `artifacts.json`. This is the **only** interface
to CompCert for other repos, and it is why the files in the tarballs must be
real files: `v3.17-1` shipped absolute symlinks into this tree and had to be
replaced by `v3.17-2`.

- The export tarball is a dune project (`compcert_<t>` library, `ccomp` driver)
  with a portable `compcert.ini`, the runtime sources and headers, `LICENSE`, a
  `MANIFEST` (CompCert revision, configure line, tool versions, hash of every
  file) and `install.sh`.
- The asm tarball is `ccomp -S` output for CompCert's own test programs:
  `sources/`, `asm/`, `results/` and a `manifest.txt` with source and generated
  hashes. `ccomp` writes its command line into each `.s`, so the invocation
  paths are part of the bytes (`tools/compcert-asm-corpus.sh` fixes them).

### Verification (`.github/workflows/artifacts.yml`)

Per target, independent of any assembler: `extract` (the only job with Rocq)
builds the export tarball; `verify` removes Rocq, unpacks, builds, checks
`ccomp -version`, builds the runtime, compiles and runs `hello.c` and every
`test/c` program under QEMU against CompCert's `Results/`, generates the asm
corpus, and assembles every generated `.s` with the cross binutils; `index`
writes `SHA256SUMS` and `artifacts.json`. `release.yml` calls it on `v*` tags and
uploads the 14 assets. Changing the tarball contents means cutting a new tag;
consumers pin the tag and every hash.

Other workflows: `build.yml` (CompCert build, proof check, tests, cross-smoke,
its tri-state self-test), `compcert-split.yml` (the Rocq-free split build),
`images.yml` (the devcontainer image).

## Commit messages

- Keep commit messages concise and to the point: a short summary line, plus only the detail actually needed to understand the change.
- Never reference files, paths, or documents that are not tracked in this repository (e.g. scratch notes, local-only files, untracked working directories).

## Code comments

- Never reference files, paths, or documents that are not tracked in this repository. Comments must make sense to anyone who clones the repo, not just to someone with access to your local working tree.
