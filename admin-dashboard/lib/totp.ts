/**
 * Standard RFC 6238 TOTP (Time-based One-Time Password) implementation
 * Compatible with Google Authenticator, Authy, 1Password, and Microsoft Authenticator.
 */

// Base32 Decoding
export function base32Decode(base32: string): Uint8Array {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  let clean = base32.toUpperCase().replace(/=+$/, "").replace(/[^A-Z2-7]/g, "");
  let bits = "";
  for (let i = 0; i < clean.length; i++) {
    const val = alphabet.indexOf(clean[i]);
    bits += val.toString(2).padStart(5, "0");
  }
  const bytes = new Uint8Array(Math.floor(bits.length / 8));
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(bits.substring(i * 8, (i + 1) * 8), 2);
  }
  return bytes;
}

// Generate random Base32 secret for setup
export function generateBase32Secret(length = 16): string {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  let secret = "";
  const cryptoObj = typeof window !== "undefined" ? window.crypto : null;
  if (cryptoObj && cryptoObj.getRandomValues) {
    const values = new Uint8Array(length);
    cryptoObj.getRandomValues(values);
    for (let i = 0; i < length; i++) {
      secret += alphabet[values[i] % alphabet.length];
    }
  } else {
    for (let i = 0; i < length; i++) {
      secret += alphabet[Math.floor(Math.random() * alphabet.length)];
    }
  }
  return secret;
}

// HMAC-SHA1 calculation using Web Crypto API
export async function generateTOTP(secretBase32: string, timeOffsetSteps = 0): Promise<string> {
  const keyBytes = base32Decode(secretBase32);
  const timeStep = 30; // 30 seconds
  const counter = Math.floor(Date.now() / 1000 / timeStep) + timeOffsetSteps;

  // Convert counter to 8-byte big-endian buffer
  const buffer = new ArrayBuffer(8);
  const dataView = new DataView(buffer);
  dataView.setUint32(4, counter, false); // low 32 bits

  const key = await crypto.subtle.importKey(
    "raw",
    keyBytes.buffer as ArrayBuffer,
    { name: "HMAC", hash: { name: "SHA-1" } },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign("HMAC", key, buffer);
  const sigBytes = new Uint8Array(signature);

  // Dynamic truncation
  const offset = sigBytes[sigBytes.length - 1] & 0xf;
  const binary =
    ((sigBytes[offset] & 0x7f) << 24) |
    ((sigBytes[offset + 1] & 0xff) << 16) |
    ((sigBytes[offset + 2] & 0xff) << 8) |
    (sigBytes[offset + 3] & 0xff);

  const otp = (binary % 1000000).toString().padStart(6, "0");
  return otp;
}

// Verify 6-digit TOTP token with a ±1 time step tolerance window (30s window)
export async function verifyTOTP(token: string, secretBase32: string): Promise<boolean> {
  const cleanToken = token.trim();
  if (cleanToken.length !== 6 || !/^\d{6}$/.test(cleanToken)) {
    return false;
  }

  for (let offset = -1; offset <= 1; offset++) {
    const expected = await generateTOTP(secretBase32, offset);
    if (expected === cleanToken) {
      return true;
    }
  }
  return false;
}
