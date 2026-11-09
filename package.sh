#!/usr/bin/env bash
# Build plasma-island-<version>.plasmoid for upload to the KDE Store.
# Compiles the translations first: package/contents/locale/ is generated, not committed,
# so a plain `zip` of package/ would ship without them.
set -euo pipefail

cd "$(dirname "$0")"
./po/build.sh

VERSION="$(python3 -c 'import json; print(json.load(open("package/metadata.json"))["KPlugin"]["Version"])')"
OUT="$PWD/plasma-island-$VERSION.plasmoid"
rm -f "$OUT"
(cd package && zip -qr "$OUT" . -x '*.swp' '*~')

echo "Built $OUT"
unzip -l "$OUT" | grep -E 'metadata\.json|\.mo$'
