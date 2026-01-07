#!/bin/bash
##############################################################
# Mio AI Toolkit Installer for macOS
# Simple installer: Claude Code + Plugin + Workspace Shortcut
##############################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
PLUGIN_REPO="mcohoon04/mio-ai-toolkit"
MARKETPLACE_NAME="mio-ai-marketplace"
PLUGIN_NAME="mio-ai-toolkit"
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

    # Verify it installed
    if [[ ! -x "$CLAUDE_BIN" ]]; then
        log_error "Claude Code installation failed"
        log_info "Please install manually: curl -fsSL https://claude.ai/install.sh | bash"
        exit 1
    fi
    log_success "Claude Code installed"
fi

# Ensure PATH has ~/.local/bin for this session
export PATH="$HOME/.local/bin:$PATH"

# Add to .zshrc if not already there
if ! grep -q '.local/bin' ~/.zshrc 2>/dev/null; then
    echo '' >> ~/.zshrc
    echo '# Claude Code' >> ~/.zshrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    log_success "Added ~/.local/bin to PATH"
fi

echo ""

##############################################################
# STEP 2: GitHub Authentication (needed for private plugin)
##############################################################
log_info "Step 2/4: GitHub authentication..."

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    log_info "Installing GitHub CLI..."

    # Try Homebrew first
    if command -v brew &> /dev/null; then
        brew install gh
    else
        # Install Homebrew first
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Set up Homebrew PATH
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi

        brew install gh
    fi
fi

# Check if already authenticated
if gh auth status &> /dev/null; then
    log_success "GitHub already authenticated"
else
    log_info "Please sign in to GitHub (browser will open)..."
    gh auth login --web --git-protocol https
    log_success "GitHub authenticated"
fi

# Configure git to use GitHub CLI credentials (needed for private repo access)
gh auth setup-git 2>/dev/null || true

echo ""

##############################################################
# STEP 3: Install Plugin
##############################################################
log_info "Step 3/4: Installing Mio AI Toolkit plugin..."

# Add marketplace
log_info "Adding marketplace..."
"$CLAUDE_BIN" plugin marketplace add "$PLUGIN_REPO" 2>/dev/null || true

# Install plugin
log_info "Installing plugin..."
if "$CLAUDE_BIN" plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}"; then
    log_success "Plugin installed"
else
    log_error "Plugin installation failed"
    log_info "Try manually: claude plugin install ${PLUGIN_NAME}@${MARKETPLACE_NAME}"
    exit 1
fi

echo ""

##############################################################
# STEP 4: Create Workspace & Shortcut
##############################################################
log_info "Step 4/4: Creating workspace and shortcut..."

# Create workspace
mkdir -p "$WORKSPACE_DIR"
log_success "Workspace created: $WORKSPACE_DIR"

# Create desktop shortcut (.app bundle)
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

# Add to Dock
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

# Launch
sleep 2
open "$APP_PATH"
