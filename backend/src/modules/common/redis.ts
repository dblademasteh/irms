import { Redis } from "ioredis";
import { config } from "./config.js";

export const redis = new Redis({
  host: config.redis.host,
  port: config.redis.port,
  password: config.redis.password || undefined,
  lazyConnect: true,
});

export async function connectRedis(): Promise<void> {
  if (redis.status === "ready") return;
  await redis.connect();
}

export async function blacklistToken(
  jti: string,
  ttlSeconds: number
): Promise<void> {
  await redis.set(`bl:${jti}`, "1", "EX", ttlSeconds);
}

export async function isBlacklisted(jti: string): Promise<boolean> {
  const v = await redis.get(`bl:${jti}`);
  return v === "1";
}

export async function trackSession(jti: string, ttlSeconds: number): Promise<void> {
  await redis.set(`session:${jti}`, "1", "EX", ttlSeconds);
}

export async function untrackSession(jti: string): Promise<void> {
  await redis.del(`session:${jti}`);
}

export async function getActiveSessionCount(): Promise<number> {
  const keys = await redis.keys("session:*");
  return keys.length;
}
