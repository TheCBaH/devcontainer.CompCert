#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
bits=${1:?usage: compcert-fp32-stdio-test.sh bits compiler config}
compiler=$(realpath "${2:?missing compiler}")
config=$(realpath "${3:?missing configuration}")
case "$bits" in
  32) abi=ilp32f ;;
  64) abi=lp64f ;;
  *) exit 1 ;;
esac
work="$root/.fp32-work/rv$bits/calls/stdio"
mkdir -p "$work/fixtures"
cp "$root/test/riscv-fp32/stdio.c" "$root/test/riscv-fp32/start.S" \
  "$root/LICENSE" "$work/fixtures/"
runtime="$work/runtime"
"$root/tools/compcert-fp32-runtime.sh" "$bits" "$runtime"
prefix="riscv$bits-linux-gnu-"
flags=(-march="rv${bits}imf_zicsr" -mabi="$abi" -mno-relax -fno-pie)
reference=(-march="rv${bits}imafd_zicsr" -mabi="${abi%f}d" -fno-pie)
printf 'source\tstatus\n' > "$work/execution.tsv"
sources=("$root/test/riscv-fp32/stdio.c")
for name in varargs1 varargs3 expr1 funptr2 volatile1 volatile3 volatile4; do
  sources+=("$root/modules/CompCert/test/regression/$name.c")
done
for source in "${sources[@]}"; do
  name=$(basename "$source" .c)
  cp "$source" "$work/fixtures/$name.c"
  "$compiler" -conf "$config" -fall -fno-pie -I"$root/runtime/include" \
    -I"$root/modules/CompCert/runtime/include" -S -o "$work/$name.s" "$source" \
    > "$work/$name.compile.log" 2>&1
  "${prefix}gcc" "${flags[@]}" -nostdlib -static -no-pie -Wl,--no-relax,-e,_start \
    "$root/test/riscv-fp32/start.S" "$work/$name.s" "$runtime/libcompcert-fp32.a" \
    -o "$work/$name.elf"
  "${prefix}gcc" "${reference[@]}" -O2 -fno-builtin -static -no-pie "$source" \
    -o "$work/$name.reference.elf"
  timeout 30 "qemu-riscv$bits" -cpu "rv$bits,d=false" "$work/$name.elf" > "$work/$name.stdout"
  timeout 30 "qemu-riscv$bits" -cpu "rv$bits" "$work/$name.reference.elf" > "$work/$name.reference.stdout"
  diff -u "$work/$name.reference.stdout" "$work/$name.stdout"
  printf '%s\trun-pass\n' "$name.c" >> "$work/execution.tsv"
done
"${prefix}readelf" -hA "$work/stdio.elf" > "$work/elf-attributes.txt"
grep -q 'single-float ABI' "$work/elf-attributes.txt"
cat "$work/execution.tsv"
echo "PASS RV$bits: F-only printf/snprintf/vprintf, floating promotions and seven unchanged upstream programs match D-ABI libc reference output"
