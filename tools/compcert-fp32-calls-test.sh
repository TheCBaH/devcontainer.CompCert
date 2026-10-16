#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
bits=${1:?usage: compcert-fp32-calls-test.sh bits compiler}
compiler=$(realpath "${2:?missing compiler}")
case "$bits" in
  32) abi=ilp32f ;;
  64) abi=lp64f ;;
  *) echo 'bits must be 32 or 64' >&2; exit 1 ;;
esac
work="$root/.fp32-work/rv$bits/calls"
fixtures="$root/test/riscv-fp32"
prefix="riscv$bits-linux-gnu-"
mkdir -p "$work"
mkdir -p "$work/fixtures"
cp "$fixtures"/calls* "$fixtures/start.S" "$root/LICENSE" "$work/fixtures/"
(cd "$root/modules/CompCert" && ./tools/linkhier "$work/configuration")
(
  cd "$work/configuration"
  opam exec -- ./configure -toolprefix "$prefix" "rv$bits-fp32"
  opam exec -- make compcert.ini
)
config="$work/configuration/compcert.ini"
cp "$config" "$work/calls.ini"
{
  printf '#include "calls.h"\nvoid cc_call_pressure(float *out, const volatile float *x) {\n'
  for ((i=0; i<40; ++i)); do printf '  float v%d = x[%d];\n' "$i" "$i"; done
  printf '  float r = gcc_clobber();\n  *out = r'
  for ((i=0; i<40; ++i)); do printf ' + v%d' "$i"; done
  printf ';\n}\n'
} > "$work/call-pressure.c"
flags=(-march="rv${bits}imf_zicsr" -mabi="$abi" -mno-relax -fno-pie)
cflags=(-O2 -ffreestanding -fno-builtin -fno-stack-protector)
"$compiler" -conf "$config" -fno-pie -DFP32_PREFIX=cc_ -S \
  -o "$work/cc-leaf.s" "$fixtures/calls-leaf.c"
"$compiler" -conf "$config" -fno-pie -S \
  -o "$work/cc-caller.s" "$fixtures/calls-caller.c"
"$compiler" -conf "$config" -fno-pie -I"$fixtures" -S \
  -o "$work/call-pressure.s" "$work/call-pressure.c"
grep -Eq 'tail[[:space:]]+gcc_leaf' "$work/cc-caller.s"
grep -Eq 'jalr[[:space:]]' "$work/cc-caller.s"
grep -Eq 'jr[[:space:]]+[^r]' "$work/cc-caller.s"
grep -Eq 'fsw[[:space:]].*\((sp|x2)\)' "$work/call-pressure.s"
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" -DFP32_PREFIX=gcc_ -c \
  "$fixtures/calls-leaf.c" -o "$work/gcc-leaf.o"
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" -nostdlib -static -no-pie \
  -Wl,--no-relax,-e,_start "$fixtures/start.S" "$fixtures/calls-main.c" \
  "$fixtures/calls-runtime.S" "$work/gcc-leaf.o" "$work/cc-leaf.s" \
  "$work/cc-caller.s" "$work/call-pressure.s" -o "$work/calls.elf"
"${prefix}objdump" -dr "$work/calls.elf" > "$work/calls.dis"
"${prefix}readelf" -hA "$work/calls.elf" > "$work/elf-attributes.txt"
grep -q 'single-float ABI' "$work/elf-attributes.txt"
timeout 30 "qemu-riscv$bits" -cpu "rv$bits,d=false" "$work/calls.elf"
echo "PASS RV$bits: $abi calls, returns, indirect/tail calls, overflow arguments, recursion, live FP32 spills and preserved fs registers with D disabled"

reject() {
  local name=$1 code=$2 reason=$3
  printf '%s\n' "$code" > "$work/$name.c"
  if "$compiler" -conf "$config" -fno-pie -fall -S -o "$work/$name.s" \
       "$work/$name.c" > "$work/$name.log" 2>&1; then
    echo "unexpected acceptance: $name" >&2; exit 1
  fi
  grep -F "FP32: $reason" "$work/$name.log"
}
reject promotion 'float f(float x) { return x + 0.1; }' 'FP64 arithmetic and comparisons'
reject fp64-comparison 'int f(double x, double y) { return x == y; }' 'FP64 arithmetic and comparisons'
reject fp64-to-int 'int f(double x) { return (int)x; }' 'FP64 integer conversions'
reject int-to-fp64 'double f(int x) { return x; }' 'FP64 integer conversions'
reject long-double 'long double f(long double x) { return x; }' 'long double interfaces'
reject aggregate-argument 'struct s { float x; }; float f(struct s s) { return s.x; }' 'aggregate-by-value'
reject aggregate-result 'struct s { float x; }; struct s f(float x) { struct s s = { x }; return s; }' 'aggregate-by-value'
reject aggregate-call 'struct s { float x; }; extern float g(struct s); float f(float x) { struct s s = { x }; return g(s); }' 'aggregate-by-value'
if [ "$bits" = 32 ]; then
  reject int64 'long long f(float x) { return (long long)x; }' 'FP64 or unsupported instruction'
fi
echo "PASS RV$bits: unsupported FP64 arithmetic and aggregate interfaces rejected"

printf '%s\n' 'int abi_probe(void) { return 0; }' > "$work/abi-probe.c"
"${prefix}gcc" -march="rv${bits}imafd_zicsr" -mabi="${abi%f}d" \
  -fno-pie -c "$work/abi-probe.c" -o "$work/abi-d.o"
if "${prefix}ld" -r "$work/gcc-leaf.o" "$work/abi-d.o" \
     -o "$work/abi-mismatch.o" > "$work/abi-mismatch.log" 2>&1; then
  echo 'Linker unexpectedly accepted F/D ABI mixing' >&2; exit 1
fi
grep -Ei 'double-float|single-float' "$work/abi-mismatch.log"
printf '%s\n' 'extern int printf(const char *, ...);' \
  'void print_float(float x) { printf("%f", x); }' > "$work/varargs-reference.c"
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" -S \
  "$work/varargs-reference.c" -o "$work/varargs-reference.s"
grep -q '__extendsfdf2' "$work/varargs-reference.s"
echo "PASS RV$bits: F/D ELF ABI mixing rejected; GCC varargs reference uses software float-to-double conversion"

"$root/tools/compcert-fp32-varargs-test.sh" "$bits" "$compiler" "$config"
"$root/tools/compcert-fp32-fp64-test.sh" "$bits" "$compiler" "$config"

if [ "$#" -ge 3 ]; then
  standard_config=$(realpath "$3")
else
  (cd "$root/modules/CompCert" && ./tools/linkhier "$work/standard-configuration")
  (
    cd "$work/standard-configuration"
    opam exec -- ./configure -toolprefix "$prefix" -no-runtime-lib \
      -no-standard-headers "rv$bits-linux"
    opam exec -- make compcert.ini
  )
  standard_config="$work/standard-configuration/compcert.ini"
fi
"$root/tools/compcert-fp32-suite.sh" "$bits" "$compiler" \
  "$config" "$standard_config" calls
