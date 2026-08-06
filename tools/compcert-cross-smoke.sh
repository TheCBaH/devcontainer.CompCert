#!/usr/bin/env bash
# Build, install, and smoke-test CompCert as a cross compiler for each of
# x86_32, x86_64, arm, and aarch64: an isolated configure+build+install per
# target, then compile+link+run test/cross-smoke/hello.c under QEMU user
# mode and check its output against test/cross-smoke/Results/hello.
#
# Usage: tools/compcert-cross-smoke.sh [x86_32|x86_64|arm|aarch64|all]
# (default: all). Every target is attempted even if an earlier one fails;
# the script exits non-zero at the end if any did. A target whose
# cross-compiler package isn't installed on this host is skipped rather
# than failed (see .devcontainer/Dockerfile). Work root defaults to
# <repo>/.cross-smoke-work, override with the CROSS_SMOKE_WORK env var.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
COMPCERT_DIR="$REPO_ROOT/modules/CompCert"
JOBS=$(nproc)
WORK_ROOT="${CROSS_SMOKE_WORK:-$REPO_ROOT/.cross-smoke-work}"
SMOKE_SRC="$REPO_ROOT/test/cross-smoke/hello.c"
SMOKE_EXPECTED="$REPO_ROOT/test/cross-smoke/Results/hello"
ALL_TARGETS=(x86_32 x86_64 arm aarch64)

Fatal() {
  echo "FATAL: $*" 1>&2
  exit 1
}

# Distinct exit code so the caller can tell "this target's toolchain isn't
# installed on this host" apart from an actual build/test failure. Debian
# only builds the *-linux-gnu cross-gcc packages from amd64/arm64/i386
# hosts (see .devcontainer/Dockerfile); an armhf host only has
# gcc-arm-linux-gnueabihf, so the other 3 targets are skipped there rather
# than failed.
SkipTarget() {
  echo "SKIP: $*" 1>&2
  exit 2
}

usage() {
  echo "Usage: $0 [x86_32|x86_64|arm|aarch64|all]" 1>&2
}

Opam() {
  if command -v opam >/dev/null 2>&1; then
    opam exec -- "$@"
  else
    "$@"
  fi
}

# Sets CONFIGURE_TARGET, TOOLPREFIX, QEMU_BIN, QEMU_SYSROOT,
# CCOMP_EXTRA_ARGS, READELF_MACHINE for the given target. Every target,
# including x86_32/x86_64, uses its own dedicated "*-linux-gnu-" cross-gcc
# package (see .devcontainer/Dockerfile) rather than the host's native gcc:
# gcc-multilib conflicts at the package level with the arm/aarch64
# cross-gcc packages on Debian, and using cross packages uniformly also
# keeps this table valid no matter which architecture the container itself
# runs on.
target_config() {
  CONFIGURE_TARGET=""
  TOOLPREFIX=""
  QEMU_BIN=""
  QEMU_SYSROOT=""
  CCOMP_EXTRA_ARGS=()
  READELF_MACHINE=""
  case "$1" in
    x86_32)
      CONFIGURE_TARGET="x86_32-linux"
      TOOLPREFIX="i686-linux-gnu-"
      QEMU_BIN="qemu-i386"
      QEMU_SYSROOT="/usr/i686-linux-gnu"
      READELF_MACHINE="Intel 80386"
      ;;
    x86_64)
      CONFIGURE_TARGET="x86_64-linux"
      TOOLPREFIX="x86_64-linux-gnu-"
      QEMU_BIN="qemu-x86_64"
      QEMU_SYSROOT="/usr/x86_64-linux-gnu"
      READELF_MACHINE="Advanced Micro Devices X86-64"
      ;;
    arm)
      CONFIGURE_TARGET="arm-linux"
      TOOLPREFIX="arm-linux-gnueabihf-"
      QEMU_BIN="qemu-arm"
      QEMU_SYSROOT="/usr/arm-linux-gnueabihf"
      CCOMP_EXTRA_ARGS=(-marm)
      READELF_MACHINE="ARM"
      ;;
    aarch64)
      CONFIGURE_TARGET="aarch64-linux"
      TOOLPREFIX="aarch64-linux-gnu-"
      QEMU_BIN="qemu-aarch64"
      QEMU_SYSROOT="/usr/aarch64-linux-gnu"
      READELF_MACHINE="AArch64"
      ;;
    *)
      usage
      Fatal "unknown target '$1'"
      ;;
  esac
}

