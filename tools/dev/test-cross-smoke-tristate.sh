#!/usr/bin/env bash
# The cross-smoke suite's three-state result: OK / FAIL / SKIP.
#
# SKIP is the state that matters and the one nothing tested. A target whose
# cross compiler or user-mode emulator is absent on this host is SKIPPED, not
# failed, and the run still exits 0 - that is what lets the suite pass on a
# 32-bit host like i386 or armhf, which ships neither for the 64-bit targets.
# If SKIP ever collapsed into FAIL, those legs would go red for a reason that
# is not a defect; if it collapsed into OK, a leg that silently tested nothing
# would report success. Both are invisible on a developer machine that has
# every cross toolchain installed - which is exactly why this needs a test that
# does not depend on what happens to be installed.
#
# The two SKIP checks run BEFORE anything is built, so the whole suite can be
# exercised in a second by running it under a PATH that lacks the tool in
# question. OK is not asserted here: it needs four full CompCert builds and is
# what `make asm-libc-cross-smoke` is for.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
SMOKE="$REPO_ROOT/tools/compcert-cross-smoke.sh"

SCRATCH=$(mktemp -d)
trap 'rm -rf -- "$SCRATCH"' EXIT

pass=0
fail=0

check() {
  local name=$1 cond=$2
  if [ "$cond" = 0 ]; then echo "  ok   $name"; pass=$((pass + 1))
  else echo "  FAIL $name" >&2; fail=$((fail + 1)); fi
}

# A PATH holding only what the script needs to REACH its skip checks. Anything
# it would need in order to build is deliberately absent, so a run that got past
# the skip check could not quietly succeed at something else.
minimal_path() {
  local dir=$1 t
  mkdir -p "$dir"
  for t in bash sh dirname cat sed grep cp mkdir rm ln nproc; do
    ln -sf "$(command -v "$t")" "$dir/$t"
  done
}

run_smoke() {
  local path=$1 target=$2 out=$3 rc=0
  env PATH="$path" CROSS_SMOKE_WORK="$SCRATCH/work" "$SMOKE" "$target" >"$out" 2>&1 || rc=$?
  echo "$rc"
}

echo "cross-smoke tri-state:"

# {1 SKIP because the cross compiler is absent}
bin="$SCRATCH/bin-nogcc"
minimal_path "$bin"
rc=$(run_smoke "$bin" x86_32 "$SCRATCH/nogcc.log")
check "no cross gcc: exits 0" "$([ "$rc" = 0 ] && echo 0 || echo 1)"
check "no cross gcc: reports SKIP with the reason" \
  "$(grep -q 'SKIP: i686-linux-gnu-gcc not installed' "$SCRATCH/nogcc.log" && echo 0 || echo 1)"
check "no cross gcc: summary line says SKIP" \
  "$(grep -qE '^  x86_32: SKIP$' "$SCRATCH/nogcc.log" && echo 0 || echo 1)"
check "no cross gcc: counted as skipped, not passed" \
  "$(grep -q '(1 skipped)' "$SCRATCH/nogcc.log" && echo 0 || echo 1)"
# Nothing may be built: the skip has to happen before the work root is touched,
# or a 32-bit leg would spend a Rocq build before discovering it cannot run.
check "no cross gcc: built nothing" \
  "$([ ! -d "$SCRATCH/work/build/x86_32" ] && echo 0 || echo 1)"

# {2 SKIP because the emulator is absent}
#
# A DISTINCT branch, and the one that actually fires on a 32-bit host: the cross
# compiler for a 64-bit target can be installed while no qemu-user binary for it
# exists, because a 32-bit process cannot address a 64-bit guest.
bin2="$SCRATCH/bin-noqemu"
minimal_path "$bin2"
ln -sf "$(command -v i686-linux-gnu-gcc)" "$bin2/i686-linux-gnu-gcc"
rc=$(run_smoke "$bin2" x86_32 "$SCRATCH/noqemu.log")
check "no emulator: exits 0" "$([ "$rc" = 0 ] && echo 0 || echo 1)"
check "no emulator: reports SKIP naming the emulator, not the compiler" \
  "$(grep -q 'SKIP: qemu-i386 not installed' "$SCRATCH/noqemu.log" && echo 0 || echo 1)"
check "no emulator: built nothing" \
  "$([ ! -d "$SCRATCH/work/build/x86_32" ] && echo 0 || echo 1)"

# {3 FAIL is distinct from SKIP}
#
# Past both skip checks and then unable to proceed. Without this the two states
# would be indistinguishable here, and a change that turned every failure into a
# skip would leave every check above green.
bin3="$SCRATCH/bin-broken"
minimal_path "$bin3"
ln -sf "$(command -v i686-linux-gnu-gcc)" "$bin3/i686-linux-gnu-gcc"
ln -sf "$(command -v qemu-i386)" "$bin3/qemu-i386"
rc=$(run_smoke "$bin3" x86_32 "$SCRATCH/broken.log")
check "build failure: exits non-zero" "$([ "$rc" != 0 ] && echo 0 || echo 1)"
check "build failure: exits 1, not the 2 that means SKIP" \
  "$([ "$rc" = 1 ] && echo 0 || echo 1)"
check "build failure: summary line says FAIL" \
  "$(grep -qE '^  x86_32: FAIL$' "$SCRATCH/broken.log" && echo 0 || echo 1)"
check "build failure: not reported as skipped" \
  "$(grep -q 'x86_32: SKIP' "$SCRATCH/broken.log" && echo 1 || echo 0)"

# {4 all: every target skipped is still a pass}
rc=$(run_smoke "$bin" all "$SCRATCH/all.log")
check "all targets skipped: exits 0" "$([ "$rc" = 0 ] && echo 0 || echo 1)"
want=$("$REPO_ROOT/tools/target-matrix.sh" libc | wc -l)
check "all targets skipped: every libc target reported, from the matrix" \
  "$([ "$(grep -cE '^  [a-z0-9_]+: SKIP$' "$SCRATCH/all.log")" = "$want" ] && echo 0 || echo 1)"

# {5 usage names the matrix rather than a hand-written list}
#
# This is the copy that nothing overrode, so it was the one free to drift.
rc=$(run_smoke "$bin" nonsense "$SCRATCH/usage.log")
check "unknown target: exits 1" "$([ "$rc" = 1 ] && echo 0 || echo 1)"
expected="Usage: $SMOKE [$("$REPO_ROOT/tools/target-matrix.sh" libc | paste -sd'|')|all]"
check "unknown target: usage lists exactly the matrix's libc set" \
  "$(grep -qxF "$expected" "$SCRATCH/usage.log" && echo 0 || echo 1)"

echo "cross-smoke tri-state: $pass ok, $fail failed"
[ "$fail" -eq 0 ]
