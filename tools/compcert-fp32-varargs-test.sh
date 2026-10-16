#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
bits=${1:?usage: compcert-fp32-varargs-test.sh bits compiler config}
compiler=$(realpath "${2:?missing compiler}")
config=$(realpath "${3:?missing configuration}")
case "$bits" in
  32) abi=ilp32f ;;
  64) abi=lp64f ;;
  *) exit 1 ;;
esac
prefix="riscv$bits-linux-gnu-"
work="$root/.fp32-work/rv$bits/calls/varargs"
fixtures="$root/test/riscv-fp32"
runtime="$root/modules/CompCert/runtime"
mkdir -p "$work/fixtures"
cp "$fixtures"/varargs* "$fixtures/start.S" "$root/LICENSE" "$work/fixtures/"
cp "$runtime/riscV/vararg.S" "$runtime/riscV/sysdeps.h" "$work/fixtures/"
cp "$root/modules/CompCert/LICENSE" "$work/fixtures/CompCert-LICENSE"
flags=(-march="rv${bits}imf_zicsr" -mabi="$abi" -mno-relax -fno-pie)
cflags=(-O2 -ffreestanding -fno-builtin -fno-stack-protector)
"$compiler" -conf "$config" -fall -fno-pie -I"$runtime/include" \
  -DVARARGS_PREFIX=cc_ -S -o "$work/cc-varargs.s" "$fixtures/varargs.c"
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" -DVARARGS_PREFIX=gcc_ \
  -c "$fixtures/varargs.c" -o "$work/gcc-varargs.o"
"${prefix}gcc" "${flags[@]}" -DMODEL_"$bits" -DSYS_linux \
  -c "$runtime/riscV/vararg.S" -o "$work/vararg-runtime.o"
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" -nostdlib -static -no-pie \
  -Wl,--no-relax,-e,_start "$fixtures/start.S" "$fixtures/varargs-main.c" \
  "$work/gcc-varargs.o" "$work/cc-varargs.s" "$work/vararg-runtime.o" \
  -o "$work/varargs.elf"
"${prefix}readelf" -hA "$work/varargs.elf" > "$work/elf-attributes.txt"
"${prefix}objdump" -dr "$work/varargs.elf" > "$work/varargs.dis"
grep -q 'single-float ABI' "$work/elf-attributes.txt"
timeout 30 "qemu-riscv$bits" -cpu "rv$bits,d=false" "$work/varargs.elf"
echo "PASS RV$bits: integer/pointer variadics, named FP32, va_copy/forwarding, aligned pairs, register/stack overflow and GCC interoperation with D disabled"

printf '%s\n' 'struct s { int x; }; int f(int n, ...) {' \
  '__builtin_va_list ap; __builtin_va_start(ap, n);' \
  'return __builtin_va_arg(ap, struct s).x; }' > "$work/aggregate-vaarg.c"
if "$compiler" -conf "$config" -fall -fno-pie -S \
     -o "$work/aggregate-vaarg.s" "$work/aggregate-vaarg.c" \
     > "$work/aggregate-vaarg.log" 2>&1; then
  echo 'Aggregate va_arg unexpectedly accepted' >&2; exit 1
fi
grep -F 'FP32: aggregate' "$work/aggregate-vaarg.log"
