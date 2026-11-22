#!/bin/bash
#
# save-live-to-scaffold.sh
#
# Copies each live web/sites/<site>/settings.php back into
# scaffold/<site>.settings.php for sites where they differ, but only when
# nothing in the scaffold file would be lost: every line the live file
# changes or removes must have a replacement with the same key (the text
# before the first "="). Changed values (e.g. client_id/client_secret) and
# added lines are fine; anything else is skipped for manual review.
# scaffold/ is backed up once, right before the first copy.
#
# Usage (as webmaster): bash save-live-to-scaffold.sh

set -u
cd /home/esn-hungary/htdocs/new-hungary.esn.hu || exit 1

# keys '<'  -> keys of lines only in scaffold;  keys '>' -> only in live
keys() { sed -n "s/^$1 *\([^=]*\)=.*/\1/p" | sed 's/[[:space:]]*$//' | sort -u; }

backed_up=0
for D in $(ls web/sites | grep esn.hu); do
  S="scaffold/${D%.esn.hu}.settings.php"
  L="web/sites/$D/settings.php"

  if diff -q "$S" "$L" >/dev/null; then
    echo "$D: same"
    continue
  fi

  d=$(diff "$S" "$L")
  lost=$(comm -23 <(echo "$d" | keys '<') <(echo "$d" | keys '>'))
  if [ -n "$lost" ] || echo "$d" | grep '^<' | grep -qv '='; then
    echo "$D: SKIPPED - scaffold has lines the live file lacks (review manually)"
    continue
  fi

  if [ "$backed_up" -eq 0 ]; then
    sudo -u esn-hungary cp -a scaffold "scaffold.bak-$(date +%Y%m%d-%H%M%S)"
    backed_up=1
  fi
  sudo -u esn-hungary cp "$L" "$S" && echo "$D: saved ($(echo "$d" | grep -c '^>') lines changed or added)"
done