#!/bin/sh
# Shipped as install.sh inside compcert-export-<target>.tar.gz.
#
# Build ccomp from the unpacked package and install it like CompCert's own
# `make install`, so that <prefix>/bin/ccomp finds <prefix>/share/compcert.ini
# and <prefix>/lib/compcert/{include,libcompcert.a}:
#
#   ./install.sh <prefix>
#
# Needs OCaml, dune, menhirLib and, for libcompcert.a, the cross toolchain that
# Makefile.config names. Run it under `opam exec --` where opam is in use.
set -eu

[ $# -eq 1 ] || { echo "usage: $0 <prefix>" >&2; exit 2; }
here=$(cd "$(dirname "$0")" && pwd)
prefix=$1
case "$prefix" in /*) ;; *) prefix=$(pwd)/$prefix ;; esac

cd "$here"
dune build --root . ./bin/main.exe @install
# runtime/Makefile compiles its C sources with ../ccomp, which finds
# ../compcert.ini next to itself.
cp _build/default/bin/main.exe ccomp
dune install --root . --prefix "$prefix" >/dev/null

mkdir -p "$prefix/share"
cp compcert.ini "$prefix/share/compcert.ini"
if [ -f compcert.freestanding.ini ]; then
  cp compcert.freestanding.ini "$prefix/share/compcert.freestanding.ini"
fi

make -C runtime all
make -C runtime install PREFIX="$prefix"
