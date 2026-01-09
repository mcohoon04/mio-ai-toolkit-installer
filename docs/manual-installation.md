# Manual Installation Guide

## Step 1: Create a GitHub Account

Go to [github.com](https://github.com) and create an account. You can use Google OAuth to sign up quickly.

## Step 2: Request Access

Send your email address to **marcus@membership.io** to request an invite. Accept the invite when you receive it.

## Step 3: Generate SSH Key

```bash
ssh-keygen -t ed25519
```

Press Enter to accept defaults when prompted.

## Step 4: Copy Your Public Key

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the entire output.

## Step 5: Add Key to GitHub

1. Go to [github.com](https://github.com) → **Settings** → **SSH and GPG keys**
2. Click **New SSH key**
3. Paste your key
4. Click **Add SSH key**

## Step 6: Install Claude Code and Plugins

Run these commands one at a time:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

```bash
claude plugin marketplace add mcohoon04/mio-ai-toolkit
```

```bash
claude plugin install mio-ai-toolkit@mio-ai-marketplace
```

```bash
claude plugin marketplace add obra/superpowers-marketplace
```

```bash
claude plugin install superpowers@superpowers-marketplace
```

You're all set.
