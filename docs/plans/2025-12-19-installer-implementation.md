# Mio AI Toolkit Installer - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build cross-platform installers (Mac + Windows) that set up Claude Code with the Mio AI Toolkit plugin, Gmail MCP, and a desktop shortcut.

**Architecture:** Two separate installer scripts (Bash for Mac, PowerShell for Windows) wrapped in GUI executables. Each installer checks/installs dependencies, authenticates GitHub, installs the plugin, configures Gmail MCP, creates workspace directory, and adds desktop shortcut.

**Tech Stack:** Bash, PowerShell, Platypus (Mac GUI wrapper), PS2EXE (Windows exe wrapper), ImageMagick (icon conversion)

---

## Prerequisites

Before starting implementation:

1. Copy `gcp-oauth.keys.json` from `/Users/marcus/.gmail-mcp/gcp-oauth.keys.json` to project
2. Save the Mio logo PNG to project as `assets/mio-logo.png`
3. Install Platypus on Mac: https://sveinbjorn.org/platypus
4. Have a Windows machine or VM available for testing

---

## Task 1: Project Structure Setup

**Files:**
- Create: `src/mac/install.sh`
- Create: `src/windows/install.ps1`
- Create: `assets/mio-logo.png`
- Create: `assets/gcp-oauth.keys.json`
- Create: `dist/` (output directory)

**Step 1: Create directory structure**

```bash
mkdir -p src/mac src/windows assets dist
```

**Step 2: Copy required assets**

```bash
# Copy Gmail OAuth credentials
cp /Users/marcus/.gmail-mcp/gcp-oauth.keys.json assets/

# Save the Mio logo PNG (user must do this manually from the image provided)
# Save to: assets/mio-logo.png
```

**Step 3: Verify structure**

```bash
tree -L 2
```

Expected:
```
.
├── assets/
│   ├── gcp-oauth.keys.json
│   └── mio-logo.png
├── dist/
├── docs/
│   ├── plans/
│   └── ...
├── src/
│   ├── mac/
│   └── windows/
└── README.md
```

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: set up project structure for installer"
```

---

## Task 2: Mac Installer Script - Dependencies

**Files:**
- Create: `src/mac/install.sh`

**Step 1: Create script with header and color functions**

Create `src/mac/install.sh`:

```bash
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
```

**Step 2: Add Homebrew check/install function**

Append to `src/mac/install.sh`:

```bash
##############################################################
# STEP 1: Install Dependencies
##############################################################

install_homebrew() {
    if command -v brew &> /dev/null; then
        log_success "Homebrew already installed"
        return 0
    fi

    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for Apple Silicon Macs
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    fi

    log_success "Homebrew installed"
}
```

**Step 3: Add Node.js check/install function**

Append to `src/mac/install.sh`:

```bash
install_nodejs() {
    if command -v node &> /dev/null; then
        log_success "Node.js already installed ($(node --version))"
        return 0
    fi

    log_info "Installing Node.js..."
    brew install node
    log_success "Node.js installed ($(node --version))"
}
```

**Step 4: Add Git check/install function**

Append to `src/mac/install.sh`:

```bash
install_git() {
    if command -v git &> /dev/null; then
        log_success "Git already installed ($(git --version | cut -d' ' -f3))"
        return 0
    fi

    log_info "Installing Git..."
    brew install git
    log_success "Git installed"
}
```

**Step 5: Add GitHub CLI check/install function**

Append to `src/mac/install.sh`:

```bash
install_github_cli() {
    if command -v gh &> /dev/null; then
        log_success "GitHub CLI already installed ($(gh --version | head -1 | cut -d' ' -f3))"
        return 0
    fi

    log_info "Installing GitHub CLI..."
    brew install gh
    log_success "GitHub CLI installed"
}
```

**Step 6: Add Claude Code check/install function**

Append to `src/mac/install.sh`:

```bash
install_claude_code() {
    if command -v claude &> /dev/null; then
        log_success "Claude Code already installed"
        return 0
    fi

    log_info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash

    # Source the updated PATH
    export PATH="$HOME/.claude/bin:$PATH"

    if command -v claude &> /dev/null; then
        log_success "Claude Code installed"
    else
        log_error "Claude Code installation may require terminal restart"
        log_info "Please restart your terminal and re-run this installer if needed"
    fi
}
```

**Step 7: Make executable and test syntax**

```bash
chmod +x src/mac/install.sh
bash -n src/mac/install.sh  # Syntax check only
```

Expected: No output (no syntax errors)

**Step 8: Commit**

```bash
git add src/mac/install.sh
git commit -m "feat(mac): add dependency installation functions"
```

---

## Task 3: Mac Installer Script - GitHub Auth

**Files:**
- Modify: `src/mac/install.sh`

**Step 1: Add GitHub authentication function**

Append to `src/mac/install.sh`:

```bash
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
```

**Step 2: Verify syntax**

```bash
bash -n src/mac/install.sh
```

**Step 3: Commit**

```bash
git add src/mac/install.sh
git commit -m "feat(mac): add GitHub authentication function"
```

---

## Task 4: Mac Installer Script - Plugin Installation

**Files:**
- Modify: `src/mac/install.sh`

**Step 1: Add plugin installation function**

Append to `src/mac/install.sh`:

```bash
##############################################################
# STEP 3: Plugin Installation
##############################################################

