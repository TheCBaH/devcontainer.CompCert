#!/usr/bin/env bash
# Preprocess CompCert's own C test programs into the input corpus of the embed
# variant, and record which of them the target's ccomp rejects.
#
#   <out-dir>/<suite>/<name>.i   preprocessed source (suites: c regression
#                                raytracer compression spass)
#   <out-dir>/expected-fail.txt  <suite>/<name> that `ccomp -S` rejects
#   <out-dir>/ok.txt             <suite>/<name> that it accepts
#
# Acceptance is judged with -fstruct-passing, which the embed API enables by
# default. Preprocessing is done by the installed ccomp itself (`ccomp -E`), so the
# predefined macros, the wchar type and the target's cpp are exactly the ones
# ccomp uses, whatever the profile.
#
# Usage: tools/compcert-embed-corpus.sh <target> <prefix> <out-dir>
#   <prefix>  install prefix of compcert-export-<target>.tar.gz (bin/ccomp)
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
TESTS="$REPO_ROOT/modules/CompCert/test"

# shellcheck source=compcert-targets.sh
. "$SCRIPT_DIR/compcert-targets.sh"

Fatal() { echo "FATAL: $*" >&2; exit 1; }

target="${1:-}"
prefix="${2:-}"
out="${3:-}"
[ -n "$target" ] && [ -n "$prefix" ] && [ -n "$out" ] || Fatal "usage: $0 <target> <prefix> <out-dir>"
target_config "$target" || exit 1
prefix=$(realpath "$prefix")
ccomp="$prefix/bin/ccomp"
[ -x "$ccomp" ] || Fatal "no $ccomp"
[ -d "$TESTS/c" ] || Fatal "missing $TESTS (CompCert test submodule)"

config=compcert.ini
[ ! -f "$prefix/share/compcert.freestanding.ini" ] || config=compcert.freestanding.ini
export COMPCERT_CONFIG="$prefix/share/$config"

rm -rf "$out"
mkdir -p "$out"
out=$(realpath "$out")
: > "$out/ok.txt"
: > "$out/expected-fail.txt"

for suite in c regression raytracer compression spass; do
  mkdir -p "$out/$suite"
  for src in "$TESTS/$suite"/*.c; do
    name=$(basename "$src" .c)
    # -I for the includes next to the sources (endian.h lives one level up).
    "$ccomp" -E -I"$TESTS" -I"$TESTS/$suite" -o "$out/$suite/$name.i" "$src" ||
      Fatal "cannot preprocess $suite/$name"
    if "$ccomp" "${CCOMP_EXTRA_ARGS[@]}" -fstruct-passing -S -o /dev/null "$out/$suite/$name.i" >/dev/null 2>&1; then
      echo "$suite/$name" >> "$out/ok.txt"
    else
      echo "$suite/$name" >> "$out/expected-fail.txt"
    fi
  done
done
echo "== [$target] corpus: $(wc -l < "$out/ok.txt") ok, $(wc -l < "$out/expected-fail.txt") expected failures =="
