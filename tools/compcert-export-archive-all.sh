#!/usr/bin/env bash
# Build compcert-export-<target>.tar.gz for every target in
# compcert-targets.sh (see compcert-export-target.sh for the contents). Needs
# Rocq for the extraction only; verifying the archives is
# compcert-export-verify.sh's job, and needs no Rocq.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)

# shellcheck source=compcert-targets.sh
. "$SCRIPT_DIR/compcert-targets.sh"

cd "$REPO_ROOT"
built=()
for target in "${COMPCERT_TARGETS[@]}"; do
  "$SCRIPT_DIR/compcert-export-target.sh" "$target" "compcert-export-$target.tar.gz"
  built+=("compcert-export-$target.tar.gz")
done

echo ""
echo "All ${#built[@]} export archives built: ${built[*]}"
