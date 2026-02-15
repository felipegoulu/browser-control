#!/bin/bash
# Browser Control Skill - Installer
# Installs VNC + noVNC + ngrok with Google OAuth
# Linux only (Ubuntu/Debian)

set -e

echo "🖥️  Browser Control - Installer"
echo "================================"
echo ""

#######################################
# CHECK OS
#######################################

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "❌ This skill only supports Linux (Ubuntu/Debian)"
    echo ""
    echo "Your OS: $OSTYPE"
    echo ""
    echo "For Windows, use WSL: https://docs.microsoft.com/en-us/windows/wsl/install"
    exit 1
fi

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv7l) ARCH="arm" ;;
esac

echo "📍 OS: Linux | Arch: $ARCH"
echo ""

#######################################
# CREATE DIRECTORIES
#######################################

mkdir -p ~/.openclaw/skills/browser-control
mkdir -p ~/.openclaw/workspace
SKILL_DIR=~/.openclaw/skills/browser-control

#######################################
# GENERATE VNC PASSWORD
#######################################

VNC_PASSWORD=$(openssl rand -base64 6)
echo "$VNC_PASSWORD" > $SKILL_DIR/vnc-password
chmod 600 $SKILL_DIR/vnc-password

#######################################
# INSTALL DEPENDENCIES
#######################################

echo "📦 Installing dependencies..."

sudo apt-get update
sudo apt-get install -y tightvncserver xfce4 xfce4-terminal xterm novnc websockify curl jq python3

# Chromium
echo "📦 Installing Chromium..."
sudo apt-get install -y chromium-browser || sudo apt-get install -y chromium

# ngrok
if ! command -v ngrok &> /dev/null; then
    echo "📦 Installing ngrok ($ARCH)..."
    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
    sudo apt-get update
    sudo apt-get install -y ngrok
fi

#######################################
# CONFIGURE VNC
#######################################

echo "🔧 Configuring VNC..."
mkdir -p ~/.vnc
echo "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# VNC startup script
cat > ~/.vnc/xstartup << 'XSTARTUP'
#!/bin/bash
xrdb $HOME/.Xresources 2>/dev/null
startxfce4 &
sleep 3
# Start Chromium with remote debugging
chromium-browser --no-sandbox --disable-gpu --remote-debugging-port=9222 2>/dev/null &
XSTARTUP
chmod +x ~/.vnc/xstartup

#######################################
# NGROK SETUP
#######################################

echo ""
echo "========================================"
echo "🔐 Security Setup (ngrok + Google OAuth)"
echo "========================================"
echo ""
echo "This protects your browser with Google login."
echo "Only YOUR Google account can access it."
echo ""

# Step 1: ngrok authtoken
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 STEP 1: Login to ngrok & copy authtoken"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Open this URL in your browser:"
echo ""
echo "   👉 https://dashboard.ngrok.com/get-started/your-authtoken"
echo ""
echo "Log in (or sign up free) and copy your authtoken."
echo ""
read -p "Paste your authtoken here: " NGROK_TOKEN < /dev/tty

if [ -z "$NGROK_TOKEN" ]; then
    echo ""
    echo "❌ Authtoken required."
    echo "   Go to: https://dashboard.ngrok.com/get-started/your-authtoken"
    exit 1
fi

# Let ngrok validate the token
ngrok config add-authtoken "$NGROK_TOKEN"
echo ""
echo "✅ ngrok authenticated!"

# Step 2: Google verification
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 STEP 2: Verify your Google account"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This verifies your email via Google login."
echo "Only this email will be able to access your browser."
echo ""

# Check for Python
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
fi

if [ -z "$PYTHON_CMD" ]; then
    echo "❌ Python is required for Google verification."
    echo "   Install with: sudo apt install python3"
    exit 1
fi

# Create and run Google OAuth script
GOOGLE_AUTH_SCRIPT="/tmp/google-auth-$$.py"
cat > "$GOOGLE_AUTH_SCRIPT" << 'PYTHONSCRIPT'
#!/usr/bin/env python3
import json, sys, urllib.request
VERIFY_URL = "https://browser-control-auth.vercel.app"

