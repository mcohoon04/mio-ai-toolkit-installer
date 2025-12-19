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
