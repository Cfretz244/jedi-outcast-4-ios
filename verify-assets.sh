#!/bin/zsh
# Verify the four JK2 pk3s in fs_homepath: present, zip-valid, checksums match
# the Steam 1.04 depot copies recorded at Phase 2 (see NOTES.md).
set -uo pipefail

BASE="$HOME/Library/Application Support/OpenJO/base"

typeset -A EXPECTED
EXPECTED=(
  assets0.pk3 e8e466f219bb2faed536021bb0d10aa6b7f5cd687302aa43080da2debdae307c
  assets1.pk3 c3a9aeaf09c93e57847290e7e5cd6c1a071a560045fa8c5e8c6df3688df841c1
  assets2.pk3 aa5bf361f7623f0210473021d73fa1e6c6997f7a5cceb6af19fce951edd43368
  assets5.pk3 7dc6bc7e599a32cc882fb2a9b741065f792ef39a129302fbd04d72ef77ee7a07
)

fail=0
for f in assets0.pk3 assets1.pk3 assets2.pk3 assets5.pk3; do
  p="$BASE/$f"
  if [[ ! -f "$p" ]]; then
    echo "MISSING  $f"; fail=1; continue
  fi
  if ! unzip -tqq "$p" >/dev/null 2>&1; then
    echo "CORRUPT  $f (zip test failed)"; fail=1; continue
  fi
  sum=$(shasum -a 256 "$p" | awk '{print $1}')
  if [[ "$sum" != "${EXPECTED[$f]}" ]]; then
    echo "MISMATCH $f (got $sum)"; fail=1
  else
    echo "OK       $f"
  fi
done

(( fail )) && { echo "FAILED"; exit 1; }
echo "All four pk3s verified."
