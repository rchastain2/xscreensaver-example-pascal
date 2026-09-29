#!/bin/bash
set -e

if pgrep -f xscreensaver-settings >/dev/null; then
  echo "Close xscreensaver-settings first." >&2
  exit 1
fi

cd "$(dirname "$0")"
make
sudo install -m 755 orrery /usr/libexec/xscreensaver/
sudo install -m 644 orrery.xml /usr/share/xscreensaver/config/
sed -i "/^programs:/,/^\$/ s|^\$|\t\t\t\t  orrery \\\\n\\\\\n|" ~/.xscreensaver