install_plugin() {
    log_info "Adding private marketplace..."

    # Add marketplace (may already exist)
    if claude plugin marketplace add "$PLUGIN_REPO" 2>/dev/null; then
        log_success "Marketplace added: $PLUGIN_REPO"
    else
        log_warning "Marketplace may already exist, continuing..."
    fi

    log_info "Installing Mio AI Toolkit plugin..."

    # Install plugin
    if claude plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}"; then
        log_success "Plugin installed: $PLUGIN_NAME"
    else
        log_error "Plugin installation failed"
        log_info "You may need to restart Claude Code and run:"
        log_info "  claude plugin install ${PLUGIN_NAME}@${MARKETPLACE_NAME}"
        return 1
    fi
}
```

**Step 2: Verify syntax**

```bash
bash -n src/mac/install.sh
```

**Step 3: Commit**

```bash
git add src/mac/install.sh
git commit -m "feat(mac): add plugin installation function"
```

---

## Task 5: Mac Installer Script - Gmail MCP Setup

**Files:**
- Modify: `src/mac/install.sh`

**Step 1: Add Gmail MCP setup function**

Append to `src/mac/install.sh`:

```bash
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

    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Copy OAuth credentials (bundled with installer)
    if [[ -f "$SCRIPT_DIR/gcp-oauth.keys.json" ]]; then
        cp "$SCRIPT_DIR/gcp-oauth.keys.json" "$oauth_file"
        log_success "OAuth credentials copied"
    elif [[ -f "./gcp-oauth.keys.json" ]]; then
        cp "./gcp-oauth.keys.json" "$oauth_file"
        log_success "OAuth credentials copied"
    else
        log_error "gcp-oauth.keys.json not found"
        log_info "Please obtain this file and place it in ~/.gmail-mcp/"
        return 1
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
```

**Step 2: Verify syntax**

```bash
bash -n src/mac/install.sh
```

**Step 3: Commit**

```bash
git add src/mac/install.sh
git commit -m "feat(mac): add Gmail MCP setup function"
```

---

## Task 6: Mac Installer Script - Workspace & Shortcut

**Files:**
- Modify: `src/mac/install.sh`

**Step 1: Add workspace creation function**

Append to `src/mac/install.sh`:

```bash
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
```

**Step 2: Add desktop shortcut creation function**

Append to `src/mac/install.sh`:

```bash
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

    # Copy icon if available
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$SCRIPT_DIR/icon.icns" ]]; then
        cp "$SCRIPT_DIR/icon.icns" "$app_path/Contents/Resources/icon.icns"
    elif [[ -f "./icon.icns" ]]; then
        cp "./icon.icns" "$app_path/Contents/Resources/icon.icns"
    fi

    log_success "Desktop shortcut created: $app_name"
}
```

**Step 3: Verify syntax**

```bash
bash -n src/mac/install.sh
```

**Step 4: Commit**

```bash
git add src/mac/install.sh
git commit -m "feat(mac): add workspace and desktop shortcut functions"
```

---

## Task 7: Mac Installer Script - Main Execution

**Files:**
- Modify: `src/mac/install.sh`

**Step 1: Add main execution block**

Append to `src/mac/install.sh`:

```bash
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
    echo ""

    # Success message
    echo "==========================================="
    echo -e "${GREEN}   Installation Complete!${NC}"
    echo "==========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Double-click 'Claude Workspace' on your Desktop"
    echo "  2. Or open Terminal and run: cd ~/claude_workspace && claude"
    echo ""
    echo "Your workspace is at: $WORKSPACE_DIR"
    echo ""
}

