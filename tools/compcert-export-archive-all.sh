#!/usr/bin/env bash
# Build a compcert-export-<target>.tar.gz release archive for each of
# x86_32, x86_64, arm, and aarch64. The Rocq extraction (and hence
# compcert-lib's generated backend sources - see the Makefile's
# compcert-lib-sync) differs per architecture, so a single export archive
# only ever covers whichever target CompCert was last configured for; this
# drives the existing single-target compcert-extraction-archive /
# compcert-export-archive Make targets once per architecture via their
# COMPCERT_TARGET / COMPCERT_EXTRACTION_ARCHIVE / COMPCERT_EXPORT_ARCHIVE
# overrides, and verifies each with a -version smoke test before moving on.
#
# Unlike tools/compcert-cross-smoke.sh, this needs no cross-compiler or
# QEMU: Rocq extraction and the exported OCaml library are built and run
# with the host's own OCaml/dune, regardless of which target they describe.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)

# name:configure-target pairs, using the same target names as
# tools/compcert-cross-smoke.sh.
TARGETS=(
  "x86_32:x86_32-linux"
  "x86_64:x86_64-linux"
  "arm:arm-linux"
  "aarch64:aarch64-linux"
)

cd "$REPO_ROOT"

built=()
for entry in "${TARGETS[@]}"; do
  name="${entry%%:*}"
  target="${entry#*:}"
  extraction_archive="compcert-extraction-$name.tar.gz"
  export_archive="compcert-export-$name.tar.gz"

  echo "== [$name] extraction-archive ($target) =="
  make COMPCERT_TARGET="$target" COMPCERT_EXTRACTION_ARCHIVE="$extraction_archive" compcert-extraction-archive

  echo "== [$name] export-archive =="
  make COMPCERT_EXTRACTION_ARCHIVE="$extraction_archive" COMPCERT_EXPORT_ARCHIVE="$export_archive" compcert-export-archive

  echo "== [$name] verifying exported package builds and runs =="
  make COMPCERT_EXPORT_ARCHIVE="$export_archive" compcert-export-run ARGS=-version | grep CompCert

  echo "== [$name] OK: $export_archive =="
  built+=("$export_archive")
done

echo ""
echo "All 4 export archives built: ${built[*]}"
