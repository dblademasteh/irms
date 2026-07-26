import crypto from "crypto";
import { base32 } from "@scure/base";

export function generateTotpSecret(): { secret: string; uri: string } {
  const raw = crypto.randomBytes(20);
  const secret = base32.encode(raw);
  const label = encodeURIComponent("IRMS");
  const issuer = encodeURIComponent("IRMS");
  const uri = `otpauth://totp/${label}?secret=${secret}&issuer=${issuer}&algorithm=SHA1&digits=6&period=30`;
  return { secret, uri };
}

export function verifyTotpCode(secret: string, code: string): boolean {
  const timeStep = Math.floor(Date.now() / 1000 / 30);
  for (let i = -1; i <= 1; i++) {
    if (generateTotpForStep(secret, timeStep + i) === code.trim()) return true;
  }
  return false;
}

function generateTotpForStep(secret: string, step: number): string {
  const key = base32.decode(secret);
  const counterBuf = new ArrayBuffer(8);
  const view = new DataView(counterBuf);
  view.setBigUint64(0, BigInt(step), false);
  const counter = new Uint8Array(counterBuf);
  const hmac = crypto.createHmac("sha1", Buffer.from(key));
  hmac.update(Buffer.from(counter));
  const digest = hmac.digest();
  const offset = digest[digest.length - 1] & 0xf;
  const codeInt =
    ((digest[offset] & 0x7f) << 24) |
    ((digest[offset + 1] & 0xff) << 16) |
    ((digest[offset + 2] & 0xff) << 8) |
    (digest[offset + 3] & 0xff);
  return (codeInt % 1_000_000).toString().padStart(6, "0");
}