# Run main function
main "$@"
```

**Step 2: Verify complete script syntax**

```bash
bash -n src/mac/install.sh
```

**Step 3: Commit**

```bash
git add src/mac/install.sh
git commit -m "feat(mac): add main execution block, complete installer"
```

---

## Task 8: Windows Installer Script - Dependencies

**Files:**
- Create: `src/windows/install.ps1`

**Step 1: Create script with header and helper functions**

Create `src/windows/install.ps1`:

```powershell
##############################################################
# Mio AI Toolkit Installer for Windows
# Installs Claude Code, plugin, Gmail MCP, and desktop shortcut
##############################################################

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# Configuration
$PLUGIN_REPO = "mcohoon04/mio-ai-toolkit"
$MARKETPLACE_NAME = "mio-ai-marketplace"
$PLUGIN_NAME = "mio-ai-toolkit"
$WORKSPACE_DIR = "$env:USERPROFILE\claude_workspace"

# Logging functions
function Log-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Log-Success { param($msg) Write-Host "[✓] $msg" -ForegroundColor Green }
function Log-Warning { param($msg) Write-Host "[!] $msg" -ForegroundColor Yellow }
function Log-Error { param($msg) Write-Host "[✗] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "===========================================" -ForegroundColor White
Write-Host "   Mio AI Toolkit Installer for Windows" -ForegroundColor White
Write-Host "===========================================" -ForegroundColor White
Write-Host ""
```

**Step 2: Add dependency check/install functions**

Append to `src/windows/install.ps1`:

```powershell
##############################################################
# STEP 1: Install Dependencies
##############################################################

function Install-NodeJS {
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $version = node --version
        Log-Success "Node.js already installed ($version)"
        return
    }

    Log-Info "Installing Node.js..."

    # Try winget first
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
        Log-Success "Node.js installed via winget"
    } else {
        Log-Warning "Winget not available. Please install Node.js manually from https://nodejs.org"
        throw "Node.js installation failed"
    }

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Install-Git {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $version = git --version
        Log-Success "Git already installed ($version)"
        return
    }

    Log-Info "Installing Git..."

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install Git.Git --accept-package-agreements --accept-source-agreements
        Log-Success "Git installed via winget"
    } else {
        Log-Warning "Winget not available. Please install Git manually from https://git-scm.com"
        throw "Git installation failed"
    }

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Install-GitHubCLI {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        $version = (gh --version | Select-Object -First 1).Split(" ")[2]
        Log-Success "GitHub CLI already installed ($version)"
        return
    }

    Log-Info "Installing GitHub CLI..."

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install GitHub.cli --accept-package-agreements --accept-source-agreements
        Log-Success "GitHub CLI installed via winget"
    } else {
        Log-Warning "Winget not available. Please install GitHub CLI manually from https://cli.github.com"
        throw "GitHub CLI installation failed"
    }

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Install-ClaudeCode {
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Log-Success "Claude Code already installed"
        return
    }

    Log-Info "Installing Claude Code..."

    # Use the official Windows installer
    Invoke-Expression "& { $(Invoke-RestMethod https://claude.ai/install.ps1) }"

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $env:Path = "$env:USERPROFILE\.claude\bin;$env:Path"

    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Log-Success "Claude Code installed"
    } else {
        Log-Warning "Claude Code installed but may require terminal restart"
    }
}
```

**Step 3: Commit**

```bash
git add src/windows/install.ps1
git commit -m "feat(windows): add dependency installation functions"
```

---

## Task 9: Windows Installer Script - GitHub Auth & Plugin

**Files:**
- Modify: `src/windows/install.ps1`

**Step 1: Add GitHub authentication function**

Append to `src/windows/install.ps1`:

```powershell
##############################################################
# STEP 2: GitHub Authentication
##############################################################

