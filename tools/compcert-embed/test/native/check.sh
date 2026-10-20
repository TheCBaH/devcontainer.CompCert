#!/usr/bin/env bash
# Native oracle check, run from the root of an unpacked compcert-embed package:
#   test/native/check.sh <corpus-dir> [<repeat>]
# Environment: CCOMP, COMPCERT_CONFIG and CCOMP_ARGS as for ccomp-backend.sh.
#
# 1. every corpus file: the embed API equals `ccomp -S` (assembly after the
#    banner, diagnostics, and whether it compiled);
# 2. error inputs (syntax, type, an unpreprocessed #include): same diagnostics;
# 3. <repeat> compiles of one file in one process: identical, flat resident set.
set -euo pipefail
corpus=$(realpath "${1:?usage: $0 <corpus-dir> [<repeat>]}")
repeat="${2:-1000}"
here=$(cd "$(dirname "$0")/../.." && pwd)
cd "$here"
dune build ./test
run=_build/default/test/diff/run.exe
cli=$here/_build/default/test/native/embed_cli.exe
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

"$run" run "$here/test/native/ccomp-backend.sh" "$corpus" "$work/ref"
"$run" run "$cli" "$corpus" "$work/emb"
"$run" compare "$work/ref" "$work/emb"

mkdir -p "$work/err"
printf 'int f(int x) { return x +; }\n' > "$work/err/syntax.i"
printf 'int f(void) { return undefined_name; }\n' > "$work/err/type.i"
printf '#include <stdio.h>\nint f(void) { return 0; }\n' > "$work/err/include.i"
printf 'void g(int x) { int *p = x; }\n' > "$work/err/ptr.i"
for n in syntax type include ptr; do
  ref_status=0; emb_status=0
  "$here/test/native/ccomp-backend.sh" "$work/err/$n.i" > "$work/err/$n.ref.s" 2> "$work/err/$n.ref.err" || ref_status=$?
  "$cli" "$work/err/$n.i" > "$work/err/$n.emb.s" 2> "$work/err/$n.emb.err" || emb_status=$?
  [ "$ref_status" = "$emb_status" ] || { echo "FAIL $n: status $ref_status vs $emb_status"; exit 1; }
  cmp "$work/err/$n.ref.err" "$work/err/$n.emb.err" || { echo "FAIL $n: diagnostics differ"; exit 1; }
  echo "error case $n: status $emb_status, diagnostics identical"
done

file=$(head -n1 "$corpus/ok.txt")
"$cli" --repeat "$repeat" "$corpus/$file.i" 2> "$work/repeat.log" > /dev/null
cat "$work/repeat.log"
read -r warm end < <(sed -n 's/^rss after warmup \([0-9]*\) kB, at end \([0-9]*\) kB$/\1 \2/p' "$work/repeat.log")
[ "$((end * 10))" -le "$((warm * 11))" ] || { echo "FAIL: resident set grew from $warm to $end kB"; exit 1; }
echo "OK: $repeat repeats identical, resident set flat"
