#!/bin/bash
# Builds a real, launchable Interview Timer.app — Phase 6 of
# docs/technical-plan.md. No Xcode project exists (this is a pure SPM
# package throughout), so this script assembles the .app bundle by
# hand: Info.plist, the release binary, ad-hoc code signing. Direct
# local distribution only, per the Technical Plan's decisions — no
# App Store, no paid Developer Program membership required.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Interview Timer"
BUNDLE_ID="com.yamherlabs.interviewtimer"
VERSION="1.0.0"
BUILD_NUMBER="1"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

echo "==> Building release binary"
cd "$ROOT_DIR"
swift build -c release

BINARY_PATH="$ROOT_DIR/.build/release/TimerMac"
if [ ! -f "$BINARY_PATH" ]; then
  echo "error: release binary not found at $BINARY_PATH" >&2
  exit 1
fi

echo "==> Assembling $APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

ICNS_PATH="$ROOT_DIR/scripts/icon/AppIcon.icns"
if [ -f "$ICNS_PATH" ]; then
  cp "$ICNS_PATH" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
  echo "warning: no icon at $ICNS_PATH — shipping without a custom icon" >&2
fi

cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>26.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Interview Timer</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
</dict>
</plist>
PLIST

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Verifying signature"
codesign --verify --verbose "$APP_BUNDLE"

echo ""
echo "Done: $APP_BUNDLE"
echo "Launch it with: open \"$APP_BUNDLE\""
echo "Or move it to /Applications and launch normally."
