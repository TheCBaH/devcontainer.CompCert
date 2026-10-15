#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
bits=${1:-32}
case "$bits" in
  32) abi=ilp32 ;;
  64) abi=lp64 ;;
  *) echo "usage: $0 [32|64]" >&2; exit 1 ;;
esac
prefix="riscv${bits}-linux-gnu-"
qemu="qemu-riscv${bits}"
cpu="rv${bits},d=false"
march="rv${bits}imf_zicsr"
work="$root/.fp32-work/rv$bits"
source_dir="$root/modules/CompCert"
fixtures="$root/test/riscv-fp32"
for tool in "${prefix}gcc" "${prefix}objdump" "$qemu"; do
  command -v "$tool" >/dev/null
done
"$root/tools/compcert-prepare-source.sh"
mkdir -p "$work"
(cd "$source_dir" && ./tools/linkhier "$work/compiler")
cd "$work/compiler"
opam exec -- ./configure -toolprefix "$prefix" "rv$bits-fp32-kernel"
opam exec -- make -j"${COMPCERT_JOBS:-$(nproc)}" all
opam exec -- make check-proof
cp compcert.ini "$work/fp32.ini"

tar -czf "$work/extraction.tar.gz" Makefile.config extraction/*.ml extraction/*.mli
rm -rf "$work/split"
git clone --quiet --shared "$root" "$work/split"
git clone --quiet --shared "$source_dir" "$work/split/modules/CompCert"
make -C "$work/split" compcert-build-from-archive \
  COMPCERT_EXTRACTION_ARCHIVE="$work/extraction.tar.gz"
cd "$work/split/modules/CompCert"
echo "PASS RV$bits: extraction archive rebuilt against freshly patched sources"

flags=(-march="$march" -mabi="$abi" -mno-relax -fno-pie)
cflags=(-O2 -ffreestanding -fno-builtin -fno-stack-protector)
link=(-nostdlib -static -no-pie -Wl,--no-relax,-e,_start)

{
  printf 'void pressure(float *out, const volatile float *x) {\n'
  for ((i=0; i<40; ++i)); do
    printf '  float v%d = x[%d];\n' "$i" "$i"
  done
  printf '  *out = v0'
  for ((i=1; i<40; ++i)); do printf ' + v%d' "$i"; done
  printf ';\n}\n'
} > "$work/pressure.c"
./ccomp -fno-pie -S -o "$work/kernels.s" "$fixtures/kernels.c"
./ccomp -fno-pie -S -o "$work/pressure.s" "$work/pressure.c"
grep -Eq 'fsw[[:space:]].*\((sp|x2)\)' "$work/pressure.s" || {
  echo 'Pressure fixture did not exercise FP32 spills' >&2; exit 1;
}
grep -Eq 'fmv\.s[[:space:]]' "$work/kernels.s" "$work/pressure.s" || {
  echo 'Fixtures did not exercise FP32 register moves' >&2; exit 1;
}
if grep -Eq '\<(fld|fsd|fmv\.d|fadd\.d|fmul\.d)\>' "$work/kernels.s" "$work/pressure.s"; then
  echo 'D instruction in FP32 assembly' >&2; exit 1
fi
"${prefix}gcc" "${flags[@]}" "${cflags[@]}" "${link[@]}" \
  "$fixtures/start.S" "$fixtures/main.c" "$work/kernels.s" "$work/pressure.s" \
  -o "$work/kernels.elf"
"${prefix}objdump" -dr "$work/kernels.elf" > "$work/kernels.dis"
timeout 30 "$qemu" -cpu "$cpu" "$work/kernels.elf"
echo "PASS RV$bits: FP32 kernels, spills, copies, conversions and NaN payloads with D disabled"

"${prefix}gcc" -march="rv${bits}imafd_zicsr" -mabi="$abi" "${link[@]}" \
  "$fixtures/d-probe.S" -o "$work/d-probe.elf"
timeout 10 "$qemu" -cpu "rv$bits" "$work/d-probe.elf"
status=0
timeout 10 "$qemu" -cpu "$cpu" "$work/d-probe.elf" > "$work/d-probe.log" 2>&1 || status=$?
if [ "$status" != 132 ]; then
  cat "$work/d-probe.log" >&2
  echo "D control expected SIGILL (132), got $status" >&2; exit 1
fi
echo "PASS RV$bits: D control traps with SIGILL"

reject() {
  local name=$1 code=$2 reason=$3
  printf '%s\n' "$code" > "$work/$name.c"
  if ./ccomp -fno-pie -finline-asm -S -o "$work/$name.s" "$work/$name.c" > "$work/$name.log" 2>&1; then
    echo "unexpected acceptance: $name" >&2; exit 1
  fi
  grep -F "FP32 kernel: $reason" "$work/$name.log"
}
reject double 'void f(double *out, const volatile double *in) { *out = *in + 1.0; }' 'FP64 or unsupported instruction'
reject promotion 'void f(float *out, const volatile float *in) { *out = *in + 0.1; }' 'FP64 or unsupported instruction'
reject float-interface 'float f(float x) { return x; }' 'only non-variadic'
reject varargs 'int f(int x, ...) { return x; }' 'only non-variadic'
reject call 'extern void g(void); void f(void) { g(); }' 'calls and tail calls'
reject indirect-call 'void f(void (*g)(void)) { g(); }' 'calls and tail calls'
reject asm 'void f(void) { asm("fadd.d f0, f0, f0"); }' 'unexpanded builtins and inline assembly'
if [ "$bits" = 32 ]; then
  reject int64 'void f(long long *out, const volatile float *in) { *out = (long long)*in; }' 'FP64 or unsupported instruction'
fi
echo "PASS RV$bits: unsupported programs rejected"

# The same extracted compiler must retain the original D-ABI behavior.
opam exec -- ./configure -toolprefix "$prefix" -no-runtime-lib -no-standard-headers "rv$bits-linux"
rm compcert.ini
opam exec -- make compcert.ini
printf '%s\n' 'double add(double a, double b) { return a+b; }' > "$work/double-ok.c"
./ccomp -fno-pie -S -o "$work/double-ok.s" "$work/double-ok.c"
grep -q 'fadd.d' "$work/double-ok.s"
"${prefix}gcc" -march="rv${bits}imafd_zicsr" -mabi="${abi}d" -c "$work/double-ok.s" -o "$work/double-ok.o"
printf '%s\n' 'extern double add(double, double); int main(void) { return add(1.25, 2.5) == 3.75 ? 0 : 1; }' > "$work/double-main.c"
"${prefix}gcc" -march="rv${bits}imafd_zicsr" -mabi="${abi}d" -mno-relax \
  "${cflags[@]}" "${link[@]}" "$fixtures/start.S" "$work/double-main.c" \
  "$work/double-ok.o" -o "$work/double-ok.elf"
timeout 30 "$qemu" -cpu "rv$bits" "$work/double-ok.elf"
echo "PASS RV$bits: original D profile compiles and executes double interfaces"
