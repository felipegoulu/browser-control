---
name: browser-control
description: Remote browser access for login, 2FA, captcha, and manual verification. Protected by Google OAuth - only the configured email can access. Use when you need the user to log into a website, complete 2FA/MFA, solve a captcha, or do any manual browser action.
---

# Browser Control

Remote browser access for login, 2FA, captcha, and manual verification.
Protected by Google OAuth - the user must login with their Google account.

## When to use

When you need the user to:
- Log into a website
- Complete 2FA / MFA
- Solve a captcha
- Do any manual browser action

## Check if running

```bash
~/.openclaw/skills/browser-control/status.sh
```

Returns JSON with status of VNC, noVNC, and ngrok tunnel.

## Start if not running

```bash
~/.openclaw/skills/browser-control/start-tunnel.sh
```

Starts VNC + noVNC + ngrok tunnel with Google OAuth. Takes ~30 seconds.

## Get URL

**⚠️ ALWAYS read this file fresh before sending the URL to the user. Never use cached values.**

```bash
cat ~/.openclaw/skills/browser-control/config.json
```

Returns:
```json
{
  "novncUrl": "https://xxx.ngrok.app/vnc.html?password=xxx&autoconnect=true",
  "tunnelUrl": "https://xxx.ngrok.app",
  "allowedEmail": "user@gmail.com",
  "cdpUrl": "http://localhost:9222"
}
```

The URL changes every time the tunnel restarts. Always read the file, don't trust memory.

## Workflow

1. Check status with `status.sh`
2. If not running, start with `start-tunnel.sh`
3. **Read `config.json` NOW** (not from memory!) for URL
4. Send user the link
5. User logs in with their Google account
6. User does the manual action (login, 2FA, etc.)
7. Wait for user to say "done"
8. Continue using browser via CDP (localhost:9222)

**Important:** The tunnel URL changes frequently. Always `cat config.json` right before sending the link.

## Example message to user

```
🔐 I need you to log in.

Open: https://xxx.ngrok.app/vnc.html?password=xxx&autoconnect=true

You'll need to sign in with your Google account.
Let me know when you're done!
```

**Note:** Do NOT mention passwords. The link includes auto-login. The user just needs to:
1. Click the link
2. Login with Google
3. Do the action
4. Tell you "done"

## Resource Management

**⚠️ IMPORTANT: This runs on a small server. Be efficient!**

### Tab limits
- **Maximum 3 tabs open at once**
- Close tabs immediately when done with them
- Never leave tabs open "for later"

### After each browser task
1. Close the tab you just used
2. If you opened multiple tabs, close all except the one you need
3. Verify with `browser snapshot` that tabs are closed

### Why this matters
- Chrome eats RAM and CPU per tab
- Idle tabs still consume resources
- Too many tabs = server runs out of CPU credits = everything freezes

### Commands to manage tabs
```
browser action=close          # Close current tab
browser action=tabs           # List open tabs
```

### If the server feels slow
The server may have run out of CPU credits. Close all tabs and wait a few minutes, or ask the user to reboot the EC2 instance.

## Security

- Protected by Google OAuth
- Only the email configured during install can access
- No password to leak - authentication is via Google
- Tunnel URL changes on restart (adds obscurity)

## Stop when done (optional)

```bash
~/.openclaw/skills/browser-control/stop-tunnel.sh
```

## After server reboot

**The tunnel does NOT auto-start on reboot.** You must run `start-tunnel.sh` again.

Always check `status.sh` first before assuming the tunnel is running.

## Files

```
~/.openclaw/skills/browser-control/
├── SKILL.md           # This file
├── start-tunnel.sh    # Start everything
├── stop-tunnel.sh     # Stop everything
├── status.sh          # Check status
├── config.json        # Current URL (read this before sending to user!)
├── ngrok-config.json  # Configured email
├── vnc-password       # VNC password (auto-included in URL)
└── ngrok.log          # ngrok logs
```
