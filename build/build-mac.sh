#!/bin/bash
# Build Mac installer app that opens Terminal for interactive installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="Mio AI Toolkit Installer"
APP_PATH="$PROJECT_DIR/dist/${APP_NAME}.app"

echo "Building Mac installer..."

# Remove old app if exists
rm -rf "$APP_PATH"

# Create app bundle structure
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Copy the install script and assets to Resources
cp "$PROJECT_DIR/src/mac/install.sh" "$APP_PATH/Contents/Resources/"
cp "$PROJECT_DIR/assets/gcp-oauth.keys.json" "$APP_PATH/Contents/Resources/"
cp "$PROJECT_DIR/assets/icon.icns" "$APP_PATH/Contents/Resources/"

# Create the launcher script that opens Terminal
cat > "$APP_PATH/Contents/MacOS/launcher" << 'EOF'
#!/bin/bash
# Get the directory where this app bundle is located
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RESOURCES_DIR="$APP_DIR/Resources"

# Open Terminal, run the install script, then auto-close when done
osascript << APPLESCRIPT
tell application "Terminal"
    activate
    set newTab to do script "clear && cd '$RESOURCES_DIR' && bash './install.sh'; exit"

    -- Wait for the script to finish, then close
    repeat
        delay 2
        try
            if not busy of newTab then
                close (every window whose tabs contains newTab)
                exit repeat
            end if
        end try
    end repeat
end tell
APPLESCRIPT
EOF

chmod +x "$APP_PATH/Contents/MacOS/launcher"

# Create Info.plist
cat > "$APP_PATH/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundleIdentifier</key>
    <string>io.membership.mio-installer</string>
    <key>CFBundleName</key>
    <string>Mio AI Toolkit Installer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Copy icon
cp "$PROJECT_DIR/assets/icon.icns" "$APP_PATH/Contents/Resources/icon.icns"

echo "Built: dist/${APP_NAME}.app"
echo ""
echo "The installer will open Terminal for interactive installation"
echo "(allowing password prompts for Homebrew, etc.)"
