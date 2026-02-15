# 🖥️ Browser Control Skill

Skill de OpenClaw para browser real con acceso remoto via noVNC + cloudflared.

## ¿Qué hace?

1. **Browser real** — Chromium con GUI (no headless)
2. **Acceso remoto** — noVNC para ver/controlar desde cualquier lugar
3. **Tunnel automático** — cloudflared expone el servidor gratis
4. **Auto-update URL** — cuando el tunnel se reinicia, actualiza la config
5. **Handoff inteligente** — el agente manda el link cuando necesita ayuda

## Quick Start

```bash
# 1. Descargar el skill
git clone https://github.com/felipegoulu/claw_app
cd claw_app/skills/browser-control

# 2. Instalar
chmod +x install.sh
./install.sh

# 3. Iniciar (Linux: primero vncserver :1)
~/.openclaw/skills/browser-control/start-tunnel.sh
```

## Arquitectura

```
                    Internet
                        │
                        ▼
            ┌───────────────────────┐
            │     cloudflared       │
            │  (tunnel gratuito)    │
            │                       │
            │  https://xxx.trycloudflare.com
            └───────────┬───────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │       noVNC           │
            │     (puerto 6080)     │
            └───────────┬───────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │     VNC Server        │
            │   (puerto 5900/5901)  │
            └───────────┬───────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │      Desktop          │
            │   (xfce4 / macOS)     │
            │                       │
            │  ┌─────────────────┐  │
            │  │    Chromium     │◄─┼── OpenClaw (CDP :9222)
            │  └─────────────────┘  │
            └───────────────────────┘
```

## Compatibilidad

| OS | VNC | Browser | Estado |
|----|-----|---------|--------|
| Ubuntu/Debian | tightvnc | Chromium | ✅ |
| macOS | Screen Sharing | Chrome | ✅ |
| Windows | TBD | TBD | 🚧 |

## Archivos instalados

```
~/.openclaw/skills/browser-control/
├── start-tunnel.sh    # Inicia noVNC + cloudflared
├── stop-tunnel.sh     # Detiene todo
└── config.json        # URL actual del tunnel
```

## Configuración

El skill actualiza automáticamente:

**~/.openclaw/skills/browser-control/config.json:**
```json
{
    "novncUrl": "https://xxx.trycloudflare.com/vnc.html",
    "tunnelUrl": "https://xxx.trycloudflare.com",
    "vncPassword": "pinchme1",
    "cdpUrl": "http://localhost:9222",
    "updatedAt": "2026-02-15T00:30:00-03:00"
}
```

**~/.openclaw/workspace/TOOLS.md:** (se agrega automáticamente)
```markdown
## Browser Control

- noVNC URL: https://xxx.trycloudflare.com/vnc.html
- Password: pinchme1
```

## Uso

### Iniciar

```bash
# Linux: primero VNC
vncserver :1

# Luego el tunnel
~/.openclaw/skills/browser-control/start-tunnel.sh
```

### Detener

```bash
~/.openclaw/skills/browser-control/stop-tunnel.sh
```

### Ver URL actual

```bash
cat ~/.openclaw/skills/browser-control/config.json | jq .novncUrl
```

## Seguridad

⚠️ El link es público. Cualquiera con el link puede ver tu browser.

Mitigaciones:
- El password de VNC protege el acceso
- La URL es random y difícil de adivinar
- La URL cambia cada vez que reinicias el tunnel

Para producción, considerá:
- Cloudflare Tunnel con dominio propio + auth
- VPN/Tailscale
- IP allowlist

## Troubleshooting

**El tunnel no arranca:**
```bash
# Verificar cloudflared
cloudflared --version

# Ver logs
cloudflared tunnel --url http://localhost:6080
```

**noVNC no conecta:**
```bash
# Verificar VNC
vncserver -list

# Verificar websockify
ps aux | grep websockify
```

**El agente no ve el link:**
```bash
# Verificar TOOLS.md
cat ~/.openclaw/workspace/TOOLS.md | grep -A5 "Browser Control"
```

## TODO

- [ ] Soporte Windows
- [ ] Systemd/launchd services para auto-start
- [ ] Token de autenticación temporal
- [ ] Notificación push cuando se necesita intervención
