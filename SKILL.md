# Browser Control

Remote browser access for login, 2FA, captcha, and manual verification.

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

Returns JSON with status of VNC, noVNC, and cloudflared.

## Start if not running

```bash
~/.openclaw/skills/browser-control/start-tunnel.sh
```

Starts VNC + noVNC + cloudflared tunnel. Takes ~30 seconds.

## Get URL and password

```bash
cat ~/.openclaw/skills/browser-control/config.json
```

Returns:
```json
{
  "novncUrl": "https://xxx.trycloudflare.com/vnc.html",
  "tunnelUrl": "https://xxx.trycloudflare.com",
  "vncPassword": "abc123",
  "cdpUrl": "http://localhost:9222"
}
```

## Workflow

1. Check status with `status.sh`
2. If not running, start with `start-tunnel.sh`
3. Read `config.json` for URL and password
4. Send user the link and password
5. Wait for user to say "done"
6. Continue using browser via CDP (localhost:9222)

## Example message to user

```
🔐 I need you to log in.

Open: https://xxx.trycloudflare.com/vnc.html
Password: abc123

Let me know when you're done!
```

## Stop when done (optional)

```bash
~/.openclaw/skills/browser-control/stop-tunnel.sh
```

## Files

```
~/.openclaw/skills/browser-control/
├── SKILL.md          # This file
├── start-tunnel.sh   # Start everything
├── stop-tunnel.sh    # Stop everything
├── status.sh         # Check status
├── config.json       # Current URL + password
└── vnc-password      # VNC password (persistent)
```
