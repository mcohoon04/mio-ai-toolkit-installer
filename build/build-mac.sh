#!/bin/bash
# Build Mac installer app using Platypus

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building Mac installer..."

# Check for Platypus CLI
if ! command -v platypus &> /dev/null; then
    echo "Error: Platypus CLI not found"
    echo "Install Platypus from https://sveinbjorn.org/platypus"
    echo "Then install CLI tool from Platypus > Preferences > Install Command Line Tool"
    exit 1
fi

# Create output directory
mkdir -p "$PROJECT_DIR/dist"

# Create temporary bundle directory with all needed files
BUNDLE_DIR=$(mktemp -d)
cp "$PROJECT_DIR/src/mac/install.sh" "$BUNDLE_DIR/"
cp "$PROJECT_DIR/assets/gcp-oauth.keys.json" "$BUNDLE_DIR/"
cp "$PROJECT_DIR/assets/icon.icns" "$BUNDLE_DIR/"

# Build app with Platypus
platypus \
    --name "Mio AI Toolkit Installer" \
    --app-icon "$PROJECT_DIR/assets/icon.icns" \
    --interface-type "Text Window" \
    --interpreter "/bin/bash" \
    --bundle-identifier "io.membership.mio-installer" \
    --author "Membership.io" \
    --app-version "1.0.0" \
    --bundled-file "$BUNDLE_DIR/gcp-oauth.keys.json" \
    --bundled-file "$BUNDLE_DIR/icon.icns" \
    "$BUNDLE_DIR/install.sh" \
    "$PROJECT_DIR/dist/Mio AI Toolkit Installer.app"

# Clean up
rm -rf "$BUNDLE_DIR"

echo "Built: dist/Mio AI Toolkit Installer.app"
