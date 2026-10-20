#!/usr/bin/env bash
# Verify compcert-embed-<target>.tar.gz from the export package alone, with no
# Rocq (this is what the `embed` job runs after `extract`):
#
#   1. install the export's ccomp (the oracle) and build the embed tarball
#   2. corpus: CompCert's test programs preprocessed by that ccomp
#   3. native: every file equals `ccomp -S`, error cases, any order in one
#      process, repeated compiles (test/native/check.sh); property tests of the
#      list functions, Str, the hash and the unit tests of the stack rewrites
#   4. js_of_ocaml: byte-identical to native under node at V8's default stack
#      (with and without -g),
#      and the published input limits (EMBED_LIMITS=1)
#   5. Melange (when melc is available): byte-identical too, and the same on
#      the Melange limits
#   6. the generated assembly runs under QEMU and matches Results/
#
# Usage: tools/compcert-embed-verify.sh <target> [<compcert-export-target.tar.gz> [<embed-out.tar.gz>]]
# The embed package that was verified is copied to <embed-out.tar.gz> if given.
# Environment: EMBED_VERIFY_WORK (work root, default <repo>/.embed-verify-work),
# EMBED_LIMITS=1 (check the published input limits), EMBED_MELANGE=0 (skip
# Melange), EMBED_REPEATS (repeated compiles, default 300), EMBED_BROWSER_DIR
# (collect what test/browser/run.mjs needs: both JavaScript builds, the corpus
# and the native results).
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
WORK_ROOT="${EMBED_VERIFY_WORK:-$REPO_ROOT/.embed-verify-work}"

# shellcheck source=compcert-targets.sh
. "$SCRIPT_DIR/compcert-targets.sh"

Fatal() { echo "FATAL: $*" >&2; exit 1; }
Opam() { if command -v opam >/dev/null 2>&1; then opam exec -- "$@"; else "$@"; fi; }
Step() { echo "== [$target] $* =="; }

