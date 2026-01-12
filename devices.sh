#!/bin/bash

# FaithConnect - Show Devices
# This script lists all available devices

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/faith_connect" || exit 1

echo "📱 Available Devices:"
echo ""
flutter devices
