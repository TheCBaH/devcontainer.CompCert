#!/usr/bin/env bash
# Build compcert-export-<target>.tar.gz: one target's Rocq-extracted OCaml as a
# dune package (library compcert_<target>, executable ccomp), plus the files a
# consumer needs to run and link with it and no Rocq or CompCert checkout:
#
#   dune-project, src/, bin/   dune package, buildable with `dune build`
#   compcert.ini               portable: bare tool names, relative stdlib_path
#   compcert.freestanding.ini  only where the freestanding profile differs
#   Makefile.config, runtime/  `make -C runtime` builds libcompcert.a
#   install.sh <prefix>        build and install ccomp, ini, headers, runtime
#   LICENSE, MANIFEST          upstream license; versions and sha256 of every file
#
# Usage: tools/compcert-export-target.sh <target> [<output.tar.gz>]
# Work root: COMPCERT_EXPORT_WORK, default <repo>/.compcert-export-work.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
COMPCERT_DIR="$REPO_ROOT/modules/CompCert"
WORK_ROOT="${COMPCERT_EXPORT_WORK:-$REPO_ROOT/.compcert-export-work}"
JOBS="${COMPCERT_JOBS:-$(nproc)}"

# shellcheck source=compcert-targets.sh
. "$SCRIPT_DIR/compcert-targets.sh"

Fatal() { echo "FATAL: $*" >&2; exit 1; }
Opam() { if command -v opam >/dev/null 2>&1; then opam exec -- "$@"; else "$@"; fi; }

target="${1:-}"
[ -n "$target" ] || Fatal "usage: $0 <target> [<output.tar.gz>]  (targets: ${COMPCERT_TARGETS[*]})"
target_config "$target" || exit 1
output=$(realpath -m "${2:-$REPO_ROOT/compcert-export-$target.tar.gz}")

"$SCRIPT_DIR/compcert-prepare-source.sh"

build="$WORK_ROOT/build/$target"
stage="$WORK_ROOT/stage/$target"
pkg="compcert_$target"

rm -rf "$build" "$stage"
mkdir -p "$build" "$stage/src" "$stage/bin"

echo "== [$target] mirroring CompCert source tree =="
(cd "$COMPCERT_DIR" && ./tools/linkhier "$build")

configure=(-prefix /usr/local -toolprefix "$TOOLPREFIX")

# The profile every consumer links with: CompCert's own runtime library and
# headers. Extraction is independent of it.
echo "== [$target] configuring =="
(cd "$build" && Opam ./configure "${configure[@]}" "$CONFIGURE_TARGET")

echo "== [$target] computing dependencies and extracting =="
(cd "$build" && Opam make -j"$JOBS" depend)
(cd "$build" && Opam make -j"$JOBS" extraction)
(cd "$build" && Opam make compcert.ini driver/Version.ml tools/modorder)
(cd "$build" && Opam make -f Makefile.extr depend)

# compcert.ini names the toolchain by absolute path when configure was given
# one; keep the bare command so it resolves through PATH on any host.
portable_ini() {
  sed -E 's#^(prepro|linker|asm)=([^ ]*/)?([^ /]+)#\1=\3#' "$1"
}
portable_ini "$build/compcert.ini" > "$stage/compcert.ini"
if [ "$TARGET_PROFILE" = fp32 ]; then
  sed -i -e 's/^has_runtime_lib=false$/has_runtime_lib=true/' \
    -e 's/^has_standard_headers=false$/has_standard_headers=true/' "$stage/compcert.ini"
fi
sed -E 's#^PREFIX=.*#PREFIX=/usr/local#' "$build/Makefile.config" > "$stage/Makefile.config"
if [ "$TARGET_PROFILE" = fp32 ]; then
  sed -i -e 's/^HAS_RUNTIME_LIB=false$/HAS_RUNTIME_LIB=true/' \
    -e 's/^HAS_STANDARD_HEADERS=false$/HAS_STANDARD_HEADERS=true/' "$stage/Makefile.config"
fi

if [ "${#COMPCERT_CONFIGURE_ARGS[@]}" -gt 0 ]; then
  echo "== [$target] freestanding profile =="
  (cd "$build" && Opam ./configure "${configure[@]}" "${COMPCERT_CONFIGURE_ARGS[@]}" "$CONFIGURE_TARGET")
  rm -f "$build/compcert.ini"
  (cd "$build" && Opam make compcert.ini)
  portable_ini "$build/compcert.ini" > "$stage/compcert.freestanding.ini"
fi

echo "== [$target] collecting sources =="
objs=$(cd "$build" && tools/modorder .depend.extr driver/Driver.cmx)
[ -n "$objs" ] || Fatal "modorder listed no modules"
for o in $objs; do
  src="${o%.cmx}.ml"
  if [ "$src" != driver/Driver.ml ]; then
    cp "$build/$src" "$stage/src/"
    [ -f "$build/${src}i" ] && cp "$build/${src}i" "$stage/src/"
  fi
done

# Interface-only modules have no .cmx, so modorder never names them. Which arch
# directory holds them follows the Makefile's own ARCHDIRS test.
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
    [ -e "${f%.mli}.ml" ] || cp "$f" "$stage/src/"
  done
done
cp "$build/driver/Driver.ml" "$stage/bin/main.ml"

