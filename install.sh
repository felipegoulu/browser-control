#!/bin/bash
# Browser Control Skill - Instalador
# Instala VNC + noVNC + cloudflared automáticamente

set -e

echo "🦀 Browser Control Skill - Instalador"
echo "======================================"

# Detectar OS
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
fi

echo "📍 OS detectado: $OS"

# Crear directorios
mkdir -p ~/.openclaw/skills/browser-control
SKILL_DIR=~/.openclaw/skills/browser-control

#######################################
# INSTALACIÓN SEGÚN OS
#######################################

if [[ "$OS" == "linux" ]]; then
    echo "📦 Instalando dependencias (Linux)..."
    
    sudo apt-get update
    sudo apt-get install -y tightvncserver xfce4 xfce4-terminal xterm novnc websockify
    
    # Chromium
    sudo apt-get install -y chromium-browser
    
    # Cloudflared
    if ! command -v cloudflared &> /dev/null; then
        echo "📦 Instalando cloudflared..."
        curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /tmp/cloudflared
        sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
        sudo chmod +x /usr/local/bin/cloudflared
    fi
    
    # Configurar VNC
    echo "🔧 Configurando VNC..."
    mkdir -p ~/.vnc
    VNC_PASSWORD="pinchme1"
    echo "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
    
    # Startup script para VNC
    cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
sleep 2
chromium-browser --no-sandbox --disable-gpu --remote-debugging-port=9222 &
EOF
    chmod +x ~/.vnc/xstartup
    
    VNC_PORT=5901
    NOVNC_PORT=6080
    
elif [[ "$OS" == "mac" ]]; then
    echo "📦 Instalando dependencias (Mac)..."
    
    # Homebrew packages
    brew install websockify cloudflared || true
    
    # noVNC
    if [ ! -d "/opt/homebrew/share/novnc" ]; then
        brew install novnc || true
    fi
    
    echo "🔧 Habilitá Screen Sharing en System Preferences → Sharing"
    
    VNC_PORT=5900
    NOVNC_PORT=6080
    VNC_PASSWORD="(tu password de Mac)"
fi

#######################################
# CREAR SCRIPT DE TUNNEL
#######################################

echo "🔧 Creando script de tunnel..."

cat > $SKILL_DIR/start-tunnel.sh << 'TUNNEL_SCRIPT'
#!/bin/bash
# Inicia cloudflared y actualiza la URL automáticamente

SKILL_DIR=~/.openclaw/skills/browser-control
CONFIG_FILE=$SKILL_DIR/config.json
TOOLS_FILE=~/.openclaw/workspace/TOOLS.md

# Iniciar noVNC primero
echo "🌐 Iniciando noVNC..."
pkill -f "websockify.*6080" || true
if [[ "$OSTYPE" == "darwin"* ]]; then
    websockify --web=/opt/homebrew/share/novnc 6080 localhost:5900 &
else
    websockify --web=/usr/share/novnc 6080 localhost:5901 &
fi
sleep 2

# Iniciar cloudflared y capturar URL
echo "🚇 Iniciando tunnel..."
cloudflared tunnel --url http://localhost:6080 2>&1 | while read line; do
    echo "$line"
    
    if [[ $line == *"trycloudflare.com"* ]]; then
        URL=$(echo $line | grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com')
        
        if [ -n "$URL" ]; then
            echo ""
            echo "✅ ¡Tunnel activo!"
            echo "🔗 Link: $URL/vnc.html"
            echo ""
            
            # Guardar en config.json
            cat > $CONFIG_FILE << EOF
{
    "novncUrl": "$URL/vnc.html",
    "tunnelUrl": "$URL",
    "vncPassword": "pinchme1",
    "cdpUrl": "http://localhost:9222",
    "updatedAt": "$(date -Iseconds)"
}
EOF
            
            # Actualizar TOOLS.md
            if [ -f "$TOOLS_FILE" ]; then
                # Buscar si ya existe la sección
                if grep -q "## Browser Control" "$TOOLS_FILE"; then
                    # Actualizar URL existente
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        sed -i '' "s|noVNC URL:.*|noVNC URL: $URL/vnc.html|" "$TOOLS_FILE"
                    else
                        sed -i "s|noVNC URL:.*|noVNC URL: $URL/vnc.html|" "$TOOLS_FILE"
                    fi
                else
                    # Agregar sección
                    cat >> "$TOOLS_FILE" << EOF

## Browser Control

Cuando necesites que el usuario haga login, 2FA, captcha, o cualquier verificación manual:

- noVNC URL: $URL/vnc.html
- Password: pinchme1

Mandá el link y esperá que el usuario diga "listo".
EOF
                fi
                echo "📝 TOOLS.md actualizado"
            fi
        fi
    fi
done
TUNNEL_SCRIPT

chmod +x $SKILL_DIR/start-tunnel.sh

#######################################
# CREAR SCRIPT DE STOP
#######################################

cat > $SKILL_DIR/stop-tunnel.sh << 'STOP_SCRIPT'
#!/bin/bash
echo "🛑 Deteniendo servicios..."
pkill -f cloudflared || true
pkill -f "websockify.*6080" || true
pkill -f vncserver || true
echo "✅ Servicios detenidos"
STOP_SCRIPT

chmod +x $SKILL_DIR/stop-tunnel.sh

#######################################
# FINALIZAR
#######################################

echo ""
echo "✅ ¡Instalación completa!"
echo ""
echo "Para iniciar:"
echo "  ~/.openclaw/skills/browser-control/start-tunnel.sh"
echo ""
echo "Para detener:"
echo "  ~/.openclaw/skills/browser-control/stop-tunnel.sh"
echo ""

if [[ "$OS" == "linux" ]]; then
    echo "⚠️  Primero iniciá VNC:"
    echo "  vncserver :1"
    echo ""
fi

echo "El link de noVNC se guardará automáticamente en:"
echo "  - ~/.openclaw/skills/browser-control/config.json"
echo "  - ~/.openclaw/workspace/TOOLS.md"
