#!/usr/bin/env bash
# Verify the installed F-only package, including its packaged runtime.
set -euo pipefail
ulimit -c 0
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
. "$SCRIPT_DIR/compcert-targets.sh"
target_config "${1:?missing target}"
[ "$TARGET_PROFILE" = fp32 ]
prefix=$(realpath "${2:?missing installed prefix}")
work=$(realpath "${3:?missing work directory}")
ccomp="$prefix/bin/ccomp"
lib="$prefix/lib/compcert/libcompcert.a"
startup="$prefix/lib/compcert/crt0.o"
fixtures="$REPO_ROOT/test/riscv-fp32"
reference_flags=(-march="rv${FP32_BITS}imafd_zicsr" -mabi="${fp32_abi%f}d" -mno-relax -fno-pie)
cflags=(-O2 -ffreestanding -fno-builtin -fno-stack-protector -ffp-contract=off)
link=(-nostdlib -static -no-pie -Wl,--no-relax,-e,_start)
mkdir -p "$work/run"
grep -qx 'abi=fp32' "$prefix/share/compcert.ini"
grep -qx 'has_runtime_lib=true' "$prefix/share/compcert.ini"
grep -qx 'has_standard_headers=true' "$prefix/share/compcert.ini"
"${TOOLPREFIX}readelf" -hA "$lib" > "$work/run/runtime-attributes.txt"
grep -q 'single-float ABI' "$work/run/runtime-attributes.txt"
if grep -Eq 'double-float ABI|Tag_RISCV_arch:.*_d[0-9]' "$work/run/runtime-attributes.txt"; then
  echo 'Packaged runtime requires D' >&2; exit 1
fi

run_program() {
  local name=$1 source=$2 expected=$3
  "$ccomp" -fall -fno-pie -S -o "$work/run/$name.s" "$source"
  "$ccomp" -no-pie -static -nostdlib -Wl,--no-relax,-e,_start \
    "$startup" "$work/run/$name.s" -o "$work/run/$name.elf"
  timeout 90 "$QEMU_BIN" "${QEMU_ARGS[@]}" "$work/run/$name.elf" > "$work/run/$name.out"
  cmp "$work/run/$name.out" "$expected"
  echo "  $name: passed with D disabled"
}

run_program hello "$REPO_ROOT/test/cross-smoke/hello.c" "$REPO_ROOT/test/cross-smoke/Results/hello"
for name in native stdio varargs1 varargs2 varargs3 struct11 struct12; do
  case "$name" in
    native) source="$REPO_ROOT/test/release-fp32/native.c" ;;
    stdio) source="$fixtures/stdio.c" ;;
    *) source="$REPO_ROOT/modules/CompCert/test/regression/$name.c" ;;
  esac
  "${TOOLPREFIX}gcc" "${reference_flags[@]}" -O2 -fno-builtin -static -no-pie \
    "$source" -o "$work/run/$name.reference.elf"
  timeout 90 "$QEMU_BIN" -cpu "rv$FP32_BITS" "$work/run/$name.reference.elf" > "$work/run/$name.expected"
  run_program "$name" "$source" "$work/run/$name.expected"
done
grep -Fq fadd.s "$work/run/native.s"
"${TOOLPREFIX}readelf" -hA "$work/run/native.elf" > "$work/run/elf-attributes.txt"
grep -q 'single-float ABI' "$work/run/elf-attributes.txt"

"$ccomp" -fall -ffp32-approx-double -S -o "$work/run/approx.s" "$fixtures/fp64-approx-ops.c"
"${TOOLPREFIX}gcc" "${AS_FLAGS[@]}" "${cflags[@]}" "${link[@]}" \
  "$startup" "$fixtures/fp64-output.S" "$fixtures/fp64-approx-main.c" \
  "$work/run/approx.s" "$lib" -o "$work/run/approx.elf"
"${TOOLPREFIX}gcc" "${reference_flags[@]}" "${cflags[@]}" "${link[@]}" -DFP32_REFERENCE \
  "$fixtures/start.S" "$fixtures/fp64-output.S" "$fixtures/fp64-approx-main.c" \
  "$fixtures/fp64-approx-ops.c" -lgcc -o "$work/run/approx.reference.elf"
timeout 90 "$QEMU_BIN" "${QEMU_ARGS[@]}" "$work/run/approx.elf" > "$work/run/approx.bin"
timeout 90 "$QEMU_BIN" -cpu "rv$FP32_BITS" "$work/run/approx.reference.elf" > "$work/run/approx.reference.bin"
cmp "$work/run/approx.bin" "$work/run/approx.reference.bin"
if "${TOOLPREFIX}nm" -u "$work/run/approx.elf" | grep .; then
  echo 'F-only package has an unresolved runtime dependency' >&2; exit 1
fi
if "$ccomp" -fall -S -o "$work/run/guard.s" "$fixtures/fp64-approx-ops.c" > "$work/run/guard.log" 2>&1; then
  echo 'Approximation was unexpectedly enabled by default' >&2; exit 1
fi
grep -q 'FP32:' "$work/run/guard.log"
status=0
timeout 90 "$QEMU_BIN" "${QEMU_ARGS[@]}" "$work/run/approx.reference.elf" \
  > "$work/run/d-control.out" 2> "$work/run/d-control.err" || status=$?
[ "$status" -eq 132 ] || { echo "D control exited $status, expected SIGILL" >&2; exit 1; }
echo "PASS $1: installed F-only extraction/runtime, native FP32, aggregates, varargs and opt-in approximation; D control traps"
