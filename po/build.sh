#!/usr/bin/env bash
# Compile po/*.po into the package (package/contents/locale/<lang>/LC_MESSAGES/*.mo).
set -euo pipefail
cd "$(dirname "$0")/.."
DOMAIN="plasma_applet_io.github.luminarysrc.plasmaisland"
for po in po/*.po; do
    lang="$(basename "$po" .po)"
    dir="package/contents/locale/$lang/LC_MESSAGES"
    mkdir -p "$dir"
    msgfmt "$po" -o "$dir/$DOMAIN.mo"
done

# Per-widget language choice: the same strings as a JS dictionary (see po/gen-js.py).
python3 po/gen-js.py
