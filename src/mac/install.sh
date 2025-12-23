#!/bin/bash
##############################################################
# Mio AI Toolkit Installer for macOS
# Installs Claude Code, plugin, Gmail MCP, and desktop shortcut
##############################################################

set -e  # Exit on error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PLUGIN_REPO="mcohoon04/mio-ai-toolkit"
MARKETPLACE_NAME="mio-ai-marketplace"
PLUGIN_NAME="mio-ai-toolkit"
WORKSPACE_DIR="$HOME/claude_workspace"

# Helper function to find Claude binary
# Checks: 1) Native install location, 2) Legacy location, 3) npm/PATH
get_claude_bin() {
    # Primary: Native install location (recommended)
    if [[ -x "$HOME/.local/bin/claude" ]]; then
        echo "$HOME/.local/bin/claude"
    # Legacy: Old native location (for backwards compatibility)
    elif [[ -x "$HOME/.claude/bin/claude" ]]; then
        echo "$HOME/.claude/bin/claude"
    # Fallback: npm or other PATH-based installation
    elif command -v claude &> /dev/null; then
        command -v claude
    else
        echo ""
    fi
}

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

echo ""
echo "==========================================="
echo "   Mio AI Toolkit Installer for macOS"
echo "==========================================="
echo ""


##############################################################
# STEP 1: Install Dependencies
##############################################################

install_homebrew() {
    # Check if brew is in PATH
    if command -v brew &> /dev/null; then
        log_success "Homebrew already installed"
        return 0
    fi

    # Try to find brew in common locations and add to PATH
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        log_success "Homebrew found (Apple Silicon)"
        return 0
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        log_success "Homebrew found (Intel)"
        return 0
    fi

    # Need to install Homebrew
    log_info "Installing Homebrew (you may be prompted for your password)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for Apple Silicon Macs
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    fi

    log_success "Homebrew installed"
}

install_nodejs() {
    if command -v node &> /dev/null; then
        log_success "Node.js already installed ($(node --version))"
        return 0
    fi

    log_info "Installing Node.js..."
    brew install node
    log_success "Node.js installed ($(node --version))"
}

install_git() {
    if command -v git &> /dev/null; then
        log_success "Git already installed ($(git --version | cut -d' ' -f3))"
        return 0
    fi

    log_info "Installing Git..."
    brew install git
    log_success "Git installed"
}

install_github_cli() {
    if command -v gh &> /dev/null; then
        log_success "GitHub CLI already installed ($(gh --version | head -1 | cut -d' ' -f3))"
        return 0
    fi

    log_info "Installing GitHub CLI..."
    brew install gh
    log_success "GitHub CLI installed"
}

install_claude_code() {
    # Check if already installed using helper function
    local claude_path
    claude_path=$(get_claude_bin)
    if [[ -n "$claude_path" ]]; then
        log_success "Claude Code already installed"
        return 0
    fi

    log_info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash

    # Verify installation
    claude_path=$(get_claude_bin)
    if [[ -n "$claude_path" ]]; then
        log_success "Claude Code installed at $claude_path"
    else
        log_error "Claude Code installation failed"
        log_info "Please install manually from: https://claude.ai/download"
        return 1
    fi
}

##############################################################
# STEP 2: GitHub Authentication
##############################################################

authenticate_github() {
    # Check if already authenticated
    if gh auth status &> /dev/null; then
        log_success "GitHub CLI already authenticated"
        return 0
    fi

    log_info "GitHub authentication required..."
    log_info "A browser window will open for you to sign in to GitHub."
    echo ""

    # Run interactive GitHub auth
    if gh auth login --web --git-protocol https; then
        log_success "GitHub authenticated successfully"
    else
        log_error "GitHub authentication failed"
        log_info "Fallback: Configure Git credentials manually"
        log_info "Run: gh auth login"
        return 1
    fi
}

##############################################################
# STEP 3: Plugin Installation
##############################################################