function Authenticate-GitHub {
    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log-Success "GitHub CLI already authenticated"
        return
    }

    Log-Info "GitHub authentication required..."
    Log-Info "A browser window will open for you to sign in to GitHub."
    Write-Host ""

    gh auth login --web --git-protocol https

    if ($LASTEXITCODE -eq 0) {
        Log-Success "GitHub authenticated successfully"
    } else {
        Log-Error "GitHub authentication failed"
        throw "GitHub authentication failed"
    }
}
```

**Step 2: Add plugin installation function**

Append to `src/windows/install.ps1`:

```powershell
##############################################################
# STEP 3: Plugin Installation
##############################################################

function Install-Plugin {
    Log-Info "Adding private marketplace..."

    try {
        claude plugin marketplace add $PLUGIN_REPO 2>$null
        Log-Success "Marketplace added: $PLUGIN_REPO"
    } catch {
        Log-Warning "Marketplace may already exist, continuing..."
    }

    Log-Info "Installing Mio AI Toolkit plugin..."

    claude plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}"

    if ($LASTEXITCODE -eq 0) {
        Log-Success "Plugin installed: $PLUGIN_NAME"
    } else {
        Log-Error "Plugin installation failed"
        throw "Plugin installation failed"
    }
}
```

**Step 3: Commit**

```bash
git add src/windows/install.ps1
git commit -m "feat(windows): add GitHub auth and plugin installation"
```

---

## Task 10: Windows Installer Script - Gmail MCP Setup

**Files:**
- Modify: `src/windows/install.ps1`

**Step 1: Add Gmail MCP setup function**

Append to `src/windows/install.ps1`:

```powershell
##############################################################
# STEP 4: Gmail MCP Setup
##############################################################

function Setup-GmailMCP {
    $gmailDir = "$env:USERPROFILE\.gmail-mcp"
    $oauthFile = "$gmailDir\gcp-oauth.keys.json"
    $credsFile = "$gmailDir\credentials.json"

    if (Test-Path $credsFile) {
        Log-Success "Gmail MCP already configured"
        return
    }

    Log-Info "Setting up Gmail integration..."

    # Create directory
    if (-not (Test-Path $gmailDir)) {
        New-Item -ItemType Directory -Path $gmailDir -Force | Out-Null
    }

    # Find and copy OAuth credentials
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    $possiblePaths = @(
        "$scriptDir\gcp-oauth.keys.json",
        ".\gcp-oauth.keys.json",
        "$PSScriptRoot\gcp-oauth.keys.json"
    )

    $found = $false
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Copy-Item $path $oauthFile -Force
            Log-Success "OAuth credentials copied"
            $found = $true
            break
        }
    }

    if (-not $found) {
        Log-Error "gcp-oauth.keys.json not found"
        Log-Info "Please obtain this file and place it in $gmailDir"
        throw "Gmail OAuth credentials not found"
    }

    # Run Gmail authentication
    Log-Info "Opening browser for Gmail authentication..."
    Log-Info "Please sign in with your Google account and grant access."
    Write-Host ""

    npx -y @gongrzhe/server-gmail-autoauth-mcp auth

    if (Test-Path $credsFile) {
        Log-Success "Gmail connected successfully"
    } else {
        Log-Warning "Gmail auth completed but credentials not found"
        Log-Info "You may need to run: npx -y @gongrzhe/server-gmail-autoauth-mcp auth"
    }
}
```

**Step 2: Commit**

```bash
git add src/windows/install.ps1
git commit -m "feat(windows): add Gmail MCP setup function"
```

---

## Task 11: Windows Installer Script - Workspace & Shortcut

**Files:**
- Modify: `src/windows/install.ps1`

**Step 1: Add workspace creation function**

Append to `src/windows/install.ps1`:

```powershell
##############################################################
# STEP 5: Workspace Setup
##############################################################

