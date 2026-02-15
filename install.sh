#!/bin/bash
# Browser Control Skill - Installer
# Installs VNC + noVNC + cloudflared automatically

set -e

echo "🖥️  Browser Control - Installer"
echo "================================"

#######################################
# DETECT OS AND ARCHITECTURE
#######################################

OS="unknown"
ARCH=$(uname -m)

if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
    BREW_PREFIX=$(brew --prefix 2>/dev/null || echo "/usr/local")
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    # Normalize architecture names
    case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        armv7l) ARCH="arm" ;;
    esac
else
    echo "❌ Unsupported OS: $OSTYPE"
    echo ""
    echo "Supported: Linux (Ubuntu/Debian), macOS"
    echo "For Windows, use WSL: https://docs.microsoft.com/en-us/windows/wsl/install"
    exit 1
fi

echo "📍 OS: $OS | Arch: $ARCH"

#######################################
# CREATE DIRECTORIES
#######################################

mkdir -p ~/.openclaw/skills/browser-control
mkdir -p ~/.openclaw/workspace
SKILL_DIR=~/.openclaw/skills/browser-control

#######################################
# GENERATE PASSWORD
#######################################

VNC_PASSWORD=$(openssl rand -base64 6)
echo "$VNC_PASSWORD" > $SKILL_DIR/vnc-password
chmod 600 $SKILL_DIR/vnc-password

#######################################
# LINUX INSTALLATION
#######################################

if [[ "$OS" == "linux" ]]; then
    echo "📦 Installing dependencies (Linux)..."
    
    sudo apt-get update
    sudo apt-get install -y tightvncserver xfce4 xfce4-terminal xterm novnc websockify curl
    
    # Chromium
    echo "📦 Installing Chromium..."
    sudo apt-get install -y chromium-browser || sudo apt-get install -y chromium
    
    # Cloudflared (detect architecture)
    if ! command -v cloudflared &> /dev/null; then
        echo "📦 Installing cloudflared ($ARCH)..."
        CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$ARCH"
        curl -L "$CLOUDFLARED_URL" -o /tmp/cloudflared
        sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
        sudo chmod +x /usr/local/bin/cloudflared
    fi
    
    # Configure VNC
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
    
    # Find Chromium binary
    CHROMIUM_BIN=$(which chromium-browser 2>/dev/null || which chromium 2>/dev/null || echo "chromium-browser")
    
    NOVNC_WEB="/usr/share/novnc"
    VNC_PORT=5901
    VNC_DISPLAY=":1"

#######################################
# MAC INSTALLATION
#######################################

elif [[ "$OS" == "mac" ]]; then
    echo "📦 Installing dependencies (Mac)..."
    
    # Check for Homebrew
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not found. Install it first:"
        echo '   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
    fi
    
    brew install websockify cloudflared novnc || true
    
    # Find noVNC path
    NOVNC_WEB="$BREW_PREFIX/share/novnc"
    if [ ! -d "$NOVNC_WEB" ]; then
        NOVNC_WEB="/opt/homebrew/share/novnc"
    fi
    if [ ! -d "$NOVNC_WEB" ]; then
        NOVNC_WEB="/usr/local/share/novnc"
    fi
    
    VNC_PORT=5900
    VNC_DISPLAY=""
    
    # On Mac, use system password
    echo "(your Mac password)" > $SKILL_DIR/vnc-password
    
    echo ""
    echo "⚠️  IMPORTANT: Enable Screen Sharing"
    echo "   System Preferences → Sharing → Screen Sharing ✅"
    echo "   Your Mac login password will be the VNC password."
    echo ""
    
    # Create Chrome launcher script for Mac
    cat > $SKILL_DIR/start-chrome.sh << 'CHROME'
#!/bin/bash
# Start Chrome with remote debugging on Mac
CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CHROMIUM_PATH="/Applications/Chromium.app/Contents/MacOS/Chromium"

if [ -f "$CHROME_PATH" ]; then
    "$CHROME_PATH" --remote-debugging-port=9222 &
elif [ -f "$CHROMIUM_PATH" ]; then
    "$CHROMIUM_PATH" --remote-debugging-port=9222 &
else
    echo "❌ Chrome/Chromium not found. Please install Google Chrome."
    exit 1
