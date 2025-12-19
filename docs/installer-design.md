# Mio AI Toolkit Installer Design

## ⚡ Confirmed Decisions (Updated: 2024-12-12)

### Phase 1 Scope
**Features to ship:**
- ✅ Brand voice skill (with supporting documentation)
- ✅ Email sending via Gmail API (`/send-email` command)
- ✅ MCP integrations: Gmail, HubSpot, Zoom, Chargebee
- ✅ Plugin infrastructure (install, update mechanism)
- ❌ Client profiles - **DEFERRED to Phase 2** (will use AI DB when ready)

### Repository Architecture
- **Plugin Repo**: `mcohoon04/mio-ai-toolkit` (this repo) - Private
- **Installer Repo**: Separate repository (to be created) - Can be public or private
- **Reason**: Keep installer separate for cleaner distribution and independent versioning

### MCP Services (Phase 1)
1. **Gmail** - Email sending functionality
2. **HubSpot** - CRM contact and deal data
3. **Zoom** - Meeting management
4. **Chargebee** - Subscription and billing data

### Credential Management Strategy
**Recommended Approach**: Option A (Password-Protected Env Variables)
- Installer prompts for company password
- Writes credentials to `~/.zshrc` or `~/.bashrc`
- Acceptable security for 30-40 person trusted team
- Can upgrade to Keychain (Option D) later if needed

**Credential Types:**
- **User-specific**: `GMAIL_REFRESH_TOKEN` (each user authenticates individually)
- **Shared**: `HUBSPOT_API_KEY`, `ZOOM_API_KEY`, `CHARGEBEE_API_KEY` (same for all team members)

### Team Composition
- Total: 30-40 people
- Non-technical: ~60% (primary installer users)
- Technical: ~40% (can use manual install)

### Installation Method
**Primary**: GUI installer (Platypus wrapper around bash script)
**Fallback**: Manual command-line installation for technical users

---

## Overview

The installer automates setup of Claude Code with the company plugin for both technical and non-technical team members. It handles:

- Dependency installation (Claude Code, Git, Node.js)
- GitHub authentication for private repo access
- Claude.ai account login
- Plugin installation
- MCP server configuration
- Environment variable setup (API keys and credentials)
- Desktop shortcut creation

## Target Users

- **Primary**: Non-technical team members (60% of 30-40 person team)
- **Secondary**: Technical team members who want automated setup

## Architecture Decision: Separate Repository

**Recommendation**: Create installer in a separate repository (`mio-ai-toolkit-installer`)

**Rationale**:
- Plugin repo stays clean and focused on plugin content
- Installer can be public while plugin repo remains private
- Different update cadences (plugin content changes frequently, installer is stable)
- Easier to distribute installer without exposing plugin code
- Can version installer independently

**Alternative**: Keep in same repo under `/installer` directory
- Simpler for small teams
- Single source of truth
- Must ensure installer scripts don't leak credentials

## Security Architecture: Credential Management

### Critical Security Requirement

**PROBLEM**: Plugin requires sensitive credentials (DB passwords, API keys) but must remain private and not leak via git or unauthorized access.

### Options Matrix

| Option | Security Level | User Experience | Complexity | Recommended For | Credential Storage |
|--------|----------------|-----------------|------------|-----------------|-------------------|
| **A. Password-Protected Env Variables** | Medium | Best | Low | **POC & small teams** | `~/.zshrc` (plaintext) |
| **B. Encrypted Secrets File** | High | Good | Medium | Production teams | Encrypted file in repo |
| **C. Password → Direct .mcp.json Write** | Medium | Best | Low | Quick deployment | Plugin `.mcp.json` (plaintext) |
| **D. macOS Keychain Integration** | Highest | Good | High | Security-critical | OS Keychain (encrypted) |
| **E. Secrets Management Service** | Highest | Medium | High | Enterprise | Vault/AWS Secrets Manager |
| **F. Manual Setup (No Automation)** | Highest | Worst | None | Paranoid security | User manages everything |

### Detailed Option Analysis

#### Option A: Password-Protected Installer → Env Variables ⭐ RECOMMENDED FOR POC

