# 🖥️ Browser Control

OpenClaw skill for real browser with remote access, **protected by Google OAuth**.

Your agent can use a real browser (Chromium) and when it needs login, 2FA, or captchas, it sends you a link to take control — **from your phone or any device**. Only you can access it (via your Google account).

## Installation

**Quick install (one-liner):**
```bash
curl -sL https://raw.githubusercontent.com/felipegoulu/browser-control/ngrok-oauth/install.sh | bash
```

**Or clone and install:**
```bash
git clone -b ngrok-oauth https://github.com/felipegoulu/browser-control.git
cd browser-control
bash install.sh
```

The installer will:
1. Install VNC + noVNC + ngrok
2. Ask for your ngrok authtoken (free account)
3. Ask for your Google email (only this email can access)
4. Configure everything

## What it does

1. **Installs** VNC + noVNC + ngrok
2. **Protects** with Google OAuth (only your email can access)
3. **Creates a tunnel** so you can access from anywhere
4. **Auto-connects** to VNC (no password to enter)

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
    Open: https://xxx.ngrok.app/vnc.html
    Sign in with Google when prompted.
    Let me know when done."
         │
         ▼
   You open the link on your phone 📱
   You sign in with your Google account
   You see the browser, do the login
         │
         ▼
   You: "done"
         │
         ▼
   Agent continues and reads your emails
```

## Security

🔐 **Google OAuth Protection**
- Only YOUR Google account can access
- No password to remember or leak
- The agent never needs to share sensitive credentials

Even if someone gets the link, they can't access without logging in with your Google account.

## Commands

```bash
# Check status
~/.openclaw/skills/browser-control/status.sh

# Start everything (VNC + noVNC + ngrok tunnel)
~/.openclaw/skills/browser-control/start-tunnel.sh

# Stop everything
~/.openclaw/skills/browser-control/stop-tunnel.sh

# See current URL and config
cat ~/.openclaw/skills/browser-control/config.json
```

## OpenClaw Integration

The installer creates a `SKILL.md` that teaches OpenClaw how to:
1. Check if browser-control is running
2. Start it if needed
3. Get the URL
4. Send the link to you when login is required

**You don't need to remember the commands** — OpenClaw reads the skill and handles it.

## Access from anywhere

The link works on:
- 📱 **Phone** — Chrome, Safari, any mobile browser
- 💻 **Computer** — Any browser  
- 📟 **Tablet** — Same link, just open it

No app needed. Just a browser and your Google account.

## After reboot

Nothing starts automatically. Run this to start everything:

```bash
~/.openclaw/skills/browser-control/start-tunnel.sh
```

This starts VNC + noVNC + ngrok tunnel, and shows you the URL.

**Check current URL:**
```bash
cat ~/.openclaw/skills/browser-control/config.json
```

> 💡 The tunnel URL changes each time you run `start-tunnel.sh`.

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
   ngrok tunnel (Google OAuth)
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

## Files created

```
~/.openclaw/skills/browser-control/
├── SKILL.md             # Instructions for OpenClaw
├── start-tunnel.sh      # Start all services + tunnel
├── stop-tunnel.sh       # Stop all services
├── status.sh            # Check if running (returns JSON)
├── config.json          # Current tunnel URL
├── ngrok-config.json    # Your email (for OAuth)
├── vnc-password         # VNC password (auto-used)
└── ngrok.log            # ngrok logs
```

## Reconfigure

To change your email or ngrok token:

```bash
rm ~/.openclaw/skills/browser-control/ngrok-config.json
bash install.sh
```

## Troubleshooting

**ngrok won't start:**
```bash
# Check ngrok is installed
ngrok --version

# Check auth
ngrok config check
```

**Can't access the link:**
- Make sure you're logging in with the email you configured
- Check `cat ~/.openclaw/skills/browser-control/ngrok-config.json`

**noVNC won't connect:**
```bash
# Check VNC is running
pgrep -f Xtightvnc

# Check websockify
pgrep -f websockify
```

## Requirements

- **ngrok account** (free): https://ngrok.com/signup
- **Google account**: For OAuth login

## License

MIT
