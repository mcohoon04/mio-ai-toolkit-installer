# Installer Developer Handoff Document

**Date**: 2024-12-12
**Plugin Repo**: https://github.com/mcohoon04/mio-ai-toolkit
**Installer Repo**: To be created (separate repository)

---

## What You're Building

A GUI installer (macOS) that automates installation of the Mio AI Toolkit Claude Code plugin for 30-40 team members (60% non-technical).

**Deliverables:**
1. Bash installer script (`install.sh`)
2. Platypus GUI wrapper (`.app` file)
3. Installation documentation
4. Distribution package

---

## Technical Requirements

### Installer Must:

1. **Install dependencies**
   - Claude Code (via npm)
   - Git (via Homebrew)
   - Node.js (if not present)

2. **Configure GitHub access**
   - Authenticate to private repo: `mcohoon04/mio-ai-toolkit`
   - Use shared credentials OR individual GitHub accounts (TBD by Marcus)

3. **Install plugin**
   - Add marketplace: `claude plugin marketplace add mcohoon04/mio-ai-toolkit`
   - Install plugin: `claude plugin install mio-ai-toolkit@mio-ai-marketplace`

4. **Configure MCP credentials**
   - Write environment variables to `~/.zshrc` or `~/.bashrc`
   - See "Credentials to Inject" section below

5. **Setup Claude.ai login**
   - Trigger `claude login` flow
   - User authenticates via browser OAuth

6. **Create convenience features**
   - Desktop shortcut to launch Claude Code
   - Optional: Auto-start on login

---

## Credentials to Inject

### Shared Credentials (Same for All Users)

```bash
# HubSpot CRM
export HUBSPOT_API_KEY="[Marcus will provide]"

# Zoom
export ZOOM_API_KEY="[Marcus will provide]"
export ZOOM_API_SECRET="[Marcus will provide]"

# Chargebee
export CHARGEBEE_SITE="[Marcus will provide]"
export CHARGEBEE_API_KEY="[Marcus will provide]"

# Gmail OAuth (shared app credentials)
export GMAIL_CLIENT_ID="[Marcus will provide]"
export GMAIL_CLIENT_SECRET="[Marcus will provide]"
```

### User-Specific Credentials

```bash
# Gmail Refresh Token (each user gets their own)
export GMAIL_REFRESH_TOKEN="[User authenticates individually via OAuth]"
```

**Note**: User's Gmail token requires OAuth flow. Installer should guide user through:
1. Visit OAuth URL
2. Authenticate with Google
3. Copy refresh token
4. Installer writes it to env vars

---

## Security Requirements

### Password Protection

Installer must prompt for company password before proceeding:

```bash
# Password protection example
CORRECT_PASSWORD_HASH="[Marcus will provide SHA256 hash]"
echo "Enter installation password:"
read -s PASSWORD
ENTERED_HASH=$(echo -n "$PASSWORD" | shasum -a 256 | cut -d' ' -f1)

if [ "$ENTERED_HASH" != "$CORRECT_PASSWORD_HASH" ]; then
    echo "Incorrect password. Installation aborted."
    exit 1
fi
```

### Credential Storage

**Recommended Approach**: Option A (Env Variables)
- Write credentials to `~/.zshrc` or `~/.bashrc`
- NOT committed to git
- Medium security, acceptable for internal team

**Alternative Approaches** (see `docs/installer-design.md` for full matrix):
- Option C: Write directly to `.mcp.json`
- Option D: macOS Keychain (more secure, more complex)

Choose one and implement consistently.

### Git Credentials

**Option 1**: Shared GitHub Account
- Installer uses single GitHub PAT (Personal Access Token)
- All users clone with same credentials
- Simpler but less auditable

**Option 2**: Individual GitHub Accounts
- Each user uses their own GitHub account
- Must have access to private repo
- More secure but requires pre-provisioning

**Decision needed from Marcus**: Which approach?

---

## Implementation Steps

### Phase 1: Bash Script (install.sh)

Create working bash installer with:
- [x] Password protection
- [x] Dependency checks and installation
- [x] GitHub authentication
- [x] Claude.ai login trigger
- [x] Plugin installation
- [x] Credential injection
- [x] Desktop shortcut creation
- [x] Error handling and logging

See `docs/installer-design.md` lines 580-650 for bash script template.

### Phase 2: GUI Wrapper (Platypus)

1. Download Platypus: https://sveinbjorn.org/platypus
2. Create new project:
   - Name: "Mio AI Toolkit Installer"
   - Script: `install.sh`
   - Interface: "Text Window"
   - Icon: Optional custom icon
3. Export as `.app` bundle
4. Test on clean macOS machine

See `docs/installer-design.md` lines 365-385 for Platypus instructions.

### Phase 3: Documentation

Create for installer repo:
- `README.md` - Installation instructions
- `SECURITY.md` - Security notes and credential handling
- `TROUBLESHOOTING.md` - Common issues and fixes
- Optional: 5-minute Loom walkthrough video

---

## Information Needed from Marcus

Before you can complete the installer, Marcus needs to provide:

### 1. GitHub Access Strategy
- [ ] Shared GitHub account credentials? OR
- [ ] Team members use individual accounts?

### 2. Company Password
- [ ] Plaintext password (you'll hash it)
- [ ] Or pre-hashed SHA256 value

### 3. Shared API Credentials
- [ ] HubSpot API key
- [ ] Zoom API key and secret
- [ ] Chargebee site name and API key
- [ ] Gmail OAuth client ID and secret

### 4. Credential Injection Method
- [ ] Option A: Env variables (recommended)
- [ ] Option C: Direct .mcp.json write
- [ ] Option D: macOS Keychain

### 5. Distribution Method
- [ ] Direct download link (Google Drive, Dropbox)
- [ ] GitHub Releases
- [ ] Other?

---

## Testing Checklist

Before release, test installer on:

- [ ] Clean macOS machine (no Claude Code installed)
- [ ] Machine with existing Claude Code (upgrade scenario)
- [ ] Test wrong password (should abort)
- [ ] Test without internet (should fail gracefully)
- [ ] Test all MCP servers work after install
- [ ] Test `/send-email` command works
- [ ] Test plugin updates work

---

## Reference Documentation

**Full design doc**: `docs/installer-design.md`
- Complete security analysis
- All credential injection options analyzed
- Detailed bash script template
- Rollout plan
- Troubleshooting guide

**Plugin structure**: See `README.md` in plugin repo
- How the plugin works
- What commands are available
- Manual installation steps

**Environment variables**: `.env.example`
- All required variables documented
- Notes on user-specific vs shared credentials

---

## Questions or Issues?

Contact Marcus Cohoon: marcus@membership.io

---

## Success Metrics

Installer is successful if:
- ✅ 90%+ installation success rate
- ✅ <10 minutes total time (including downloads)
- ✅ <5 support tickets per 10 installations
- ✅ Non-technical users can complete without help

---

**Next Step**: Marcus provides the information listed in "Information Needed" section, then you can start building the installer in the separate repository.
