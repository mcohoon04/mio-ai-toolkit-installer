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
function Log-Success { param($msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Log-Warning { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Log-Error { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "===========================================" -ForegroundColor White
Write-Host "   Mio AI Toolkit Installer for Windows" -ForegroundColor White
Write-Host "===========================================" -ForegroundColor White
Write-Host ""

##############################################################
# STEP 1: Install Dependencies
##############################################################

# Helper function to refresh PATH
function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Get latest Node.js LTS version and download URL from API
function Get-NodeJSLatestLTS {
    try {
        $releases = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json" -TimeoutSec 30
        $lts = $releases | Where-Object { $_.lts -ne $false } | Select-Object -First 1
        $version = $lts.version
        return @{
            Version = $version
            Url = "https://nodejs.org/dist/$version/node-$version-x64.msi"
        }
    } catch {
        return $null
    }
}

# Get latest Git for Windows download URL from GitHub API
function Get-GitLatestUrl {
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest" -TimeoutSec 30
        $asset = $release.assets | Where-Object { $_.name -match "64-bit\.exe$" } | Select-Object -First 1
        return @{
            Version = $release.tag_name
            Url = $asset.browser_download_url
        }
    } catch {
        return $null
    }
}

# Get latest GitHub CLI download URL from GitHub API
function Get-GitHubCLILatestUrl {
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/cli/cli/releases/latest" -TimeoutSec 30
        $asset = $release.assets | Where-Object { $_.name -match "windows_amd64\.msi$" } | Select-Object -First 1
        return @{
            Version = $release.tag_name
            Url = $asset.browser_download_url
        }
    } catch {
        return $null
    }
}

# Download and install MSI silently
function Install-Msi {
    param($Url, $DisplayName)

    $tempFile = "$env:TEMP\$DisplayName-installer.msi"

    Log-Info "Downloading $DisplayName..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile $tempFile -UseBasicParsing -TimeoutSec 300
    } catch {
        throw "Failed to download $DisplayName"
    }

    Log-Info "Installing $DisplayName (this may take a moment)..."
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tempFile`" /qn /norestart" -Wait -PassThru
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

    if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3010) {
        throw "$DisplayName MSI installation failed (exit code: $($process.ExitCode))"
    }
}

# Download and install EXE silently
function Install-Exe {
    param($Url, $DisplayName, $Arguments)

    $tempFile = "$env:TEMP\$DisplayName-installer.exe"

    Log-Info "Downloading $DisplayName..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile $tempFile -UseBasicParsing -TimeoutSec 300
    } catch {
        throw "Failed to download $DisplayName"
    }

    Log-Info "Installing $DisplayName (this may take a moment)..."
    $process = Start-Process -FilePath $tempFile -ArgumentList $Arguments -Wait -PassThru
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

    if ($process.ExitCode -ne 0) {
        throw "$DisplayName installation failed (exit code: $($process.ExitCode))"
    }
}

function Install-NodeJS {
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $version = node --version
        Log-Success "Node.js already installed ($version)"
        return
    }

    Log-Info "Installing Node.js..."

    # Primary: Direct download from nodejs.org
    $nodeInfo = Get-NodeJSLatestLTS
    if ($nodeInfo) {
        try {
            Install-Msi -Url $nodeInfo.Url -DisplayName "NodeJS"
            Refresh-Path

            if (Get-Command node -ErrorAction SilentlyContinue) {
                Log-Success "Node.js installed ($(node --version))"
                return
            }
        } catch {
            Log-Warning "Direct download failed: $_"
        }
    }

    # Fallback: winget
    Log-Info "Trying winget as fallback..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements 2>$null
        Refresh-Path
        if (Get-Command node -ErrorAction SilentlyContinue) {
            Log-Success "Node.js installed via winget"
            return
        }
    }

    Log-Error "Node.js installation failed"
    Log-Info "Please install manually from: https://nodejs.org"
    throw "Node.js installation failed"
}

function Install-Git {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $version = git --version
        Log-Success "Git already installed ($version)"
        return
    }

    Log-Info "Installing Git..."

    # Primary: Direct download from GitHub
    $gitInfo = Get-GitLatestUrl
    if ($gitInfo) {
        try {
            Install-Exe -Url $gitInfo.Url -DisplayName "Git" -Arguments "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=`"icons,ext\reg\shellhere,assoc,assoc_sh`""
            Refresh-Path

            # Add Git to PATH for current session
            $gitPaths = @("${env:ProgramFiles}\Git\cmd", "${env:ProgramFiles(x86)}\Git\cmd")
            foreach ($gp in $gitPaths) {
                if (Test-Path $gp) {
                    $env:Path = "$gp;$env:Path"
                    break
                }
            }

            if (Get-Command git -ErrorAction SilentlyContinue) {
                Log-Success "Git installed"
                return
            }
        } catch {
            Log-Warning "Direct download failed: $_"
        }
    }

    # Fallback: winget
    Log-Info "Trying winget as fallback..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install Git.Git --accept-package-agreements --accept-source-agreements 2>$null
        Refresh-Path
        if (Get-Command git -ErrorAction SilentlyContinue) {
            Log-Success "Git installed via winget"
            return
        }
    }

    Log-Error "Git installation failed"
    Log-Info "Please install manually from: https://git-scm.com"
    throw "Git installation failed"
}

