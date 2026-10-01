#!/usr/bin/env bash
# Compare ccomp built by dune from the export tarball with the committed
# fixture assembly produced by the Makefile-built freestanding ccomp.
# Usage: spike/s3.sh <target>...
set -uo pipefail
cd "$(dirname "$0")/.."
. tools/compcert-targets.sh
FIX=asm/fixtures/compcert-3.17
status=0
for t in "$@"; do
  target_config "$t"
  W=$PWD/.s3-work/$t; rm -rf "$W"; mkdir -p "$W"
  t0=$(date +%s)
  COMPCERT_EXPORT_WORK=$W/work tools/compcert-export-target.sh "$t" "$W/exp.tar.gz" >"$W/export.log" 2>&1 \
    || { echo "$t: export FAILED"; tail -20 "$W/export.log"; status=1; continue; }
  t1=$(date +%s)
  mkdir "$W/pkg" && tar -C "$W/pkg" -xzf "$W/exp.tar.gz" --strip-components=1
  (cd "$W/pkg" && opam exec -- ./install.sh "$W/prefix") >"$W/install.log" 2>&1 \
    || { echo "$t: install FAILED"; tail -20 "$W/install.log"; status=1; continue; }
  t2=$(date +%s)
  echo "$t: export $((t1-t0))s, dune build+install $((t2-t1))s"
  ok=0; bad=0
  for d in "$FIX"/*/; do
    n=$(basename "$d"); src=$(ls "$d"/source/*.c | head -1); b=$(basename "${src%.c}")
    [ -f "$d/$t/$b.s" ] || continue
    ini=$W/prefix/share/compcert.ini
    [ -f "$W/pkg/compcert.freestanding.ini" ] && ini=$W/pkg/compcert.freestanding.ini
    COMPCERT_CONFIG=$ini "$W/prefix/bin/ccomp" -S "${CCOMP_EXTRA_ARGS[@]}" -o "$W/$n.s" "$src" 2>"$W/$n.err"
    if cmp -s "$W/$n.s" "$d/$t/$b.s"; then ok=$((ok+1))
    else bad=$((bad+1)); status=1; echo "DIFF $t/$n"; diff "$W/$n.s" "$d/$t/$b.s" | head -6; fi
  done
  echo "$t: identical=$ok differing=$bad"
done
exit $status
