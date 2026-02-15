#!/bin/bash
# Browser Control Setup Script
# Corre esto en un EC2 Ubuntu para instalar todo

set -e

echo "📦 Instalando dependencias..."
sudo apt-get update
sudo apt-get install -y tightvncserver xfce4 xfce4-terminal xterm novnc websockify

echo "📦 Instalando Chromium..."
sudo apt-get install -y chromium-browser

echo "🔧 Configurando VNC..."
mkdir -p ~/.vnc

# Password por defecto (cambialo si querés)
VNC_PASSWORD="${VNC_PASSWORD:-pinchme1}"
echo "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Startup script
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
sleep 2
chromium-browser --no-sandbox --disable-gpu --remote-debugging-port=9222 &
EOF
chmod +x ~/.vnc/xstartup

echo "🚀 Iniciando VNC..."
vncserver -kill :1 2>/dev/null || true
vncserver :1

echo "🌐 Iniciando noVNC..."
pkill -f websockify || true
nohup websockify --web=/usr/share/novnc 6080 localhost:5901 &>/tmp/novnc.log &

echo "✅ Setup completo!"
echo ""
echo "Acceso:"
PUBLIC_IP=$(curl -s ifconfig.me)
echo "  noVNC: http://$PUBLIC_IP:6080/vnc.html"
echo "  Password: $VNC_PASSWORD"
echo ""
echo "Puertos a abrir en Security Group:"
echo "  - 5901 (VNC)"
echo "  - 6080 (noVNC)"
echo "  - 9222 (CDP - solo si necesitás acceso externo)"