**Implementation:**
```bash
# Installer prompts for company password
# If correct, writes credentials to shell config

cat >> ~/.zshrc << 'EOF'
export COMPANY_DB_USER="shared-user"
export COMPANY_DB_PASSWORD="actual-password"
export HUBSPOT_API_KEY="actual-key"
EOF
```

**Security Analysis:**
- ✅ Credentials NOT in git (written locally only)
- ✅ Password gates installation
- ⚠️ Password hash in installer script (extractable)
- ⚠️ Credentials in plaintext in `~/.zshrc`
- ⚠️ Anyone with shell access can read credentials
- ⚠️ Shared credentials (all users have same DB password)

**Threat Model:**
- **Protects against**: Accidental git commits, unauthorized downloads
- **Vulnerable to**: Local machine compromise, malware, shoulder surfing
- **Acceptable for**: Internal company tools with trusted employees

**Risk Assessment**: Low-Medium risk for 30-40 person startup with trusted team

---

#### Option B: Encrypted Secrets File in Private Repo

**Implementation:**
```bash
# Pre-setup: Encrypt credentials file
openssl enc -aes-256-cbc -salt -in secrets.env -out secrets.env.enc -k "company-password"

# Installer fetches and decrypts
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://raw.githubusercontent.com/your-org/mio-ai-toolkit/main/secrets.env.enc \
  -o /tmp/secrets.enc

openssl enc -aes-256-cbc -d -in /tmp/secrets.enc -out /tmp/secrets.env -k "$PASSWORD"
source /tmp/secrets.env >> ~/.zshrc
```

**Security Analysis:**
- ✅ Credentials encrypted at rest in repo
- ✅ Password required to decrypt
- ✅ No plaintext secrets in git
- ⚠️ Still plaintext in `~/.zshrc` after installation
- ⚠️ Requires managing encrypted file updates

**Threat Model:**
- **Protects against**: Git exposure, unauthorized repo access
- **Vulnerable to**: Local machine compromise after install
- **Better than Option A**: Credentials encrypted in transit and at rest

**Risk Assessment**: Medium security - good balance of security and UX

---

#### Option C: Direct .mcp.json Write

**Implementation:**
```bash
# After plugin installation, overwrite .mcp.json
cat > ~/.claude/plugins/mio-ai-toolkit/.mcp.json << 'EOF'
{
  "mcpServers": {
    "company-mysql": {
      "env": {
        "MYSQL_PASSWORD": "actual-password-here"
      }
    }
  }
}
EOF
```

**Security Analysis:**
- ✅ Very simple for users
- ✅ Credentials NOT in git
- ⚠️ Credentials in plaintext in plugin directory
- ⚠️ Same vulnerability as Option A
- ❌ Plugin updates might overwrite custom .mcp.json

**Threat Model**: Identical to Option A

**Risk Assessment**: Same as Option A, but simpler implementation

---

#### Option D: macOS Keychain Integration (Most Secure)

**Implementation:**
```bash
# Installer adds credentials to Keychain
security add-generic-password \
  -a "$USER" \
  -s "company-db-password" \
  -w "actual-password" \
  -T ""

# MCP wrapper script reads from Keychain
#!/bin/bash
export MYSQL_PASSWORD=$(security find-generic-password -a "$USER" -s "company-db-password" -w)
npx -y @modelcontextprotocol/server-mysql
```

**Security Analysis:**
- ✅ OS-level encryption
- ✅ Requires user password/TouchID to access
- ✅ No plaintext credentials in files
- ✅ Industry best practice
- ⚠️ macOS only (need alternatives for Windows/Linux)
- ⚠️ More complex setup
- ⚠️ Requires wrapper scripts for each MCP server

**Threat Model:**
- **Protects against**: Malware, unauthorized access, file theft
- **Requires compromise of**: User's macOS login + Keychain access
- **Gold standard**: Similar to how password managers work

**Risk Assessment**: High security - recommended for production

**Windows Alternative**: Use Windows Credential Manager
```powershell
cmdkey /generic:"company-db-password" /user:"db-user" /pass:"password"
```

---

#### Option E: Secrets Management Service (Enterprise)

**Implementation:**
```bash
# Fetch credentials from Vault/AWS Secrets Manager
export VAULT_TOKEN="user-specific-token"
CREDENTIALS=$(vault kv get -format=json secret/company/claude-toolkit)
```

