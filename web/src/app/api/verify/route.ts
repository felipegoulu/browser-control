import { NextRequest, NextResponse } from 'next/server';

// In-memory store (for production, use Redis or a database)
const verificationCodes: Map<string, { email: string; expiresAt: number }> = new Map();

// Clean up expired codes periodically
function cleanupExpiredCodes() {
  const now = Date.now();
  for (const [code, data] of verificationCodes.entries()) {
    if (data.expiresAt < now) {
      verificationCodes.delete(code);
    }
  }
}

// Generate a random 6-character code
function generateCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed similar chars (0,O,1,I)
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

// POST: Generate a new code for an email
export async function POST(request: NextRequest) {
  try {
    const { email } = await request.json();
    
    if (!email) {
      return NextResponse.json({ error: 'Email required' }, { status: 400 });
    }
    
    cleanupExpiredCodes();
    
    // Generate unique code
    let code: string;
    do {
      code = generateCode();
    } while (verificationCodes.has(code));
    
    // Store with 5 minute expiration
    verificationCodes.set(code, {
      email,
      expiresAt: Date.now() + 5 * 60 * 1000,
    });
    
    return NextResponse.json({ code });
  } catch (error) {
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  }
}

// GET: Look up email by code
export async function GET(request: NextRequest) {
  const code = request.nextUrl.searchParams.get('code');
  
  if (!code) {
    return NextResponse.json({ error: 'Code required' }, { status: 400 });
  }
  
  cleanupExpiredCodes();
  
  const data = verificationCodes.get(code.toUpperCase());
  
  if (!data) {
    return NextResponse.json({ error: 'Invalid or expired code' }, { status: 404 });
  }
  
  // Delete code after successful lookup (one-time use)
  verificationCodes.delete(code.toUpperCase());
  
  return NextResponse.json({ email: data.email });
}
