# Devcontainer for CompCert

[![CompCert devcontainer build](https://github.com/TheCBaH/devcontainer.CompCert/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/TheCBaH/devcontainer.CompCert/actions/workflows/build.yml)

Devcontainer to build and check [CompCert](https://compcert.org/), the
formally-verified C compiler, vendored here as the `modules/CompCert`
submodule, using [Rocq](https://rocq-prover.org/) (formerly Coq). It is also
the **extractor**: it turns CompCert into release artifacts that need no Rocq,
which downstream projects consume.

CompCert is not free software; this non-commercial distribution may only be used
for evaluation, research, educational and personal purposes. See
[modules/CompCert/LICENSE](modules/CompCert/LICENSE) for details. This repo's
own [LICENSE](LICENSE) covers only the devcontainer and build tooling.

## Get started
* [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=1323060576)
* Then, inside the devcontainer:
  * `make compcert` configure and build CompCert (proof + `ccomp`) for the
    native architecture
  * `make compcert-check-proof` recheck the proof with `coqchk`/`rocqchk`
  * `make compcert-test` run the CompCert test suite

List of OCaml/opam packages (including Rocq and Menhir) installed by the
devcontainer is located in
[.devcontainer/devcontainer.json](.devcontainer/devcontainer.json).

## Release artifacts
A release tag `v<compcert-version>-<n>` (for example `v3.17-2`; `-rc<k>` marks a
prerelease) publishes, for each of the six targets `x86_32`, `x86_64`, `arm`,
`aarch64`, `riscv32` and `riscv64`:

* `compcert-export-<target>.tar.gz` - CompCert's extracted OCaml as a dune
  project (library `compcert_<target>`, `ccomp` driver), a portable
  `compcert.ini`, the runtime sources and headers, `LICENSE`, a `MANIFEST` and
  `install.sh`. Building it needs OCaml, dune and Menhir, and no Rocq.
* `compcert-asm-<target>.tar.gz` - the assembly `ccomp` emits for CompCert's own
  test programs, with their sources and a `manifest.txt` of hashes.

plus `SHA256SUMS` and `artifacts.json` (CompCert revision, targets, versions).
Consumers pin the tag and every hash and verify them before use. Starting from a
release, `ccomp` for one target is:

```sh
tar xzf compcert-export-aarch64.tar.gz -C export && export/install.sh "$PWD/install"
```

[TheCBaH/rivet-compcert](https://github.com/TheCBaH/rivet-compcert) is the
consumer: it pins these artifacts in `compcert.lock` and uses them to test the
[rivet](https://github.com/TheCBaH/rivet) assembler against CompCert's output.

### Verification
`.github/workflows/artifacts.yml` runs per target, independent of any assembler:
extract (the only job with Rocq), then, in a job without Rocq, build the export,
check `ccomp -version`, build the runtime, compile and run every `test/c`
program under QEMU against CompCert's expected results, generate the assembly
corpus, run the cross GNU `as` over it, and publish. `release.yml` reuses it on
`v*` tags and uploads the 14 assets. `pre-split` tags the tree from before the
assembler moved out.

## Rocq-free split build
Rocq is only needed to check the proof and extract OCaml sources from it;
building `ccomp` from those sources is plain OCaml.

* `make compcert-extraction-archive` prove and extract, then archive the
  extracted sources into `compcert-extraction.tar.gz` - the only step that
  needs Rocq
* `make compcert-build-from-archive` build `ccomp` from that archive alone

## CompCert as a dune library
`compcert-lib/` is a standalone dune project that builds the same sources as a
regular OCaml library (`compcert`), so CompCert can be depended on like any
other library. `ccomp`'s CLI entry point, `driver/Driver.ml`, is kept out of the
library as `bin/main.ml`.

* `make compcert-lib-build` sync the sources into `compcert-lib/` (not
  committed) and build them with dune
* `make compcert-lib-run ARGS=-version` run the dune-built driver

## Redistributable package
For consumers who just want to `dune build` CompCert as a library, without
cloning this repo or touching Rocq:

* `make compcert-export-archive` package that dune project plus CompCert's own
  `LICENSE` into `compcert-export.tar.gz`
* `make compcert-export-run ARGS=-version` build and run the unpacked archive

The per-target tarballs above are built from the same sources by
`tools/compcert-export-archive-all.sh <target>`.

## Cross-compilation smoke test
`tools/compcert-cross-smoke.sh [<target>|all]` builds and installs CompCert as a
cross compiler for each target, then compiles, links and runs
`test/cross-smoke/hello.c` under QEMU, skipping targets whose compiler or
emulator is absent. `make compcert-cross-smoke-selftest`
asserts its OK/FAIL/SKIP reporting without building anything.

## Where the assembler went
The retargetable assembler that used to live in `asm/` is now
[TheCBaH/rivet](https://github.com/TheCBaH/rivet), and its CompCert integration
is [TheCBaH/rivet-compcert](https://github.com/TheCBaH/rivet-compcert). The
history of both starts from this repository; the last commit that still holds
the assembler is tagged `pre-split`.
