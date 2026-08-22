# Small Plan: Install and Smoke-Test CompCert as a Cross Compiler

## Goal

This document covers the libc-backed cross-smoke suite, which deliberately uses
four Linux profiles. The assembler itself supports six profiles: x86-32, x86-64,
ARMv7-A, AArch64, RISC-V 32-bit, and RISC-V 64-bit. The two RISC-V profiles use
the freestanding fixture-oracle workflow because their CompCert configurations
are built without the runtime library or standard headers; see
`asm/docs/fixture-oracle.md` and `asm/docs/riscv-inventory.md`.

Build and install the four libc-capable Linux CompCert configurations on an
x86-64 host, then compile, link, and execute one Hello-World-style CompCert
suite test:

| Target | Configure target | Execution |
|---|---|---|
| x86-32 | `x86_32-linux` | `qemu-i386` |
| x86-64 | `x86_64-linux` | `qemu-x86_64` |
| ARMv7 hard-float | `arm-linux`, with `-marm` in the test | `qemu-arm` |
| AArch64 | `aarch64-linux` | `qemu-aarch64` |

One configured `ccomp` is target-specific, so each matrix entry needs an isolated
build and installation directory. The same scripts must run locally and in GitHub
Actions.

## Smoke test

Add a dedicated case under `modules/CompCert/test/cross-smoke/`:

```c
#include <stdio.h>

int main(void)
{
  puts("Hello from CompCert cross compilation!");
  return 0;
}
```

Store the exact expected stdout in `Results/hello`. This deliberately uses libc:
the purpose is to verify the complete cross workflow—preprocessing, CompCert code
generation, target assembly, linking, guest dynamic loader, and QEMU execution.

For each target, the smoke script must:

1. Run the installed `ccomp -version`.
2. Compile and link `hello.c` with `-v`, adding `-marm` for ARM, and retain the
   external-tool command log.
3. Inspect `readelf -h hello.compcert` and check the expected machine type.
4. Execute it through QEMU user mode with a 10-second timeout.
5. Compare stdout byte-for-byte with `Results/hello` and require exit status 0.
6. Save the generated `.s`, executable, configuration, command log, stdout, and
   stderr as diagnostic artifacts.

QEMU must be invoked even for x86-32 and x86-64 so CI exercises one explicit
execution path rather than depending on host binary-format behavior.

## Packages

Use one container or CI job per target to avoid conflicts between multilib and
cross-GCC packages.

| Target | Debian/Ubuntu packages | QEMU prefix |
|---|---|---|
| x86-32 | `gcc-multilib libc6-dev-i386 qemu-user` | `/` |
| x86-64 | `gcc libc6-dev qemu-user` | `/` |
| ARM | `gcc-arm-linux-gnueabihf libc6-dev-armhf-cross qemu-user` | `/usr/arm-linux-gnueabihf` |
| AArch64 | `gcc-aarch64-linux-gnu libc6-dev-arm64-cross qemu-user` | `/usr/aarch64-linux-gnu` |

Common build dependencies are the CompCert-supported Rocq/Coq and OCaml versions,
Menhir/MenhirLib, OPAM/findlib as required by the chosen environment, and GNU
Make. Prefer the repository devcontainer or the same pinned OCaml/Rocq container
in both local and CI use.

## Build and install driver

Add one project-owned entry point, for example:

```text
tools/compcert-cross-smoke.sh <x86_32|x86_64|arm|aarch64>
```

It should create target-isolated paths under a configurable work root:

```text
<work>/build/<target>/
<work>/install/<target>/
<work>/artifacts/<target>/
```

Use `modules/CompCert/tools/linkhier` or another non-copying isolated source tree.
Configure as follows:

```text
x86_32:  ./configure -prefix <install>/x86_32 x86_32-linux
x86_64:  ./configure -prefix <install>/x86_64 x86_64-linux
arm:     ./configure -prefix <install>/arm \
             -toolprefix arm-linux-gnueabihf- arm-linux
aarch64: ./configure -prefix <install>/aarch64 \
             -toolprefix aarch64-linux-gnu- aarch64-linux
```

Run `make -j<N> all` followed by `make install`; keep the CompCert runtime library
enabled so installation and the normal link policy are tested. Invoke `ccomp`
from `<install>/<target>/bin`, not from the build tree.

The execution commands are:

```text
timeout 10s qemu-i386    -L / <artifacts>/hello.compcert
timeout 10s qemu-x86_64  -L / <artifacts>/hello.compcert
timeout 10s qemu-arm     -L /usr/arm-linux-gnueabihf <artifacts>/hello.compcert
timeout 10s qemu-aarch64 -L /usr/aarch64-linux-gnu <artifacts>/hello.compcert
```

The actual script should use argument arrays rather than evaluating these lines as
shell text.

## GitHub Actions

Add a root workflow with:

- `push`, `pull_request`, and manual dispatch triggers.
- An Ubuntu matrix over `x86_32`, `x86_64`, `arm`, and `aarch64`.
- `fail-fast: false`, so one target failure does not hide the others.
- The repository's pinned devcontainer/OCaml/Rocq environment.
- A target-specific dependency-install step.
- The same `tools/compcert-cross-smoke.sh <target>` command used locally.
- Artifact upload on failure, and preferably always during initial bring-up.

Do not begin with shared build caches: establish reproducibility first. Add OPAM
or compiled-proof caches later with keys containing the CompCert revision, target,
OCaml/Rocq versions, and dependency lock state.

## Verification criteria

The libc cross-smoke test is complete when, locally and in GitHub Actions:

- All four CompCert configurations build and install independently.
- Each installed configuration invokes the expected prefixed external tools.
- `readelf` reports the intended architecture for every executable.
- Every executable is run through the intended QEMU binary and sysroot.
- All four runs exit 0 and exactly match `Results/hello`.
- A deliberate output mismatch, invalid QEMU prefix, and compile failure are
  reported as failures with useful retained artifacts.

This is not the assembler support matrix: the six-profile freestanding
fixture-oracle gate is the authoritative coverage gate for assembler targets.

CompCert's existing `tools/runner.sh` should be treated as the reference for
package names, configure targets, tool prefixes, and QEMU `-L` paths. The official
cross-compilation requirements are documented at:
<https://compcert.org/man/manual002.html>.
