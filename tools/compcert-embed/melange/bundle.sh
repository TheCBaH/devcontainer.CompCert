#!/bin/sh
# Bundle the Melange build into one minified ES module (needs esbuild in PATH):
#   melange/bundle.sh <out.mjs> [<emitted-dir>]
# With no second argument the build is run first (dune, COMPCERT_MELANGE=true)
# and its output is used; <emitted-dir> is a copy of
# _build/default/melange/bind/out, bundled without dune or OCaml.
# The module exports compile(source, options), version and target.
#
# Melange emits `const` for a loop variable it reassigns in one generated
# function of the verified parser (Interpreter_complete, which never runs), and
# esbuild rejects that. Loop variables are the underscore-named ones, so they
# are made `let` in a scratch copy before bundling.
set -eu
[ $# -ge 1 ] && [ $# -le 2 ] || { echo "usage: $0 <out.mjs> [<emitted-dir>]" >&2; exit 2; }
root=$(cd "$(dirname "$0")/.." && pwd)
out=$(realpath -m "$1")
if [ $# -eq 2 ]; then
  emitted=$(realpath "$2")
else
  COMPCERT_MELANGE=true dune build --root "$root" ./melange/bind
  emitted="$root/_build/default/melange/bind/out"
fi
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp -r "$emitted/." "$tmp/"
chmod -R u+w "$tmp"
find "$tmp" -name '*.mjs' -exec sed -i -E 's/^( *)const (_[A-Za-z0-9_$]*) =/\1let \2 =/' {} +
esbuild "$tmp/melange/bind/compcert_melange.mjs" --bundle --format=esm --minify --outfile="$out"
