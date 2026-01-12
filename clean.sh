#!/bin/bash

# FaithConnect - Clean & Get Dependencies
# This script cleans the project and reinstalls dependencies

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/faith_connect" || exit 1

echo "🧹 Cleaning project..."
flutter clean

echo ""
echo "📦 Getting dependencies..."
flutter pub get

echo ""
echo "✅ Done! Project is clean and dependencies are installed."
