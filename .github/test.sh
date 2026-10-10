#!/usr/bin/env sh

STATEFILE=$(mktemp -t state.XXXXXX)
trap "rm -f $STATEFILE" EXIT

rgbasm -Weverything -s "equ,var:$STATEFILE" example.asm

if grep -E "^def __" "$STATEFILE"; then
  echo "Unpurged internal temporary symbols!"
  exit 1
fi
