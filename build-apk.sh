#!/bin/bash

# FaithConnect - Build Release APK
# This script builds a release APK for Android

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/faith_connect" || exit 1

echo "🏗️  Building Release APK..."
echo "📂 Working directory: $(pwd)"
echo ""

flutter build apk --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "📦 APK location: build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "📊 APK size:"
    ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print $5, $9}'
else
    echo ""
    echo "❌ Build failed!"
fi
