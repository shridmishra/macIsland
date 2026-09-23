#!/bin/bash
set -e

PLIST_PATH="$HOME/Library/LaunchAgents/com.macisland.app.plist"
APP_BIN="/Users/shrid/Repos/projects/macIsland/MacIsland.app/Contents/MacOS/MacIsland"

echo "Creating LaunchAgent at $PLIST_PATH..."
mkdir -p "$HOME/Library/LaunchAgents"

cat <<EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.macisland.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>${APP_BIN}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF

echo "Loading LaunchAgent with launchctl..."
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load -w "$PLIST_PATH"

echo "✅ Mac Island LaunchAgent installed!"
echo "Mac Island will launch automatically when you log into your Mac."