function Install-GitHubCLI {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        $version = (gh --version | Select-Object -First 1).Split(" ")[2]
        Log-Success "GitHub CLI already installed ($version)"
        return
    }

    Log-Info "Installing GitHub CLI..."

    # Primary: Direct download from GitHub
    $ghInfo = Get-GitHubCLILatestUrl
    if ($ghInfo) {
        try {
            Install-Msi -Url $ghInfo.Url -DisplayName "GitHubCLI"
            Refresh-Path

            # Add gh to PATH for current session
            $ghPath = "${env:ProgramFiles}\GitHub CLI"
            if (Test-Path $ghPath) {
                $env:Path = "$ghPath;$env:Path"
            }

            if (Get-Command gh -ErrorAction SilentlyContinue) {
                Log-Success "GitHub CLI installed"
                return
            }
        } catch {
            Log-Warning "Direct download failed: $_"
        }
    }

    # Fallback: winget
    Log-Info "Trying winget as fallback..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install GitHub.cli --accept-package-agreements --accept-source-agreements 2>$null
        Refresh-Path
        if (Get-Command gh -ErrorAction SilentlyContinue) {
            Log-Success "GitHub CLI installed via winget"
            return
        }
    }

    Log-Error "GitHub CLI installation failed"
    Log-Info "Please install manually from: https://cli.github.com"
    throw "GitHub CLI installation failed"
}

function Install-ClaudeCode {
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Log-Success "Claude Code already installed"
        return
    }

    Log-Info "Installing Claude Code..."

    # Use the official Windows installer
    try {
        Invoke-Expression "& { $(Invoke-RestMethod https://claude.ai/install.ps1) }"
    } catch {
        Log-Error "Failed to download Claude Code installer"
        Log-Info "Please install manually from: https://claude.ai/download"
        throw "Claude Code installation failed"
    }

    # Refresh PATH and add Claude bin directories (installer uses .local\bin)
    Refresh-Path
    $claudePaths = @(
        "$env:USERPROFILE\.local\bin",
        "$env:USERPROFILE\.claude\bin"
    )
    foreach ($cp in $claudePaths) {
        if (Test-Path $cp) {
            $env:Path = "$cp;$env:Path"
        }
    }

    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Log-Success "Claude Code installed"
    } else {
        Log-Warning "Claude Code installed but may require terminal restart"
        Log-Info "Add this to your PATH: $env:USERPROFILE\.local\bin"
    }
}

##############################################################
# STEP 2: GitHub Authentication
##############################################################

