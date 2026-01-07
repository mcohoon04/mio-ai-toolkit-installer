# Mio AI Toolkit Installer

macOS installer for setting up Claude Code with the Mio AI Toolkit plugin.

## What It Does

1. Installs Claude Code (using official installer)
2. Authenticates your GitHub account
3. Installs the Mio AI Toolkit plugin from private marketplace
4. Creates `~/claude_workspace` directory
5. Adds "Claude Workspace" shortcut to your Desktop and Dock

## Installation

Open Terminal and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mcohoon04/mio-ai-toolkit-installer/main/src/mac/install.sh)"
```

### Prerequisites

- macOS 10.15 or later
- GitHub account with access to `mcohoon04/mio-ai-toolkit` repo

## After Installation

Double-click "Claude Workspace" on your Desktop or Dock to start Claude Code in your workspace.

Your workspace is at `~/claude_workspace`.

## License

Proprietary - Membership.io
