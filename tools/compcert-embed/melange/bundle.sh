#!/bin/sh
# Bundle the Melange build into one minified ES module (needs esbuild in PATH):
#   melange/bundle.sh <out.mjs>
# The module exports compile(source, options), version and target.
#
# Melange emits `const` for a loop variable it reassigns in one generated
# function of the verified parser (Interpreter_complete, which never runs), and
# esbuild rejects that. Loop variables are the underscore-named ones, so they
# are made `let` in a scratch copy before bundling.
set -eu
[ $# -eq 1 ] || { echo "usage: $0 <out.mjs>" >&2; exit 2; }
root=$(cd "$(dirname "$0")/.." && pwd)
out=$(realpath -m "$1")
COMPCERT_MELANGE=true dune build --root "$root" ./melange/bind
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp -r "$root/_build/default/melange/bind/out/." "$tmp/"
chmod -R u+w "$tmp"
find "$tmp" -name '*.mjs' -exec sed -i -E 's/^( *)const (_[A-Za-z0-9_$]*) =/\1let \2 =/' {} +
esbuild "$tmp/melange/bind/compcert_melange.mjs" --bundle --format=esm --minify --outfile="$out"
