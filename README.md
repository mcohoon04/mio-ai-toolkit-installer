# Mio AI Toolkit Installer

macOS installer for Claude Code with workspace setup.

## What It Does

1. Installs Claude Code (official installer)
2. Creates `~/claude_workspace` directory with `.env` and `.mcp.json`
3. Creates "Claude Workspace" shortcut on Desktop and Dock

## Installation

Open Terminal and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mcohoon04/mio-ai-toolkit-installer/main/src/mac/install.sh)"
```

### Prerequisites

- macOS 10.15 or later

## After Installation

Double-click "Claude Workspace" on your Desktop or Dock to start Claude Code.

Your workspace is at `~/claude_workspace`.

## Plugin Installation (Optional)

To install the Mio AI Toolkit plugin, you'll need to set up SSH authentication with GitHub.

### Step 1: Generate SSH Key

Open Terminal and run:

```bash
ssh-keygen -t ed25519
```

Press Enter to accept defaults.

### Step 2: Copy Your Public Key

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the output.

### Step 3: Add Key to GitHub

1. Go to [github.com](https://github.com) → Settings → SSH and GPG keys
2. Click **New SSH key**
3. Paste the key
4. Click **Add SSH key**

### Step 4: Install Plugins

Open Claude Workspace and run these commands one at a time:

**Mio AI Toolkit:**
```
/plugin marketplace add mcohoon04/mio-ai-toolkit
/plugin install mio-ai-toolkit@mio-ai-marketplace
```

**Superpowers (Optional):**
```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

## License

Proprietary - Membership.io