# drop_internal <native-g-dir> <other-dir>...: ccomp -S -g dies on a few inputs
# (an assertion in Dwarfgen with struct passing), which the embed API reports as
# an internal error, status 3, with a message that names the source file as the
# backend sees it; those entries are not compared.
drop_internal() {
  local ref=$1 s n rel d
  shift
  for s in "$ref"/*/*.status; do
    [ "$(cat "$s")" = 3 ] || continue
    n=${s%.status}; rel=${n#"$ref"/}
    echo "  -g: internal error on $rel in every backend: not compared"
    for d in "$ref" "$@"; do rm -f "$d/$rel".s "$d/$rel".err "$d/$rel".status; done
  done
}

target="${1:-}"
[ -n "$target" ] || Fatal "usage: $0 <target> [<export.tar.gz>]"
target_config "$target" || exit 1
export_tar=$(realpath "${2:-$REPO_ROOT/compcert-export-$target.tar.gz}")
[ -f "$export_tar" ] || Fatal "missing $export_tar"
embed_out=""
[ -z "${3:-}" ] || embed_out=$(realpath -m "$3")
[ -z "${EMBED_BROWSER_DIR:-}" ] || EMBED_BROWSER_DIR=$(realpath -m "$EMBED_BROWSER_DIR")
for tool in node "${TOOLPREFIX}gcc" "${TOOLPREFIX}as" "$QEMU_BIN"; do
  command -v "$tool" >/dev/null 2>&1 || Fatal "missing $tool"
done
Opam sh -c 'command -v js_of_ocaml' >/dev/null 2>&1 || Fatal "missing js_of_ocaml (opam install js_of_ocaml)"

work="$WORK_ROOT/$target"
rm -rf "$work"
mkdir -p "$work/export" "$work/embed"

Step "install the export's ccomp and build the embed package"
tar -xzf "$export_tar" -C "$work/export"
(cd "$work/export" && Opam ./install.sh "$work/prefix" > "$work/install.log" 2>&1) || { tail -20 "$work/install.log" >&2; Fatal "export install failed"; }
COMPCERT_EMBED_EXPORT="$export_tar" COMPCERT_EMBED_WORK="$work/embed-work" \
  "$SCRIPT_DIR/compcert-embed-target.sh" "$target" "$work/embed.tar.gz"
# The package is a function of the export package: building it again gives the same bytes.
COMPCERT_EMBED_EXPORT="$export_tar" COMPCERT_EMBED_WORK="$work/embed-work" \
  "$SCRIPT_DIR/compcert-embed-target.sh" "$target" "$work/embed-again.tar.gz" > /dev/null
cmp "$work/embed.tar.gz" "$work/embed-again.tar.gz" || Fatal "the embed package is not reproducible"
tar -xzf "$work/embed.tar.gz" -C "$work/embed"

Step "corpus"
Opam "$SCRIPT_DIR/compcert-embed-corpus.sh" "$target" "$work/prefix" "$work/corpus"
corpus="$work/corpus"

config=compcert.ini
[ ! -f "$work/prefix/share/compcert.freestanding.ini" ] || config=compcert.freestanding.ini
export COMPCERT_CONFIG="$work/prefix/share/$config"
export CCOMP="$work/prefix/bin/ccomp"
export CCOMP_ARGS="${CCOMP_EXTRA_ARGS[*]}"

cd "$work/embed"
Step "native: equals ccomp -S, any order, repeated"
Opam test/native/check.sh "$corpus" "${EMBED_REPEATS:-300}"

Step "property and unit tests"
Opam dune build --profile release ./test ./jsoo 2>&1 | tail -20
Opam dune test ./test/hash ./test/shims --force
Opam ./_build/default/test/stack/unit.exe

run=_build/default/test/diff/run.exe
cli="$PWD/_build/default/test/native/embed_cli.exe"
"$run" run "$cli" "$corpus" "$work/out-native" > /dev/null
# (inputs that ccomp -g itself dies on are internal errors here, status 3: not a failure of the run)
"$run" run "$cli -g" "$corpus" "$work/out-native-g" > /dev/null || true

Step "js_of_ocaml under node --stack-size=984"
export CC_BUNDLE="$PWD/_build/default/jsoo/compcert_jsoo.bc.js"
"$run" run "node --stack-size=984 $PWD/test/node/compile.js" "$corpus" "$work/out-jsoo" | tail -2
"$run" compare "$work/out-native" "$work/out-jsoo"
CC_DEBUG=1 "$run" run "node --stack-size=984 $PWD/test/node/compile.js" "$corpus" "$work/out-jsoo-g" | tail -1 || true
drop_internal "$work/out-native-g" "$work/out-jsoo-g" "$work/out-melange-g"
"$run" compare "$work/out-native-g" "$work/out-jsoo-g"
if [ "${EMBED_LIMITS:-0}" = 1 ]; then
  node test/stack/limits.js
fi

melange_out=""
if [ "${EMBED_MELANGE:-auto}" != 0 ] && Opam sh -c 'command -v melc' >/dev/null 2>&1; then
  Step "Melange under node --stack-size=984"
  COMPCERT_MELANGE=true Opam dune build ./melange/bind 2>&1 | tail -20
  export CC_BUNDLE="$PWD/_build/default/melange/bind/out/melange/bind/compcert_melange.js"
  "$run" run "node --stack-size=984 $PWD/test/node/compile.js" "$corpus" "$work/out-melange" | tail -2
  "$run" compare "$work/out-native" "$work/out-melange"
  CC_DEBUG=1 "$run" run "node --stack-size=984 $PWD/test/node/compile.js" "$corpus" "$work/out-melange-g" | tail -1 || true
  "$run" compare "$work/out-native-g" "$work/out-melange-g"
  melange_out="$work/out-melange"
  if [ "${EMBED_LIMITS:-0}" = 1 ]; then
    node test/stack/limits.js --limits test/stack/limits-melange.txt
  fi
else
  echo "== [$target] Melange skipped (no melc) =="
fi

if [ -n "${EMBED_BROWSER_DIR:-}" ]; then
  chmod -R u+w "$EMBED_BROWSER_DIR" 2>/dev/null || true
  rm -rf "$EMBED_BROWSER_DIR"
  mkdir -p "$EMBED_BROWSER_DIR"
  cp _build/default/jsoo/compcert_jsoo.bc.js "$EMBED_BROWSER_DIR/"
  [ -z "$melange_out" ] || cp -r _build/default/melange/bind/out "$EMBED_BROWSER_DIR/melange-out"
  cp -r "$corpus" "$EMBED_BROWSER_DIR/corpus"
  cp -r "$work/out-native" "$EMBED_BROWSER_DIR/expected"
  echo "$corpus" > "$EMBED_BROWSER_DIR/corpus-path.txt"
fi

if [ "$TARGET_PROFILE" = fp32 ]; then
  echo "== [$target] QEMU run skipped: the fp32 profile has no libc to run test/c with =="
else
  Step "the assembly runs under QEMU"
  Opam "$SCRIPT_DIR/compcert-embed-qemu.sh" "$target" "$work/prefix" "${melange_out:-$work/out-jsoo}"
fi
if [ -n "$embed_out" ]; then
  mkdir -p "$(dirname "$embed_out")"
  cp "$work/embed.tar.gz" "$embed_out"
fi
echo "== [$target] embed OK =="
