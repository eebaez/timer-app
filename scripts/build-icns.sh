#!/bin/bash
# Compiles scripts/icon/AppIcon-1024.png into scripts/icon/AppIcon.icns
# using macOS's built-in sips/iconutil — no extra dependencies. Both
# files are tracked in git; this only needs re-running if
# AppIcon-1024.png itself is replaced (e.g. with a new design).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_DIR="$ROOT_DIR/scripts/icon"
SRC="$ICON_DIR/AppIcon-1024.png"
ICONSET="$ICON_DIR/AppIcon.iconset"

if [ ! -f "$SRC" ]; then
  echo "error: $SRC not found" >&2
  exit 1
fi

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

sips -z 16 16   "$SRC" --out "$ICONSET/icon_16x16.png" > /dev/null
sips -z 32 32   "$SRC" --out "$ICONSET/icon_16x16@2x.png" > /dev/null
sips -z 32 32   "$SRC" --out "$ICONSET/icon_32x32.png" > /dev/null
sips -z 64 64   "$SRC" --out "$ICONSET/icon_32x32@2x.png" > /dev/null
sips -z 128 128 "$SRC" --out "$ICONSET/icon_128x128.png" > /dev/null
sips -z 256 256 "$SRC" --out "$ICONSET/icon_128x128@2x.png" > /dev/null
sips -z 256 256 "$SRC" --out "$ICONSET/icon_256x256.png" > /dev/null
sips -z 512 512 "$SRC" --out "$ICONSET/icon_256x256@2x.png" > /dev/null
sips -z 512 512 "$SRC" --out "$ICONSET/icon_512x512.png" > /dev/null
cp "$SRC" "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$ICON_DIR/AppIcon.icns"
rm -rf "$ICONSET"

echo "Done: $ICON_DIR/AppIcon.icns"