**Security Analysis:**
- ✅ Centralized secret management
- ✅ Audit logging
- ✅ Secret rotation
- ✅ Fine-grained access control
- ❌ Requires infrastructure setup
- ❌ Higher complexity
- ❌ Overkill for 40-person startup

**Threat Model**: Enterprise-grade security

**Risk Assessment**: Highest security, but unnecessarily complex for your scale

---

#### Option F: Manual Setup (No Automation)

**Implementation:**
User manually:
1. Installs Claude Code
2. Configures git
3. Clones plugin repo
4. Installs plugin
5. Creates their own .env file
6. Sets up environment variables

**Security Analysis:**
- ✅ Maximum control
- ✅ No automation vulnerabilities
- ❌ Terrible UX
- ❌ Error-prone
- ❌ Poor adoption rate

**Risk Assessment**: Secure but defeats the purpose of the installer

---

## Recommended Approach: Phased Security

### Phase 1: POC/MVP (Ship in 1 week)
**Use Option A or C**: Password-protected installer → env variables

**Rationale**:
- 40-person trusted internal team
- Fast time-to-value
- Low implementation complexity
- Acceptable risk for internal tools
- Can upgrade later if needed

**Acceptable because**:
- Employees have company device management
- Trust baseline in small company
- Not handling customer PII (internal tools)
- Can monitor for suspicious activity

### Phase 2: Production Hardening (If needed)
**Upgrade to Option D**: Keychain integration

**Trigger for upgrade**:
- Company grows beyond 100 people
- Handling more sensitive data
- Compliance requirements (SOC2, ISO)
- Security audit findings
- Remote/BYOD devices

### Phase 3: Enterprise (Future)
**Option E**: Secrets management service

**Trigger for upgrade**:
- Regulatory requirements
- Multi-region deployment
- Secret rotation needs
- Audit requirements

---

## Installer Implementation Plan

### Phase 1: Bash Script (Week 1, Days 1-3)

**File**: `install.sh`

**Features**:
1. Check/install dependencies (Homebrew, Git, Node.js, Claude Code)
2. Password protection (SHA256 hash check)
3. Configure GitHub credentials for private repo access
4. Trigger Claude.ai login flow (`claude login`)
5. Install plugin from private marketplace
6. Write environment variables to `~/.zshrc`
7. Create desktop shortcut
8. Display success message

**Testing**:
- Test on clean macOS machine
- Test with wrong password
- Test with existing installations
- Test credential validation

**Deliverable**: Working bash script that automates full setup

### Phase 2: GUI Wrapper (Week 1, Days 4-5)

**Tool**: Platypus (Free Mac app)

**Process**:
1. Download Platypus: https://sveinbjorn.org/platypus
2. Create new Platypus project
3. Select "Text Window" output mode
4. Set app name: "Mio AI Toolkit Installer"
5. Add custom icon (optional)
6. Select bash script
7. Export as .app bundle

**Features**:
- Native Mac app appearance
- Progress output in text window
- Professional looking installer
- Double-click to run

**Testing**:
- Test .app on multiple Macs
- Verify it launches correctly
- Check code signing (optional but recommended)

**Deliverable**: `Mio AI Toolkit Installer.app`

### Phase 3: Documentation (Week 1, Day 5)

**Create**:
1. `SETUP.md` - Installation instructions with screenshots
2. `TROUBLESHOOTING.md` - Common issues and fixes
3. Video walkthrough (5 min Loom video)

**Distribute**:
- Share installer .app via Slack/email
- Share documentation in company wiki
- Schedule installation office hours

---

## Bash Script Structure

```bash
#!/bin/bash

##############################################################
# Mio AI Toolkit Installer
# Version: 1.0.0
##############################################################

set -e  # Exit on error

# Configuration
PLUGIN_REPO="mcohoon04/mio-ai-toolkit"
PLUGIN_NAME="mio-ai-toolkit"
GITHUB_USER="shared-github-user"
GITHUB_TOKEN="ghp_xxxxx"  # GitHub Personal Access Token
PASSWORD_HASH="sha256-hash-here"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
check_password() { ... }
install_homebrew() { ... }
install_git() { ... }
install_node() { ... }
install_claude_code() { ... }
configure_github() { ... }
login_claude() { ... }
install_plugin() { ... }
configure_credentials() { ... }
create_desktop_shortcut() { ... }

# Main execution
main() {
    check_password
    echo "Starting installation..."

    install_homebrew
    install_git
    install_node
    install_claude_code
    configure_github
    login_claude
    install_plugin
    configure_credentials
    create_desktop_shortcut

    echo "✅ Installation complete!"
}

main
```

