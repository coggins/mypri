#!/bin/bash
# Builds MyPri.app: compiles the Swift package in release mode and
# assembles a standard macOS .app bundle with icon + Info.plist.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="MyPri"
BUILD_DIR=".build/release"
APP_BUNDLE="dist/${APP_NAME}.app"

echo "==> Building Swift package (release)…"
swift build -c release

echo "==> Assembling app bundle…"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

echo "==> Code signing (ad-hoc)…"
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Done: $APP_BUNDLE"