function Create-Workspace {
    if (Test-Path $WORKSPACE_DIR) {
        Log-Success "Workspace already exists: $WORKSPACE_DIR"
        return
    }

    Log-Info "Creating workspace directory..."
    New-Item -ItemType Directory -Path $WORKSPACE_DIR -Force | Out-Null
    Log-Success "Workspace created: $WORKSPACE_DIR"
}

function Create-DesktopShortcut {
    $shortcutPath = "$env:USERPROFILE\Desktop\Claude Workspace.lnk"

    if (Test-Path $shortcutPath) {
        Log-Success "Desktop shortcut already exists"
        return
    }

    Log-Info "Creating desktop shortcut..."

    # Create WScript Shell object
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)

    # Configure shortcut
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-NoExit -Command `"cd '$WORKSPACE_DIR'; claude`""
    $Shortcut.WorkingDirectory = $WORKSPACE_DIR
    $Shortcut.Description = "Open Claude Code in workspace"

    # Set icon if available
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    $iconPaths = @(
        "$scriptDir\icon.ico",
        ".\icon.ico",
        "$PSScriptRoot\icon.ico"
    )

    foreach ($iconPath in $iconPaths) {
        if (Test-Path $iconPath) {
            # Copy icon to permanent location
            $permanentIcon = "$env:USERPROFILE\.claude\mio-icon.ico"
            Copy-Item $iconPath $permanentIcon -Force
            $Shortcut.IconLocation = $permanentIcon
            break
        }
    }

    $Shortcut.Save()
    Log-Success "Desktop shortcut created: Claude Workspace"
}
```

**Step 2: Commit**

```bash
git add src/windows/install.ps1
git commit -m "feat(windows): add workspace and desktop shortcut functions"
```

---

## Task 12: Windows Installer Script - Main Execution

**Files:**
- Modify: `src/windows/install.ps1`

**Step 1: Add main execution block**

Append to `src/windows/install.ps1`:

```powershell
##############################################################
# MAIN EXECUTION
##############################################################

function Main {
    Write-Host "Starting installation..." -ForegroundColor White
    Write-Host ""

    try {
        # Step 1: Dependencies
        Log-Info "Step 1/5: Installing dependencies..."
        Install-NodeJS
        Install-Git
        Install-GitHubCLI
        Install-ClaudeCode
        Write-Host ""

        # Step 2: GitHub Auth
        Log-Info "Step 2/5: GitHub authentication..."
        Authenticate-GitHub
        Write-Host ""

        # Step 3: Plugin
        Log-Info "Step 3/5: Installing plugin..."
        Install-Plugin
        Write-Host ""

        # Step 4: Gmail MCP
        Log-Info "Step 4/5: Setting up Gmail..."
        Setup-GmailMCP
        Write-Host ""

        # Step 5: Workspace & Shortcut
        Log-Info "Step 5/5: Creating workspace..."
        Create-Workspace
        Create-DesktopShortcut
        Write-Host ""

        # Success message
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host "   Installation Complete!" -ForegroundColor Green
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "  1. Double-click 'Claude Workspace' on your Desktop"
        Write-Host "  2. Or open PowerShell and run: cd $WORKSPACE_DIR; claude"
        Write-Host ""
        Write-Host "Your workspace is at: $WORKSPACE_DIR"
        Write-Host ""

    } catch {
        Log-Error "Installation failed: $_"
        Write-Host ""
        Write-Host "Please fix the error above and re-run the installer."
        exit 1
    }
}

# Run main function
Main