fi
echo "✅ Chrome started with remote debugging on port 9222"
CHROME
    chmod +x $SKILL_DIR/start-chrome.sh
fi

#######################################
# CREATE START SCRIPT
#######################################

echo "🔧 Creating start script..."

cat > $SKILL_DIR/start-tunnel.sh << STARTSCRIPT
#!/bin/bash
# Browser Control - Start all services

set -e

SKILL_DIR=~/.openclaw/skills/browser-control
CONFIG_FILE=\$SKILL_DIR/config.json
TOOLS_FILE=~/.openclaw/workspace/TOOLS.md
VNC_PASSWORD=\$(cat \$SKILL_DIR/vnc-password 2>/dev/null || echo "unknown")
OS="$OS"
VNC_PORT=$VNC_PORT
NOVNC_WEB="$NOVNC_WEB"

echo "🖥️  Browser Control - Starting..."
echo ""

#######################################
# START VNC (Linux only)
#######################################

if [[ "\$OS" == "linux" ]]; then
    # Check if VNC is already running
    if pgrep -f "Xtightvnc.*:1" > /dev/null; then
        echo "✅ VNC already running"
    else
        echo "🖥️  Starting VNC server..."
        vncserver -kill :1 2>/dev/null || true
        vncserver :1 -geometry 1280x800 -depth 24
        sleep 2
        echo "✅ VNC started on display :1"
    fi
fi

if [[ "\$OS" == "mac" ]]; then
    # Check Screen Sharing
    if ! pgrep -x "screensharingd" > /dev/null; then
        echo "⚠️  Screen Sharing doesn't seem to be running."
        echo "   Enable it in System Preferences → Sharing → Screen Sharing"
    else
        echo "✅ Screen Sharing is running"
    fi
    
    # Start Chrome with CDP if not running
    if ! pgrep -f "remote-debugging-port=9222" > /dev/null; then
        echo "🌐 Starting Chrome with remote debugging..."
        \$SKILL_DIR/start-chrome.sh
        sleep 2
    else
        echo "✅ Chrome already running with remote debugging"
    fi
fi

#######################################
# START NOVNC
#######################################

echo "🌐 Starting noVNC..."
pkill -f "websockify.*6080" 2>/dev/null || true
sleep 1

if [ ! -d "\$NOVNC_WEB" ]; then
    echo "❌ noVNC not found at \$NOVNC_WEB"
    exit 1
fi

websockify --web=\$NOVNC_WEB 6080 localhost:\$VNC_PORT &
WEBSOCKIFY_PID=\$!
sleep 2

# Verify websockify started
if ! kill -0 \$WEBSOCKIFY_PID 2>/dev/null; then
    echo "❌ Failed to start noVNC"
    exit 1
fi
echo "✅ noVNC started on port 6080"

#######################################
# START CLOUDFLARED TUNNEL
#######################################

echo "🚇 Starting cloudflared tunnel..."
echo "   (This may take a few seconds)"
echo ""

# Kill any existing cloudflared
pkill -f "cloudflared.*tunnel" 2>/dev/null || true
sleep 1

# Start cloudflared in background, log to file
TUNNEL_LOG=\$SKILL_DIR/tunnel.log
cloudflared tunnel --url http://localhost:6080 > \$TUNNEL_LOG 2>&1 &
CLOUDFLARED_PID=\$!
echo \$CLOUDFLARED_PID > \$SKILL_DIR/cloudflared.pid

# Wait for URL (max 30 seconds)
echo "   Waiting for tunnel URL..."
URL=""
for i in {1..30}; do
    sleep 1
    URL=\$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' \$TUNNEL_LOG 2>/dev/null | head -1)
    if [ -n "\$URL" ]; then
        break
    fi
    echo -n "."
done
echo ""

if [ -z "\$URL" ]; then
    echo "❌ Failed to get tunnel URL after 30s"
    echo "   Check log: \$TUNNEL_LOG"
    cat \$TUNNEL_LOG
    exit 1
fi

echo ""
echo "========================================="
echo "✅ TUNNEL ACTIVE!"
echo ""
echo "🔗 Link: \$URL/vnc.html"
echo "🔑 Password: \$VNC_PASSWORD"
echo ""
echo "Open from your phone or any browser!"
echo "========================================="
echo ""

