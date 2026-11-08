#!/usr/bin/env bash
# Install or update the Plasma Island widget for the current user.
set -euo pipefail

cd "$(dirname "$0")"

./po/build.sh
ID="io.github.luminarysrc.plasmaisland"

if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$ID"; then
    kpackagetool6 -t Plasma/Applet -u package
    echo
    echo "Updated. Plasma keeps the old version loaded until it restarts:"
    echo "    systemctl --user restart plasma-plasmashell"
else
    kpackagetool6 -t Plasma/Applet -i package
    echo
    echo "Installed. Right-click your top panel → Add or Manage Widgets → search \"Plasma Island\"."
fi
