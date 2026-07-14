#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Mac Deep Cleaner"
BUNDLE_ID="app.macdeepcleaner"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$ROOT_DIR/$APP_NAME.app"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"

cd "$ROOT_DIR"

swift build -c release

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp ".build/release/MacDeepCleaner" "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

/usr/bin/plutil -create xml1 "$APP_DIR/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleName -string "$APP_NAME" "$APP_DIR/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleDisplayName -string "$APP_NAME" "$APP_DIR/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleExecutable -string "$APP_NAME" "$APP_DIR/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$APP_DIR/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleVersion -string "1" "$APP_DIR/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleShortVersionString -string "1.0" "$APP_DIR/Contents/Info.plist"
/usr/bin/plutil -replace LSMinimumSystemVersion -string "14.0" "$APP_DIR/Contents/Info.plist"
/usr/bin/plutil -replace NSHighResolutionCapable -bool YES "$APP_DIR/Contents/Info.plist"

/usr/bin/ditto "$APP_DIR" "$INSTALL_DIR/$APP_NAME.app"

echo "Installed: $INSTALL_DIR/$APP_NAME.app"
echo "Open: open \"$INSTALL_DIR/$APP_NAME.app\""
