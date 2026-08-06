#!/usr/bin/env bash
# Build compcert-export-<target>.tar.gz for x86_32, x86_64, arm, and
# aarch64. Rocq extraction (and compcert-lib's generated sources) differs
# per architecture, so this loops the Makefile's single-target
# extraction-archive/export-archive over all 4 via their COMPCERT_TARGET /
# COMPCERT_EXTRACTION_ARCHIVE / COMPCERT_EXPORT_ARCHIVE overrides, verifying
# each with a -version smoke test. Unlike cross-smoke.sh, no cross-compiler
# or QEMU needed - this builds/runs with the host's own OCaml/dune.
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
