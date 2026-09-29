#!/usr/bin/env bash
# Verify one target's compcert-export-<target>.tar.gz without Rocq and without
# building anything from the CompCert source tree:
#
#   1. unpack, install.sh, ccomp -version
#   2. cross-smoke: test/cross-smoke/hello.c and every test/c program compiled
#      and linked by this ccomp, run under QEMU, output compared with Results/
#   3. the compcert-asm-<target> corpus (tools/compcert-asm-corpus.sh)
#   4. the cross binutils assemble every generated .s
#
# Usage: tools/compcert-export-verify.sh <target> <export.tar.gz> <corpus-out.tar.gz>
# Work root: VERIFY_WORK, default <repo>/.verify-work.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
TESTS="$REPO_ROOT/modules/CompCert/test"
SMOKE_SRC="$REPO_ROOT/test/cross-smoke/hello.c"
SMOKE_EXPECTED="$REPO_ROOT/test/cross-smoke/Results/hello"

# shellcheck source=compcert-targets.sh
. "$SCRIPT_DIR/compcert-targets.sh"

Fatal() { echo "FATAL: $*" >&2; exit 1; }
Opam() { if command -v opam >/dev/null 2>&1; then opam exec -- "$@"; else "$@"; fi; }

target="${1:-}"
tarball="${2:-}"
corpus_out="${3:-}"
[ -n "$target" ] && [ -n "$tarball" ] && [ -n "$corpus_out" ] ||
  Fatal "usage: $0 <target> <export.tar.gz> <corpus-out.tar.gz>"
target_config "$target" || exit 1
tarball=$(realpath "$tarball")
corpus_out=$(realpath -m "$corpus_out")

# Fail rather than skip: a leg that cannot run its toolchain proves nothing.
for tool in "${TOOLPREFIX}gcc" "${TOOLPREFIX}as" "${TOOLPREFIX}readelf" "$QEMU_BIN"; do
  command -v "$tool" >/dev/null 2>&1 || Fatal "missing $tool"
done
[ -d "$TESTS/c/Results" ] || Fatal "missing $TESTS (CompCert test submodule)"

work="${VERIFY_WORK:-$REPO_ROOT/.verify-work}/$target"
rm -rf "$work"
mkdir -p "$work/export" "$work/run"

echo "== [$target] unpack and install =="
tar -xzf "$tarball" -C "$work/export"
(cd "$work/export" && Opam ./install.sh "$work/prefix")
ccomp="$work/prefix/bin/ccomp"
"$ccomp" -version | tee "$work/ccomp-version.txt" | grep CompCert

# run_program <name> <source> <expected> <cwd>
run_program() {
  local name=$1 src=$2 expected=$3 cwd=$4
  local exe="$work/run/$name.compcert"
  "$ccomp" "${CCOMP_EXTRA_ARGS[@]}" -o "$exe" "$src" -lm
  local status=0
  (cd "$cwd" && timeout 300s "$QEMU_BIN" -L "$QEMU_SYSROOT" "$exe") > "$work/run/$name.out" 2> "$work/run/$name.err" || status=$?
  if [ "$status" -ne 0 ]; then
    cat "$work/run/$name.err" >&2
    Fatal "$name exited with status $status under $QEMU_BIN"
  fi
  cmp -s "$work/run/$name.out" "$expected" || Fatal "$name: output differs from $expected"
  echo "  $name: passed"
}

echo "== [$target] cross-smoke =="
run_program hello "$SMOKE_SRC" "$SMOKE_EXPECTED" "$work/run"
machine=$("${TOOLPREFIX}readelf" -h "$work/run/hello.compcert" | sed -n 's/^ *Machine: *//p')
[ "$machine" = "$READELF_MACHINE" ] || Fatal "expected ELF machine '$READELF_MACHINE', got '$machine'"
for r in "$TESTS"/c/Results/*; do
  name=$(basename "$r")
  [ -f "$TESTS/c/$name.c" ] || continue
  run_program "$name" "$TESTS/c/$name.c" "$r" "$TESTS/c"
done

echo "== [$target] asm corpus =="
"$SCRIPT_DIR/compcert-asm-corpus.sh" "$target" "$work/prefix" "$work/export" "$corpus_out"

echo "== [$target] GNU as on every generated .s =="
mkdir -p "$work/corpus"
tar -xzf "$corpus_out" -C "$work/corpus"
failed=()
for s in "$work"/corpus/asm/*/*.s; do
  if ! "${TOOLPREFIX}as" "${AS_FLAGS[@]}" -o /dev/null "$s" 2>"$work/as.err"; then
    failed+=("${s#"$work"/corpus/asm/}")
  fi
done
if [ "${#failed[@]}" -gt 0 ]; then
  printf '  gas rejected: %s\n' "${failed[@]}"
fi
# The regression suite deliberately holds constructs GNU as may reject
# (architecture-specific builtins); the other suites must assemble cleanly.
for f in "${failed[@]}"; do
  case "$f" in regression/*) ;; *) Fatal "$f does not assemble" ;; esac
done
echo "== [$target] OK =="
