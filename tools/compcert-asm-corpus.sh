#!/usr/bin/env bash
# Build compcert-asm-<target>.tar.gz: the assembly CompCert emits for its own
# small-test suites, with the sources and reference outputs it came from, so a
# consumer can check an assembler against real compiler output without a
# CompCert build.
#
#   sources/{c,regression,compression}/, sources/endian.h   the C inputs
#   asm/<suite>/<name>.s                                    ccomp -S output
#   asm/runtime/*.S                                         the runtime's own assembly
#   results/<suite>/                                        the suites' Results/
#   manifest.txt                                            one block per suite
#
# The compiler is the one installed from compcert-export-<target>.tar.gz
# (its install.sh), never a CompCert source-tree build.
#
# Usage: tools/compcert-asm-corpus.sh <target> <prefix> <export-dir> [<out.tar.gz>]
#   <prefix>      install.sh's prefix (bin/ccomp, share/compcert.ini)
#   <export-dir>  the unpacked export tarball (runtime sources, MANIFEST)
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
TESTS="$REPO_ROOT/modules/CompCert/test"

# shellcheck source=compcert-targets.sh
. "$SCRIPT_DIR/compcert-targets.sh"

Fatal() { echo "FATAL: $*" >&2; exit 1; }

target="${1:-}"
prefix="${2:-}"
export_dir="${3:-}"
[ -n "$target" ] && [ -n "$prefix" ] && [ -n "$export_dir" ] ||
  Fatal "usage: $0 <target> <prefix> <export-dir> [<out.tar.gz>]"
target_config "$target" || exit 1
output=$(realpath -m "${4:-$REPO_ROOT/compcert-asm-$target.tar.gz}")
prefix=$(realpath "$prefix")
export_dir=$(realpath "$export_dir")

ccomp="$prefix/bin/ccomp"
[ -x "$ccomp" ] || Fatal "no $ccomp"
[ -d "$TESTS/c" ] || Fatal "missing $TESTS (CompCert test submodule)"

# The RISC-V fixtures were always generated freestanding.
config=compcert.ini
if [ -f "$prefix/share/compcert.freestanding.ini" ]; then
  config=compcert.freestanding.ini
fi
export COMPCERT_CONFIG="$prefix/share/$config"

ccomp_version=$("$ccomp" -version | head -n1)
revision=$(sed -n 's/^compcert-revision: //p' "$export_dir/MANIFEST")
[ -n "$revision" ] || Fatal "no compcert-revision in $export_dir/MANIFEST"
header_sha=$(sha256sum "$TESTS/endian.h" | cut -d' ' -f1)

root="${CORPUS_WORK:-$REPO_ROOT/.corpus-work}/$target"
rm -rf "$root"
mkdir -p "$root/sources" "$root/asm" "$root/results"
cp "$TESTS/endian.h" "$root/sources/"

# ccomp writes its command line into the .s header, so the hashes depend on
# the paths it is given. Invoke it from a scratch directory that presents the
# sources under the historical modules/CompCert/test path, which keeps the
# hashes equal to the ones already recorded for these suites.
legacy="${CORPUS_WORK:-$REPO_ROOT/.corpus-work}/legacy-$target"
rm -rf "$legacy"
mkdir -p "$legacy/modules/CompCert"
ln -s "$root/sources" "$legacy/modules/CompCert/test"

manifest="$root/manifest.txt"
: > "$manifest"

sha() { sha256sum "$1" | cut -d' ' -f1; }

# suite_block <suite> <args...>: compile every .c of the suite, in place.
suite_block() {
  local suite=$1; shift
  local args=("${CCOMP_EXTRA_ARGS[@]}" "$@")
  mkdir -p "$root/sources/$suite" "$root/asm/$suite"
  cp "$TESTS/$suite"/*.c "$TESTS/$suite"/*.h "$root/sources/$suite/" 2>/dev/null || true
  if [ -d "$TESTS/$suite/Results" ]; then
    mkdir -p "$root/results/$suite"
    cp -r "$TESTS/$suite/Results/." "$root/results/$suite/"
  fi
  {
    [ ! -s "$manifest" ] || echo
    echo "suite:$suite"
    echo "target:$target"
    echo "ccomp-version:$ccomp_version"
    echo "ccomp-args:${args[*]}"
    echo "compcert-revision:$revision"
    echo "shared-header:test/endian.h	sha256:$header_sha"
    echo "config:$config"
  } >> "$manifest"
  local src name out err tmp reason
  for src in $(cd "$root" && ls sources/"$suite"/*.c | LC_ALL=C sort); do
    name=$(basename "$src" .c)
    out="asm/$suite/$name.s"
    err="$root/.err"
    tmp=".corpus-work/$suite/$target/$name/output.s"
    mkdir -p "$legacy/$(dirname "$tmp")"
    if (cd "$legacy" && "$ccomp" -S "${args[@]}" -o "$tmp" "modules/CompCert/test/$suite/$name.c") 2>"$err"; then
      mv "$legacy/$tmp" "$root/$out"
      printf '%s\tsource-sha256:%s\tgenerated-sha256:%s\toutcome:accepted\n' \
        "$src" "$(sha "$root/$src")" "$(sha "$root/$out")" >> "$manifest"
    else
      reason=$(grep -m1 . "$err" | sed 's#modules/CompCert/test/#sources/#' || true)
      printf '%s\tsource-sha256:%s\toutcome:compile-failed\treason:%s\n' \
        "$src" "$(sha "$root/$src")" "${reason:-(no diagnostic)}" >> "$manifest"
    fi
  done
  rm -f "$root/.err"
}

suite_block c
suite_block regression -fall
suite_block compression

# The runtime's own assembly is copied, not compiled.
arch=$(grep '^ARCH=' "$export_dir/Makefile.config" | cut -d= -f2)
bitsize=$(grep '^BITSIZE=' "$export_dir/Makefile.config" | cut -d= -f2)
rtdir="$export_dir/runtime/$arch"
[ -d "$export_dir/runtime/${arch}_${bitsize}" ] && rtdir="$export_dir/runtime/${arch}_${bitsize}"
mkdir -p "$root/asm/runtime"
{
  echo
  echo "suite:runtime"
  echo "target:$target"
  echo "compcert-revision:$revision"
} >> "$manifest"
for f in $(cd "$rtdir" && ls -- *.S 2>/dev/null | LC_ALL=C sort); do
  cp "$rtdir/$f" "$root/asm/runtime/$f"
  h=$(sha "$root/asm/runtime/$f")
  printf 'asm/runtime/%s\tsource-sha256:%s\tgenerated-sha256:%s\toutcome:copied\n' "$f" "$h" "$h" >> "$manifest"
done

mkdir -p "$(dirname "$output")"
(cd "$root" && find . -mindepth 1 | LC_ALL=C sort | tar -cf - --no-recursion --owner=0 --group=0 --numeric-owner --mtime=@0 -T - | gzip -n > "$output")
echo "== [$target] OK: $output =="
grep -c 'outcome:accepted' "$manifest" | sed 's/^/accepted: /'
grep -c 'outcome:compile-failed' "$manifest" | sed 's/^/compile-failed: /' || true
