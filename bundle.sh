#!/bin/bash

set -e  # Exit on error

APP_NAME="MacCleaner"
VERSION="${1:-1.0.0}"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
DMG_NAME="$APP_NAME-v$VERSION.dmg"
DMG_DIR="dist"

echo "🔨 Building $APP_NAME v$VERSION..."
swift build -c release

echo "📦 Creating App Bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ $APP_NAME.app created successfully!"

# Create DMG if requested
if [ "$2" == "--dmg" ]; then
    echo "💿 Creating DMG..."
    mkdir -p "$DMG_DIR"
    
    # Remove old DMG if exists
    rm -f "$DMG_DIR/$DMG_NAME"
    
    # Create a temporary directory for the DMG content
    TMP_DMG_DIR=$(mktemp -d)
    cp -R "$APP_BUNDLE" "$TMP_DMG_DIR/"
    
    # Create DMG using hdiutil
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$TMP_DMG_DIR" \
        -ov -format UDZO \
        "$DMG_DIR/$DMG_NAME"
    
    # Clean up
    rm -rf "$TMP_DMG_DIR"
    
    # Calculate SHA256
    SHA256=$(shasum -a 256 "$DMG_DIR/$DMG_NAME" | awk '{print $1}')
    echo "$SHA256" > "$DMG_DIR/$DMG_NAME.sha256"
    
    echo "✅ DMG created: $DMG_DIR/$DMG_NAME"
    echo "📝 SHA256: $SHA256"
else
    echo "💡 Tip: Run './bundle.sh $VERSION --dmg' to create a DMG package"
fi

echo ""
echo "You can now open it with: open $APP_NAME.app"
