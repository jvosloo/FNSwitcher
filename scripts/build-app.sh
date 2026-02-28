#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
SPM_DIR="$PROJECT_DIR/FNSwitcher"
APP_NAME="FNSwitcher"
BUNDLE_ID="com.fnswitcher.app"
BUILD_DIR="$PROJECT_DIR/dist"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building release binary..."
cd "$SPM_DIR"
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$SPM_DIR/.build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Create Info.plist
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
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
PLIST

# Ad-hoc code sign
echo "Code signing (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE"

# Create ZIP for distribution
echo "Creating ZIP..."
cd "$BUILD_DIR"
zip -r "$APP_NAME.zip" "$APP_NAME.app"

echo ""
echo "Done!"
echo "  App bundle: $APP_BUNDLE"
echo "  ZIP:        $BUILD_DIR/$APP_NAME.zip"
echo ""
echo "To install: unzip and drag FNSwitcher.app to /Applications"
echo "First launch: right-click → Open to bypass Gatekeeper"