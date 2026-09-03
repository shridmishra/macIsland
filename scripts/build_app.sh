#!/bin/bash
set -e

echo "🔨 Building Mac Island..."
swift build -c release

BUILD_BIN=".build/release/MacIsland"
APP_DIR="MacIsland.app"

echo "📦 Packaging ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# Copy binary
cp "${BUILD_BIN}" "${APP_DIR}/Contents/MacOS/MacIsland"

# Copy Info.plist
cp "Sources/MacIsland/Resources/Info.plist" "${APP_DIR}/Contents/Info.plist"

# Ad-hoc sign the app bundle for macOS Gatekeeper / ARM64 execution
codesign --force --deep --sign - "${APP_DIR}"

echo "✅ Mac Island packaged successfully into ${APP_DIR}!"
echo "To run, execute: open ${APP_DIR}"
