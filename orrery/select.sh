#!/bin/bash
set -e

if pgrep -f xscreensaver-settings >/dev/null; then
  echo "Close xscreensaver-settings first." >&2
  exit 1
fi

N=$(awk '/^programs:/ { p = 1 } p && /[ \t]orrery[ \t]/ { print n; exit } p && /\\n\\$/ { n++ }' ~/.xscreensaver)
sed -i "s/^mode:.*/mode:\t\tone/; s/^selected:.*/selected:\t$N/" ~/.xscreensaver
