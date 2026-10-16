#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
bits=${1:?usage: compcert-fp32-approx-test.sh bits compiler config}
compiler=$(realpath "${2:?missing compiler}")
config=$(realpath "${3:?missing configuration}")
case "$bits" in
  32) abi=ilp32f ;;
  64) abi=lp64f ;;
  *) exit 1 ;;
esac
work="$root/.fp32-work/rv$bits/calls/approx"
fixtures="$root/test/riscv-fp32"
mkdir -p "$work/fixtures"
cp "$fixtures"/fp64-approx*.c "$fixtures/fp64-output.S" "$fixtures/start.S" "$work/fixtures/"
"$root/tools/compcert-fp32-runtime.sh" "$bits" "$work/runtime"
prefix="riscv$bits-linux-gnu-"
flags=(-march="rv${bits}imf_zicsr" -mabi="$abi" -mno-relax -fno-pie)
reference=(-march="rv${bits}imafd_zicsr" -mabi="${abi%f}d" -mno-relax -fno-pie)
cflags=(-O2 -ffreestanding -fno-builtin -fno-stack-protector -ffp-contract=off)
link=(-nostdlib -static -no-pie -Wl,--no-relax,-e,_start)
"$compiler" -conf "$config" -fall -ffp32-approx-double -S \
  -o "$work/operations.s" "$fixtures/fp64-approx-ops.c"
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" "${link[@]}" \
  "$fixtures/start.S" "$fixtures/fp64-output.S" "$fixtures/fp64-approx-main.c" \
  "$work/operations.s" "$work/runtime/libcompcert-fp32.a" -o "$work/approx.elf"
"${prefix}gcc" "${reference[@]}" "${cflags[@]}" -DFP32_REFERENCE "${link[@]}" \
  "$fixtures/start.S" "$fixtures/fp64-output.S" "$fixtures/fp64-approx-main.c" \
  "$fixtures/fp64-approx-ops.c" -lgcc -o "$work/reference.elf"
timeout 90 "qemu-riscv$bits" -cpu "rv$bits,d=false" "$work/approx.elf" > "$work/approx.bin"
timeout 90 "qemu-riscv$bits" -cpu "rv$bits" "$work/reference.elf" > "$work/reference.bin"
cmp "$work/approx.bin" "$work/reference.bin"
"${prefix}objdump" -dr "$work/runtime/approx.o" > "$work/runtime/approx.dis"
for instruction in fadd.s fsub.s fmul.s fdiv.s fsqrt.s fmadd.s; do
  grep -Fq "$instruction" "$work/runtime/approx.dis"
done
if "${prefix}nm" -u "$work/approx.elf" | grep .; then
  echo 'Unexpected runtime dependency' >&2; exit 1
fi
# -fall must not enable approximation, and -fno- must restore the guard.
for option in -fall -fno-fp32-approx-double; do
  if "$compiler" -conf "$config" -ffp32-approx-double "$option" -S \
       -o "$work/guard.s" "$fixtures/fp64-approx-ops.c" > "$work/guard.log" 2>&1; then
    if [ "$option" != -fall ]; then echo 'Approximation guard bypassed' >&2; exit 1; fi
  elif [ "$option" = -fall ]; then cat "$work/guard.log"; exit 1; fi
done
grep -q 'FP32:' "$work/guard.log"
sed 's/^abi=fp32$/abi=standard/' "$config" > "$work/wrong-profile.ini"
if "$compiler" -conf "$work/wrong-profile.ini" -ffp32-approx-double -S \
     -o "$work/wrong-profile.s" "$fixtures/fp64-approx-ops.c" > "$work/wrong-profile.log" 2>&1; then
  echo 'Approximation accepted outside the F call profile' >&2; exit 1
fi
grep -q 'requires the fp32 call profile' "$work/wrong-profile.log"
if "$compiler" -conf "$config" -fall -S -o "$work/default.s" \
     "$fixtures/fp64-approx-ops.c" > "$work/default.log" 2>&1; then
  echo '-fall unexpectedly enabled approximation' >&2; exit 1
fi
grep -q 'FP32:' "$work/default.log"
echo "PASS RV$bits: opt-in approximate FP64 operations, comparisons, builtins, side effects and 12000 conversion vectors match explicit FP32 reference; D disabled; no extra runtime dependency"
