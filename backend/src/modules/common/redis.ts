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