run_target() {
  local TARGET="$1"
  target_config "$TARGET"

  if ! command -v "${TOOLPREFIX}gcc" >/dev/null 2>&1; then
    SkipTarget "${TOOLPREFIX}gcc not installed (no $TARGET cross-compiler package for this host architecture)"
  fi

  local BUILD_DIR="$WORK_ROOT/build/$TARGET"
  local INSTALL_DIR="$WORK_ROOT/install/$TARGET"
  local ARTIFACTS_DIR="$WORK_ROOT/artifacts/$TARGET"

  echo "== [$TARGET] cleaning isolated work directories =="
  rm -rf "$BUILD_DIR" "$INSTALL_DIR" "$ARTIFACTS_DIR"
  mkdir -p "$INSTALL_DIR" "$ARTIFACTS_DIR"

  echo "== [$TARGET] mirroring CompCert source tree (linkhier) =="
  (cd "$COMPCERT_DIR" && ./tools/linkhier "$BUILD_DIR")

  echo "== [$TARGET] linking in cross-smoke test case =="
  mkdir -p "$BUILD_DIR/test/cross-smoke/Results"
  ln -sf "$SMOKE_SRC" "$BUILD_DIR/test/cross-smoke/hello.c"
  ln -sf "$SMOKE_EXPECTED" "$BUILD_DIR/test/cross-smoke/Results/hello"

  echo "== [$TARGET] configuring =="
  local configure_args=(-prefix "$INSTALL_DIR" -toolprefix "$TOOLPREFIX" "$CONFIGURE_TARGET")
  ( cd "$BUILD_DIR" && Opam ./configure "${configure_args[@]}" )

  echo "== [$TARGET] building (make -j$JOBS all) =="
  ( cd "$BUILD_DIR" && Opam make -j"$JOBS" all )

  echo "== [$TARGET] installing =="
  ( cd "$BUILD_DIR" && Opam make install )
  cp "$BUILD_DIR/Makefile.config" "$ARTIFACTS_DIR/Makefile.config"

  local CCOMP="$INSTALL_DIR/bin/ccomp"
  [ -x "$CCOMP" ] || Fatal "installed ccomp not found at $CCOMP"

  echo "== [$TARGET] ccomp -version =="
  "$CCOMP" -version | tee "$ARTIFACTS_DIR/ccomp-version.txt"

  echo "== [$TARGET] compiling and linking hello.c =="
  local COMMAND_LOG="$ARTIFACTS_DIR/command.log"
  local asm_cmd=("$CCOMP" "${CCOMP_EXTRA_ARGS[@]}" -S -o "$ARTIFACTS_DIR/hello.s" "$BUILD_DIR/test/cross-smoke/hello.c")
  local link_cmd=("$CCOMP" "${CCOMP_EXTRA_ARGS[@]}" -v -o "$ARTIFACTS_DIR/hello.compcert" "$BUILD_DIR/test/cross-smoke/hello.c")
  {
    echo "+ ${asm_cmd[*]}"
    "${asm_cmd[@]}"
    echo "+ ${link_cmd[*]}"
    "${link_cmd[@]}"
  } >"$COMMAND_LOG" 2>&1 || { cat "$COMMAND_LOG" 1>&2; Fatal "compile/link failed, see $COMMAND_LOG"; }
  cat "$COMMAND_LOG"

  local EXE="$ARTIFACTS_DIR/hello.compcert"
  [ -x "$EXE" ] || Fatal "expected executable missing: $EXE"

  echo "== [$TARGET] checking ELF machine type =="
  readelf -h "$EXE" >"$ARTIFACTS_DIR/readelf.txt"
  local actual_machine
  actual_machine=$(sed -n 's/^ *Machine: *//p' "$ARTIFACTS_DIR/readelf.txt")
  if [ "$actual_machine" != "$READELF_MACHINE" ]; then
    cat "$ARTIFACTS_DIR/readelf.txt" 1>&2
    Fatal "expected ELF machine '$READELF_MACHINE', got '$actual_machine'"
  fi
  echo "ELF machine: $actual_machine"

  echo "== [$TARGET] running under QEMU user mode =="
  local STDOUT_LOG="$ARTIFACTS_DIR/run.stdout"
  local STDERR_LOG="$ARTIFACTS_DIR/run.stderr"
  local qemu_cmd=(timeout 10s "$QEMU_BIN" -L "$QEMU_SYSROOT" "$EXE")
  echo "+ ${qemu_cmd[*]}"
  local run_status=0
  "${qemu_cmd[@]}" >"$STDOUT_LOG" 2>"$STDERR_LOG" || run_status=$?
  if [ "$run_status" -eq 124 ]; then
    cat "$STDERR_LOG" 1>&2
    Fatal "qemu run timed out after 10s"
  elif [ "$run_status" -ne 0 ]; then
    cat "$STDERR_LOG" 1>&2
    Fatal "qemu run exited with status $run_status"
  fi

  echo "== [$TARGET] comparing stdout to expected output =="
  if ! cmp -s "$STDOUT_LOG" "$SMOKE_EXPECTED"; then
    echo "--- expected ---" 1>&2
    cat "$SMOKE_EXPECTED" 1>&2
    echo "--- actual ---" 1>&2
    cat "$STDOUT_LOG" 1>&2
    Fatal "stdout did not match $SMOKE_EXPECTED"
  fi

  echo "== [$TARGET] OK: cross-smoke test passed =="
  echo "artifacts: $ARTIFACTS_DIR"
}

[ -f "$SMOKE_SRC" ] || Fatal "missing smoke test source: $SMOKE_SRC"
[ -f "$SMOKE_EXPECTED" ] || Fatal "missing expected output: $SMOKE_EXPECTED"

REQUESTED="${1:-all}"
if [ "$REQUESTED" = "all" ]; then
  targets=("${ALL_TARGETS[@]}")
else
  targets=()
  for t in "${ALL_TARGETS[@]}"; do
    [ "$t" = "$REQUESTED" ] && targets=("$t")
  done
  [ "${#targets[@]}" -eq 1 ] || { usage; Fatal "unknown target '$REQUESTED'"; }
fi

failed=()
skipped=()
for t in "${targets[@]}"; do
  rc=0
  ( run_target "$t" ) || rc=$?
  if [ "$rc" -eq 2 ]; then
    skipped+=("$t")
  elif [ "$rc" -ne 0 ]; then
    echo "== [$t] FAILED ==" 1>&2
    failed+=("$t")
  fi
done

echo ""
echo "== summary =="
for t in "${targets[@]}"; do
  status="OK"
  for f in "${failed[@]:-}"; do
    [ "$f" = "$t" ] && status="FAIL"
  done
  for s in "${skipped[@]:-}"; do
    [ "$s" = "$t" ] && status="SKIP"
  done
  echo "  $t: $status"
done

if [ "${#failed[@]}" -gt 0 ]; then
  Fatal "failed target(s): ${failed[*]}"
fi

echo "All attempted targets passed (${#skipped[@]} skipped)."
