import crypto from "crypto";
import jwt from "jsonwebtoken";
import { config } from "./config.js";

export interface TokenPayload {
  userId: string;
  role: string;
}

export function signAccessToken(payload: TokenPayload): string {
  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.accessTtl,
  });
}

export function signRefreshToken(payload: TokenPayload): { token: string; jti: string } {
  const jti = crypto.randomUUID();
  const token = jwt.sign({ ...payload, jti }, config.jwt.secret, {
    expiresIn: config.jwt.refreshTtl,
  });
  return { token, jti };
}

export function refreshJti(token: string): string | undefined {
  try {
    const decoded = jwt.decode(token) as { jti?: string } | null;
    return decoded?.jti;
  } catch {
    return undefined;
  }
}

export function verifyToken(token: string): TokenPayload {
  return jwt.verify(token, config.jwt.secret) as TokenPayload;
}
