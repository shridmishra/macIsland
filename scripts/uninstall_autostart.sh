#!/bin/bash
PLIST_PATH="$HOME/Library/LaunchAgents/com.macisland.app.plist"

echo "Unloading and removing LaunchAgent..."
launchctl unload -w "$PLIST_PATH" 2>/dev/null || true
rm -f "$PLIST_PATH"

echo "✅ Mac Island LaunchAgent removed."