install_plugin() {
    # Get Claude binary path
    local claude_bin
    claude_bin=$(get_claude_bin)
    if [[ -z "$claude_bin" ]]; then
        log_error "Claude Code not found"
        log_info "Please install Claude Code first"
        return 1
    fi

    log_info "Adding private marketplace..."

    # Add marketplace (may already exist) - use full path
    if "$claude_bin" plugin marketplace add "$PLUGIN_REPO" 2>/dev/null; then
        log_success "Marketplace added: $PLUGIN_REPO"
    else
        log_warning "Marketplace may already exist, continuing..."
    fi

    log_info "Installing Mio AI Toolkit plugin..."

    # Install plugin - use full path
    if "$claude_bin" plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}"; then
        log_success "Plugin installed: $PLUGIN_NAME"
    else
        log_error "Plugin installation failed"
        log_info "You may need to restart Claude Code and run:"
        log_info "  claude plugin install ${PLUGIN_NAME}@${MARKETPLACE_NAME}"
        return 1
    fi
}

##############################################################
# STEP 4: Gmail MCP Setup
##############################################################

setup_gmail_mcp() {
    local gmail_dir="$HOME/.gmail-mcp"
    local oauth_file="$gmail_dir/gcp-oauth.keys.json"
    local creds_file="$gmail_dir/credentials.json"

    # Check if already configured
    if [[ -f "$creds_file" ]]; then
        log_success "Gmail MCP already configured"
        return 0
    fi

    log_info "Setting up Gmail integration..."

    # Create directory
    mkdir -p "$gmail_dir"

    # Embedded OAuth credentials
    local OAUTH_JSON='{"installed":{"client_id":"604655086804-u03uf4fegj12e0dql8bklb0fb9nhicps.apps.googleusercontent.com","project_id":"gmail-mcp-481715","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_secret":"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","redirect_uris":["http://localhost"]}}'

    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Try to copy from bundled file first, otherwise use embedded
    if [[ -f "$SCRIPT_DIR/gcp-oauth.keys.json" ]]; then
        cp "$SCRIPT_DIR/gcp-oauth.keys.json" "$oauth_file"
        log_success "OAuth credentials copied"
    elif [[ -f "./gcp-oauth.keys.json" ]]; then
        cp "./gcp-oauth.keys.json" "$oauth_file"
        log_success "OAuth credentials copied"
    else
        # Use embedded credentials
        echo "$OAUTH_JSON" > "$oauth_file"
        log_success "OAuth credentials created"
    fi

    # Run Gmail authentication
    log_info "Opening browser for Gmail authentication..."
    log_info "Please sign in with your Google account and grant access."
    echo ""

    if npx -y @gongrzhe/server-gmail-autoauth-mcp auth; then
        if [[ -f "$creds_file" ]]; then
            log_success "Gmail connected successfully"
        else
            log_warning "Gmail auth completed but credentials not found"
            log_info "You may need to run: npx -y @gongrzhe/server-gmail-autoauth-mcp auth"
        fi
    else
        log_error "Gmail authentication failed"
        log_info "Try running manually: npx -y @gongrzhe/server-gmail-autoauth-mcp auth"
        return 1
    fi
}

##############################################################
# STEP 5: Workspace Setup
##############################################################

create_workspace() {
    if [[ -d "$WORKSPACE_DIR" ]]; then
        log_success "Workspace already exists: $WORKSPACE_DIR"
        return 0
    fi

    log_info "Creating workspace directory..."
    mkdir -p "$WORKSPACE_DIR"
    log_success "Workspace created: $WORKSPACE_DIR"
}

