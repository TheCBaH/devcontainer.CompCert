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
  ini=$W/prefix/share/compcert.ini
  [ -f "$W/pkg/compcert.freestanding.ini" ] && ini=$W/pkg/compcert.freestanding.ini
  for d in "$FIX"/*/; do
    n=$(basename "$d"); [ -d "$d/$t" ] || continue
    rm -rf "$W/fx/$n"; mkdir -p "$W/fx/$n/$t"; cp -r "$d/source" "$W/fx/$n/source"
    for src in "$d"/source/*.c; do
      b=$(basename "${src%.c}")
      (cd "$W/fx/$n" && COMPCERT_CONFIG=$ini "$W/prefix/bin/ccomp" -S "${CCOMP_EXTRA_ARGS[@]}" -o "$t/$b.s" "source/$b.c" 2>"$W/$n.err")
      if cmp -s "$W/fx/$n/$t/$b.s" "$d/$t/$b.s"; then ok=$((ok+1))
      else bad=$((bad+1)); status=1; echo "DIFF $t/$n/$b"; diff "$W/fx/$n/$t/$b.s" "$d/$t/$b.s" | head -6; fi
    done
  done
  echo "$t: identical=$ok differing=$bad"
done
exit $status
