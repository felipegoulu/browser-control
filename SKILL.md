# Browser Control Skill

This skill lets you use a real browser (Chromium) and ask the user for help when you need login, 2FA, captchas, etc.

## How it works

You have a real browser running with remote access via noVNC. When you need the user to intervene, you send them the link and they take control of the browser.

## Getting the link

**IMPORTANT:** The link can change. Always read the current link and password from `TOOLS.md` or `~/.openclaw/skills/browser-control/config.json` before sending it.

## When to ask for help

Ask for help when you detect:
- Login page / "Sign in" / "Log in"
- Captcha / "Verify you're human" / reCAPTCHA
- 2FA / "Verification code" / "Two-factor authentication"
- "Access denied" / "Unauthorized" / "Session expired"
- Any verification that requires the user's credentials

## How to ask for help

Send this message (adapt to context):

```
🔐 I need your help to continue.

Open this link from your phone or computer:
👉 [LINK FROM TOOLS.MD]

Password: [PASSWORD FROM TOOLS.MD]

Do [login / verification / etc.] and let me know when you're done.
```

## Full flow

1. You try to do something in the browser (e.g., open Gmail)
2. You detect a login page → send the link to the user
3. Wait for them to say "done" (or variants: "ready", "finished", "listo")
4. Verify the page changed (no longer login)
5. Continue with the original task

## Example

**User:** "Check my Gmail"

**You:** 
1. Open Gmail in browser
2. See Google login page

**You respond:**
> 🔐 Gmail is asking you to log in.
> 
> Open this: https://xxxx.trycloudflare.com/vnc.html
> Password: abc123
> 
> Log in with your Google account and tell me "done".

**User:** "done"

**You:**
1. Verify you're in the inbox
2. Read emails and respond

> ✅ Done! You have 3 new emails:
> 1. From John: "Meeting tomorrow"
> 2. ...

## Important notes

- **Don't ask for passwords.** The user types them directly in the browser.
- **Don't spam the link.** If the user doesn't respond, wait.
- **Verify after.** When the user says "done", confirm it worked.
- **The link can change.** Always read the updated link from TOOLS.md.
