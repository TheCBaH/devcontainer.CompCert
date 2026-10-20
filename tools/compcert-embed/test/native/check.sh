#!/usr/bin/env bash
# Native oracle check, run from the root of an unpacked compcert-embed package:
#   test/native/check.sh <corpus-dir> [<repeat>]
# Environment: CCOMP, COMPCERT_CONFIG and CCOMP_ARGS as for ccomp-backend.sh.
#
# 1. every corpus file: the embed API equals `ccomp -S` (assembly after the
#    banner, diagnostics, and whether it compiled);
# 2. error inputs (syntax, type, an unpreprocessed #include): same diagnostics;
# 2b. the same with -g (debug information), apart from the source lines that
#    `ccomp -S -g` copies into comments, which need the C files: the embed
#    variant reads none; and the same output whatever the hash seed;
# 3. the corpus compiled in one process, forwards, backwards and shuffled: a
#    compile must not depend on the ones before it;
# 4. <repeat> compiles of one file in one process: identical, flat resident set.
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

CCOMP_ARGS="${CCOMP_ARGS:-} -g" "$run" run "$here/test/native/ccomp-backend.sh" "$corpus" "$work/ref-g"
# (the inputs ccomp itself fails on make the embed variant report an internal error: status 3)
"$run" run "$cli -g" "$corpus" "$work/emb-g" || true
# `ccomp -S -g` itself dies on a few inputs (an assertion in Dwarfgen with
# struct passing); there is nothing to compare there.
for e in "$work"/ref-g/*/*.err; do
  if grep -q 'Fatal error: uncaught exception' "$e"; then
    n=${e%.err}; rel=${n#"$work"/ref-g/}
    echo "ccomp -g itself fails on $rel: not compared"
    rm -f "$n".s "$n".err "$n".status "$work/emb-g/$rel".s "$work/emb-g/$rel".err "$work/emb-g/$rel".status
  fi
done
"$run" compare --drop-source-comments "$work/ref-g" "$work/emb-g"
OCAMLRUNPARAM=R "$run" run "$cli -g" "$corpus" "$work/emb-g-seeded" > /dev/null || true
"$run" compare "$work/emb-g" "$work/emb-g-seeded"
OCAMLRUNPARAM=R "$run" run "$cli" "$corpus" "$work/emb-seeded" > /dev/null
"$run" compare "$work/emb" "$work/emb-seeded"

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

names=$(cat "$corpus/ok.txt" "$corpus/expected-fail.txt")
for order in forward reverse shuffled; do
  case $order in
    forward) list=$names ;;
    reverse) list=$(printf '%s\n' $names | tac) ;;
    shuffled) list=$(printf '%s\n' $names | shuf --random-source=<(yes)) ;;
  esac
  rm -rf "$work/many"; mkdir -p "$work/many"
  "$cli" --many "$work/many" $(for n in $list; do echo "$corpus/$n.i"; done)
  "$run" compare "$work/emb" "$work/many" || { echo "FAIL: compiling in $order order in one process differs"; exit 1; }
  echo "one process, $order order: identical"
done

file=$(head -n1 "$corpus/ok.txt")
"$cli" --repeat "$repeat" "$corpus/$file.i" 2> "$work/repeat.log" > /dev/null
cat "$work/repeat.log"
read -r warm end < <(sed -n 's/^rss after warmup \([0-9]*\) kB, at end \([0-9]*\) kB$/\1 \2/p' "$work/repeat.log")
[ "$((end * 10))" -le "$((warm * 11))" ] || { echo "FAIL: resident set grew from $warm to $end kB"; exit 1; }
echo "OK: $repeat repeats identical, resident set flat"
