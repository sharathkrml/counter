#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

xcodebuild \
  -project "$ROOT/counter.xcodeproj" \
  -scheme counter \
  -configuration Release \
  -derivedDataPath "$ROOT/build/DerivedData" \
  build

echo "App build OK"
