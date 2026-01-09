# Gmail MCP Setup Guide

This guide walks you through setting up the Gmail MCP server for Claude Code, enabling AI-powered email management, drafting, and automation.

## Prerequisites

- Claude Code installed and working
- Node.js installed (`node --version` to verify)
- The `gcp-oauth.keys.json` credentials file

**Don't have the credentials file?** Contact marcus@membership.io to request the `gcp-oauth.keys.json` file.

---

## Step 1: Set Up OAuth Credentials

### 1.1 Create the Gmail MCP Directory

```bash
mkdir -p ~/.gmail-mcp
```

### 1.2 Copy Your Credentials File

Place your `gcp-oauth.keys.json` file in the directory:

```bash
# If the file is in your Downloads folder:
cp ~/Downloads/gcp-oauth.keys.json ~/.gmail-mcp/

# Or if it's in your current directory:
cp gcp-oauth.keys.json ~/.gmail-mcp/
```

### 1.3 Verify the File is in Place

```bash
ls -la ~/.gmail-mcp/
# Should show: gcp-oauth.keys.json
```

---

## Step 2: Install the Gmail MCP Server

Choose **one** of the following methods:

### Option A: Using `claude mcp add` Command (Recommended)

Run this command in your terminal:

```bash
claude mcp add --transport stdio gmail -- npx -y @gongrzhe/server-gmail-autoauth-mcp
```

This adds the Gmail MCP server to your user configuration, making it available across all projects.

**To add it to a specific project only:**

```bash
claude mcp add --transport stdio gmail --scope project -- npx -y @gongrzhe/server-gmail-autoauth-mcp
```

### Option B: Using `.mcp.json` File

Create a `.mcp.json` file in your project root (e.g., `~/claude_workspace/.mcp.json`):

```json
{
  "mcpServers": {
    "gmail": {
      "command": "npx",
      "args": ["-y", "@gongrzhe/server-gmail-autoauth-mcp"]
    }
  }
}
```

This makes Gmail available only in that project folder.

---

## Step 3: Authenticate with Google

After adding the MCP server, you need to authenticate with your Google account.

### 3.1 Run the Authentication Command

```bash
npx -y @gongrzhe/server-gmail-autoauth-mcp auth
```

### 3.2 Complete Browser Authentication

1. Your browser will open automatically
2. Sign in with your Google account
3. Grant the requested Gmail permissions
4. The browser will confirm successful authentication

### 3.3 Verify Authentication

Check that credentials were created:

```bash
ls -la ~/.gmail-mcp/
# Should show both:
#   gcp-oauth.keys.json
#   credentials.json
```

---

## Step 4: Verify the MCP Server

### 4.1 Check MCP Status

Start Claude Code and run:

```
/mcp
```

You should see `gmail` listed as a connected server.

### 4.2 Test the Connection

Try a simple command like:

```
Search my inbox for the 5 most recent emails
```

---

## Available Gmail Tools

Once configured, you can ask Claude to:

| Task | Example Prompt |
|------|----------------|
| **Search emails** | "Find emails from john@example.com in the last week" |
| **Read emails** | "Show me the content of that email" |
| **Draft emails** | "Draft a reply thanking them for the meeting" |
| **Send emails** | "Send an email to team@company.com about the project update" |
| **Manage labels** | "Create a label called 'Important Projects'" |
| **Organize inbox** | "Move all newsletters to the Promotions label" |
| **Handle attachments** | "Download the PDF attachment from that email" |
| **Batch operations** | "Archive all emails from noreply@github.com" |

---

## Troubleshooting

### "OAuth keys not found"

Ensure `gcp-oauth.keys.json` exists in `~/.gmail-mcp/`:

```bash
ls ~/.gmail-mcp/gcp-oauth.keys.json
```

If missing, copy it there (see Step 1.2).

### "Invalid credentials format"

Your `gcp-oauth.keys.json` should have this structure:

```json
{
  "installed": {
    "client_id": "...",
    "project_id": "...",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "client_secret": "...",
    "redirect_uris": ["http://localhost"]
  }
}
```

Contact marcus@membership.io if your file looks different.

### "Connection closed" or MCP not connecting

1. Restart Claude Code
2. Run `/mcp` to check server status
3. Re-run authentication if needed:
   ```bash
   npx -y @gongrzhe/server-gmail-autoauth-mcp auth
   ```

### "Port 3000 already in use"

Another process is using port 3000. Find and stop it:

```bash
lsof -i :3000
kill -9 <PID>
```

Then retry authentication.

### Re-authenticating or Switching Accounts

To switch to a different Google account:

```bash
# Remove existing credentials
rm ~/.gmail-mcp/credentials.json

# Re-authenticate
npx -y @gongrzhe/server-gmail-autoauth-mcp auth
```

---

## Security Notes

- OAuth credentials are stored locally in `~/.gmail-mcp/`
- Never commit credentials to version control
- The server uses offline access for persistent authentication
- Review connected apps periodically at [Google Account Security](https://myaccount.google.com/permissions)

---

## Need Help?

- **Missing credentials file:** Contact marcus@membership.io
- **Technical issues:** Check the [Gmail MCP Server repo](https://github.com/GongRzhe/Gmail-MCP-Server)
- **Claude Code questions:** Run `/help` in Claude Code
