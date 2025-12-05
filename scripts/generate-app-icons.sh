#!/bin/bash

# App Icon Generator for Wine Lens
# This script generates all required app icon sizes from a source image

SOURCE_IMAGE="${1:-../assets/WineLens Logo.png}"
OUTPUT_DIR="../ios/WineListAssistant/Resources/Assets.xcassets/AppIcon.appiconset"

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image not found at $SOURCE_IMAGE"
    echo "Usage: ./generate-app-icons.sh [source-image.png]"
    exit 1
fi

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is required but not installed."
    echo "Install with: brew install imagemagick"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Generating app icons from: $SOURCE_IMAGE"
echo "Output directory: $OUTPUT_DIR"

# iOS and macOS icon sizes
SIZES=(16 32 64 128 256 512 1024)

for size in "${SIZES[@]}"; do
    echo "  Creating ${size}x${size}..."
    convert "$SOURCE_IMAGE" \
        -resize "${size}x${size}" \
        -background "#722F37" \
        -gravity center \
        -extent "${size}x${size}" \
        "$OUTPUT_DIR/AppIcon-${size}.png"
done

echo ""
echo "Done! Generated ${#SIZES[@]} icon sizes."
echo ""
echo "Icon files created:"
ls -la "$OUTPUT_DIR"/*.png 2>/dev/null || echo "  (No PNG files found - check for errors)"
