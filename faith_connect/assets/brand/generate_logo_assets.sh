#!/bin/bash

# FaithConnect Logo Asset Generator
# This script generates various logo sizes from the SVG file

echo "🎨 FaithConnect Logo Asset Generator"
echo "===================================="

# Check if ImageMagick or rsvg-convert is installed
if command -v rsvg-convert &> /dev/null; then
    CONVERTER="rsvg-convert"
elif command -v convert &> /dev/null; then
    CONVERTER="convert"
else
    echo "❌ Error: Please install rsvg-convert or ImageMagick"
    echo "   macOS: brew install librsvg"
    echo "   Ubuntu: sudo apt-get install librsvg2-bin"
    exit 1
fi

SVG_FILE="faithconnect_logo_new.svg"
OUTPUT_DIR="generated"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "📁 Output directory: $OUTPUT_DIR"
echo ""

# Generate different sizes
sizes=(1024 512 256 128 64 32)

for size in "${sizes[@]}"; do
    output_file="$OUTPUT_DIR/faithconnect_logo_${size}x${size}.png"
    
    if [ "$CONVERTER" = "rsvg-convert" ]; then
        rsvg-convert -w "$size" -h "$size" "$SVG_FILE" -o "$output_file"
    else
        convert -background none -resize "${size}x${size}" "$SVG_FILE" "$output_file"
    fi
    
    if [ -f "$output_file" ]; then
        echo "✅ Generated: $output_file"
    else
        echo "❌ Failed: $output_file"
    fi
done

# Generate iOS app icon (1024x1024 with rounded corners)
if [ "$CONVERTER" = "rsvg-convert" ]; then
    rsvg-convert -w 1024 -h 1024 "$SVG_FILE" -o "$OUTPUT_DIR/faithconnect_ios_icon.png"
    echo "✅ Generated: $OUTPUT_DIR/faithconnect_ios_icon.png"
fi

# Generate Android adaptive icon (foreground 1024x1024)
if [ "$CONVERTER" = "rsvg-convert" ]; then
    rsvg-convert -w 1024 -h 1024 "$SVG_FILE" -o "$OUTPUT_DIR/faithconnect_android_foreground.png"
    echo "✅ Generated: $OUTPUT_DIR/faithconnect_android_foreground.png"
fi

echo ""
echo "✨ Logo assets generated successfully!"
echo "📂 Check the '$OUTPUT_DIR' directory for all files"
echo ""
echo "💡 Next steps:"
echo "   1. Review generated PNG files"
echo "   2. Update app icons in iOS/Android projects"
echo "   3. Test on various devices"
