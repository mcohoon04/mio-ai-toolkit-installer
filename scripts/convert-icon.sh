#!/bin/bash
# Convert PNG to icns (Mac) and ico (Windows)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

INPUT_PNG="$PROJECT_DIR/assets/mio-logo.png"
OUTPUT_ICNS="$PROJECT_DIR/assets/icon.icns"
OUTPUT_ICO="$PROJECT_DIR/assets/icon.ico"

if [[ ! -f "$INPUT_PNG" ]]; then
    echo "Error: $INPUT_PNG not found"
    exit 1
fi

# Check for required tools
if ! command -v sips &> /dev/null; then
    echo "Error: sips not found (macOS only)"
    exit 1
fi

echo "Converting PNG to icons..."

# Create iconset directory
ICONSET_DIR="$PROJECT_DIR/assets/icon.iconset"
mkdir -p "$ICONSET_DIR"

# Generate different sizes for Mac iconset
sips -z 16 16     "$INPUT_PNG" --out "$ICONSET_DIR/icon_16x16.png"
sips -z 32 32     "$INPUT_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png"
sips -z 32 32     "$INPUT_PNG" --out "$ICONSET_DIR/icon_32x32.png"
sips -z 64 64     "$INPUT_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png"
sips -z 128 128   "$INPUT_PNG" --out "$ICONSET_DIR/icon_128x128.png"
sips -z 256 256   "$INPUT_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png"
sips -z 256 256   "$INPUT_PNG" --out "$ICONSET_DIR/icon_256x256.png"
sips -z 512 512   "$INPUT_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png"
sips -z 512 512   "$INPUT_PNG" --out "$ICONSET_DIR/icon_512x512.png"
sips -z 1024 1024 "$INPUT_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png"

# Convert to icns
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"
echo "Created: $OUTPUT_ICNS"

# Clean up iconset
rm -rf "$ICONSET_DIR"

# Create ICO for Windows (requires ImageMagick)
if command -v magick &> /dev/null; then
    magick "$INPUT_PNG" -define icon:auto-resize=256,128,64,48,32,16 "$OUTPUT_ICO"
    echo "Created: $OUTPUT_ICO"
elif command -v convert &> /dev/null; then
    convert "$INPUT_PNG" -define icon:auto-resize=256,128,64,48,32,16 "$OUTPUT_ICO"
    echo "Created: $OUTPUT_ICO"
else
    echo "Warning: ImageMagick not found, skipping ICO conversion"
    echo "Install with: brew install imagemagick"
    echo "Or use online converter for ICO"
fi

echo "Done!"
