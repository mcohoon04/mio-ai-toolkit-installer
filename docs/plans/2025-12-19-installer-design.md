# Mio AI Toolkit Installer - Design Document

**Date:** 2025-12-19
**Status:** Approved
**Owner:** Marcus Cohoon

---

## Overview

A cross-platform installer that automates setup of Claude Code with the Mio AI Toolkit private plugin for team members. The installer handles all dependencies, authentication, plugin installation, Gmail MCP configuration, and creates a desktop shortcut for daily use.

## Target Users

- 30-40 team members at Membership.io
- 60% non-technical users
- Mac and Windows users

---

## Installation Flow

```
┌─────────────────────────────────────────────────────────┐
│                 MIO AI TOOLKIT INSTALLER                │
├─────────────────────────────────────────────────────────┤
│  1. CHECK/INSTALL DEPENDENCIES                          │
│     ├─ Node.js (required for MCPs)                      │
│     ├─ Git                                              │
│     ├─ GitHub CLI                                       │
│     └─ Claude Code (native binary installer)            │
│                                                         │
│  2. GITHUB AUTHENTICATION                               │
│     └─ gh auth login (browser OAuth flow)               │
│     └─ Fallback: Git Credential Manager                 │
│                                                         │
│  3. PLUGIN INSTALLATION                                 │
│     ├─ Add private marketplace                          │
│     └─ Install mio-ai-toolkit plugin                    │
│                                                         │
│  4. GMAIL MCP SETUP                                     │
│     ├─ Copy OAuth app credentials                       │
│     └─ Run Gmail auth (browser OAuth flow)              │
│                                                         │
│  5. WORKSPACE SETUP                                     │
│     ├─ Create ~/claude_workspace directory              │
│     └─ Create "Claude Workspace" desktop shortcut       │
│                                                         │
│  6. SUCCESS                                             │
│     └─ Display completion message + next steps          │
└─────────────────────────────────────────────────────────┘
```

---

## Key Decisions

### Dependencies

| Dependency | Purpose | Mac Install | Windows Install |
|------------|---------|-------------|-----------------|
| Node.js | Required for MCP servers (npx) | `brew install node` | `winget install OpenJS.NodeJS.LTS` |
| Git | Version control | `brew install git` | `winget install Git.Git` |
| GitHub CLI | OAuth authentication | `brew install gh` | `winget install GitHub.cli` |
| Claude Code | AI assistant | `curl -fsSL https://claude.ai/install.sh \| bash` | `irm https://claude.ai/install.ps1 \| iex` |

**Note:** Claude Code native installer does NOT require Node.js. Node.js is only needed for MCP servers.

**Windows Fallback:** If Winget is unavailable, download and run official installers silently.

### GitHub Authentication

- **Method:** GitHub CLI OAuth (`gh auth login --web`)
- **Flow:** Browser opens, user signs into their GitHub account
- **Prerequisite:** User must already have access to `mcohoon04/mio-ai-toolkit` repo (Marcus grants access manually)
- **Fallback:** Git Credential Manager if GitHub CLI fails
- **No shared credentials:** Each user authenticates with their own GitHub account

### Plugin Installation

```bash
# Add private marketplace
claude plugin marketplace add mcohoon04/mio-ai-toolkit

# Install plugin
claude plugin install mio-ai-toolkit@mio-ai-marketplace
```

### Auto-Update Mechanism

