#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
bits=${1:?usage: compcert-fp32-aggregates-test.sh bits compiler config}
compiler=$(realpath "${2:?missing compiler}")
config=$(realpath "${3:?missing configuration}")
case "$bits" in 32) abi=ilp32f ;; 64) abi=lp64f ;; *) exit 1 ;; esac
prefix="riscv$bits-linux-gnu-"
work="$root/.fp32-work/rv$bits/calls/aggregates"
fixtures="$root/test/riscv-fp32"
mkdir -p "$work/fixtures"
cp "$fixtures"/aggregates* "$fixtures/start.S" "$root/LICENSE" "$work/fixtures/"
flags=(-march="rv${bits}imf_zicsr" -mabi="$abi" -mno-relax -fno-pie)
cflags=(-O2 -ffreestanding -fno-builtin -fno-stack-protector)
"$compiler" -conf "$config" -fall -fno-pie -I"$root/modules/CompCert/runtime/include" \
  -DAGG_PREFIX=cc_ -DAGG_OTHER=gcc_ -S -o "$work/cc-aggregates.s" "$fixtures/aggregates.c"
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" -DAGG_PREFIX=gcc_ -DAGG_OTHER=cc_ \
  -c "$fixtures/aggregates.c" -o "$work/gcc-aggregates.o"
"$root/tools/compcert-fp32-runtime.sh" "$bits" "$work/runtime"
printf 'caller\tstatus\n' > "$work/execution.tsv"
for caller in cc gcc; do
  elf="$work/aggregates-$caller.elf"
  "${prefix}gcc" "${flags[@]}" "${cflags[@]}" -DAGG_DRIVER="${caller}_" -nostdlib -static -no-pie \
    -Wl,--no-relax,-e,_start "$fixtures/start.S" "$fixtures/aggregates-main.c" \
    "$work/gcc-aggregates.o" "$work/cc-aggregates.s" "$work/runtime/libcompcert-fp32.a" \
    -o "$elf"
  "${prefix}objdump" -dr "$elf" > "$work/aggregates-$caller.dis"
  status=0
  timeout 30 "qemu-riscv$bits" -cpu "rv$bits,d=false" "$elf" || status=$?
  if [ "$status" != 0 ]; then
    echo "FAIL RV$bits: $caller caller, fixture status $status" >&2
    exit 1
  fi
  printf '%s\trun-pass\n' "$caller" >> "$work/execution.tsv"
done
"${prefix}readelf" -hA "$work/aggregates-cc.elf" > "$work/elf-attributes.txt"
grep -q 'single-float ABI' "$work/elf-attributes.txt"
echo "PASS RV$bits: aggregate calls/returns, GCC interoperation, indirect calls, register/stack overflow, FP flattening, packed/aligned layouts, unions, bitfields and aggregate varargs with D disabled"
