#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/DerivedData/Build/Products/Release/counter.app"
OUT="$ROOT/build/CounterApp-1.0.0.dmg"

if [ ! -d "$APP" ]; then
    echo "Build the app first: scripts/build_app.sh" >&2
    exit 1
fi

rm -f "$OUT"
hdiutil create -volname "CounterApp" -srcfolder "$APP" -ov -format UDZO "$OUT"

echo "DMG created at $OUT"
