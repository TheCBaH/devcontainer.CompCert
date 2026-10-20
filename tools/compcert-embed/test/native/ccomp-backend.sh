#!/bin/sh
# The reference backend for the differential driver: the export package's own
# ccomp -S on a preprocessed file. Environment: CCOMP (the binary),
# COMPCERT_CONFIG, CCOMP_ARGS (target flags).
out=$(mktemp)
trap 'rm -f "$out"' EXIT
# shellcheck disable=SC2086
"$CCOMP" $CCOMP_ARGS -fstruct-passing -S -o "$out" "$1" || exit 1
cat "$out"
