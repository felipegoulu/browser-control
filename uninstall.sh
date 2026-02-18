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

sudo apt remove --purge -y \
    chromium-browser chromium \
    xvfb x11vnc novnc websockify tightvncserver \
    xfce4 xfce4-terminal xterm \
    ngrok \
    2>/dev/null || true

echo "   ✓ Packages removed"

echo ""
echo "🧹 Cleaning up..."
sudo apt autoremove -y
sudo apt clean
sudo rm -f /etc/apt/sources.list.d/ngrok.list

#######################################
# REMOVE SKILL FILES
#######################################

echo ""
echo "📁 Removing skill files..."

rm -rf "$SKILL_DIR"
echo "   ✓ $SKILL_DIR removed"

rm -rf ~/.vnc
echo "   ✓ ~/.vnc removed"

#######################################
# CLEAN TOOLS.MD
#######################################

TOOLS_FILE=~/.openclaw/workspace/TOOLS.md
if [ -f "$TOOLS_FILE" ]; then
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
echo "Run 'df -h' to check freed space."
echo ""
