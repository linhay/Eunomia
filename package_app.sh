#!/bin/bash

APP_NAME="Enjoyable"
BUNDLE_ID="com.enjoyable.Enjoyable"
BUILD_DIR=".build/arm64-apple-macosx/debug"
APP_BUNDLE="Enjoyable.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "🔨 Building project..."
swift build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "📦 Creating App Bundle structure..."
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy Binary
cp "$BUILD_DIR/$APP_NAME" "$MACOS/"

# Copy SPM Resources if they exist
# In SPM, resources are often in a .bundle folder
find "$BUILD_DIR" -name "*_EnjoyableKit.bundle" -exec cp -R {} "$RESOURCES/" \;

# Create Info.plist
cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "🚀 Launching $APP_BUNDLE..."
killall "$APP_NAME" 2>/dev/null || true
open "$APP_BUNDLE"

echo "✅ Done!"
