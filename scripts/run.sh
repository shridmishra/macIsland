#!/bin/bash
set -e

echo "🔨 Compiling Mac Island (Debug)..."
swift build

echo "🚀 Launching Mac Island..."
.build/debug/MacIsland