---

## Distribution Strategy

### Option 1: Direct Download (Simplest)
1. Build installer .app
2. Upload to company file storage (Google Drive, Dropbox)
3. Share link in Slack/email
4. Users download and run

**Pros**: Simple, fast
**Cons**: Need to manually distribute updates

### Option 2: Internal GitHub Releases
1. Create `mio-ai-toolkit-installer` repo (can be public)
2. Use GitHub Releases for versioning
3. Attach .app as release asset
4. Users download from Releases page

**Pros**: Version tracking, changelog
**Cons**: Requires GitHub access

### Option 3: Homebrew Tap (Advanced)
1. Create custom Homebrew tap
2. Users install via `brew install mio/tap/toolkit`

**Pros**: Professional, auto-updates
**Cons**: More setup complexity

**Recommendation**: Start with Option 1, move to Option 2 when you have updates

---

## Security Checklist

### Before Distributing Installer

- [ ] Review all hardcoded values in installer
- [ ] Verify GitHub token has minimal permissions (read-only to plugin repo)
- [ ] Test password protection
- [ ] Ensure credentials are NOT committed to git
- [ ] Add `.env` to `.gitignore`
- [ ] Test on clean machine
- [ ] Document what data installer accesses
- [ ] Add logging for debugging (without logging secrets)
- [ ] Consider code signing the .app (macOS Gatekeeper)

### Security Monitoring

- [ ] Track who installs the plugin
- [ ] Monitor for failed authentication attempts
- [ ] Rotate shared credentials periodically
- [ ] Audit who has access to credential storage
- [ ] Set up alerts for suspicious database access

---

## Credential Leak Prevention

### Git Protection

Add to `.gitignore`:
```gitignore
# Credentials - NEVER COMMIT
.env
*.env
*secrets*
*password*
*credentials*

# Installer with embedded secrets
install.sh

# Local config
.mcp.json
```

### Code Review Checklist

Before committing any installer code:
- [ ] No plaintext passwords
- [ ] No API keys
- [ ] No database credentials
- [ ] Password hash only (not plaintext password)
- [ ] GitHub token has minimal permissions

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Block commits containing potential secrets
if git diff --cached | grep -E '(password|api[_-]key|secret|token).*=.*["\']' ; then
    echo "❌ Potential secret detected in commit!"
    echo "Remove sensitive data before committing."
    exit 1
fi
```

---

## Rollout Plan

### Week 1: POC Group (3-5 technical users)
- Install manually to test
- Gather feedback
- Fix critical bugs
- Iterate on UX

### Week 2: Non-Technical Early Adopters (5-10 users)
- Distribute installer .app
- Schedule 1:1 installation support
- Document common issues
- Create FAQ

### Week 3: Full Team Rollout (30-40 users)
- Announce in all-hands
- Send installation email with video
- Host office hours for support
- Monitor adoption metrics

### Week 4: Optimization
- Address feedback
- Update documentation
- Plan v2 features

---

## Success Metrics

**Installation Success Rate**: Target 90%+ successful installs
**Time to Install**: Target <10 minutes including downloads
**Support Tickets**: Target <5 tickets per 10 installations
**Adoption Rate**: Target 80%+ of team using within 2 weeks

---

## Future Enhancements

1. **Auto-update mechanism**: Check for plugin updates on startup
2. **Uninstaller**: Clean removal script
3. **Windows support**: PowerShell installer for Windows users
4. **Credential rotation**: Automated secret rotation
5. **Usage analytics**: Track which features are most used
6. **Onboarding tutorial**: Interactive first-run experience

---

## Appendix: Complete Bash Installer Template

See `installer-template.sh` (to be created in separate file)

---

**Document Version**: 1.0.0
**Last Updated**: 2024-12-10
**Owner**: Marcus Cohoon (marcus@membership.io)
