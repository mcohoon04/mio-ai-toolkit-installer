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