create_desktop_shortcut() {
    local app_name="Claude Workspace"
    local app_path="$HOME/Desktop/${app_name}.app"

    if [[ -d "$app_path" ]]; then
        log_success "Desktop shortcut already exists"
        return 0
    fi

    log_info "Creating desktop shortcut..."

    # Create app bundle structure
    mkdir -p "$app_path/Contents/MacOS"
    mkdir -p "$app_path/Contents/Resources"

    # Create launch script
    cat > "$app_path/Contents/MacOS/launch.sh" << 'LAUNCH_EOF'
#!/bin/bash
# Launch Claude Code in workspace directory

WORKSPACE="$HOME/claude_workspace"

# Ensure workspace exists
mkdir -p "$WORKSPACE"

# Open default terminal and run claude
osascript << EOF
tell application "Terminal"
    activate
    do script "cd '$WORKSPACE' && claude"
end tell
EOF
LAUNCH_EOF

    chmod +x "$app_path/Contents/MacOS/launch.sh"

    # Create Info.plist
    cat > "$app_path/Contents/Info.plist" << 'PLIST_EOF'
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
PLIST_EOF

    # Copy icon if available, otherwise download from repo
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$SCRIPT_DIR/icon.icns" ]]; then
        cp "$SCRIPT_DIR/icon.icns" "$app_path/Contents/Resources/icon.icns"
    elif [[ -f "./icon.icns" ]]; then
        cp "./icon.icns" "$app_path/Contents/Resources/icon.icns"
    else
        # Download icon from GitHub repo
        curl -fsSL "https://raw.githubusercontent.com/mcohoon04/mio-ai-toolkit-installer/main/assets/icon.icns" \
            -o "$app_path/Contents/Resources/icon.icns" 2>/dev/null || true
    fi

    log_success "Desktop shortcut created: $app_name"
}

add_to_dock() {
    local app_path="$HOME/Desktop/Claude Workspace.app"

    if [[ ! -d "$app_path" ]]; then
        log_warning "App not found, skipping Dock"
        return 0
    fi

    log_info "Adding to Dock..."

    # Check if already in Dock (avoid duplicates)
    if defaults read com.apple.dock persistent-apps 2>/dev/null | grep -q "Claude Workspace"; then
        log_success "Already in Dock"
        return 0
    fi

    # Add to Dock using defaults
    defaults write com.apple.dock persistent-apps -array-add "<dict>
        <key>tile-data</key>
        <dict>
            <key>file-data</key>
            <dict>
                <key>_CFURLString</key>
                <string>$app_path</string>
                <key>_CFURLStringType</key>
                <integer>0</integer>
            </dict>
        </dict>
    </dict>"

    # Restart Dock to apply changes
    killall Dock

    log_success "Added to Dock"
}

launch_app() {
    local app_path="$HOME/Desktop/Claude Workspace.app"

    if [[ -d "$app_path" ]]; then
        log_info "Launching Claude Workspace..."
        sleep 2  # Give Dock time to restart
        open "$app_path"
        log_success "Claude Workspace launched!"
    fi
}

##############################################################
# MAIN EXECUTION
##############################################################

main() {
    echo "Starting installation..."
    echo ""

    # Step 1: Dependencies
    log_info "Step 1/5: Installing dependencies..."
    install_homebrew
    install_nodejs
    install_git
    install_github_cli
    install_claude_code
    echo ""

    # Step 2: GitHub Auth
    log_info "Step 2/5: GitHub authentication..."
    authenticate_github
    echo ""

    # Step 3: Plugin
    log_info "Step 3/5: Installing plugin..."
    install_plugin
    echo ""

    # Step 4: Gmail MCP
    log_info "Step 4/5: Setting up Gmail..."
    setup_gmail_mcp
    echo ""

    # Step 5: Workspace & Shortcut
    log_info "Step 5/5: Creating workspace..."
    create_workspace
    create_desktop_shortcut
    add_to_dock
    echo ""

    # Success message
    echo "==========================================="
    echo -e "${GREEN}   Installation Complete!${NC}"
    echo "==========================================="
    echo ""
    echo "Claude Workspace has been added to your Dock and Desktop."
    echo "Your workspace is at: $WORKSPACE_DIR"
    echo ""

    # Get current terminal window ID before launching app
    INSTALLER_WINDOW=$(osascript -e 'tell application "Terminal" to get id of front window')

    # Launch the app
    launch_app

    # Auto-close the installer terminal window (not the Claude Workspace one)
    sleep 3
    osascript -e "tell application \"Terminal\" to close (every window whose id is $INSTALLER_WINDOW)" &
}

# Run main function
main "$@"
