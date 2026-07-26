import crypto from "crypto";

const B32_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
const B32_PAD_CHARS = 8;

function intToBase32(n: number): string {
  let result = "";
  for (let i = 7; i >= 0; i--) {
    result += B32_ALPHABET[(n >> (i * 5)) & 0x1f];
  }
  return result;
}

function base32Encode(buf: Buffer): string {
  let bits = 0;
  let value = 0;
  let output = "";
  for (const byte of buf) {
    bits += 8;
    value = (value << 8) | byte;
    while (bits >= 5) {
      output += B32_ALPHABET[(value >> (bits - 5)) & 0x1f];
      bits -= 5;
    }
  }
  if (bits > 0) {
    output += B32_ALPHABET[(value << (5 - bits)) & 0x1f];
  }
  const padLen = (B32_PAD_CHARS - (output.length % B32_PAD_CHARS)) % B32_PAD_CHARS;
  return output + "=".repeat(padLen);
}

function base32Decode(str: string): Buffer {
  const clean = str.replace(/[\s=]+/g, "").toUpperCase();
  if (!/^[A-Z2-7]+$/.test(clean)) {
    throw new Error("Invalid base32 characters");
  }
  let bits = 0;
  let value = 0;
  const out: number[] = [];
  for (const ch of clean) {
    const v = B32_ALPHABET.indexOf(ch);
    if (v < 0) throw new Error("Invalid base32 character: " + ch);
    bits += 5;
    value = (value << 5) | v;
    if (bits >= 8) {
      out.push((value >> (bits - 8)) & 0xff);
      bits -= 8;
    }
  }
  return Buffer.from(out);
}

export function generateTotpSecret(): { secret: string; uri: string } {
  const rawSecret = crypto.randomBytes(20);
  const secret = base32Encode(rawSecret);
  const label = encodeURIComponent("IRMS");
  const issuer = encodeURIComponent("IRMS");
  const uri = `otpauth://totp/${label}:${label}?secret=${secret}&issuer=${issuer}&algorithm=SHA1&digits=6&period=30`;
  return { secret, uri };
}

export function verifyTotpCode(secret: string, code: string): boolean {
  const timeStep = Math.floor(Date.now() / 1000 / 30);
  for (let i = -1; i <= 1; i++) {
    const calculated = generateTotpForStep(secret, timeStep + i);
    if (calculated === code.trim()) return true;
  }
  return false;
}

function generateTotpForStep(secret: string, step: number): string {
  const buf = Buffer.alloc(8);
  buf.writeBigInt64BE(BigInt(step));
  const key = base32Decode(secret);
  const hmac = crypto.createHmac("sha1", key);
  hmac.update(buf);
  const digest = hmac.digest();
  const offset = digest[digest.length - 1] & 0xf;
  const codeInt =
    ((digest[offset] & 0x7f) << 24) |
    ((digest[offset + 1] & 0xff) << 16) |
    ((digest[offset + 2] & 0xff) << 8) |
    (digest[offset + 3] & 0xff);
  const code = (codeInt % 1000000).toString().padStart(6, "0");
  return code;
}