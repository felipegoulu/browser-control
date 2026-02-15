# 🖥️ Browser Control

OpenClaw skill for real browser with remote access.

Your agent can use a real browser (Chromium) and when it needs login, 2FA, or captchas, it sends you a link to take control — **from your phone or any device**.

## Installation

```bash
curl -sL https://raw.githubusercontent.com/felipegoulu/browser-control/main/install.sh | bash
```

## What it does

1. **Installs** VNC + noVNC + cloudflared + Chromium
2. **Creates a tunnel** so you can access from anywhere
3. **Configures auto-start** so it runs on boot
4. **Updates TOOLS.md** with the link so your agent knows it

## Flow

```
You: "Check my Gmail"
         │
         ▼
   Agent opens Gmail
         │
         ▼
   Gmail asks for login
         │
         ▼
   Agent sends you:
   "🔐 I need you to log in.
    Open this link: https://xxx.trycloudflare.com/vnc.html
    Password: pinchme1
    Let me know when you're done."
         │
         ▼
   You open the link on your phone (Chrome, Safari, any browser)
   You see the desktop and do the login
         │
         ▼
   You: "done"
         │
         ▼
   Agent continues and reads your emails
```

## Access from anywhere

The noVNC link works on:
- 📱 **Phone** — Chrome, Safari, any mobile browser
- 💻 **Computer** — Any browser
- 📟 **Tablet** — Same link, just open it

No app needed. Just a browser.

## Compatibility

| OS | Status |
|----|--------|
| Linux (Ubuntu/Debian) | ✅ |
| macOS | ✅ |
| Windows | ❌ (use WSL) |

## Architecture

```
Internet
    │
    ▼
cloudflared (free tunnel)
    │
    ▼
noVNC (web server)
    │
    ▼
VNC Server
    │
    ▼
Desktop + Chromium ◄── OpenClaw (CDP)
```

## Files

```
browser-control/
├── install.sh          # Main installer
├── SKILL.md            # Instructions for the agent
├── README.md           # This file
├── config.example.yaml # Config example
└── services/           # Systemd units for auto-start
```

## Commands

```bash
# Start (if not auto-starting)
~/.openclaw/skills/browser-control/start-tunnel.sh

# Stop
~/.openclaw/skills/browser-control/stop-tunnel.sh

# See current URL
cat ~/.openclaw/skills/browser-control/config.json
```

## Security

⚠️ The link is public. Anyone with the link + password can see your browser.

- The URL is random and hard to guess
- It changes every time the tunnel restarts
- The VNC password adds a layer of protection

## License

MIT
