import crypto from "crypto";
import { redis } from "../common/redis.js";

const OTP_TTL = 300; // 5 minutes
const OTP_LENGTH = 6;
const OTP_PREFIX = "otp:";

export function generateOtp(): string {
  return crypto.randomInt(100000, 999999).toString();
}

export async function storeOtp(phone: string, otp: string): Promise<void> {
  const key = `${OTP_PREFIX}${phone}`;
  await redis.set(key, otp, "EX", OTP_TTL);
}

export async function verifyOtp(phone: string, code: string): Promise<boolean> {
  const key = `${OTP_PREFIX}${phone}`;
  const stored = await redis.get(key);
  if (!stored) return false;
  if (stored !== code.trim()) return false;
  await redis.del(key);
  return true;
}
