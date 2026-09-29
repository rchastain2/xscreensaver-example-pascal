#!/bin/bash
set -e

if pgrep -f xscreensaver-settings >/dev/null; then
  echo "Close xscreensaver-settings first." >&2
  exit 1
fi

DEMO=$(realpath "$1")
sed -i "/^programs:/,/^\$/ s|^\$|\t\t\t\t  $DEMO \\\\n\\\\\n|" ~/.xscreensaver