# Keep window open
Write-Host "Press any key to close..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
```

**Step 2: Commit**

```bash
git add src/windows/install.ps1
git commit -m "feat(windows): add main execution block, complete installer"
```

---

## Task 13: Icon Conversion

**Files:**
- Create: `scripts/convert-icon.sh`
- Create: `assets/icon.icns`
- Create: `assets/icon.ico`

**Step 1: Create icon conversion script**

Create `scripts/convert-icon.sh`:

```bash
#!/bin/bash
# Convert PNG to icns (Mac) and ico (Windows)

set -e

INPUT_PNG="assets/mio-logo.png"
OUTPUT_ICNS="assets/icon.icns"
OUTPUT_ICO="assets/icon.ico"

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
ICONSET_DIR="assets/icon.iconset"
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
if command -v convert &> /dev/null; then
    convert "$INPUT_PNG" -define icon:auto-resize=256,128,64,48,32,16 "$OUTPUT_ICO"
    echo "Created: $OUTPUT_ICO"
else
    echo "Warning: ImageMagick not found, skipping ICO conversion"
    echo "Install with: brew install imagemagick"
    echo "Or use online converter for ICO"
fi

echo "Done!"
```

**Step 2: Make executable and run**

```bash
chmod +x scripts/convert-icon.sh
mkdir -p scripts
# Note: Ensure mio-logo.png exists in assets/ first
./scripts/convert-icon.sh
```

**Step 3: Commit**

```bash
git add scripts/convert-icon.sh assets/icon.icns assets/icon.ico
git commit -m "feat: add icon conversion script and generated icons"
```

---

## Task 14: Mac GUI Wrapper with Platypus

**Files:**
- Create: `build/build-mac.sh`
- Output: `dist/Mio AI Toolkit Installer.app`

**Step 1: Create Mac build script**

Create `build/build-mac.sh`:

```bash
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
```

**Step 2: Make executable**

```bash
mkdir -p build
chmod +x build/build-mac.sh
```

**Step 3: Commit**

```bash
git add build/build-mac.sh
git commit -m "feat: add Mac build script using Platypus"
```

---

## Task 15: Windows EXE Wrapper

**Files:**
- Create: `build/build-windows.ps1`
- Output: `dist/MioAIToolkitInstaller.exe`

**Step 1: Create Windows build script**

Create `build/build-windows.ps1`:

```powershell
# Build Windows installer EXE
# Requires PS2EXE module: Install-Module -Name ps2exe

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir

Write-Host "Building Windows installer..."

# Check for PS2EXE
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "Installing PS2EXE module..."
    Install-Module -Name ps2exe -Force -Scope CurrentUser
}

Import-Module ps2exe

# Create output directory
$distDir = "$projectDir\dist"
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

# Create temporary directory with all files
$bundleDir = New-Item -ItemType Directory -Path "$env:TEMP\mio-installer-$(Get-Random)" -Force

# Copy files
Copy-Item "$projectDir\src\windows\install.ps1" "$bundleDir\"
Copy-Item "$projectDir\assets\gcp-oauth.keys.json" "$bundleDir\"
Copy-Item "$projectDir\assets\icon.ico" "$bundleDir\"

# Create wrapper script that extracts bundled files
$wrapperScript = @'
# Mio AI Toolkit Installer Wrapper
$tempDir = "$env:TEMP\mio-installer-run"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Extract bundled files (embedded as base64)

'@

# Add base64 encoded files
$installScript = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$bundleDir\install.ps1"))
$oauthFile = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$bundleDir\gcp-oauth.keys.json"))
$iconFile = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$bundleDir\icon.ico"))

