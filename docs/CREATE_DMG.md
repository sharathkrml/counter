# Creating a DMG for CounterApp

This guide covers producing a distributable `CounterApp-1.0.0.dmg` from a release build.

## Prerequisites

- Xcode (with a valid signing identity for distribution, or use ad-hoc signing for local testing).
- A completed Release build of the app (see `scripts/build_app.sh`).
- `hdiutil` (ships with macOS).

## 1. Build the app (Release)

```bash
./scripts/build_app.sh
```

This runs `xcodebuild` in Release configuration and outputs:

```
build/DerivedData/Build/Products/Release/counter.app
```

## 2. (Optional) Bundle the Python sidecar

For a shipping build the sidecar must be embedded. With PyInstaller:

```bash
cd backend
source .venv/bin/activate
pip install pyinstaller
pyinstaller --onefile --name counter-backend src/counter_backend/main.py
# copy dist/counter-backend into the app bundle:
cp dist/counter-backend ../build/DerivedData/Build/Products/Release/counter.app/Contents/Resources/Backend/
```

Then update `BackendManager.resolvePythonPath()` to prefer the bundled executable.

## 3. Code sign (distribution)

```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: YOUR NAME (TEAMID)" \
  build/DerivedData/Build/Products/Release/counter.app
```

Verify:

```bash
codesign --verify --deep --strict --verbose=2 build/DerivedData/Build/Products/Release/counter.app
spctl --assess --type exec --verbose build/DerivedData/Build/Products/Release/counter.app
```

## 4. Create the DMG

Use the provided script:

```bash
./scripts/create_dmg.sh
```

Or manually:

```bash
hdiutil create \
  -volname "CounterApp" \
  -srcfolder build/DerivedData/Build/Products/Release/counter.app \
  -ov -format UDZO \
  build/CounterApp-1.0.0.dmg
```

## 5. Notarize (required for Gatekeeper on customer Macs)

```bash
xcrun notarytool submit build/CounterApp-1.0.0.dmg \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password" \
  --wait
```

Then staple the ticket:

```bash
xcrun stapler staple build/CounterApp-1.0.0.dmg
```

## 6. Verify on a clean machine

- Copy the DMG to a Mac without Xcode/Python dev tools.
- Open, drag `CounterApp.app` to `/Applications`.
- Launch and confirm the counter works and persists across restarts.

## Troubleshooting

- **"damaged and can't be opened"**: notarization missing or signature invalid; re-run steps 3–5.
- **Backend fails to start**: check `~/Library/Application Support/com.personal.counter/` logs; ensure the bundled binary is executable (`chmod +x`).
- **Port conflicts**: the backend auto-allocates a port; no manual port configuration needed.
