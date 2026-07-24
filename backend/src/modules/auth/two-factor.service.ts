import crypto from "crypto";

export function generateTotpSecret(): { secret: string; uri: string } {
  const secret = crypto.randomBytes(20).toString("hex").toUpperCase();
  const uri = `otpauth://totp/IRMS:${secret}?secret=${secret}&issuer=IRMS`;
  return { secret, uri };
}

export function verifyTotpCode(secret: string, code: string): boolean {
  // Simple HMAC-SHA1 TOTP verification window (+- 1 step)
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
  const hmac = crypto.createHmac("sha1", Buffer.from(secret, "hex"));
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
