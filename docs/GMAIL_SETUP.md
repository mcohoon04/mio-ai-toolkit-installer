# Gmail MCP Setup Instructions

## Overview

The Gmail MCP integration uses file-based OAuth authentication. Each user authenticates individually with their Google account.

### How It Works

| File | What It Is | Who Creates It | Shared? |
|------|------------|----------------|---------|
| `gcp-oauth.keys.json` | OAuth app credentials (client ID/secret) | Marcus (one-time) | Yes — bundle in installer |
| `credentials.json` | User's personal access tokens | Auto-generated per user | No — never share |

**Key point:** The OAuth app credentials identify the company app to Google. They're safe to distribute via the installer. Each user then authenticates with their own Google account, generating their own personal `credentials.json`.

---

## For the Installer

### Complete Installer Script

```bash
#!/bin/bash
# Gmail MCP Setup for Mio AI Toolkit

echo "Setting up Gmail integration..."

# 1. Create directory
mkdir -p ~/.gmail-mcp

# 2. Copy OAuth app credentials (bundled in installer)
# Option A: Bundled file
if [ -f "./bundled/gcp-oauth.keys.json" ]; then
    cp ./bundled/gcp-oauth.keys.json ~/.gmail-mcp/
# Option B: Download from secure location
# elif curl -sf -o ~/.gmail-mcp/gcp-oauth.keys.json "https://your-secure-url/gcp-oauth.keys.json"; then
#     echo "Downloaded OAuth credentials"
else
    echo "❌ Error: Could not find gcp-oauth.keys.json"
    echo "Please contact Marcus for the OAuth credentials file."
    exit 1
fi

# 3. Verify OAuth credentials exist
if [ ! -f ~/.gmail-mcp/gcp-oauth.keys.json ]; then
    echo "❌ Error: gcp-oauth.keys.json not found in ~/.gmail-mcp/"
    exit 1
fi

# 4. Run authentication flow
echo ""
echo "Opening browser for Gmail authentication..."
echo "Please sign in with your Google account and grant access."
echo ""

npx -y @gongrzhe/server-gmail-autoauth-mcp auth

# 5. Verify success
if [ -f ~/.gmail-mcp/credentials.json ]; then
    echo ""
    echo "✅ Gmail connected successfully!"
    echo "You can now use /send-email and /create-voice-guide commands."
else
    echo ""
    echo "❌ Gmail authentication failed."
    echo ""
    echo "Troubleshooting:"
    echo "  1. Make sure you completed the browser sign-in"
    echo "  2. Make sure you granted all requested permissions"
    echo "  3. Try running manually: npx -y @gongrzhe/server-gmail-autoauth-mcp auth"
    exit 1
fi
```

### User Experience Flow

When the installer runs:

1. **Installer copies** `gcp-oauth.keys.json` to `~/.gmail-mcp/`
2. **Installer runs** the auth command
3. **Browser opens** to Google OAuth consent screen
4. **User signs in** with their Google account
5. **User grants permissions** (read emails, send emails)
6. **Browser shows** "Authentication completed successfully"
7. **Credentials saved** to `~/.gmail-mcp/credentials.json`
8. **Installer confirms** success

### What to Bundle

Include `gcp-oauth.keys.json` in your installer package. This file contains:
- Client ID (identifies the app)
- Client secret (authenticates the app)

This is **safe to distribute** — it only identifies the Mio AI Toolkit app to Google. Users still authenticate with their own Google accounts.

---

## OAuth App Setup (Completed)

The Google Cloud OAuth app has been created with these settings:

| Setting | Value |
|---------|-------|
| Project | Mio AI Toolkit |
| Application type | Desktop app |
| OAuth scopes | `gmail.readonly`, `gmail.send`, `gmail.modify` |

### Required Scopes

The OAuth app requests these permissions:

| Scope | Purpose |
|-------|---------|
| `gmail.readonly` | Read sent emails (for voice guide extraction) |
| `gmail.send` | Send emails via /send-email command |
| `gmail.modify` | Modify labels, manage drafts |

### Credentials File Location

The OAuth app credentials are stored at:
```
~/.gmail-mcp/gcp-oauth.keys.json
```

**To get this file:** Contact Marcus or check the secure company storage.

---

## Manual Setup (Without Installer)

If a user needs to set up Gmail manually:

```bash
# 1. Get gcp-oauth.keys.json from Marcus or company storage

# 2. Create directory and move file
mkdir -p ~/.gmail-mcp
mv ~/Downloads/gcp-oauth.keys.json ~/.gmail-mcp/

# 3. Run authentication
npx -y @gongrzhe/server-gmail-autoauth-mcp auth

# 4. Verify (should see credentials.json)
ls ~/.gmail-mcp/
# Expected: credentials.json  gcp-oauth.keys.json

# 5. Done! Restart Claude Code to use Gmail features
```

---

## Troubleshooting

### "Browser didn't open automatically"

The terminal shows a URL. Copy and paste it into your browser manually.

### "Authentication succeeded but commands don't work"

1. Restart Claude Code to load the Gmail MCP
2. Check that `.claude/.mcp/gmail_mcp.json` exists and is configured

### "credentials.json not found"

Run the auth command again:
```bash
npx -y @gongrzhe/server-gmail-autoauth-mcp auth
```

### "Invalid client" error

The `gcp-oauth.keys.json` file is missing or corrupted. Get a fresh copy.

### "Access denied" or "App not verified"

During OAuth consent, click "Advanced" → "Go to Mio AI Toolkit (unsafe)" to proceed. This warning appears because the app isn't verified by Google (normal for internal tools).

### "Insufficient permissions"

The user didn't grant all requested permissions during OAuth. Re-run auth and make sure to check all permission boxes.

---

## Security Notes

| Item | Security Level | Notes |
|------|----------------|-------|
| `gcp-oauth.keys.json` | Low sensitivity | Safe to bundle in installer; identifies app only |
| `credentials.json` | **High sensitivity** | Never share; contains user's access tokens |
| OAuth scopes | Principle of least privilege | Only request scopes actually needed |

### Best Practices

- Never commit `credentials.json` to version control
- Store `gcp-oauth.keys.json` securely but it's OK to distribute via installer
- Users should only authenticate with accounts they own
- Revoke access anytime at: https://myaccount.google.com/permissions

---

## References

- Gmail MCP Server: https://github.com/GongRzhe/Gmail-MCP-Server
- NPM Package: `@gongrzhe/server-gmail-autoauth-mcp`
- Google Cloud Console: https://console.cloud.google.com
- Manage Google Permissions: https://myaccount.google.com/permissions
