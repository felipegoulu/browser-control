#!/usr/bin/env python3
"""
Google OAuth authentication via verification service.
Uses browser-control-auth.vercel.app for the OAuth flow,
which generates a 6-char code the user pastes here.
"""

import json
import os
import sys
import urllib.request
from pathlib import Path

VERIFY_URL = "https://browser-control-auth.vercel.app"

def read_input(prompt):
    """Read input from terminal, even when stdin is piped."""
    sys.stdout.write(prompt)
    sys.stdout.flush()
    
    # If stdin is not a tty (e.g., piped), read from /dev/tty
    if not sys.stdin.isatty():
        try:
            with open('/dev/tty', 'r') as tty:
                return tty.readline().strip()
        except:
            return input()  # Fallback
    return input().strip()

def main():
    print("")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🔐 Verify your Google account")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("")
    print("1. Open this link in your browser:")
    print("")
    print(f"   👉 {VERIFY_URL}/verify")
    print("")
    print("2. Sign in with Google")
    print("3. Copy the 6-character code")
    print("")
    
    code = read_input("Enter code: ").upper()
    
    if len(code) != 6:
        print("❌ Invalid code (should be 6 characters)")
        sys.exit(1)
    
    # Verify the code
    try:
        url = f"{VERIFY_URL}/api/verify?code={code}"
        req = urllib.request.Request(url, method="GET")
        req.add_header("Accept", "application/json")
        
        with urllib.request.urlopen(req, timeout=30) as response:
            data = json.loads(response.read().decode())
            
            if "email" not in data:
                print(f"❌ Invalid response: {data}")
                sys.exit(1)
            
            email = data["email"]
            print("")
            print(f"✅ Verified: {email}")
            print("")
            
            # Output for calling script to capture
            print(f"GOOGLE_EMAIL={email}")
            
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print("❌ Invalid or expired code")
        else:
            print(f"❌ Error: {e.code} {e.reason}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