**Handled by the plugin itself** (not the installer). The plugin designer will add a SessionStart hook:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "claude plugin marketplace update mio-ai-marketplace && claude plugin update mio-ai-toolkit@mio-ai-marketplace"
          }
        ]
      }
    ]
  }
}
```

This ensures all users get automatic updates when they start Claude Code.

### Gmail MCP Configuration

**Full OAuth flow during installation:**

1. Create `~/.gmail-mcp/` directory
2. Copy bundled `gcp-oauth.keys.json` (OAuth app credentials)
3. Run authentication: `npx -y @gongrzhe/server-gmail-autoauth-mcp auth`
4. Browser opens, user signs into Google, grants permissions
5. Personal tokens saved to `~/.gmail-mcp/credentials.json`

**Source file location:** `/Users/marcus/.gmail-mcp/gcp-oauth.keys.json`

### Other MCPs

Not configured by installer. Users set up HubSpot, Zoom, Chargebee, etc. on a personal basis as needed.

### Security

- **No password protection** on installer - GitHub repo access serves as the gate
- **No shared credentials** - each user authenticates individually
- Gmail OAuth app credentials are safe to distribute (only identifies the app)
- User-specific tokens stay local and are never shared

---

## Workspace & Desktop Shortcut

### Working Directory

- **Path:** `~/claude_workspace`
- **Purpose:** Default directory for Claude Code sessions

### Desktop Shortcut

- **Name:** "Claude Workspace"
- **Icon:** Mio logo (green mountains with orange sun)
- **Action:** Opens user's default terminal, cd's to workspace, runs `claude`

**Mac Implementation (`Claude Workspace.app`):**

```
Claude Workspace.app/
├── Contents/
│   ├── Info.plist
│   ├── MacOS/
│   │   └── launch.sh
│   └── Resources/
│       └── icon.icns
```

Launch script opens default terminal with:
```bash
cd ~/claude_workspace && claude
```

**Windows Implementation (`Claude Workspace.lnk`):**

Shortcut pointing to:
```
powershell.exe -NoExit -Command "cd $env:USERPROFILE\claude_workspace; claude"
```

With Mio `.ico` icon attached.

---

## Platform-Specific Details

### Mac Installer

| Component | Details |
|-----------|---------|
| Script | `install.sh` (Bash) |
| GUI Wrapper | Platypus `.app` with text output window |
| Package Manager | Homebrew (installed if missing) |
| Terminal | User's default terminal for shortcut |
| Icon Format | `.icns` |

### Windows Installer

| Component | Details |
|-----------|---------|
| Script | `install.ps1` (PowerShell) |
| GUI Wrapper | `.exe` via PS2EXE or similar |
| Package Manager | Winget (fallback: direct installers) |
| Terminal | PowerShell for shortcut |
| Icon Format | `.ico` |

---

## Error Handling

### Idempotent Design

Each step checks before acting - installer can be re-run safely:

| Step | Check Before Running |
|------|---------------------|
| Node.js | `node --version` - skip if exists |
| Git | `git --version` - skip if exists |
| GitHub CLI | `gh --version` - skip if exists |
| Claude Code | `claude --version` - skip if exists |
| GitHub Auth | `gh auth status` - skip if authenticated |
| Plugin | Check if already installed |
| Gmail | Check if `~/.gmail-mcp/credentials.json` exists |
| Workspace | Check if `~/claude_workspace` exists |
| Shortcut | Check if desktop shortcut exists |

### Failure Recovery

1. Display clear error message explaining what failed
2. Suggest manual fix or "try again" option
3. User can re-run installer - picks up where it left off

**Example error output:**
```
✓ Node.js installed
✓ Git installed
✗ GitHub CLI installation failed

  Try manually: brew install gh (Mac) or winget install GitHub.cli (Windows)
  Then re-run this installer.
```

---

## Deliverables

### Files to Build

| Deliverable | Platform | Description |
|-------------|----------|-------------|
| `install.sh` | Mac | Bash installer script |
| `Mio AI Toolkit Installer.app` | Mac | Platypus GUI wrapper |
| `install.ps1` | Windows | PowerShell installer script |
| `MioAIToolkitInstaller.exe` | Windows | Executable wrapper |
| `icon.icns` | Mac | Mio logo for shortcut |
| `icon.ico` | Windows | Mio logo for shortcut |

### Bundled Files

| File | Source | Purpose |
|------|--------|---------|
| `gcp-oauth.keys.json` | `/Users/marcus/.gmail-mcp/` | Gmail OAuth app credentials |
| Mio logo PNG | Provided | Convert to .icns and .ico |

### Created on User's Machine

| Item | Location |
|------|----------|
| Working directory | `~/claude_workspace` |
| Desktop shortcut | `~/Desktop/Claude Workspace.app` (Mac) or `.lnk` (Windows) |
| Gmail credentials | `~/.gmail-mcp/credentials.json` |

---

## Distribution

- Marcus sends installer file directly to team members (URL or file attachment)
- No password protection needed
- Users must have GitHub repo access before running installer

---

## Prerequisites for Users

Before running installer:

1. Have a GitHub account
2. Be granted access to `mcohoon04/mio-ai-toolkit` repo by Marcus
3. Have a Google account for Gmail integration

---

## References

- [Claude Code Setup](https://code.claude.com/docs/en/setup) - Native binary installation
- [Claude Code Plugins](https://code.claude.com/docs/en/plugins) - Plugin system documentation
- [Claude Code Hooks](https://code.claude.com/docs/en/hooks) - SessionStart hook for auto-update
- [GitHub CLI Auth](https://cli.github.com/manual/gh_auth_login) - OAuth flow
- [Gmail MCP Server](https://github.com/GongRzhe/Gmail-MCP-Server) - Gmail integration

---

## Summary for Plugin Designer

Add auto-update hook to mio-ai-toolkit plugin in `hooks/hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "claude plugin marketplace update mio-ai-marketplace && claude plugin update mio-ai-toolkit@mio-ai-marketplace"
          }
        ]
      }
    ]
  }
}
```

---

## Next Steps

1. Plugin designer adds SessionStart auto-update hook to plugin
2. Build Mac installer (`install.sh` + Platypus wrapper)
3. Build Windows installer (`install.ps1` + exe wrapper)
4. Convert Mio logo to `.icns` and `.ico` formats
5. Test on clean Mac and Windows machines
6. Distribute to team
