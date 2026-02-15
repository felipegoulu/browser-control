#!/bin/bash
# Browser Control Skill - Installer
# Installs VNC + noVNC + cloudflared automatically

set -e

echo "🖥️ Browser Control - Installer"
echo "==============================="

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo "❌ Unsupported OS: $OSTYPE"
    echo ""
    echo "Supported: Linux (Ubuntu/Debian), macOS"
    echo "For Windows, use WSL: https://docs.microsoft.com/en-us/windows/wsl/install"
    exit 1
fi

echo "📍 OS detected: $OS"

# Create directories
mkdir -p ~/.openclaw/skills/browser-control
SKILL_DIR=~/.openclaw/skills/browser-control

# Generate random password
VNC_PASSWORD=$(openssl rand -base64 6)
echo "$VNC_PASSWORD" > $SKILL_DIR/vnc-password
chmod 600 $SKILL_DIR/vnc-password

#######################################
# OS-SPECIFIC INSTALLATION
#######################################

if [[ "$OS" == "linux" ]]; then
    echo "📦 Installing dependencies (Linux)..."
    
    sudo apt-get update
    sudo apt-get install -y tightvncserver xfce4 xfce4-terminal xterm novnc websockify
    
    # Chromium
    sudo apt-get install -y chromium-browser
    
    # Cloudflared
    if ! command -v cloudflared &> /dev/null; then
        echo "📦 Installing cloudflared..."
        curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /tmp/cloudflared
        sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
        sudo chmod +x /usr/local/bin/cloudflared
    fi
    
    # Configure VNC
    echo "🔧 Configuring VNC..."
    mkdir -p ~/.vnc
    echo "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
    
    # VNC startup script
    cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
sleep 2
chromium-browser --no-sandbox --disable-gpu --remote-debugging-port=9222 &
EOF
    chmod +x ~/.vnc/xstartup
    
    NOVNC_WEB="/usr/share/novnc"
    VNC_PORT=5901
    
elif [[ "$OS" == "mac" ]]; then
    echo "📦 Installing dependencies (Mac)..."
    
    brew install websockify cloudflared novnc || true
    
    echo ""
    echo "⚠️  Enable Screen Sharing: System Preferences → Sharing → Screen Sharing ✅"
    echo "   Your Mac login password will be the VNC password."
    echo ""
    
    NOVNC_WEB="/opt/homebrew/share/novnc"
    VNC_PORT=5900
    
    # On Mac, use the system password
    echo "(your Mac password)" > $SKILL_DIR/vnc-password
fi

#######################################
# CREATE START SCRIPT
#######################################

echo "🔧 Creating tunnel script..."

cat > $SKILL_DIR/start-tunnel.sh << EOF
#!/bin/bash
# Browser Control - Start tunnel

SKILL_DIR=~/.openclaw/skills/browser-control
CONFIG_FILE=\$SKILL_DIR/config.json
TOOLS_FILE=~/.openclaw/workspace/TOOLS.md
VNC_PASSWORD=\$(cat \$SKILL_DIR/vnc-password)

# Start noVNC
echo "🌐 Starting noVNC..."
pkill -f "websockify.*6080" || true
websockify --web=$NOVNC_WEB 6080 localhost:$VNC_PORT &
sleep 2

# Start cloudflared and capture URL
echo "🚇 Starting tunnel..."
cloudflared tunnel --url http://localhost:6080 2>&1 | while read line; do
    echo "\$line"
    
    if [[ \$line == *"trycloudflare.com"* ]]; then
        URL=\$(echo \$line | grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com')
        
        if [ -n "\$URL" ]; then
            echo ""
            echo "✅ Tunnel active!"
            echo "🔗 Link: \$URL/vnc.html"
            echo "🔑 Password: \$VNC_PASSWORD"
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
            mkdir -p ~/.openclaw/workspace
            if [ -f "\$TOOLS_FILE" ]; then
                if grep -q "## Browser Control" "\$TOOLS_FILE"; then
                    # Update existing
                    sed -i'' -e "s|noVNC URL:.*|noVNC URL: \$URL/vnc.html|" "\$TOOLS_FILE"
                    sed -i'' -e "s|Password:.*|Password: \$VNC_PASSWORD|" "\$TOOLS_FILE"
                else
                    # Add section
                    cat >> "\$TOOLS_FILE" << TOOLS

## Browser Control

When you need the user to login, 2FA, captcha, or any manual verification:

- noVNC URL: \$URL/vnc.html
- Password: \$VNC_PASSWORD

Send the link and wait for the user to say "done".
TOOLS
                fi
            else
                cat > "\$TOOLS_FILE" << TOOLS
## Browser Control

When you need the user to login, 2FA, captcha, or any manual verification:

- noVNC URL: \$URL/vnc.html
- Password: \$VNC_PASSWORD

Send the link and wait for the user to say "done".
TOOLS
            fi
            echo "📝 TOOLS.md updated"
        fi
    fi
done
EOF

chmod +x $SKILL_DIR/start-tunnel.sh

#######################################
# CREATE STOP SCRIPT
#######################################

cat > $SKILL_DIR/stop-tunnel.sh << 'STOP'
#!/bin/bash
echo "🛑 Stopping services..."
pkill -f cloudflared || true
pkill -f "websockify.*6080" || true
pkill -f vncserver || true
echo "✅ Services stopped"
STOP

chmod +x $SKILL_DIR/stop-tunnel.sh

#######################################
# DONE
#######################################

echo ""
echo "✅ Installation complete!"
echo ""
echo "🔑 Your VNC password: $VNC_PASSWORD"
echo "   (saved in $SKILL_DIR/vnc-password)"
echo ""
if [[ "$OS" == "linux" ]]; then
    echo "To start:"
    echo "  1. vncserver :1"
    echo "  2. $SKILL_DIR/start-tunnel.sh"
else
    echo "To start:"
    echo "  1. Enable Screen Sharing in System Preferences"
    echo "  2. $SKILL_DIR/start-tunnel.sh"
fi
echo ""
echo "To stop:"
echo "  $SKILL_DIR/stop-tunnel.sh"
