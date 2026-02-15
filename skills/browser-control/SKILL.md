# Browser Control Skill

Este skill te permite usar un browser real (Chromium) y pedir ayuda al usuario cuando necesitás que haga login, 2FA, captchas, etc.

## Cómo funciona

Tenés un browser real corriendo con acceso remoto via noVNC. Cuando necesitás que el usuario intervenga, le mandás el link y él toma control del browser.

## Obtener el link

**IMPORTANTE:** El link puede cambiar. Siempre leé el link actualizado de `TOOLS.md` o de `~/.openclaw/skills/browser-control/config.json` antes de mandarlo.

## Cuándo pedir ayuda

Pedí ayuda cuando detectes:
- Página de login / "Sign in" / "Log in"
- Captcha / "Verify you're human" / reCAPTCHA
- 2FA / "Verification code" / "Two-factor authentication"
- "Access denied" / "Unauthorized" / "Session expired"
- Cualquier verificación que requiera credenciales del usuario

## Cómo pedir ayuda

Mandá este mensaje (adaptalo al contexto):

```
🔐 Necesito tu ayuda para continuar.

Entrá a este link desde tu celu o compu:
👉 [LINK DE TOOLS.MD]

Password: pinchme1

Hacé [login / la verificación / etc.] y cuando termines decime "listo".
```

## Flujo completo

1. Intentás hacer algo en el browser (ej: abrir Gmail)
2. Detectás página de login → mandás el link al usuario
3. Esperás a que diga "listo" (o variantes: "ya está", "done", "terminé", "listo!")
4. Verificás que la página cambió (ya no es login)
5. Continuás con la tarea original

## Ejemplo

**Usuario:** "Fijate mis emails de Gmail"

**Vos:** 
1. Abrís Gmail en el browser
2. Ves página de login de Google

**Vos respondés:**
> 🔐 Gmail me pide que inicies sesión.
> 
> Entrá acá: https://xxxx.trycloudflare.com/vnc.html
> Password: pinchme1
> 
> Logueate con tu cuenta de Google y decime "listo".

**Usuario:** "listo"

**Vos:**
1. Verificás que estás en la bandeja de entrada
2. Leés los emails y respondés

> ✅ Perfecto! Tenés 3 emails nuevos:
> 1. De Juan: "Reunión mañana"
> 2. ...

## Notas importantes

- **No pidas contraseñas.** El usuario las escribe directo en el browser.
- **No spamees el link.** Si el usuario no responde, esperá.
- **Verificá después.** Cuando el usuario dice "listo", confirmá que funcionó.
- **El link puede cambiar.** Siempre leé el link actualizado de TOOLS.md.
