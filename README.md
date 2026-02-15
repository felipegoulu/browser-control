# 🖥️ Browser Control

Skill de OpenClaw para browser real con acceso remoto.

Tu agente puede usar un browser real (Chromium) y cuando necesita login, 2FA, o captchas, te manda un link para que tomes control.

## Instalación

```bash
curl -sL https://raw.githubusercontent.com/felipegoulu/browser-control/main/install.sh | bash
```

## ¿Qué hace?

1. **Instala** VNC + noVNC + cloudflared + Chromium
2. **Crea un tunnel** para acceder desde cualquier lugar
3. **Configura auto-start** para que arranque solo
4. **Actualiza TOOLS.md** con el link para que el agente lo sepa

## Flujo

```
Vos: "Fijate mi Gmail"
         │
         ▼
   Agente abre Gmail
         │
         ▼
   Gmail pide login
         │
         ▼
   Agente te manda:
   "🔐 Necesito que te loguees.
    Entrá acá: https://xxx.trycloudflare.com/vnc.html
    Password: pinchme1
    Avisame cuando termines."
         │
         ▼
   Vos abrís el link, hacés login
         │
         ▼
   Vos: "listo"
         │
         ▼
   Agente continúa y lee tus emails
```

## Compatibilidad

| OS | Estado |
|----|--------|
| Linux (Ubuntu/Debian) | ✅ |
| macOS | ✅ |
| Windows | ❌ (usá WSL) |

## Arquitectura

```
Internet
    │
    ▼
cloudflared (tunnel gratis)
    │
    ▼
noVNC (web server)
    │
    ▼
VNC Server
    │
    ▼
Desktop + Chromium ◄── OpenClaw (CDP)
```

## Archivos

```
browser-control/
├── install.sh          # Instalador principal
├── SKILL.md            # Instrucciones para el agente
├── README.md           # Este archivo
├── config.example.yaml # Ejemplo de config
└── services/           # Systemd units para auto-start
```

## Comandos

```bash
# Iniciar (si no está en auto-start)
~/.openclaw/skills/browser-control/start-tunnel.sh

# Detener
~/.openclaw/skills/browser-control/stop-tunnel.sh

# Ver URL actual
cat ~/.openclaw/skills/browser-control/config.json
```

## Seguridad

⚠️ El link es público. Cualquiera con el link + password puede ver tu browser.

- La URL es random y difícil de adivinar
- Cambia cada vez que reinicia el tunnel
- El password de VNC agrega una capa de protección

## Licencia

MIT
