#!/usr/bin/env bash
# Write SHA256SUMS and artifacts.json for a directory holding the
# compcert-export-<t>.tar.gz and compcert-asm-<t>.tar.gz of every target.
#
# artifacts.json is what a consumer checks against its own target config:
# per target, the configure target and tool prefix the tarballs were built for.
#
# Usage: tools/compcert-artifacts-index.sh <dir> [<tag>]
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=compcert-targets.sh
. "$SCRIPT_DIR/compcert-targets.sh"

Fatal() { echo "FATAL: $*" >&2; exit 1; }

dir="${1:-}"
[ -d "$dir" ] || Fatal "usage: $0 <dir> [<tag>]"
tag="${2:-untagged}"
cd "$dir"

files=()
for t in "${COMPCERT_TARGETS[@]}"; do
  for f in "compcert-export-$t.tar.gz" "compcert-asm-$t.tar.gz"; do
    [ -f "$f" ] || Fatal "missing $dir/$f"
    files+=("$f")
  done
done
sha256sum "${files[@]}" > SHA256SUMS

manifest_field() { tar -xOzf "compcert-export-$1.tar.gz" ./MANIFEST | sed -n "s/^$2: //p" | head -n1; }

version=$(manifest_field "${COMPCERT_TARGETS[0]}" compcert-version)
revision=$(manifest_field "${COMPCERT_TARGETS[0]}" compcert-revision)

targets='{}'
for t in "${COMPCERT_TARGETS[@]}"; do
  target_config "$t"
  [ "$(manifest_field "$t" compcert-revision)" = "$revision" ] || Fatal "$t was built from another CompCert revision"
  targets=$(jq -n --argjson acc "$targets" --arg t "$t" \
    --arg configure "$CONFIGURE_TARGET" --arg toolprefix "$TOOLPREFIX" \
    --arg export "compcert-export-$t.tar.gz" --arg asm "compcert-asm-$t.tar.gz" \
    --arg export_sha "$(sha256sum "compcert-export-$t.tar.gz" | cut -d' ' -f1)" \
    --arg asm_sha "$(sha256sum "compcert-asm-$t.tar.gz" | cut -d' ' -f1)" \
    '$acc + {($t): {configure_target: $configure, toolprefix: $toolprefix,
      export: {file: $export, sha256: $export_sha}, asm: {file: $asm, sha256: $asm_sha}}}')
done

jq -n --arg tag "$tag" --arg version "$version" --arg revision "$revision" \
  --argjson targets "$targets" \
  '{tag: $tag, compcert_version: $version, compcert_revision: $revision, targets: $targets}' \
  > artifacts.json
echo "indexed ${#files[@]} tarballs: $dir/SHA256SUMS $dir/artifacts.json"
