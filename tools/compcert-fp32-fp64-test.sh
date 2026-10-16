#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
bits=${1:?usage: compcert-fp32-fp64-test.sh bits compiler config}
compiler=$(realpath "${2:?missing compiler}")
config=$(realpath "${3:?missing configuration}")
case "$bits" in
  32) abi=ilp32f ;;
  64) abi=lp64f ;;
  *) exit 1 ;;
esac
prefix="riscv$bits-linux-gnu-"
work="$root/.fp32-work/rv$bits/calls/fp64"
fixtures="$root/test/riscv-fp32"
mkdir -p "$work/fixtures"
cp "$fixtures"/fp64-* "$fixtures/start.S" "$root/runtime/riscv-fp32.c" \
  "$root/LICENSE" "$work/fixtures/"
flags=(-march="rv${bits}imf_zicsr" -mabi="$abi" -mno-relax -fno-pie)
cflags=(-O2 -ffreestanding -fno-builtin -fno-stack-protector)
link=(-nostdlib -static -no-pie -Wl,--no-relax,-e,_start)
"$compiler" -conf "$config" -fall -fno-pie \
  -I"$root/modules/CompCert/runtime/include" -DFP64_PREFIX=cc_ \
  -S -o "$work/cc-fp64.s" "$fixtures/fp64-varargs.c"
"$compiler" -conf "$config" -fall -fno-pie \
  -S -o "$work/cc-memory.s" "$fixtures/fp64-memory.c"
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" -DFP64_PREFIX=gcc_ \
  -c "$fixtures/fp64-varargs.c" -o "$work/gcc-fp64.o"
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" -c \
  "$root/runtime/riscv-fp32.c" -o "$work/fp64-runtime.o"
"${prefix}gcc" "${flags[@]}" -DMODEL_"$bits" -DSYS_linux -c \
  "$root/modules/CompCert/runtime/riscV/vararg.S" -o "$work/vararg-runtime.o"
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" "${link[@]}" \
  "$fixtures/start.S" "$fixtures/fp64-main.c" "$work/cc-fp64.s" "$work/cc-memory.s" \
  "$work/gcc-fp64.o" "$work/fp64-runtime.o" "$work/vararg-runtime.o" \
  -o "$work/fp64.elf"
"${prefix}readelf" -hA "$work/fp64.elf" > "$work/elf-attributes.txt"
"${prefix}objdump" -dr "$work/fp64.elf" > "$work/fp64.dis"
grep -q 'single-float ABI' "$work/elf-attributes.txt"
timeout 30 "qemu-riscv$bits" -cpu "rv$bits,d=false" "$work/fp64.elf"
echo "PASS RV$bits: software binary64 transport, floating variadics, va_arg(double), named F-ABI doubles, payloads and GCC interoperation with D disabled"

"$compiler" -conf "$config" -fall -fno-pie -S \
  -o "$work/conversions-cc.s" "$fixtures/fp64-conversions.c"
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" -S \
  "$fixtures/fp64-conversions.c" -o "$work/conversions-gcc.s"
reference=(-march="rv${bits}imafd_zicsr" -mabi="${abi%f}d" -mno-relax -fno-pie)
"${prefix}gcc" "${reference[@]}" "${cflags[@]}" -S \
  "$fixtures/fp64-conversions.c" -o "$work/conversions-reference.s"
grep -q 'fcvt.d.s' "$work/conversions-reference.s"
grep -q 'fcvt.s.d' "$work/conversions-reference.s"
for kind in cc gcc; do
  "${prefix}gcc" "${flags[@]}" "${link[@]}" "$fixtures/start.S" \
    "$fixtures/fp64-output.S" "$work/conversions-$kind.s" "$work/fp64-runtime.o" \
    -o "$work/conversions-$kind.elf"
  timeout 30 "qemu-riscv$bits" -cpu "rv$bits,d=false" \
    "$work/conversions-$kind.elf" > "$work/conversions-$kind.bin"
done
"${prefix}gcc" "${reference[@]}" "${link[@]}" "$fixtures/start.S" \
  "$fixtures/fp64-output.S" "$work/conversions-reference.s" \
  -o "$work/conversions-reference.elf"
timeout 30 "qemu-riscv$bits" -cpu "rv$bits" \
  "$work/conversions-reference.elf" > "$work/conversions-reference.bin"
test "$(wc -c < "$work/conversions-reference.bin")" = 480000
cmp "$work/conversions-reference.bin" "$work/conversions-cc.bin"
cmp "$work/conversions-reference.bin" "$work/conversions-gcc.bin"
echo "PASS RV$bits: 30000 promotions and 30000 truncations match hardware D reference (edges, ties, subnormals, overflow and canonical NaNs)"
