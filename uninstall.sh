#!/bin/bash
# Browser Control Skill - Uninstaller
# Removes all installed components

set -e

echo "🗑️  Browser Control - Uninstaller"
echo "================================="
echo ""

SKILL_DIR=~/.openclaw/skills/browser-control

#######################################
# STOP SERVICES
#######################################

echo "🛑 Stopping services..."

pkill -f "ngrok.*http" 2>/dev/null && echo "   ✓ ngrok stopped" || true
pkill -f "websockify.*6080" 2>/dev/null && echo "   ✓ noVNC stopped" || true
pkill -f "x11vnc" 2>/dev/null && echo "   ✓ x11vnc stopped" || true
pkill -f "chromium.*remote-debugging-port" 2>/dev/null && echo "   ✓ Chromium stopped" || true
pkill -f "Xvfb.*:99" 2>/dev/null && echo "   ✓ Xvfb stopped" || true
vncserver -kill :1 2>/dev/null && echo "   ✓ VNC :1 stopped" || true

echo ""

#######################################
# REMOVE PACKAGES
#######################################

echo "📦 Removing installed packages..."
echo ""

read -p "Remove Chromium? [y/N]: " REMOVE_CHROME < /dev/tty
if [[ "$REMOVE_CHROME" =~ ^[Yy]$ ]]; then
    sudo apt remove --purge -y chromium-browser chromium 2>/dev/null || true
    echo "   ✓ Chromium removed"
fi

read -p "Remove VNC/display packages (xvfb, x11vnc, novnc, websockify)? [y/N]: " REMOVE_VNC < /dev/tty
if [[ "$REMOVE_VNC" =~ ^[Yy]$ ]]; then
    sudo apt remove --purge -y xvfb x11vnc novnc websockify tightvncserver 2>/dev/null || true
    echo "   ✓ VNC packages removed"
fi

read -p "Remove desktop environment (xfce4)? [y/N]: " REMOVE_DE < /dev/tty
if [[ "$REMOVE_DE" =~ ^[Yy]$ ]]; then
    sudo apt remove --purge -y xfce4 xfce4-terminal xterm 2>/dev/null || true
    echo "   ✓ Desktop environment removed"
fi

read -p "Remove ngrok? [y/N]: " REMOVE_NGROK < /dev/tty
if [[ "$REMOVE_NGROK" =~ ^[Yy]$ ]]; then
    sudo apt remove --purge -y ngrok 2>/dev/null || true
    sudo rm -f /etc/apt/sources.list.d/ngrok.list
    echo "   ✓ ngrok removed"
fi

echo ""
echo "🧹 Cleaning up..."
sudo apt autoremove -y
sudo apt clean

#######################################
# REMOVE SKILL FILES
#######################################

echo ""
read -p "Remove skill directory ($SKILL_DIR)? [y/N]: " REMOVE_SKILL < /dev/tty
if [[ "$REMOVE_SKILL" =~ ^[Yy]$ ]]; then
    rm -rf "$SKILL_DIR"
    echo "   ✓ Skill directory removed"
fi

#######################################
# REMOVE VNC CONFIG
#######################################

read -p "Remove VNC config (~/.vnc)? [y/N]: " REMOVE_VNC_CONFIG < /dev/tty
if [[ "$REMOVE_VNC_CONFIG" =~ ^[Yy]$ ]]; then
    rm -rf ~/.vnc
    echo "   ✓ VNC config removed"
fi

#######################################
# CLEAN TOOLS.MD
#######################################

TOOLS_FILE=~/.openclaw/workspace/TOOLS.md
if [ -f "$TOOLS_FILE" ]; then
    # Remove Browser Control section
    sed -i '/## Browser Control/,/^## /{ /^## Browser Control/d; /^## /!d; }' "$TOOLS_FILE" 2>/dev/null || true
    sed -i '/^The user will need to login/d' "$TOOLS_FILE" 2>/dev/null || true
    echo "   ✓ TOOLS.md cleaned"
fi

#######################################
# DONE
#######################################

echo ""
echo "========================================"
echo "✅ Uninstall complete!"
echo "========================================"
echo ""
echo "Space freed. Run 'df -h' to check."
echo ""