# Use /dev/tty for interactive I/O
try:
    tty = open('/dev/tty', 'w')
except:
    tty = sys.stdout

def tty_print(msg=""):
    tty.write(msg + "\n")
    tty.flush()

def read_input(prompt):
    tty.write(prompt)
    tty.flush()
    try:
        with open('/dev/tty', 'r') as tty_in:
            return tty_in.readline().strip()
    except:
        return input().strip()

tty_print("")
tty_print("1. Open this link in your browser:")
tty_print("")
tty_print(f"   👉 {VERIFY_URL}/verify")
tty_print("")
tty_print("2. Sign in with Google")
tty_print("3. Copy the 6-character code")
tty_print("")

code = read_input("Enter code: ").upper()

if len(code) != 6:
    tty_print("❌ Invalid code (should be 6 characters)")
    sys.exit(1)

try:
    url = f"{VERIFY_URL}/api/verify?code={code}"
    req = urllib.request.Request(url, method="GET")
    req.add_header("Accept", "application/json")
    with urllib.request.urlopen(req, timeout=30) as response:
        data = json.loads(response.read().decode())
        if "email" not in data:
            tty_print(f"❌ Invalid response: {data}")
            sys.exit(1)
        email = data["email"]
        tty_print("")
        tty_print(f"✅ Verified: {email}")
        tty_print("")
        # Output email to stdout for capture
        print(f"GOOGLE_EMAIL={email}")
except urllib.error.HTTPError as e:
    tty_print("❌ Invalid or expired code" if e.code == 404 else f"❌ Error: {e.code} {e.reason}")
    sys.exit(1)
except Exception as e:
    tty_print(f"❌ Error: {e}")
    sys.exit(1)
PYTHONSCRIPT
AUTH_OUTPUT=$($PYTHON_CMD "$GOOGLE_AUTH_SCRIPT" 2>&1)
AUTH_EXIT=$?
rm -f "$GOOGLE_AUTH_SCRIPT"

if [ $AUTH_EXIT -ne 0 ]; then
    echo ""
    echo "❌ Google verification failed. Please try again."
    exit 1
fi

# Extract email from output
ALLOWED_EMAIL=$(echo "$AUTH_OUTPUT" | grep "^GOOGLE_EMAIL=" | cut -d= -f2)

if [ -z "$ALLOWED_EMAIL" ]; then
    echo "❌ Could not get email. Please try again."
    exit 1
fi