function Authenticate-GitHub {
    # Check auth status without throwing on stderr
    $origErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $null = gh auth status 2>&1
    $authExitCode = $LASTEXITCODE
    $ErrorActionPreference = $origErrorAction

    if ($authExitCode -eq 0) {
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

    # Embedded OAuth credentials
    $OAUTH_JSON = '{"installed":{"client_id":"604655086804-u03uf4fegj12e0dql8bklb0fb9nhicps.apps.googleusercontent.com","project_id":"gmail-mcp-481715","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_secret":"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","redirect_uris":["http://localhost"]}}'

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
        # Use embedded credentials
        $OAUTH_JSON | Out-File -FilePath $oauthFile -Encoding UTF8
        Log-Success "OAuth credentials created"
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

    # Set icon if available, otherwise download from repo
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    $iconPaths = @(
        "$scriptDir\icon.ico",
        ".\icon.ico",
        "$PSScriptRoot\icon.ico"
    )
    $permanentIcon = "$env:USERPROFILE\.claude\mio-icon.ico"
    $iconFound = $false

    foreach ($iconPath in $iconPaths) {
        if (Test-Path $iconPath) {
            # Copy icon to permanent location
            New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude" -Force | Out-Null
            Copy-Item $iconPath $permanentIcon -Force
            $Shortcut.IconLocation = $permanentIcon
            $iconFound = $true
            break
        }
    }

    if (-not $iconFound) {
        # Download icon from GitHub repo
        try {
            New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude" -Force | Out-Null
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mcohoon04/mio-ai-toolkit-installer/main/assets/icon.ico" `
                -OutFile $permanentIcon -UseBasicParsing
            $Shortcut.IconLocation = $permanentIcon
        } catch {
            # Silently continue without icon
        }
    }

    $Shortcut.Save()
    Log-Success "Desktop shortcut created: Claude Workspace"
}

function Add-ToTaskbar {
    $shortcutPath = "$env:USERPROFILE\Desktop\Claude Workspace.lnk"

    if (-not (Test-Path $shortcutPath)) {
        Log-Warning "Shortcut not found, skipping taskbar"
        return
    }

    Log-Info "Adding to Taskbar..."

    try {
        # Use Shell.Application to pin to taskbar
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace((Split-Path $shortcutPath))
        $item = $folder.ParseName((Split-Path $shortcutPath -Leaf))

        # Try to pin (verb may vary by Windows version)
        $verb = $item.Verbs() | Where-Object { $_.Name -match 'Pin to Taskbar|An Taskleiste anheften' }
        if ($verb) {
            $verb.DoIt()
            Log-Success "Added to Taskbar"
        } else {
            # Alternative: Copy to taskbar pins folder
            $taskbarPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
            if (Test-Path $taskbarPath) {
                Copy-Item $shortcutPath $taskbarPath -Force
                Log-Success "Added to Taskbar"
            } else {
                Log-Warning "Could not pin to taskbar automatically"
            }
        }
    } catch {
        Log-Warning "Could not pin to taskbar: $_"
    }
}

function Launch-App {
    $shortcutPath = "$env:USERPROFILE\Desktop\Claude Workspace.lnk"

    if (Test-Path $shortcutPath) {
        Log-Info "Launching Claude Workspace..."
        Start-Sleep -Seconds 2
        Start-Process $shortcutPath
        Log-Success "Claude Workspace launched!"
    }
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
        Add-ToTaskbar
        Write-Host ""

        # Success message
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host "   Installation Complete!" -ForegroundColor Green
        Write-Host "===========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Claude Workspace has been added to your Desktop and Taskbar."
        Write-Host "Your workspace is at: $WORKSPACE_DIR"
        Write-Host ""

        # Launch the app
        Launch-App

    } catch {
        Log-Error "Installation failed: $_"
        Write-Host ""
        Write-Host "Please fix the error above and re-run the installer."
        Write-Host "Press any key to close..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# Run main function
Main
