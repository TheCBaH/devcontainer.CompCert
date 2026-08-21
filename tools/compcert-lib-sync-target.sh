#!/usr/bin/env bash
# Sync one target's Coq-extracted + hand-written CompCert OCaml sources into
# compcert-lib-<target>/src, so it can be depended on as an ordinary dune
# library (compcert_<target>) independent of whichever ARCH happens to be
# configured in modules/CompCert/Makefile.config.
#
# This is compcert-lib-sync (see ../Makefile) generalized to run for an
# arbitrary target rather than "whatever ARCH is currently configured", by
# giving each target its own linkhier-mirrored, independently-./configure'd
# source tree - the same isolation trick tools/compcert-fixture-setup.sh
# already uses to build six coexisting freestanding compilers. Unlike that
# script, this one never touches a cross C toolchain: depend/extraction/
# modorder are pure Rocq+OCaml+Menhir steps, so no -toolprefix'd cc/as/ld or
# QEMU is required here.
#
# Work root: COMPCERT_LIB_WORK, default <repo>/.compcert-lib-work. Deliberately
# not .fixture-work or .cross-smoke-work: each of those suites recreates its
# own build/install/artifacts destructively, and a shared root would let one
# suite's run delete another's evidence mid-flight.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
COMPCERT_DIR="$REPO_ROOT/modules/CompCert"
WORK_ROOT="${COMPCERT_LIB_WORK:-$REPO_ROOT/.compcert-lib-work}"
JOBS="${COMPCERT_JOBS:-$(nproc)}"

# shellcheck source=target-matrix.sh
. "$SCRIPT_DIR/target-matrix.sh"

Fatal() { echo "FATAL: $*" >&2; exit 1; }
usage() { echo "Usage: $0 <target>  (targets: ${FIXTURE_TARGETS[*]})" >&2; }
Opam() { if command -v opam >/dev/null 2>&1; then opam exec -- "$@"; else "$@"; fi; }

target="${1:-}"
found=false
for t in "${FIXTURE_TARGETS[@]}"; do
  [ "$t" = "$target" ] && found=true
done
if [ "$found" != true ]; then
  usage
  Fatal "unknown target '$target'"
fi

target_config "$target"

build="$WORK_ROOT/build/$target"
libdir="$REPO_ROOT/compcert-lib-$target"

rm -rf "$build"
mkdir -p "$build"
echo "== [$target] mirroring CompCert source tree =="
(cd "$COMPCERT_DIR" && ./tools/linkhier "$build")

echo "== [$target] configuring =="
(cd "$build" && Opam ./configure -toolprefix "$TOOLPREFIX" \
  "${COMPCERT_CONFIGURE_ARGS[@]}" "$CONFIGURE_TARGET")

echo "== [$target] computing dependencies and extracting =="
(cd "$build" && Opam make -j"$JOBS" depend)
(cd "$build" && Opam make -j"$JOBS" extraction)
(cd "$build" && Opam make compcert.ini driver/Version.ml tools/modorder)
(cd "$build" && Opam make -f Makefile.extr depend)

echo "== [$target] syncing into $libdir/src =="
[ -d "$libdir/src" ] || Fatal "missing $libdir/src - is compcert-lib-$target/ scaffolding committed?"
rm -f "$libdir"/src/*.ml "$libdir"/src/*.mli
mkdir -p "$libdir/src"

objs=$(cd "$build" && tools/modorder .depend.extr driver/Driver.cmx)
[ -n "$objs" ] || Fatal "modorder listed no modules"
for o in $objs; do
  src="${o%.cmx}.ml"
  if [ "$src" != driver/Driver.ml ]; then
    cp "$build/$src" "$libdir/src/"
    [ -f "$build/${src}i" ] && cp "$build/${src}i" "$libdir/src/"
  fi
done

# Interface-only modules (cparser/C.mli, debug/D*Types.mli) have no .cmx, so
# modorder never names them, but the modules above won't compile without
# them - see also src/dune's modules_without_implementation. Which arch
# subdirectory holds them depends on whether this target has a split
# <arch>_<bitsize> directory (mirrors modules/CompCert/Makefile's own
# ARCHDIRS test, lines 25-28, rather than assuming a bare $arch as the
# single-target compcert-lib-sync recipe does - x86_32/x86_64 do have a
# split dir and would silently lose their .mli-only modules otherwise).
arch=$(grep '^ARCH=' "$build/Makefile.config" | cut -d= -f2)
bitsize=$(grep '^BITSIZE=' "$build/Makefile.config" | cut -d= -f2)
if [ -d "$build/${arch}_${bitsize}" ]; then
  archdirs="${arch}_${bitsize} $arch"
else
  archdirs="$arch"
fi
for d in extraction lib common $archdirs backend cfrontend cparser debug driver; do
  for f in "$build/$d"/*.mli; do
    [ -e "$f" ] || continue
    [ -e "${f%.mli}.ml" ] || cp "$f" "$libdir/src/"
  done
done

echo "== [$target] done: $libdir/src synced =="
