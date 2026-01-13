#!/bin/bash

# Build script for ClipboardManager
# This script builds the app and creates a DMG installer

set -e

echo "🔨 Building ClipboardManager..."

# Clean build folder
rm -rf build/

# Build the app for Release
xcodebuild -project ClipboardManager.xcodeproj \
    -scheme ClipboardManager \
    -configuration Release \
    -derivedDataPath build \
    -arch arm64 \
    clean build

echo "✅ Build complete!"

# Create DMG
echo "📦 Creating DMG..."

APP_PATH="build/Build/Products/Release/ClipboardManager.app"
DMG_PATH="ClipboardManager.dmg"

# Remove old DMG if exists
rm -f "$DMG_PATH"

# Create temporary DMG folder
TMP_DMG_DIR="build/dmg_temp"
rm -rf "$TMP_DMG_DIR"
mkdir -p "$TMP_DMG_DIR"

# Copy app to temp folder
cp -R "$APP_PATH" "$TMP_DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$TMP_DMG_DIR/Applications"

# Create DMG
hdiutil create -volname "ClipboardManager" \
    -srcfolder "$TMP_DMG_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

# Clean up
rm -rf "$TMP_DMG_DIR"

echo "✅ DMG created: $DMG_PATH"
echo ""
echo "📱 Installation:"
echo "1. Open ClipboardManager.dmg"
echo "2. Drag ClipboardManager to Applications folder"
echo "3. Launch from Applications"
echo ""
echo "⌨️  Keyboard shortcut: ⌘⇧V to show/hide clipboard history"