mli_only=""
for f in "$stage"/src/*.mli; do
  [ -e "${f%.mli}.ml" ] && continue
  b=$(basename "$f" .mli)
  mli_only="$mli_only $(printf '%s' "${b:0:1}" | tr '[:upper:]' '[:lower:]')${b:1}"
done

version=$(tr -d '\n' < "$COMPCERT_DIR/VERSION" | sed -E 's/^[^0-9]*//; s/[^0-9.].*$//')
cat > "$stage/dune-project" <<EOF
(lang dune 3.0)
(name $pkg)
(package
 (name $pkg)
 (synopsis "CompCert $version $target extraction, as a plain dune library"))
EOF
cat > "$stage/src/dune" <<EOF
(library
 (name $pkg)
 (public_name $pkg)
 (wrapped false)
 (libraries str unix menhirLib)
 (modules_without_implementation$mli_only)
 (flags
  (:standard -w -a -strict-sequence)))
EOF
cat > "$stage/bin/dune" <<EOF
(executable
 (name main)
 (public_name ccomp)
 (package $pkg)
 (libraries $pkg))
EOF

echo "== [$target] runtime and license =="
mkdir -p "$stage/runtime"
(cd "$build/runtime" && tar -chf - --exclude=./test --exclude='*.o' --exclude='*.a' .) | tar -xf - -C "$stage/runtime"
if [ "$TARGET_PROFILE" = fp32 ]; then
  test "$(git -C "$REPO_ROOT/modules/nanoprintf" rev-parse HEAD)" = bebaecbeaf430e36a2d30d31a2fed4e098388c93
  mkdir -p "$stage/runtime/nanoprintf" "$stage/runtime/gcc-include"
  git -C "$REPO_ROOT/modules/nanoprintf" archive HEAD nanoprintf.h LICENSE | \
    tar -xf - -C "$stage/runtime/nanoprintf"
  patch -s -d "$stage/runtime/nanoprintf" -p1 < "$REPO_ROOT/patches/nanoprintf/0001-optional-long-double.patch"
  cp "$REPO_ROOT/runtime/"*.c "$stage/runtime/"
  cp "$REPO_ROOT/runtime/include/"*.h "$stage/runtime/include/"
  cp "$REPO_ROOT/runtime/include/"*.h "$stage/runtime/gcc-include/"
  cp "$REPO_ROOT/test/riscv-fp32/start.S" "$stage/runtime/riscV/start.S"
  cp "$REPO_ROOT/runtime/Makefile.fp32" "$stage/runtime/Makefile"
  cp "$REPO_ROOT/LICENSE" "$stage/runtime/FP32-LICENSE"
  cp "$REPO_ROOT/runtime/README.fp32.md" "$stage/FP32.md"
fi
cp "$COMPCERT_DIR/LICENSE" "$stage/LICENSE"
install -m 0755 "$SCRIPT_DIR/compcert-export-install.sh" "$stage/install.sh"

if grep -rIl -e "$REPO_ROOT" -e "$WORK_ROOT" "$stage" >/dev/null; then
  grep -rIl -e "$REPO_ROOT" -e "$WORK_ROOT" "$stage" >&2
  Fatal "host paths leaked into the package"
fi

# The build tree symlinks CompCert's runtime sources; a link in the package
# would point into this checkout.
if [ -n "$(find "$stage" -type l)" ]; then
  find "$stage" -type l >&2
  Fatal "symlinks in the package"
fi

revision=$(git -C "$COMPCERT_DIR" rev-parse HEAD 2>/dev/null || echo unknown)
{
  echo "compcert-version: $version"
  echo "compcert-revision: $revision"
  for patch in "$REPO_ROOT"/patches/compcert/*.patch; do
    echo "compcert-patch: $(basename "$patch") $(sha256sum "$patch" | cut -d' ' -f1)"
  done
  echo "target: $target"
  echo "profile: $TARGET_PROFILE"
  if [ "$TARGET_PROFILE" = fp32 ]; then
    echo "isa: rv${FP32_BITS}imf_zicsr"
    echo "abi: $fp32_abi"
    echo "approximate-double-default: false"
    echo "nanoprintf-revision: $(git -C "$REPO_ROOT/modules/nanoprintf" rev-parse HEAD)"
    echo "nanoprintf-patch: $(sha256sum "$REPO_ROOT/patches/nanoprintf/0001-optional-long-double.patch" | cut -d' ' -f1)"
  fi
  echo "configure: ${configure[*]} $CONFIGURE_TARGET"
  [ "${#COMPCERT_CONFIGURE_ARGS[@]}" -eq 0 ] || echo "freestanding-configure: ${configure[*]} ${COMPCERT_CONFIGURE_ARGS[*]} $CONFIGURE_TARGET"
  echo "ocaml: $(Opam ocamlfind ocamlopt -version 2>/dev/null || Opam ocamlopt -version)"
  echo "menhir: $(Opam menhir --version | head -n1)"
  echo "rocq: $(Opam rocq --version 2>/dev/null | head -n1)"
  echo "sha256:"
  (cd "$stage" && find . -type f ! -name MANIFEST | LC_ALL=C sort | sed 's#^\./##' | xargs sha256sum | sed 's/^/  /')
} > "$stage/MANIFEST"

mkdir -p "$(dirname "$output")"
(cd "$stage" && find . -mindepth 1 | LC_ALL=C sort | tar -cf - --no-recursion --owner=0 --group=0 --numeric-owner --mtime=@0 -T - | gzip -n > "$output")
echo "== [$target] OK: $output =="
