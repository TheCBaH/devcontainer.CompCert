#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
bits=${1:?usage: compcert-fp32-suite.sh bits compiler fp32.ini standard.ini}
compiler=$(realpath "${2:?missing compiler}")
fp32_config=$(realpath "${3:?missing FP32 configuration}")
standard_config=$(realpath "${4:?missing standard configuration}")
mode=${5:-kernel}
case "$bits" in
  32) abi=ilp32 ;;
  64) abi=lp64 ;;
  *) echo 'bits must be 32 or 64' >&2; exit 1 ;;
esac
case "$mode" in
  kernel)
    profile=fp32-kernel
    work="$root/.fp32-work/rv$bits/upstream"
    expected="$root/test/riscv-fp32/upstream-rv$bits.tsv"
    ;;
  calls)
    profile=fp32
    abi=${abi}f
    work="$root/.fp32-work/rv$bits/calls/upstream"
    expected="$root/test/riscv-fp32/upstream-calls-rv$bits.tsv"
    ;;
  *) echo 'mode must be kernel or calls' >&2; exit 1 ;;
esac
tests="$root/modules/CompCert/test"
[ -f "$tests/Makefile" ] || {
  echo 'Initialize the CompCert test submodule recursively first' >&2; exit 1;
}
grep -qx "model=$bits" "$fp32_config"
grep -qx "abi=$profile" "$fp32_config"
grep -qx "model=$bits" "$standard_config"
grep -qx 'abi=standard' "$standard_config"
rm -rf "$work"
mkdir -p "$work/test" "$work/evidence"
git -C "$tests" archive HEAD | tar -xf - -C "$work/test"
{
  printf 'compcert-revision: %s\n' "$(git -C "$root/modules/CompCert" rev-parse HEAD)"
  printf 'tests-revision: %s\n' "$(git -C "$tests" rev-parse HEAD)"
  printf 'cpu: rv%s,d=false\n' "$bits"
  "qemu-riscv$bits" --version | head -1
} > "$work/metadata.txt"
cp "$(dirname "$standard_config")/Makefile.config" "$work/Makefile.config"
opam exec -- make -s -C "$work/test/abi" fixed_decl.h vararg_decl.h struct_decl.h layout.h

report="$work/results.tsv"
printf 'source\tstatus\tdiagnostic\n' > "$report"
unexpected=0
while IFS= read -r src; do
  suite=${src%%/*}
  stem=${src%.c}
  log="$work/evidence/$stem"
  mkdir -p "$(dirname "$log")"
  flags=(-fno-pie -DSYSTEM_linux -I"$root/modules/CompCert/runtime/include")
  case "$suite" in
    regression) flags+=(-fall -DARCH_riscV -DMODEL_"$bits") ;;
    raytracer|spass) flags+=(-fstruct-passing) ;;
    abi) flags+=(-fstruct-passing) ;;
    pic) flags+=(-fpic) ;;
  esac
  # Preprocess once with the installed D-ABI libc headers. Only the .i is
  # reused: no D-ABI objects or libraries enter an F-only executable.
  status=baseline-rejected
  if timeout 120 "$compiler" -conf "$standard_config" "${flags[@]}" -E \
       -o "$log.i" "$work/test/$src" > "$log.preprocess.log" 2>&1 &&
     timeout 120 "$compiler" -conf "$standard_config" "${flags[@]}" -S \
       -o "$log.standard.s" "$log.i" > "$log.standard.log" 2>&1; then
    if timeout 120 "$compiler" -conf "$fp32_config" "${flags[@]}" -S \
         -o "$log.fp32.s" "$log.i" > "$log.fp32.log" 2>&1; then
      if "riscv$bits-linux-gnu-as" -march="rv${bits}imf_zicsr" -mabi="$abi" \
           -o "$log.o" "$log.fp32.s" > "$log.assemble.log" 2>&1; then
        status=compile-pass
      else
        status=assembly-failed
        unexpected=1
      fi
    elif grep -Eq 'FP32( kernel)?:' "$log.fp32.log"; then
      status=profile-rejected
    else
      status=unexpected-compile-failure
      unexpected=1
    fi
  fi
  diagnostic=$(sed -n '/error:\|FP32:/ { s/.*error: //; p; q; }' "$log".*.log | tr '\t\n' '  ')
  printf '%s\t%s\t%s\n' "$src" "$status" "$diagnostic" >> "$report"
done < <(cd "$work/test" && find c compression raytracer spass regression abi pic export \
  -name '*.c' -type f | LC_ALL=C sort)

echo "RV$bits $profile upstream suite (translation units; compilation is not execution):"
awk -F '\t' 'NR > 1 { count[$2]++ } END { for (s in count) print "  " s ": " count[s] }' "$report" | LC_ALL=C sort

printf 'source\tstatus\n' > "$work/execution.tsv"
for src in regression/{expr3,expr4,extern1,ptrs1,struct9,types1}.c export/{bitfields,issue216}.c; do
  stem=${src%.c}
  name=${stem##*/}
  log="$work/evidence/$stem"
  if ! awk -F '\t' -v src="$src" '$1 == src && $2 == "compile-pass" { found=1 } END { exit !found }' "$report"; then
    echo "Required upstream leaf test did not compile: $src" >&2
    exit 1
  fi
  "riscv$bits-linux-gnu-gcc" -march="rv${bits}imf_zicsr" -mabi="$abi" \
    -mno-relax -fno-pie -O2 -ffreestanding -fno-builtin -fno-stack-protector \
    -nostdlib -static -no-pie -Wl,--no-relax,-e,_start -DTEST_"$name" \
    "$root/test/riscv-fp32/start.S" "$root/test/riscv-fp32/upstream-main.c" \
    "$log.o" -o "$log.elf"
  status=run-pass
  if ! timeout 30 "qemu-riscv$bits" -cpu "rv$bits,d=false" "$log.elf" > "$log.run.log" 2>&1; then
    status=run-failed
    unexpected=1
  fi
  printf '%s\t%s\n' "$src" "$status" >> "$work/execution.tsv"
done
if [ "$mode" = calls ]; then
  log="$work/evidence/export/issue319"
  "riscv$bits-linux-gnu-gcc" -march="rv${bits}imf_zicsr" -mabi="$abi" \
    -mno-relax -fno-pie -nostdlib -static -no-pie -Wl,--no-relax,-e,_start \
    "$root/test/riscv-fp32/start.S" "$log.o" -o "$log.elf"
  exit_status=0
  timeout 30 "qemu-riscv$bits" -cpu "rv$bits,d=false" "$log.elf" \
    > "$log.run.log" 2>&1 || exit_status=$?
  status=run-pass
  if [ "$exit_status" != 48 ]; then
    status=run-failed
    unexpected=1
  fi
  printf 'export/issue319.c\t%s\n' "$status" >> "$work/execution.tsv"
fi
cat "$work/execution.tsv"
cut -f1,2 "$report" > "$work/status.tsv"
if [ ! -f "$expected" ]; then
  echo "Missing reviewed baseline: $expected" >&2
  exit 1
fi
diff -u "$expected" "$work/status.tsv"
exit "$unexpected"