# Save to config.json
cat > \$CONFIG_FILE << CONF
{
    "novncUrl": "\$URL/vnc.html",
    "tunnelUrl": "\$URL",
    "vncPassword": "\$VNC_PASSWORD",
    "cdpUrl": "http://localhost:9222",
    "updatedAt": "\$(date -Iseconds)"
}
CONF

# Update TOOLS.md
if [ -f "\$TOOLS_FILE" ]; then
    # Remove old Browser Control section
    grep -v "## Browser Control" "\$TOOLS_FILE" | grep -v "noVNC URL:" | grep -v "Password:" | grep -v "Send the link" | grep -v "When you need the user" > "\$TOOLS_FILE.tmp" || true
    mv "\$TOOLS_FILE.tmp" "\$TOOLS_FILE"
fi

cat >> "\$TOOLS_FILE" << TOOLS

## Browser Control

When you need the user to login, 2FA, captcha, or any manual verification:

- noVNC URL: \$URL/vnc.html
- Password: \$VNC_PASSWORD

Send the link and wait for the user to say "done".
TOOLS

echo "📝 TOOLS.md updated"
echo "📝 Config saved to \$CONFIG_FILE"
echo ""
echo "🔄 Tunnel running in background (PID: \$CLOUDFLARED_PID)"
echo "   Stop with: \$SKILL_DIR/stop-tunnel.sh"
STARTSCRIPT

chmod +x $SKILL_DIR/start-tunnel.sh

#######################################
# CREATE STOP SCRIPT
#######################################

cat > $SKILL_DIR/stop-tunnel.sh << 'STOPSCRIPT'
#!/bin/bash
echo "🛑 Stopping Browser Control services..."

pkill -f cloudflared 2>/dev/null && echo "   ✓ cloudflared stopped" || echo "   - cloudflared not running"
pkill -f "websockify.*6080" 2>/dev/null && echo "   ✓ noVNC stopped" || echo "   - noVNC not running"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    vncserver -kill :1 2>/dev/null && echo "   ✓ VNC stopped" || echo "   - VNC not running"
fi

echo ""
echo "✅ All services stopped"
STOPSCRIPT

chmod +x $SKILL_DIR/stop-tunnel.sh

#######################################
# CREATE SYSTEMD SERVICES (Linux)
#######################################

if [[ "$OS" == "linux" ]]; then
    echo "🔧 Creating systemd services..."
    
    mkdir -p ~/.config/systemd/user
    
    # VNC Service
    cat > ~/.config/systemd/user/browser-control-vnc.service << VNCSERVICE
[Unit]
Description=Browser Control VNC Server
After=network.target

[Service]
Type=forking
ExecStartPre=/usr/bin/vncserver -kill :1 || true
ExecStart=/usr/bin/vncserver :1 -geometry 1280x800 -depth 24
ExecStop=/usr/bin/vncserver -kill :1
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
VNCSERVICE

    # noVNC Service
    cat > ~/.config/systemd/user/browser-control-novnc.service << NOVNCSERVICE
[Unit]
Description=Browser Control noVNC
After=browser-control-vnc.service
Requires=browser-control-vnc.service

[Service]
Type=simple
ExecStart=/usr/bin/websockify --web=$NOVNC_WEB 6080 localhost:5901
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
NOVNCSERVICE

    # Enable services
    systemctl --user daemon-reload
    systemctl --user enable browser-control-vnc.service 2>/dev/null || true
    systemctl --user enable browser-control-novnc.service 2>/dev/null || true
    
    echo "✅ Systemd services created"
    echo "   Auto-start on login enabled"
fi

#######################################
# FINAL OUTPUT
#######################################

echo ""
echo "========================================"
echo "✅ Installation complete!"
echo "========================================"
echo ""
echo "🔑 VNC Password: $VNC_PASSWORD"
echo "   (saved in $SKILL_DIR/vnc-password)"
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

if [[ "$OS" == "linux" ]]; then
    echo "🔄 AUTO-START (optional):"
    echo "   systemctl --user start browser-control-vnc"
    echo "   systemctl --user start browser-control-novnc"
    echo "   (Then run start-tunnel.sh for cloudflared)"
    echo ""
fi

if [[ "$OS" == "mac" ]]; then
    echo "⚠️  Don't forget:"
    echo "   1. Enable Screen Sharing in System Preferences"
    echo "   2. Your VNC password = your Mac login password"
    echo ""
fi
