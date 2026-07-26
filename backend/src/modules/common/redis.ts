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

export async function blacklistToken(jti: string, ttlSeconds: number): Promise<void> {
  await redis.set(`bl:${jti}`, "1", "EX", ttlSeconds);
}

export async function isBlacklisted(jti: string): Promise<boolean> {
  const v = await redis.get(`bl:${jti}`);
  return v === "1";
}

export interface SessionMeta {
  userId: string;
  jti: string;
  userAgent: string;
  ip: string;
  createdAt: string;
}

export async function trackSession(
  jti: string,
  ttlSeconds: number,
  meta: SessionMeta
): Promise<void> {
  await redis.set(`session:${jti}`, JSON.stringify(meta), "EX", ttlSeconds);
  await redis.sadd(`user_sessions:${meta.userId}`, `session:${jti}`);
  await redis.expire(`user_sessions:${meta.userId}`, ttlSeconds);
  await redis.set(`current_session:${meta.userId}`, jti, "EX", ttlSeconds);
}

export async function untrackSession(jti: string): Promise<void> {
  const raw = await redis.get(`session:${jti}`);
  if (raw) {
    try {
      const meta: SessionMeta = JSON.parse(raw);
      await redis.srem(`user_sessions:${meta.userId}`, `session:${jti}`);
      const currentJti = await redis.get(`current_session:${meta.userId}`);
      if (currentJti === jti) await redis.del(`current_session:${meta.userId}`);
    } catch { /* ignore */ }
  }
  await redis.del(`session:${jti}`);
}

export async function getActiveSessionCount(): Promise<number> {
  const keys = await redis.keys("session:*");
  return keys.length;
}

export async function getUserSessions(userId: string): Promise<SessionMeta[]> {
  const sessionKeys = await redis.smembers(`user_sessions:${userId}`);
  if (!sessionKeys.length) return [];
  const sessions: SessionMeta[] = [];
  for (const key of sessionKeys) {
    const raw = await redis.get(key);
    if (!raw) {
      await redis.srem(`user_sessions:${userId}`, key);
      continue;
    }
    try {
      const meta: SessionMeta = JSON.parse(raw);
      sessions.push({ ...meta, jti: key.replace("session:", "") });
    } catch { /* ignore corrupt entries */ }
  }
  return sessions;
}

export async function getCurrentSessionJti(userId: string): Promise<string | null> {
  return redis.get(`current_session:${userId}`);
}

export async function getCurrentSessionMeta(jti: string): Promise<SessionMeta | null> {
  const raw = await redis.get(`session:${jti}`);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as SessionMeta;
  } catch {
    return null;
  }
}