#!/usr/bin/env bash
# Build compcert-embed-<target>.tar.gz from a target's export package: the same
# extracted CompCert sources with a strict one-line-per-file patch and a few
# injected modules, so the compiler reads its input from memory and prints
# assembly into a buffer. The result is a dune project (library
# compcert_<target>_embed, wrapped) that needs no Rocq:
#
#   dune-project, src/   patched sources, injected embed_*.ml, embed_config_data.ml
#   test/                native API test, differential driver
#   api/                 Compcert_js, the backend-neutral compile API
#   patches/embed.patch  the patch that was applied
#   LICENSE, MANIFEST    upstream license; provenance and sha256 of every file
#
# Usage: tools/compcert-embed-target.sh <target> [<output.tar.gz>]
# Input: COMPCERT_EMBED_EXPORT, a compcert-export-<target>.tar.gz or an unpacked
# export directory; default <repo>/compcert-export-<target>.tar.gz.
# Work root: COMPCERT_EMBED_WORK, default <repo>/.compcert-embed-work.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
EMBED_DIR="$SCRIPT_DIR/compcert-embed"
WORK_ROOT="${COMPCERT_EMBED_WORK:-$REPO_ROOT/.compcert-embed-work}"

# shellcheck source=compcert-targets.sh
. "$SCRIPT_DIR/compcert-targets.sh"

Fatal() { echo "FATAL: $*" >&2; exit 1; }
Opam() { if command -v opam >/dev/null 2>&1; then opam exec -- "$@"; else "$@"; fi; }

target="${1:-}"
[ -n "$target" ] || Fatal "usage: $0 <target> [<output.tar.gz>]  (targets: ${COMPCERT_TARGETS[*]})"
target_config "$target" || exit 1
output=$(realpath -m "${2:-$REPO_ROOT/compcert-embed-$target.tar.gz}")
input=$(realpath -m "${COMPCERT_EMBED_EXPORT:-$REPO_ROOT/compcert-export-$target.tar.gz}")
pkg="compcert_${target}_embed"

stage="$WORK_ROOT/stage/$target"
rm -rf "$stage" "$WORK_ROOT/export/$target"
mkdir -p "$stage/src" "$stage/patches"

if [ -d "$input" ]; then
  export_dir="$input"
  export_sha=$(sha256sum "$export_dir/MANIFEST" | cut -d' ' -f1)
else
  [ -f "$input" ] || Fatal "missing export package $input"
  export_dir="$WORK_ROOT/export/$target"
  mkdir -p "$export_dir"
  tar -xzf "$input" -C "$export_dir"
  export_sha=$(sha256sum "$input" | cut -d' ' -f1)
fi
for f in MANIFEST LICENSE compcert.ini src/Readconfig.ml; do
  [ -f "$export_dir/$f" ] || Fatal "export package lacks $f"
done

echo "== [$target] copying and patching sources =="
cp "$export_dir"/src/* "$stage/src/"
cp "$EMBED_DIR/common.patch" "$stage/patches/embed.patch"
patch -s --fuzz=0 -p1 -d "$stage/src" < "$stage/patches/embed.patch"
if [ -n "$(find "$stage" \( -name '*.rej' -o -name '*.orig' \))" ]; then
  find "$stage" \( -name '*.rej' -o -name '*.orig' \) >&2
  Fatal "patch left reject or backup files"
fi
injected=(embed_argv.ml embed_asm_out.ml embed_config.ml embed_diag_out.ml embed_source_in.ml)
for f in "${injected[@]}"; do cp "$EMBED_DIR/$f" "$stage/src/$f"; done

# The profile whose configuration the embedded compiler reports: the
# freestanding one where the export has it, as the RISC-V runtime-less profiles
# do, otherwise the default.
ini=compcert.ini
[ ! -f "$export_dir/compcert.freestanding.ini" ] || ini=compcert.freestanding.ini
"$EMBED_DIR/gen-config-data.sh" "$export_dir/$ini" "$export_dir/src/Readconfig.ml" \
  > "$stage/src/embed_config_data.ml"

mli_only=""
for f in "$stage"/src/*.mli; do
  [ -e "${f%.mli}.ml" ] && continue
  b=$(basename "$f" .mli)
  mli_only="$mli_only $(printf '%s' "${b:0:1}" | tr '[:upper:]' '[:lower:]')${b:1}"
done

version=$(sed -n 's/^compcert-version: //p' "$export_dir/MANIFEST")
cat > "$stage/dune-project" <<EOT
(lang dune 3.0)
(name $pkg)
(package
 (name $pkg)
 (synopsis "CompCert $version $target, in-memory embed variant"))
EOT
cat > "$stage/src/dune" <<EOT
(library
 (name $pkg)
 (public_name $pkg)
 (libraries str unix menhirLib)
 (modules_without_implementation$mli_only)
 (flags
  (:standard -w -a -strict-sequence)))
EOT

# The backend-neutral API, built on the embed library of this package.
mkdir -p "$stage/api"
cp "$EMBED_DIR/api/compcert_js.ml" "$stage/api/"
sed "s/@PKG@/$pkg/" "$EMBED_DIR/api/dune.in" > "$stage/api/dune"
echo "module CC = $(printf '%s' "${pkg:0:1}" | tr '[:lower:]' '[:upper:]')${pkg:1}" > "$stage/api/embed_cc.ml"
mkdir -p "$stage/jsoo" "$stage/test"
cp "$EMBED_DIR"/jsoo/* "$stage/jsoo/"
cp -r "$EMBED_DIR/test/." "$stage/test/"
cp "$export_dir/LICENSE" "$stage/LICENSE"

if grep -rIl -e "$REPO_ROOT" -e "$WORK_ROOT" "$stage" >/dev/null; then
  grep -rIl -e "$REPO_ROOT" -e "$WORK_ROOT" "$stage" >&2
  Fatal "host paths leaked into the package"
fi
if [ -n "$(find "$stage" -type l)" ]; then
  find "$stage" -type l >&2
  Fatal "symlinks in the package"
fi

{
  grep -E '^(compcert-version|compcert-revision|target|profile|configure|ocaml|menhir):' "$export_dir/MANIFEST"
  echo "export-sha256: $export_sha"
  echo "embed-patch: $(sha256sum "$stage/patches/embed.patch" | cut -d' ' -f1)"
  echo "embed-config: $ini"
  for f in "${injected[@]}"; do
    echo "embed-module: $f $(sha256sum "$stage/src/$f" | cut -d' ' -f1)"
  done
  echo "api-sources: compcert_js.ml $(sha256sum "$EMBED_DIR/api/compcert_js.ml" | cut -d' ' -f1)"
  echo "sha256:"
  (cd "$stage" && find . -type f ! -name MANIFEST | LC_ALL=C sort | sed 's#^\./##' | xargs sha256sum | sed 's/^/  /')
} > "$stage/MANIFEST"

mkdir -p "$(dirname "$output")"
(cd "$stage" && find . -mindepth 1 | LC_ALL=C sort | tar -cf - --no-recursion --owner=0 --group=0 --numeric-owner --mtime=@0 -T - | gzip -n > "$output")
echo "== [$target] OK: $output =="
