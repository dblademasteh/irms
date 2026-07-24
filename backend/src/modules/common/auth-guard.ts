import type { FastifyRequest, FastifyReply, preHandlerHookHandler } from "fastify";
import { verifyToken, TokenPayload } from "./jwt.js";
import { errors } from "./errors.js";

declare module "fastify" {
  interface FastifyRequest {
    user?: TokenPayload;
  }
}

export function parseBearer(header?: string): string | null {
  if (!header) return null;
  const [scheme, token] = header.split(" ");
  if (scheme !== "Bearer" || !token) return null;
  return token;
}

export function authGuard(roles?: string[]): preHandlerHookHandler {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    console.log(`[authGuard] URL: ${request.url}, Auth Header: ${request.headers.authorization}`);
    const token = parseBearer(request.headers.authorization);
    if (!token) throw errors.unauthorized("Missing bearer token");
    let payload: TokenPayload;
    try {
      payload = verifyToken(token);
    } catch {
      throw errors.unauthorized("Invalid or expired token");
    }
    if (roles && !roles.includes(payload.role)) {
      throw errors.forbidden("Insufficient role");
    }
    request.user = payload;
  };
}

export function optionalAuthGuard(): preHandlerHookHandler {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    const token = parseBearer(request.headers.authorization);
    if (!token) return;
    try {
      request.user = verifyToken(token);
    } catch {
      // Ignore invalid tokens for optional auth
    }
  };
}
