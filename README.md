# Mio AI Toolkit Installer

Cross-platform installer for setting up Claude Code with the Mio AI Toolkit plugin.

## What It Does

1. Installs dependencies (Node.js, Git, GitHub CLI, Claude Code)
2. Authenticates your GitHub account
3. Installs the Mio AI Toolkit plugin from private marketplace
4. Configures Gmail MCP integration
5. Creates `~/claude_workspace` directory
6. Adds "Claude Workspace" shortcut to your Desktop and Dock/Taskbar

## Installation

### Mac

Open Terminal and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mcohoon04/mio-ai-toolkit-installer/main/src/mac/install.sh)"
```

### Windows

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/mcohoon04/mio-ai-toolkit-installer/main/src/windows/install.ps1 | iex
```

### Prerequisites

- GitHub account with access to `mcohoon04/mio-ai-toolkit` repo
- Google account for Gmail integration

## After Installation

- **Mac:** Double-click "Claude Workspace" on your Desktop or Dock
- **Windows:** Double-click "Claude Workspace" on your Desktop or Taskbar

Your workspace is at `~/claude_workspace` (Mac) or `%USERPROFILE%\claude_workspace` (Windows).

## Project Structure

```
src/
  mac/install.sh        # Mac installer script
  windows/install.ps1   # Windows installer script
assets/
  icon.icns             # Mac icon
  icon.ico              # Windows icon
  mio-logo.png          # Source logo
build/
  build-mac.sh          # Build Mac .app (optional)
  build-windows.ps1     # Build Windows .exe (optional)
scripts/
  convert-icon.sh       # PNG to icon converter
```

## License

Proprietary - Membership.io