$wrapperScript += @"
`$installScript = '$installScript'
`$oauthFile = '$oauthFile'
`$iconFile = '$iconFile'

[IO.File]::WriteAllBytes("`$tempDir\install.ps1", [Convert]::FromBase64String(`$installScript))
[IO.File]::WriteAllBytes("`$tempDir\gcp-oauth.keys.json", [Convert]::FromBase64String(`$oauthFile))
[IO.File]::WriteAllBytes("`$tempDir\icon.ico", [Convert]::FromBase64String(`$iconFile))

# Run installer
Set-Location `$tempDir
. .\install.ps1
"@

$wrapperPath = "$bundleDir\wrapper.ps1"
$wrapperScript | Out-File -FilePath $wrapperPath -Encoding UTF8

# Convert to EXE
$exePath = "$distDir\MioAIToolkitInstaller.exe"
$iconPath = "$projectDir\assets\icon.ico"

Invoke-PS2EXE -InputFile $wrapperPath `
              -OutputFile $exePath `
              -IconFile $iconPath `
              -Title "Mio AI Toolkit Installer" `
              -Company "Membership.io" `
              -Version "1.0.0" `
              -RequireAdmin `
              -NoConsole:$false

# Clean up
Remove-Item $bundleDir -Recurse -Force

Write-Host "Built: dist\MioAIToolkitInstaller.exe"
```

**Step 2: Commit**

```bash
git add build/build-windows.ps1
git commit -m "feat: add Windows build script using PS2EXE"
```

---

## Task 16: Testing Checklist

**Files:**
- Create: `docs/TESTING.md`

**Step 1: Create testing documentation**

Create `docs/TESTING.md`:

```markdown
# Installer Testing Checklist

## Mac Testing

### Prerequisites Test
- [ ] Clean Mac without Claude Code installed
- [ ] Or Mac with existing Claude Code (upgrade scenario)

### Installation Steps
1. [ ] Double-click `Mio AI Toolkit Installer.app`
2. [ ] Observe text output window
3. [ ] Homebrew installs (if needed)
4. [ ] Node.js installs (if needed)
5. [ ] Git installs (if needed)
6. [ ] GitHub CLI installs (if needed)
7. [ ] Browser opens for GitHub OAuth
8. [ ] GitHub authentication succeeds
9. [ ] Claude Code installs (if needed)
10. [ ] Plugin marketplace added
11. [ ] Plugin installs
12. [ ] Browser opens for Gmail OAuth
13. [ ] Gmail authentication succeeds
14. [ ] Workspace directory created at `~/claude_workspace`
15. [ ] Desktop shortcut appears: "Claude Workspace"
16. [ ] Installation complete message shown

### Post-Installation Verification
- [ ] Double-click "Claude Workspace" on Desktop
- [ ] Terminal opens to `~/claude_workspace`
- [ ] `claude` command runs
- [ ] Plugin auto-update hook runs (check for update message)
- [ ] Gmail MCP works: try `/send-email` command

### Re-run Test
- [ ] Run installer again
- [ ] Each step should skip (already installed)
- [ ] No errors

---

## Windows Testing

### Prerequisites Test
- [ ] Clean Windows 10/11 without Claude Code
- [ ] Or Windows with existing Claude Code (upgrade scenario)
- [ ] Winget available (Windows 10 1809+ or Windows 11)

### Installation Steps
1. [ ] Double-click `MioAIToolkitInstaller.exe`
2. [ ] Allow admin permissions if prompted
3. [ ] Observe PowerShell output
4. [ ] Node.js installs via winget (if needed)
5. [ ] Git installs via winget (if needed)
6. [ ] GitHub CLI installs via winget (if needed)
7. [ ] Browser opens for GitHub OAuth
8. [ ] GitHub authentication succeeds
9. [ ] Claude Code installs (if needed)
10. [ ] Plugin marketplace added
11. [ ] Plugin installs
12. [ ] Browser opens for Gmail OAuth
13. [ ] Gmail authentication succeeds
14. [ ] Workspace directory created at `%USERPROFILE%\claude_workspace`
15. [ ] Desktop shortcut appears: "Claude Workspace"
16. [ ] Installation complete message shown

### Post-Installation Verification
- [ ] Double-click "Claude Workspace" on Desktop
- [ ] PowerShell opens to workspace directory
- [ ] `claude` command runs
- [ ] Plugin auto-update hook runs
- [ ] Gmail MCP works: try `/send-email` command

### Re-run Test
- [ ] Run installer again
- [ ] Each step should skip (already installed)
- [ ] No errors

---

## Error Scenario Testing

### Wrong GitHub Account
- [ ] User not added to private repo
- [ ] Clear error message about access denied
- [ ] Installer suggests contacting admin

### Network Failure
- [ ] Disconnect network mid-install
- [ ] Installer fails gracefully
- [ ] Re-run works when network restored

### Gmail OAuth Cancelled
- [ ] User closes browser during Gmail OAuth
- [ ] Installer shows warning
- [ ] Provides manual command to retry

---

## Checklist Sign-off

**Mac Tester:** ___________________ **Date:** ___________

**Windows Tester:** ___________________ **Date:** ___________
```

**Step 2: Commit**

```bash
git add docs/TESTING.md
git commit -m "docs: add testing checklist"
```

---

## Task 17: Update README

**Files:**
- Modify: `README.md`

**Step 1: Update README with project documentation**

Replace contents of `README.md`:

```markdown
# Mio AI Toolkit Installer

Cross-platform installer for setting up Claude Code with the Mio AI Toolkit plugin.

## What It Does

1. Installs dependencies (Node.js, Git, GitHub CLI, Claude Code)
2. Authenticates your GitHub account
3. Installs the Mio AI Toolkit plugin from private marketplace
4. Configures Gmail MCP integration
5. Creates `~/claude_workspace` directory
6. Adds "Claude Workspace" shortcut to your Desktop

## For Users

### Mac

1. Download `Mio AI Toolkit Installer.app`
2. Double-click to run
3. Follow the prompts (browser windows will open for authentication)
4. When complete, double-click "Claude Workspace" on your Desktop

### Windows

1. Download `MioAIToolkitInstaller.exe`
2. Double-click to run (allow admin permissions if prompted)
3. Follow the prompts (browser windows will open for authentication)
4. When complete, double-click "Claude Workspace" on your Desktop

### Prerequisites

- GitHub account with access to `mcohoon04/mio-ai-toolkit` repo
- Google account for Gmail integration

## For Developers

### Project Structure

```
├── src/
│   ├── mac/
│   │   └── install.sh          # Mac installer script
│   └── windows/
│       └── install.ps1         # Windows installer script
├── assets/
│   ├── mio-logo.png            # Source logo
│   ├── icon.icns               # Mac icon
│   ├── icon.ico                # Windows icon
│   └── gcp-oauth.keys.json     # Gmail OAuth app credentials
├── build/
│   ├── build-mac.sh            # Build Mac .app
│   └── build-windows.ps1       # Build Windows .exe
├── dist/                       # Output directory
├── scripts/
│   └── convert-icon.sh         # PNG to icon converter
└── docs/
    ├── plans/                  # Design documents
    └── TESTING.md              # Testing checklist
```

### Building

**Mac:**
```bash
./build/build-mac.sh
# Output: dist/Mio AI Toolkit Installer.app
```

**Windows (run in PowerShell):**
```powershell
.\build\build-windows.ps1
# Output: dist\MioAIToolkitInstaller.exe
```

### Requirements

- **Mac build:** Platypus with CLI tools installed
- **Windows build:** PS2EXE PowerShell module
- **Icon conversion:** ImageMagick (for .ico generation)

## License

Proprietary - Membership.io
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README with full project documentation"
```

---

## Summary

This plan creates:

| File | Purpose |
|------|---------|
| `src/mac/install.sh` | Mac Bash installer script |
| `src/windows/install.ps1` | Windows PowerShell installer script |
| `scripts/convert-icon.sh` | PNG to icns/ico converter |
| `build/build-mac.sh` | Builds Mac .app using Platypus |
| `build/build-windows.ps1` | Builds Windows .exe using PS2EXE |
| `docs/TESTING.md` | Testing checklist |

**Total commits:** 14
**Estimated implementation time:** 2-4 hours

---

## Post-Implementation

After all tasks complete:

1. Run `./scripts/convert-icon.sh` to generate icons
2. Run `./build/build-mac.sh` to build Mac installer
3. Run `.\build\build-windows.ps1` to build Windows installer (on Windows)
4. Test both installers per `docs/TESTING.md`
5. Distribute to team
