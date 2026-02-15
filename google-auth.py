#!/usr/bin/env python3
"""
Google OAuth authentication to get user's email.
Starts a temporary local server to handle the OAuth callback.
"""

import http.server
import json
import os
import secrets
import socketserver
import sys
import urllib.parse
import urllib.request
import webbrowser
from pathlib import Path

# OAuth configuration
# Using a public OAuth client for CLI apps (no secret needed)
CLIENT_ID = "929025941742-kd8he80abnf5grm1587snsvo0aq4ugu3.apps.googleusercontent.com"
REDIRECT_PORT = 8585
REDIRECT_URI = f"http://localhost:{REDIRECT_PORT}/callback"
SCOPES = "openid email"

# Where to save the email
SKILL_DIR = Path.home() / ".openclaw" / "skills" / "browser-control"
OUTPUT_FILE = SKILL_DIR / "google-email.txt"


class OAuthHandler(http.server.BaseHTTPRequestHandler):
    """Handle OAuth callback"""
    
    email = None
    error = None
    
    def log_message(self, format, *args):
        """Suppress HTTP logs"""
        pass
    
    def do_GET(self):
        """Handle GET request (OAuth callback)"""
        parsed = urllib.parse.urlparse(self.path)
        
        if parsed.path == "/callback":
            params = urllib.parse.parse_qs(parsed.query)
            
            if "error" in params:
                OAuthHandler.error = params.get("error", ["Unknown error"])[0]
                self.send_response(200)
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.wfile.write(b"""
                    <html><body style="font-family: sans-serif; text-align: center; padding-top: 50px;">
                    <h1>&#10060; Authentication Failed</h1>
                    <p>You can close this window.</p>
                    </body></html>
                """)
                return
            
            if "code" not in params:
                OAuthHandler.error = "No authorization code received"
                self.send_response(400)
                self.end_headers()
                return
            
            code = params["code"][0]
            
            # Exchange code for tokens
            try:
                email = self.exchange_code_for_email(code)
                OAuthHandler.email = email
                
                self.send_response(200)
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.wfile.write(f"""
                    <html><body style="font-family: sans-serif; text-align: center; padding-top: 50px;">
                    <h1>&#9989; Verified!</h1>
                    <p style="font-size: 24px; color: #333;">{email}</p>
                    <p style="color: #666;">You can close this window and return to the terminal.</p>
                    </body></html>
                """.encode())
                
            except Exception as e:
                OAuthHandler.error = str(e)
                self.send_response(200)
                self.send_header("Content-type", "text/html")
                self.end_headers()
                self.wfile.write(f"""
                    <html><body style="font-family: sans-serif; text-align: center; padding-top: 50px;">
                    <h1>&#10060; Error</h1>
                    <p>{str(e)}</p>
                    </body></html>
                """.encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def exchange_code_for_email(self, code):
        """Exchange authorization code for tokens and get email"""
        # Token endpoint
        token_url = "https://oauth2.googleapis.com/token"
        
        data = urllib.parse.urlencode({
            "code": code,
            "client_id": CLIENT_ID,
            "redirect_uri": REDIRECT_URI,
            "grant_type": "authorization_code",
        }).encode()
        
        req = urllib.request.Request(token_url, data=data, method="POST")
        req.add_header("Content-Type", "application/x-www-form-urlencoded")
        
        with urllib.request.urlopen(req, timeout=30) as response:
            tokens = json.loads(response.read().decode())
        
        # Get user info
        userinfo_url = "https://openidconnect.googleapis.com/v1/userinfo"
        req = urllib.request.Request(userinfo_url)
        req.add_header("Authorization", f"Bearer {tokens['access_token']}")
        
        with urllib.request.urlopen(req, timeout=30) as response:
            userinfo = json.loads(response.read().decode())
        
        return userinfo.get("email", "")


def main():
    print("")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🔐 Verify your Google account")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("")
    print("Opening Google login...")
    print("Sign in with the Google account you want to use.")
    print("")
    
    # Build OAuth URL
    state = secrets.token_urlsafe(16)
    auth_url = (
        "https://accounts.google.com/o/oauth2/v2/auth?"
        + urllib.parse.urlencode({
            "client_id": CLIENT_ID,
            "redirect_uri": REDIRECT_URI,
            "response_type": "code",
            "scope": SCOPES,
            "state": state,
            "access_type": "online",
            "prompt": "select_account",  # Always show account picker
        })
    )
    
    # Start server
    try:
        server = socketserver.TCPServer(("", REDIRECT_PORT), OAuthHandler)
        server.timeout = 120  # 2 minute timeout
    except OSError as e:
        print(f"❌ Could not start server on port {REDIRECT_PORT}: {e}")
        sys.exit(1)
    
    # Open browser
    webbrowser.open(auth_url)
    
    print(f"Waiting for login... (timeout: 2 minutes)")
    print("")
    
    # Wait for callback
    server.handle_request()
    server.server_close()
    
    if OAuthHandler.error:
        print(f"❌ Authentication failed: {OAuthHandler.error}")
        sys.exit(1)
    
    if not OAuthHandler.email:
        print("❌ Could not get email from Google")
        sys.exit(1)
    
    email = OAuthHandler.email
    
    # Save email
    SKILL_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(email)
    
    print(f"✅ Verified: {email}")
    print("")
    
    # Output email for the calling script
    print(f"GOOGLE_EMAIL={email}")


if __name__ == "__main__":
    main()
