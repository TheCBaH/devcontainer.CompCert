#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
bits=${1:?usage: compcert-fp32-runtime.sh bits output-directory}
work=$(realpath -m "${2:?missing output directory}")
case "$bits" in
  32) abi=ilp32f ;;
  64) abi=lp64f ;;
  *) exit 1 ;;
esac
source="$root/modules/nanoprintf"
test "$(git -C "$source" rev-parse HEAD)" = bebaecbeaf430e36a2d30d31a2fed4e098388c93
mkdir -p "$work/nanoprintf" "$work/source"
git -C "$source" archive HEAD nanoprintf.h LICENSE | tar -xf - -C "$work/nanoprintf"
patch -s -d "$work/nanoprintf" -p1 < "$root/patches/nanoprintf/0001-optional-long-double.patch"
cp "$root/runtime/"*.c "$root/LICENSE" "$work/source/"
cp -r "$root/runtime/include" "$work/source/"
cp "$root/modules/CompCert/runtime/riscV/vararg.S" \
  "$root/modules/CompCert/runtime/riscV/sysdeps.h" "$work/source/"
cp "$root/modules/CompCert/LICENSE" "$work/source/CompCert-LICENSE"
prefix="riscv$bits-linux-gnu-"
flags=(-march="rv${bits}imf_zicsr" -mabi="$abi" -mno-relax -fno-pie)
cflags=(-O2 -ffreestanding -fno-builtin -fno-stack-protector -fno-tree-loop-distribute-patterns)
includes=(-nostdinc -I"$root/runtime/include" -isystem "$("${prefix}gcc" -print-file-name=include)")
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" "${includes[@]}" -I"$work/nanoprintf" \
  -c "$root/runtime/riscv-fp32-stdio.c" -o "$work/stdio.o"
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" -c \
  "$root/runtime/riscv-fp32.c" -o "$work/conversions.o"
"${prefix}gcc" "${flags[@]}" -DMODEL_"$bits" -DSYS_linux -c \
  "$root/modules/CompCert/runtime/riscV/vararg.S" -o "$work/varargs.o"
"${prefix}ar" rcs "$work/libcompcert-fp32.a" "$work/stdio.o" "$work/conversions.o" "$work/varargs.o"
"${prefix}readelf" -hA "$work/stdio.o" > "$work/elf-attributes.txt"
"${prefix}objdump" -dr "$work/stdio.o" > "$work/stdio.dis"
