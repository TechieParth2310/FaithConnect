#!/bin/bash

# FaithConnect - Quick Run Script
# This script always runs from the correct directory

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the faith_connect directory
cd "$SCRIPT_DIR/faith_connect" || {
    echo "❌ Error: faith_connect directory not found"
    exit 1
}

echo "📱 FaithConnect - Running from: $(pwd)"
echo ""

# Check if a device ID is provided as argument
if [ -n "$1" ]; then
    echo "🚀 Running on device: $1"
    flutter run -d "$1"
else
    echo "📋 Available devices:"
    flutter devices
    echo ""
    echo "💡 To run on a specific device, use: ./run.sh DEVICE_ID"
    echo "   Example: ./run.sh ZD222C8W4J"
fi
