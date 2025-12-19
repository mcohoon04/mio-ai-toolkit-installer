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
