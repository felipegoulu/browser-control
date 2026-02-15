#!/usr/bin/env python3
"""
Google OAuth authentication to get user's email.
Works on both desktop (localhost) and headless servers (via ngrok tunnel).
"""

import http.server
import json
import os
import secrets
import socketserver
import subprocess
import sys
import threading
import time
import urllib.parse
import urllib.request
import webbrowser
from pathlib import Path

# OAuth configuration
CLIENT_ID = "929025941742-kd8he80abnf5grm1587snsvo0aq4ugu3.apps.googleusercontent.com"
LOCAL_PORT = 8585
SCOPES = "openid email"

# Where to save the email
SKILL_DIR = Path.home() / ".openclaw" / "skills" / "browser-control"


class OAuthHandler(http.server.BaseHTTPRequestHandler):
    """Handle OAuth callback"""
    
    email = None
    error = None
    server_should_stop = False
    
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
                self.send_error_page("Authentication cancelled or failed")
                OAuthHandler.server_should_stop = True
                return
            
            if "code" not in params:
                OAuthHandler.error = "No authorization code received"
                self.send_error_page("No authorization code received")
                OAuthHandler.server_should_stop = True
                return
            
            code = params["code"][0]
            redirect_uri = params.get("state", [""])[0]  # We pass redirect_uri in state
            
            # Exchange code for tokens
            try:
                email = self.exchange_code_for_email(code, redirect_uri)
                OAuthHandler.email = email
                self.send_success_page(email)
            except Exception as e:
                OAuthHandler.error = str(e)
                self.send_error_page(str(e))
            
            OAuthHandler.server_should_stop = True
        else:
            self.send_response(404)
            self.end_headers()
    
    def send_success_page(self, email):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(f"""
            <html>
            <head><title>Verified!</title></head>
            <body style="font-family: -apple-system, sans-serif; text-align: center; padding-top: 50px; background: #1a1a2e; color: white;">
            <h1 style="color: #4ade80;">✓ Verified!</h1>
            <p style="font-size: 24px; color: #e0e0e0;">{email}</p>
            <p style="color: #888;">You can close this window and return to the terminal.</p>
            </body></html>
        """.encode())
    
    def send_error_page(self, error):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(f"""
            <html>
            <head><title>Error</title></head>
            <body style="font-family: -apple-system, sans-serif; text-align: center; padding-top: 50px; background: #1a1a2e; color: white;">
            <h1 style="color: #f87171;">✗ Error</h1>
            <p style="color: #e0e0e0;">{error}</p>
            <p style="color: #888;">Close this window and try again.</p>
            </body></html>
        """.encode())
    
    def exchange_code_for_email(self, code, redirect_uri):
        """Exchange authorization code for tokens and get email"""
        token_url = "https://oauth2.googleapis.com/token"
        
        data = urllib.parse.urlencode({
            "code": code,
            "client_id": CLIENT_ID,
            "redirect_uri": redirect_uri,
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


def get_ngrok_url():
    """Start ngrok and get the public URL"""
    # Kill any existing ngrok on this port
    subprocess.run(["pkill", "-f", f"ngrok.*{LOCAL_PORT}"], capture_output=True)
    time.sleep(1)
    
    # Start ngrok in background
    process = subprocess.Popen(
        ["ngrok", "http", str(LOCAL_PORT), "--log=stdout"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    
    # Wait for tunnel URL (max 15 seconds)
    for _ in range(15):
        time.sleep(1)
        try:
            req = urllib.request.Request("http://127.0.0.1:4040/api/tunnels")
            with urllib.request.urlopen(req, timeout=2) as response:
                data = json.loads(response.read().decode())
                tunnels = data.get("tunnels", [])
                for tunnel in tunnels:
                    url = tunnel.get("public_url", "")
                    if url.startswith("https://"):
                        return url, process
        except:
            pass
    
    process.kill()
    return None, None


def has_display():
    """Check if we have a GUI display"""
    if sys.platform == "darwin":
        return True
    return bool(os.environ.get("DISPLAY"))


def main():
    print("")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🔐 Verify your Google account")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("")
    
    use_ngrok = not has_display()
    ngrok_process = None
    
    if use_ngrok:
        print("Starting temporary tunnel for authentication...")
        redirect_uri_base, ngrok_process = get_ngrok_url()
        if not redirect_uri_base:
            print("❌ Could not start ngrok tunnel")
            sys.exit(1)
        redirect_uri = f"{redirect_uri_base}/callback"
        print(f"✓ Tunnel ready")
    else:
        redirect_uri = f"http://localhost:{LOCAL_PORT}/callback"
    
    # Build OAuth URL (pass redirect_uri in state so callback knows it)
    auth_url = (
        "https://accounts.google.com/o/oauth2/v2/auth?"
        + urllib.parse.urlencode({
            "client_id": CLIENT_ID,
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "scope": SCOPES,
            "state": redirect_uri,  # Pass redirect_uri for token exchange
            "access_type": "online",
            "prompt": "select_account",
        })
    )
    
    # Start local server
    try:
        server = socketserver.TCPServer(("", LOCAL_PORT), OAuthHandler)
        server.timeout = 120
    except OSError as e:
        print(f"❌ Could not start server on port {LOCAL_PORT}: {e}")
        if ngrok_process:
            ngrok_process.kill()
        sys.exit(1)
    
    # Show URL to user
    print("")
    print("Open this link in your browser:")
    print("")
    print(f"👉 {auth_url}")
    print("")
    print("Waiting for login... (2 min timeout)")
    
    # Try to open browser (works on desktop)
    if has_display():
        webbrowser.open(auth_url)
    
    # Wait for callback
    while not OAuthHandler.server_should_stop:
        server.handle_request()
    
    server.server_close()
    
    # Cleanup ngrok
    if ngrok_process:
        ngrok_process.kill()
        subprocess.run(["pkill", "-f", f"ngrok.*{LOCAL_PORT}"], capture_output=True)
    
    if OAuthHandler.error:
        print(f"❌ Authentication failed: {OAuthHandler.error}")
        sys.exit(1)
    
    if not OAuthHandler.email:
        print("❌ Could not get email from Google")
        sys.exit(1)
    
    email = OAuthHandler.email
    
    print("")
    print(f"✅ Verified: {email}")
    print("")
    
    # Output for calling script
    print(f"GOOGLE_EMAIL={email}")


if __name__ == "__main__":
    main()
