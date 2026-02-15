# 🖥️ Browser Control

**Remote browser access for your AI agent — protected by Google OAuth.**

When your agent needs you to login, solve a captcha, or do 2FA, it sends you a link. Open it on your phone, do the thing, done.

---

## 🚀 Install

```bash
git clone https://github.com/felipegoulu/browser-control.git
cd browser-control
bash install.sh
```

### What you'll see:

**Step 1: ngrok authtoken**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔑 STEP 1: Login to ngrok & copy authtoken
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Open this URL in your browser:

   👉 https://dashboard.ngrok.com/get-started/your-authtoken

Log in (or sign up free) and copy your authtoken.

Paste your authtoken here: ▌
```

**Step 2: Google verification**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔐 STEP 2: Verify your Google account
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Open this link in your browser:

   👉 https://browser-control-auth.vercel.app/verify

2. Sign in with Google
3. Copy the 6-character code

Enter code: ▌
```

**Done!**
```
✅ Verified: you@gmail.com
✅ Configured! Only you@gmail.com can access.

========================================
✅ Installation complete!
========================================
```

Takes ~2 minutes.

---

## 🎯 The Problem

Your AI agent is browsing the web and hits a login page. It can't (and shouldn't) know your password.

**Before:** Agent gets stuck. You have to SSH in, open a browser, do the login manually.

**After:** Agent sends you a link. You open it on your phone, login, say "done". Agent continues.

---

## 🔄 How It Works

```
Agent hits login page
        ↓
Agent sends you a link
        ↓
You open on your phone 📱
        ↓
Google OAuth (only YOU can access)
        ↓
You see the browser, do the login
        ↓
You say "done"
        ↓
Agent continues
```

---

## 🔐 Security

- **Google OAuth** — Only your Google account can access
- **No passwords shared** — The agent never sees your credentials
- **Unique URLs** — Link changes every time the tunnel restarts

Even if someone gets the link, they can't get in without your Google login.

---

## 📱 Commands

```bash
# Start the tunnel (run this first)
~/.openclaw/skills/browser-control/start-tunnel.sh

# Check status
~/.openclaw/skills/browser-control/status.sh

# Stop everything
~/.openclaw/skills/browser-control/stop-tunnel.sh

# Get the current URL
cat ~/.openclaw/skills/browser-control/config.json
```

---

## ⚡ Quick Reference

| Action | Command |
|--------|---------|
| Start | `~/.openclaw/skills/browser-control/start-tunnel.sh` |
| Stop | `~/.openclaw/skills/browser-control/stop-tunnel.sh` |
| Status | `~/.openclaw/skills/browser-control/status.sh` |
| Get URL | `cat ~/.openclaw/skills/browser-control/config.json` |

---

## 📝 Notes

- **After reboot:** Run `start-tunnel.sh` again (doesn't auto-start)
- **URL changes:** Every restart gets a new URL — always check `config.json`
- **Works anywhere:** Phone, tablet, laptop — any browser

---

## 🖥️ Compatibility

| OS | Status |
|----|--------|
| Ubuntu/Debian (amd64, arm64) | ✅ |
| macOS (Intel & Apple Silicon) | ✅ |
| Windows | Use WSL |

---

## 🔧 Reconfigure

```bash
# Run install again — it will ask for new credentials
curl -fsSL https://raw.githubusercontent.com/felipegoulu/browser-control/main/install.sh | bash
```

---

## 📄 License

MIT
