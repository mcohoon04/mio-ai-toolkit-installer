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