# Validate email format
if [[ ! "$ALLOWED_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "❌ Invalid email format."
    exit 1
fi

# Save config
cat > "$SKILL_DIR/ngrok-config.json" << EOF
{
    "email": "$ALLOWED_EMAIL",
    "configuredAt": "$(date -Iseconds)"
}
EOF
chmod 600 "$SKILL_DIR/ngrok-config.json"

echo ""
echo "✅ Configured! Only $ALLOWED_EMAIL can access."

#######################################
# CREATE START SCRIPT
#######################################

echo "🔧 Creating start script..."

cat > $SKILL_DIR/start-tunnel.sh << 'STARTSCRIPT'
#!/bin/bash
# Browser Control - Start all services

set -e

SKILL_DIR=~/.openclaw/skills/browser-control
CONFIG_FILE=$SKILL_DIR/config.json
NGROK_CONFIG=$SKILL_DIR/ngrok-config.json
TOOLS_FILE=~/.openclaw/workspace/TOOLS.md
VNC_PASSWORD=$(cat $SKILL_DIR/vnc-password 2>/dev/null || echo "")

echo "🖥️  Browser Control - Starting..."
echo ""

# Check ngrok config
if [ ! -f "$NGROK_CONFIG" ]; then
    echo "❌ ngrok not configured. Run install.sh first."
    exit 1
fi

ALLOWED_EMAIL=$(jq -r '.email' "$NGROK_CONFIG")
if [ -z "$ALLOWED_EMAIL" ] || [ "$ALLOWED_EMAIL" = "null" ]; then
    echo "❌ No email configured. Run install.sh first."
    exit 1
fi

VNC_PORT=5901
NOVNC_WEB="/usr/share/novnc"

#######################################
# START VNC
#######################################

if pgrep -f "Xtightvnc.*:1" > /dev/null; then
    echo "✅ VNC already running"
else
    echo "🖥️  Starting VNC server..."
    vncserver -kill :1 2>/dev/null || true
    vncserver :1 -geometry 1280x800 -depth 24
    sleep 2
    echo "✅ VNC started on display :1"
fi

#######################################
# START NOVNC
#######################################

echo "🌐 Starting noVNC..."
pkill -f "websockify.*6080" 2>/dev/null || true
sleep 1

if [ ! -d "$NOVNC_WEB" ]; then
    echo "❌ noVNC not found at $NOVNC_WEB"
    exit 1
fi

websockify --web=$NOVNC_WEB 6080 localhost:$VNC_PORT &
WEBSOCKIFY_PID=$!
sleep 2

if ! kill -0 $WEBSOCKIFY_PID 2>/dev/null; then
    echo "❌ Failed to start noVNC"
    exit 1
fi
echo "✅ noVNC started on port 6080"

#######################################
# START NGROK TUNNEL
#######################################

echo "🚇 Starting ngrok tunnel with Google OAuth..."
echo "   Only $ALLOWED_EMAIL can access"
echo ""

# Kill any existing ngrok
pkill -f "ngrok.*http" 2>/dev/null || true
sleep 1

# Start ngrok in background
ngrok http 6080 \
    --oauth=google \
    --oauth-allow-email="$ALLOWED_EMAIL" \
    --log=stdout \
    > $SKILL_DIR/ngrok.log 2>&1 &

NGROK_PID=$!
echo $NGROK_PID > $SKILL_DIR/ngrok.pid

# Wait for tunnel to be ready
echo "   Waiting for tunnel..."
for i in {1..30}; do
    sleep 1
    # Query ngrok API for tunnel URL
    TUNNEL_URL=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[0].public_url' 2>/dev/null)
    if [ -n "$TUNNEL_URL" ] && [ "$TUNNEL_URL" != "null" ]; then
        break
    fi
    echo -n "."
done
echo ""

if [ -z "$TUNNEL_URL" ] || [ "$TUNNEL_URL" = "null" ]; then
    echo "❌ Failed to get tunnel URL"
    echo "   Check log: $SKILL_DIR/ngrok.log"
    cat $SKILL_DIR/ngrok.log | tail -20
    exit 1
fi

# Build noVNC URL with auto-login password
if [ -n "$VNC_PASSWORD" ]; then
    NOVNC_URL="${TUNNEL_URL}/vnc.html?password=${VNC_PASSWORD}&autoconnect=true"
else
    NOVNC_URL="${TUNNEL_URL}/vnc.html?autoconnect=true"
fi

echo ""
echo "========================================="
echo "✅ TUNNEL ACTIVE!"
echo ""
echo "🔗 Link: $NOVNC_URL"
echo "🔐 Protected by: Google OAuth ($ALLOWED_EMAIL)"
echo ""
echo "Open from your phone or any browser!"
echo "You'll need to login with your Google account."
echo "========================================="
echo ""

# Save to config.json
cat > $CONFIG_FILE << CONF
{
    "novncUrl": "$NOVNC_URL",
    "tunnelUrl": "$TUNNEL_URL",
    "allowedEmail": "$ALLOWED_EMAIL",
    "cdpUrl": "http://localhost:9222",
    "updatedAt": "$(date -Iseconds)"
}
CONF

# Update TOOLS.md
if [ -f "$TOOLS_FILE" ]; then
    # Remove old Browser Control section
    grep -v "## Browser Control" "$TOOLS_FILE" | grep -v "noVNC URL:" | grep -v "Protected by:" | grep -v "Send the link" | grep -v "When you need the user" | grep -v "Google OAuth" > "$TOOLS_FILE.tmp" || true
    mv "$TOOLS_FILE.tmp" "$TOOLS_FILE"
fi

cat >> "$TOOLS_FILE" << TOOLS

## Browser Control

When you need the user to login, 2FA, captcha, or any manual verification:

- noVNC URL: $NOVNC_URL
- Protected by: Google OAuth ($ALLOWED_EMAIL)

Send the link and wait for the user to say "done".
The user will need to login with their Google account.
TOOLS

echo "📝 TOOLS.md updated"
echo "📝 Config saved to $CONFIG_FILE"
echo ""
echo "🔄 Tunnel running in background (PID: $NGROK_PID)"
echo "   Stop with: $SKILL_DIR/stop-tunnel.sh"
STARTSCRIPT

chmod +x $SKILL_DIR/start-tunnel.sh

#######################################
# CREATE STOP SCRIPT
#######################################

cat > $SKILL_DIR/stop-tunnel.sh << 'STOPSCRIPT'
#!/bin/bash
echo "🛑 Stopping Browser Control services..."

pkill -f "ngrok.*http" 2>/dev/null && echo "   ✓ ngrok stopped" || echo "   - ngrok not running"
pkill -f "websockify.*6080" 2>/dev/null && echo "   ✓ noVNC stopped" || echo "   - noVNC not running"
vncserver -kill :1 2>/dev/null && echo "   ✓ VNC stopped" || echo "   - VNC not running"

echo ""
echo "✅ All services stopped"
STOPSCRIPT

chmod +x $SKILL_DIR/stop-tunnel.sh

#######################################
# CREATE STATUS SCRIPT
#######################################

cat > $SKILL_DIR/status.sh << 'STATUSSCRIPT'
#!/bin/bash
# Browser Control - Status Check

SKILL_DIR=~/.openclaw/skills/browser-control

# Check VNC
if pgrep -f "Xtightvnc.*:1" > /dev/null; then
    VNC_STATUS="running"
else
    VNC_STATUS="stopped"
fi

# Check noVNC
if pgrep -f "websockify.*6080" > /dev/null; then
    NOVNC_STATUS="running"
else
    NOVNC_STATUS="stopped"
fi

# Check ngrok
if pgrep -f "ngrok.*http" > /dev/null; then
    TUNNEL_STATUS="running"
else
    TUNNEL_STATUS="stopped"
fi

# Get URL if available
if [ -f "$SKILL_DIR/config.json" ]; then
    URL=$(jq -r '.novncUrl' "$SKILL_DIR/config.json" 2>/dev/null)
    EMAIL=$(jq -r '.allowedEmail' "$SKILL_DIR/config.json" 2>/dev/null)
else
    URL=""
    EMAIL=""
fi

# Output JSON
cat << EOF
{
  "vnc": "$VNC_STATUS",
  "novnc": "$NOVNC_STATUS",
  "tunnel": "$TUNNEL_STATUS",
  "ready": $([ "$VNC_STATUS" = "running" ] && [ "$NOVNC_STATUS" = "running" ] && [ "$TUNNEL_STATUS" = "running" ] && echo "true" || echo "false"),
  "url": "$URL",
  "allowedEmail": "$EMAIL"
}
EOF
STATUSSCRIPT

chmod +x $SKILL_DIR/status.sh

#######################################
# COPY SKILL.MD
#######################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/SKILL.md" ]; then
    cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
    echo "📝 SKILL.md installed"
fi

#######################################
# FINAL OUTPUT
#######################################

echo ""
echo "========================================"
echo "✅ Installation complete!"
echo "========================================"
echo ""
echo "🔐 Protected by: Google OAuth"
echo "   Only $ALLOWED_EMAIL can access"
echo ""
echo "📂 Scripts installed in:"
echo "   $SKILL_DIR/"
echo ""
echo "🚀 TO START:"
echo "   $SKILL_DIR/start-tunnel.sh"
echo ""
echo "🛑 TO STOP:"
echo "   $SKILL_DIR/stop-tunnel.sh"
echo ""
echo "📊 TO CHECK STATUS:"
echo "   $SKILL_DIR/status.sh"
echo ""
