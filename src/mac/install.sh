#!/bin/bash
##############################################################
# Mio AI Toolkit Installer for macOS
# Installs Claude Code + Creates Workspace with Shortcut
##############################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
WORKSPACE_DIR="$HOME/claude_workspace"
CLAUDE_BIN="$HOME/.local/bin/claude"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "==========================================="
echo "   Mio AI Toolkit Installer"
echo "==========================================="
echo ""

##############################################################
# STEP 1: Install Claude Code
##############################################################
log_info "Step 1/4: Installing Claude Code..."

if [[ -x "$CLAUDE_BIN" ]]; then
    log_success "Claude Code already installed"
else
    log_info "Running Claude Code installer..."
    curl -fsSL https://claude.ai/install.sh | bash

    if [[ ! -x "$CLAUDE_BIN" ]]; then
        log_error "Claude Code installation failed"
        exit 1
    fi
    log_success "Claude Code installed"
fi

echo ""

##############################################################
# STEP 2: PATH Safety Check
##############################################################
log_info "Step 2/4: Checking PATH configuration..."

# Export PATH for this script session
export PATH="$HOME/.local/bin:$PATH"

# Check if PATH needs to be added to shell config
SHELL_CONFIG=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if [[ -n "$SHELL_CONFIG" ]]; then
    # Create shell config if it doesn't exist
    touch "$SHELL_CONFIG"

    if ! grep -q '.local/bin' "$SHELL_CONFIG" 2>/dev/null; then
        echo '' >> "$SHELL_CONFIG"
        echo '# Claude Code' >> "$SHELL_CONFIG"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG"
        log_success "Added ~/.local/bin to PATH in $(basename "$SHELL_CONFIG")"
        echo -e "${BLUE}[NOTE]${NC} If 'claude' isn't found in other terminals, run: source $SHELL_CONFIG"
    else
        log_success "PATH already configured"
    fi
else
    log_info "Unknown shell, please add ~/.local/bin to your PATH manually"
fi

echo ""

##############################################################
# STEP 3: Create Workspace with Config Files
##############################################################
log_info "Step 3/4: Creating workspace..."

mkdir -p "$WORKSPACE_DIR"
log_success "Workspace created: $WORKSPACE_DIR"

# Create .env if it doesn't exist
if [[ ! -f "$WORKSPACE_DIR/.env" ]]; then
    cat > "$WORKSPACE_DIR/.env" << 'EOF'
# Environment variables for Claude workspace
EOF
    log_success "Created .env"
fi

# Create .mcp.json if it doesn't exist
if [[ ! -f "$WORKSPACE_DIR/.mcp.json" ]]; then
    cat > "$WORKSPACE_DIR/.mcp.json" << 'EOF'
{
  "mcpServers": {}
}
EOF
    log_success "Created .mcp.json"
fi

echo ""

##############################################################
# STEP 4: Create Desktop Shortcut & Add to Dock
##############################################################
log_info "Step 4/4: Creating shortcut..."

APP_PATH="$HOME/Desktop/Claude Workspace.app"

if [[ ! -d "$APP_PATH" ]]; then
    mkdir -p "$APP_PATH/Contents/MacOS"
    mkdir -p "$APP_PATH/Contents/Resources"

    # Launch script
    cat > "$APP_PATH/Contents/MacOS/launch.sh" << 'EOF'
#!/bin/bash
WORKSPACE="$HOME/claude_workspace"
mkdir -p "$WORKSPACE"
osascript << APPLESCRIPT
tell application "Terminal"
    activate
    do script "cd '$WORKSPACE' && claude"
end tell
APPLESCRIPT
EOF
    chmod +x "$APP_PATH/Contents/MacOS/launch.sh"

    # Info.plist
    cat > "$APP_PATH/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>launch.sh</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundleIdentifier</key>
    <string>io.membership.claude-workspace</string>
    <key>CFBundleName</key>
    <string>Claude Workspace</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
</dict>
</plist>
EOF

    # Download icon
    curl -fsSL "https://raw.githubusercontent.com/mcohoon04/mio-ai-toolkit-installer/main/assets/icon.icns" \
        -o "$APP_PATH/Contents/Resources/icon.icns" 2>/dev/null || true

    log_success "Desktop shortcut created"
fi

# Add to Dock if not already there
if ! defaults read com.apple.dock persistent-apps 2>/dev/null | grep -q "Claude Workspace"; then
    defaults write com.apple.dock persistent-apps -array-add "<dict>
        <key>tile-data</key>
        <dict>
            <key>file-data</key>
            <dict>
                <key>_CFURLString</key>
                <string>$APP_PATH</string>
                <key>_CFURLStringType</key>
                <integer>0</integer>
            </dict>
        </dict>
    </dict>"
    killall Dock
    log_success "Added to Dock"
fi

echo ""
echo "==========================================="
echo -e "${GREEN}   Installation Complete!${NC}"
echo "==========================================="
echo ""
echo "Your workspace: $WORKSPACE_DIR"
echo "Click 'Claude Workspace' on your Desktop or Dock to start."
echo ""
echo "To install the Mio AI Toolkit plugin, see the README for instructions."
echo ""

# Launch
sleep 2
open "$APP_PATH"
