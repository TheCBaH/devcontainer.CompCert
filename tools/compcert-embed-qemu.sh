#!/usr/bin/env bash
# Run the assembly an embed backend produced for CompCert's test/c programs
# under QEMU and compare with the suite's Results/. It is the execution check
# behind the byte-for-byte one: the assembly is linked by the installed ccomp
# (which assembles .s files with the cross binutils and links the runtime).
#
# Usage: tools/compcert-embed-qemu.sh <target> <prefix> <asm-dir>
#   <prefix>   install prefix of compcert-export-<target>.tar.gz (bin/ccomp)
#   <asm-dir>  tree with c/<name>.s, as written by test/diff/run.exe
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
TESTS="$REPO_ROOT/modules/CompCert/test"

# shellcheck source=compcert-targets.sh
. "$SCRIPT_DIR/compcert-targets.sh"

Fatal() { echo "FATAL: $*" >&2; exit 1; }

target="${1:-}"
prefix="${2:-}"
asm="${3:-}"
[ -n "$target" ] && [ -n "$prefix" ] && [ -n "$asm" ] || Fatal "usage: $0 <target> <prefix> <asm-dir>"
target_config "$target" || exit 1
prefix=$(realpath "$prefix")
asm=$(realpath "$asm")
ccomp="$prefix/bin/ccomp"
[ -x "$ccomp" ] || Fatal "no $ccomp"
command -v "$QEMU_BIN" >/dev/null || Fatal "no $QEMU_BIN"

config=compcert.ini
[ ! -f "$prefix/share/compcert.freestanding.ini" ] || config=compcert.freestanding.ini
export COMPCERT_CONFIG="$prefix/share/$config"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
passed=0
for r in "$TESTS"/c/Results/*; do
  name=$(basename "$r")
  [ -f "$asm/c/$name.s" ] || continue
  exe="$work/$name"
  "$ccomp" "${CCOMP_EXTRA_ARGS[@]}" -no-pie -o "$exe" "$asm/c/$name.s" -lm
  status=0
  (cd "$TESTS/c" && timeout 300s "$QEMU_BIN" -L "$QEMU_SYSROOT" "$exe") > "$work/$name.out" 2> "$work/$name.err" || status=$?
  [ "$status" -eq 0 ] || { cat "$work/$name.err" >&2; Fatal "$name exited with status $status"; }
  cmp -s "$work/$name.out" "$r" || Fatal "$name: output differs from $r"
  passed=$((passed + 1))
done
[ "$passed" -gt 0 ] || Fatal "no program ran"
echo "== [$target] $passed programs from $asm match Results/ under $QEMU_BIN =="
