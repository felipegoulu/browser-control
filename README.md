# 🖥️ Browser Control

OpenClaw skill for real browser with remote access.

Your agent can use a real browser (Chromium) and when it needs login, 2FA, or captchas, it sends you a link to take control — **from your phone or any device**.

## Installation

**Quick install (one-liner):**
```bash
curl -sL https://raw.githubusercontent.com/felipegoulu/browser-control/main/install.sh | bash
```

**Or clone and install:**
```bash
git clone https://github.com/felipegoulu/browser-control.git
cd browser-control
bash install.sh
```

## What it does

1. **Installs** VNC + noVNC + cloudflared + Chromium
2. **Creates a tunnel** so you can access from anywhere
3. **Auto-generates** a random VNC password
4. **Updates TOOLS.md** with the link so your agent knows it
5. **Creates systemd services** for auto-start (Linux)

## How it works

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
    Open: https://xxx.trycloudflare.com/vnc.html
    Password: (from install)
    Let me know when done."
         │
         ▼
   You open the link on your phone 📱
   You see the browser, do the login
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

## Commands

```bash
# Start everything (VNC + noVNC + tunnel)
~/.openclaw/skills/browser-control/start-tunnel.sh

# Stop everything
~/.openclaw/skills/browser-control/stop-tunnel.sh

# See current URL and password
cat ~/.openclaw/skills/browser-control/config.json
```

## Compatibility

| OS | Arch | Status |
|----|------|--------|
| Linux (Ubuntu/Debian) | amd64 | ✅ |
| Linux (Ubuntu/Debian) | arm64 | ✅ |
| macOS | Apple Silicon | ✅ |
| macOS | Intel | ✅ |
| Windows | - | ❌ (use WSL) |

## Architecture

```
Your phone/browser
         │
         ▼ (https)
   cloudflared tunnel (free)
         │
         ▼
   noVNC web server (:6080)
         │
         ▼
   VNC server (:5901)
         │
         ▼
   Desktop (xfce4)
      └── Chromium ◄── OpenClaw (CDP :9222)
```

## After reboot

Nothing starts automatically. Run this to start everything:

```bash
~/.openclaw/skills/browser-control/start-tunnel.sh
```

This starts VNC + noVNC + cloudflared tunnel, and shows you the new URL.

**Check current URL and password:**
```bash
cat ~/.openclaw/skills/browser-control/config.json
```

> 💡 The tunnel URL changes each time you run `start-tunnel.sh`.

## Files created

```
~/.openclaw/skills/browser-control/
├── start-tunnel.sh      # Start all services + tunnel
├── stop-tunnel.sh       # Stop all services
├── vnc-password         # Your VNC password
├── config.json          # Current tunnel URL
└── start-chrome.sh      # (Mac only) Start Chrome with CDP

~/.config/systemd/user/  # (Linux only)
├── browser-control-vnc.service
└── browser-control-novnc.service
```

## Security

⚠️ The tunnel link is public. Anyone with the link + password can see your browser.

Protections:
- Random URL (hard to guess)
- URL changes on restart
- VNC password required
- Random password generated on install

For production, consider:
- Cloudflare Tunnel with custom domain + auth
- VPN / Tailscale
- IP allowlist

## Troubleshooting

**Tunnel won't start:**
```bash
# Check cloudflared
cloudflared --version
cloudflared tunnel --url http://localhost:6080
```

**noVNC won't connect:**
```bash
# Check VNC is running
vncserver -list
pgrep -f Xtightvnc

# Check websockify
pgrep -f websockify
```

**Agent doesn't see the link:**
```bash
cat ~/.openclaw/workspace/TOOLS.md | grep -A5 "Browser Control"
```

## License

MIT
