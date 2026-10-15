#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source_dir="$root/modules/CompCert"
revision=a354849f0e5f52bdb9c1064b78f468369e0bf6a3

if [ "$(git -C "$source_dir" rev-parse HEAD)" != "$revision" ]; then
  echo "CompCert patches require upstream $revision" >&2
  exit 1
fi
for patch in "$root"/patches/compcert/*.patch; do
  if git -C "$source_dir" apply --reverse --check "$patch" 2>/dev/null; then
    continue
  fi
  git -C "$source_dir" apply --check "$patch"
  git -C "$source_dir" apply "$patch"
done
