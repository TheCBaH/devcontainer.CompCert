#!/usr/bin/env bash
# Find which CompCert code recurses on a long input, natively and without a
# stack limit: build a scratch copy of the package whose modules all open
# stack_probe.ml, then compile the input with the bytecode CLI.
#   test/stack/probe.sh <shape> <N> [<limit>]
# Run from the root of an unpacked package. Prints every call site that passed a
# list longer than the limit to one of the probed functions (the lists the
# input makes long), then the outcome of the compile.
set -euo pipefail
here=$(cd "$(dirname "$0")/../.." && pwd)
shape=${1:?usage: $0 <shape> <N> [<limit>]}; n=${2:?}
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
cp -r "$here/api" "$here/src" "$here/test" "$here/dune-project" "$scratch/"
mkdir "$scratch/probe"
cp "$here/test/stack/stack_probe.ml" "$scratch/probe/"
printf "(package (name stack_probe))\n" >> "$scratch/dune-project"
printf '(library (name stack_probe) (public_name stack_probe) (wrapped false) (libraries unix) (flags (:standard -w -a)))\n' > "$scratch/probe/dune"
sed -i 's/(libraries str unix menhirLib)/(libraries str unix menhirLib stack_probe)/; s/-strict-sequence/-strict-sequence -open Stack_probe/' "$scratch/src/dune"
rm -rf "$scratch/test/diff" "$scratch/test/node"
printf '(executable (name embed_cli) (modes byte) (flags (:standard -w -a)) (libraries compcert_js))\n' > "$scratch/test/native/dune"
(cd "$scratch" && dune build ./test/native/embed_cli.bc 2>&1 | head -20)
node "$here/test/stack/gen.js" "$shape" "$n" > "$scratch/in.i"
# With PROBE_STACK=<words> the bytecode stack is that small and the real
# overflow is shown instead: its innermost frames, repeated ones collapsed.
if [ -n "${PROBE_STACK:-}" ]; then
  OCAMLRUNPARAM=b,l=$PROBE_STACK "$scratch/_build/default/test/native/embed_cli.bc" "$scratch/in.i" 2>&1 >/dev/null |
    grep -v '^$' | sed -E 's/, characters [0-9-]+//; s#Compcert_[a-z0-9_]+__##' | uniq -c | head -"${PROBE_LINES:-16}" || true
else
  PROBE_LIMIT=${3:-2000} OCAMLRUNPARAM=b,l=512M "$scratch/_build/default/test/native/embed_cli.bc" "$scratch/in.i" 2>&1 >/dev/null |
    grep -E '^(probe:|error:)' | sed -E 's#Compcert_[a-z0-9_]+__##' || true
fi
