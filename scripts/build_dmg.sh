#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build_dmg_tmp"
DMG_NAME="Vapor-macOS-AppleSilicon.dmg"
DMG_PATH="$ROOT_DIR/$DMG_NAME"

echo "=================================================="
echo " Building Vapor DMG Package for macOS"
echo "=================================================="

rm -rf "$BUILD_DIR" "$DMG_PATH"
mkdir -p "$BUILD_DIR"

# Ensure Vapor GUI binary is up to date
echo "[-] Compiling SwiftUI binary..."
mkdir -p "$ROOT_DIR/gui"
swiftc -parse-as-library -O "$ROOT_DIR/gui/VaporApp.swift" -o "$ROOT_DIR/gui/Vapor"

# Ensure .app bundle structure
APP_DIR="$ROOT_DIR/Vapor.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp "$ROOT_DIR/gui/Vapor" "$APP_DIR/Contents/MacOS/Vapor"

echo "[-] Staging files..."
cp -R "$APP_DIR" "$BUILD_DIR/"
ln -s /Applications "$BUILD_DIR/Applications"

echo "[-] Generating DMG using hdiutil..."
hdiutil create -volname "Vapor Installer" -srcfolder "$BUILD_DIR" -ov -format UDZO "$DMG_PATH"

rm -rf "$BUILD_DIR"

echo "=================================================="
echo "✓ Successfully generated DMG:"
echo "  Path: $DMG_PATH"
echo "  Size: $(du -h "$DMG_PATH" | cut -f1)"
echo "=================================================="
