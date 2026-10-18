#!/usr/bin/env sh

OUTFILE=$(mktemp -t out.XXXXXX)
ERRFILE=$(mktemp -t err.XXXXXX)
STATEFILE=$(mktemp -t state.XXXXXX)
trap "rm -f $OUTFILE $ERRFILE $STATEFILE" EXIT

rgbasm -Weverything -s "var,equ,equs:$STATEFILE" example.asm >"$OUTFILE" 2>"$ERRFILE"

if ! diff -au --strip-trailing-cr .github/example.out "$OUTFILE"; then
  echo "Unexpected stdout output!" >&2
  exit 1
fi

if ! diff -au --strip-trailing-cr .github/example.err "$ERRFILE"; then
  echo "Unexpected stderr output!" >&2
  exit 1
fi

if ! diff -au --strip-trailing-cr .github/example.dump.asm "$STATEFILE"; then
  echo "Unexpected state file output! (Unpurged internal temporary symbols?)" >&2
  exit 1
fi
