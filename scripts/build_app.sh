#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${1:-release}"
APP_NAME="Meridian"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"

if [[ "$(uname -m)" == "arm64" ]]; then
    swift build -c "$CONFIGURATION" --arch arm64
    BIN_DIR="$(swift build -c "$CONFIGURATION" --arch arm64 --show-bin-path)"
else
    swift build -c "$CONFIGURATION"
    BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BIN_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
cp "$ROOT_DIR/packaging/Info.plist" "$CONTENTS_DIR/Info.plist"
if [[ -f "$ROOT_DIR/Resources/Meridian.icns" ]]; then
    cp "$ROOT_DIR/Resources/Meridian.icns" "$RESOURCES_DIR/Meridian.icns"
fi
chmod +x "$MACOS_DIR/$APP_NAME"

if command -v codesign >/dev/null 2>&1; then
    codesign --force --sign - --timestamp=none "$APP_DIR" >/dev/null
fi

echo "$APP_DIR"
