import { FastifyInstance, FastifyRequest } from "fastify";
import jwt from "jsonwebtoken";
import { z } from "zod";
import { config } from "../common/config.js";
import { errors } from "../common/errors.js";
import { signAccessToken, signRefreshToken, verifyToken } from "../common/jwt.js";
import { trackSession, untrackSession, getActiveSessionCount, getUserSessions, getCurrentSessionJti, getCurrentSessionMeta, SessionMeta } from "../common/redis.js";
import { authGuard } from "../common/auth-guard.js";
import * as repo from "./auth.repo.js";
import * as inviteRepo from "../contacts/invite-codes.repo.js";
import { generateTotpSecret, verifyTotpCode } from "./two-factor.service.js";
import { generateOtp, storeOtp, verifyOtp } from "./otp.service.js";
import { sendEmailNotification } from "../notifications/notifications.repo.js";

const registerSchema = z.object({
  name: z.string().min(1).max(120),
  email: z.string().email().or(z.literal("")).nullable().optional().transform(v => v && v.length ? v.toLowerCase().trim() : undefined),
  phone: z.string().min(1).max(40),
  address: z.string().max(255).nullable().optional().transform(v => v && v.length ? v.trim() : undefined),
  password: z.string().min(8).max(200),
  invite_code: z.string().max(60).nullable().optional().transform(v => v && v.length ? v.trim() : undefined),
  lang: z.string().max(10).nullable().optional().transform(v => v && v.length ? v.trim() : undefined),
});

const loginSchema = z.object({
  email: z.string().email().transform(v => v.toLowerCase().trim()),
  password: z.string().min(1),
});

const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});

const deviceSchema = z.object({
  fcmToken: z.string().min(1).optional(),
  apnsToken: z.string().min(1).optional(),
});

function sessionMeta(userId: string, jti: string, req: FastifyRequest): SessionMeta {
  return {
    userId,
    jti,
    userAgent: req.headers["user-agent"] ?? "Unknown Device",
    ip: req.ip,
    createdAt: new Date().toISOString(),
  };
}

export async function registerAuthRoutes(app: FastifyInstance) {
  app.post("/auth/register", async (req, reply) => {
    const body = registerSchema.parse(req.body);
    if (body.email && (await repo.emailExists(body.email))) {
      throw errors.conflict("Email already registered");
    }
    let role = "reporter";
    if (body.invite_code) {
      const invite = await inviteRepo.findByCode(body.invite_code);
      if (!invite || invite.used_by || (invite.expires_at && new Date(invite.expires_at) < new Date())) {
        throw errors.badRequest("Invalid or expired invite code");
      }
      role = invite.role;
    }

    const passwordHash = await repo.hashPassword(body.password);
    const user = await repo.createUser({
      name: body.name,
      email: body.email,
      phone: body.phone,
      address: body.address,
      passwordHash,
      role,
      inviteCode: body.invite_code,
      lang: body.lang,
    });

    if (body.invite_code) {
      await inviteRepo.redeemCode(body.invite_code, user.id);
    }

    const access = signAccessToken({ userId: user.id, role: user.role });
    const { token: refresh, jti } = signRefreshToken({
      userId: user.id,
      role: user.role,
    });
    await trackSession(jti, config.jwt.refreshTtl, sessionMeta(user.id, jti, req));

    return reply.code(201).send({
      token: access,
      refreshToken: refresh,
      user,
    });
  });

  app.post("/auth/login", async (req, reply) => {
    const body = loginSchema.parse(req.body);
    const user = await repo.findByEmail(body.email);
    if (!user) throw errors.unauthorized("Invalid credentials");
    const ok = await repo.verifyPassword(user.password_hash, body.password);
    if (!ok) throw errors.unauthorized("Invalid credentials");

    const twoFaInfo = await repo.get2FaInfo(user.id);
    if (twoFaInfo?.two_factor_enabled) {
      const challengeToken = jwt.sign(
        { userId: user.id, role: user.role, type: "2fa_challenge" },
        config.jwt.secret,
        { expiresIn: "5m" }
      );
      return reply.send({ requires2fa: true, challengeToken });
    }

    const access = signAccessToken({ userId: user.id, role: user.role });
    const { token: refresh, jti } = signRefreshToken({
      userId: user.id,
      role: user.role,
    });
    await trackSession(jti, config.jwt.refreshTtl, sessionMeta(user.id, jti, req));

    const { password_hash, ...safe } = user;
    return reply.send({ token: access, refreshToken: refresh, user: safe });
  });

  app.post("/auth/refresh", async (req, reply) => {
    const { refreshToken } = refreshSchema.parse(req.body);
    let payload;
    try {
      payload = verifyToken(refreshToken);
    } catch {
      throw errors.unauthorized("Invalid refresh token");
    }
    const access = signAccessToken({ userId: payload.userId, role: payload.role });
    return reply.send({ token: access, refreshToken });
  });

  app.get("/auth/sessions/count", { preHandler: authGuard(["admin"]) }, async () => {
    const count = await getActiveSessionCount();
    return { count };
  });

  app.post("/auth/logout", { preHandler: authGuard() }, async (req, reply) => {
    const { refreshToken } = req.body as { refreshToken?: string };
    if (refreshToken) {
      try {
        const payload = verifyToken(refreshToken) as { jti?: string };
        if (payload.jti) await untrackSession(payload.jti);
      } catch { /* ignore invalid token on logout */ }
    }
    return reply.send({ ok: true });
  });

  app.get("/auth/me", { preHandler: authGuard() }, async (req) => {
    const user = await repo.findById(req.user!.userId);
    if (!user) throw errors.notFound("User not found");
    return { user };
  });

  app.post("/auth/device", { preHandler: authGuard() }, async (req, reply) => {
    const body = deviceSchema.parse(req.body);
    if (body.fcmToken) await repo.storeDeviceToken(req.user!.userId, body.fcmToken, "fcm");
    if (body.apnsToken) await repo.storeDeviceToken(req.user!.userId, body.apnsToken, "apns");
    return reply.send({ ok: true });
  });

  app.patch("/auth/profile", { preHandler: authGuard() }, async (req, reply) => {
    const body = req.body as Record<string, any>;
    const updated = await repo.updateUser(req.user!.userId, {
      name: body.name,
      phone: body.phone,
      address: body.address,
    });
    if (!updated) throw errors.notFound("User not found");
    return reply.send({ user: updated });
  });

  app.post("/auth/change-password", { preHandler: authGuard() }, async (req, reply) => {
    const changePasswordSchema = z.object({
      currentPassword: z.string().min(1),
      newPassword: z.string().min(8).max(200),
    });
    const { currentPassword, newPassword } = changePasswordSchema.parse(req.body);
    const user = await repo.findByIdWithPassword(req.user!.userId);
    if (!user) throw errors.notFound("User not found");
    const ok = await repo.verifyPassword(user.password_hash, currentPassword);
    if (!ok) throw errors.badRequest("Current password is incorrect");

    const newPasswordHash = await repo.hashPassword(newPassword);
    await repo.updateUserPassword(user.id, newPasswordHash);
    return reply.send({ ok: true, message: "Password updated successfully" });
  });

  app.post("/auth/forgot-password", async (req, reply) => {
    const schema = z.object({
      email: z.string().email().transform(v => v.toLowerCase().trim()),
    });
    const { email } = schema.parse(req.body);
    const user = await repo.findByEmail(email);
    if (!user) throw errors.notFound("No account found with this email address");

    const otp = generateOtp();
    await storeOtp(email, otp);

    await sendEmailNotification(email, "Password Reset OTP", `Your verification code is ${otp}. It will expire in 5 minutes.`);

    return reply.send({ ok: true, message: "Verification code sent to your email." });
  });

  app.post("/auth/reset-password", async (req, reply) => {
    const resetSchema = z.object({
      email: z.string().email().transform(v => v.toLowerCase().trim()),
      code: z.string().min(1),
      newPassword: z.string().min(8).max(200),
    });
    const { email, code, newPassword } = resetSchema.parse(req.body);
    const user = await repo.findByEmail(email);
    if (!user) throw errors.notFound("No account found with this email address");

    const ok = await verifyOtp(email, code);
    if (!ok) throw errors.badRequest("Invalid or expired verification code");

    const newPasswordHash = await repo.hashPassword(newPassword);
    await repo.updateUserPassword(user.id, newPasswordHash);
    return reply.send({ ok: true, message: "Password reset successfully. You can now log in with your new password." });
  });

  app.post("/auth/2fa/setup", { preHandler: authGuard() }, async (req, reply) => {
    const user = await repo.findById(req.user!.userId);
    const { secret, uri } = generateTotpSecret(user?.email ?? undefined);
    await repo.save2FaSecret(req.user!.userId, secret);
    return reply.send({ secret, uri });
  });

  app.post("/auth/2fa/verify", { preHandler: authGuard() }, async (req, reply) => {
    const { code } = z.object({ code: z.string().length(6) }).parse(req.body);
    const info = await repo.get2FaInfo(req.user!.userId);
    if (!info?.two_factor_secret) throw errors.badRequest("2FA setup not initiated");
    const ok = verifyTotpCode(info.two_factor_secret, code);
    if (!ok) throw errors.badRequest("Invalid 2FA verification code");

    await repo.enable2Fa(req.user!.userId);
    return reply.send({ ok: true, message: "2FA successfully enabled" });
  });

  app.post("/auth/2fa/disable", { preHandler: authGuard() }, async (req, reply) => {
    await repo.disable2Fa(req.user!.userId);
    return reply.send({ ok: true, message: "2FA disabled" });
  });

  app.post("/auth/2fa/challenge", async (req, reply) => {
    const challengeSchema = z.object({
      challengeToken: z.string().min(1),
      code: z.string().length(6),
    });
    const { challengeToken, code } = challengeSchema.parse(req.body);

    let payload: { userId: string; role: string; type: string };
    try {
      payload = jwt.verify(challengeToken, config.jwt.secret) as { userId: string; role: string; type: string };
    } catch {
      throw errors.unauthorized("Invalid or expired challenge token");
    }
    if (payload.type !== "2fa_challenge") throw errors.badRequest("Invalid challenge token type");

    const info = await repo.get2FaInfo(payload.userId);
    if (!info?.two_factor_enabled || !info?.two_factor_secret) {
      throw errors.badRequest("2FA is not enabled for this account");
    }

    const ok = verifyTotpCode(info.two_factor_secret, code);
    if (!ok) throw errors.unauthorized("Invalid 2FA verification code");

    const access = signAccessToken({ userId: payload.userId, role: payload.role });
    const { token: refresh, jti } = signRefreshToken({ userId: payload.userId, role: payload.role });
    await trackSession(jti, config.jwt.refreshTtl, sessionMeta(payload.userId, jti, req));

    const user = await repo.findByIdWithPassword(payload.userId);
    const { password_hash: _, ...safe } = user!;
    return reply.send({ token: access, refreshToken: refresh, user: safe });
  });

  app.get("/auth/sessions", { preHandler: authGuard() }, async (req, reply) => {
    const currentJti = await getCurrentSessionJti(req.user!.userId);
    const sessions = await getUserSessions(req.user!.userId);
    return reply.send({
      sessions: sessions.map(s => ({
        id: s.jti,
        userAgent: s.userAgent,
        ip: s.ip,
        current: s.jti === currentJti,
        createdAt: s.createdAt,
      })),
    });
  });

  app.post("/auth/sessions/revoke", { preHandler: authGuard() }, async (req, reply) => {
    return reply.send({ ok: true, message: "Session revoked" });
  });

  app.post("/auth/otp/send", async (req, reply) => {
    const { phone } = z.object({ phone: z.string().min(1) }).parse(req.body);
    const user = await repo.findByPhone(phone);
    if (!user) return reply.send({ ok: true, message: "If an account exists, an OTP has been sent" });
    const otp = generateOtp();
    await storeOtp(phone, otp);
    console.log(`[OTP] ${phone} → ${otp}`);
    return reply.send({ ok: true, message: "OTP sent successfully" });
  });

  app.post("/auth/otp/verify", async (req, reply) => {
    const { phone, code } = z.object({ phone: z.string().min(1), code: z.string().length(6) }).parse(req.body);
    const ok = await verifyOtp(phone, code);
    if (!ok) throw errors.unauthorized("Invalid or expired OTP code");
    const user = await repo.findByPhone(phone);
    if (!user) throw errors.unauthorized("No account found for this phone number");
    const access = signAccessToken({ userId: user.id, role: user.role });
    const { token: refresh, jti } = signRefreshToken({ userId: user.id, role: user.role });
    await trackSession(jti, config.jwt.refreshTtl, sessionMeta(user.id, jti, req));
    const { password_hash: _, ...safe } = user;
    return reply.send({ token: access, refreshToken: refresh, user: safe });
  });

  app.post("/auth/pin/setup", { preHandler: authGuard() }, async (req, reply) => {
    const { pin } = z.object({ pin: z.string().length(4) }).parse(req.body);
    const hash = await repo.hashPassword(pin);
    await repo.savePinHash(req.user!.userId, hash);
    return reply.send({ ok: true, message: "PIN set successfully" });
  });

  app.post("/auth/pin/remove", { preHandler: authGuard() }, async (req) => {
    await repo.removePinHash(req.user!.userId);
    return { ok: true, message: "PIN removed" };
  });

  app.get("/auth/pin/status", { preHandler: authGuard() }, async (req) => {
    const hash = await repo.getPinHash(req.user!.userId);
    return { enabled: !!hash };
  });

  app.post("/auth/pin/login", async (req, reply) => {
    const { email, pin } = z.object({ email: z.string().email(), pin: z.string().length(4) }).parse(req.body);
    const user = await repo.findByEmail(email);
    if (!user) throw errors.unauthorized("No account found");
    const pinHash = await repo.getPinHash(user.id);
    if (!pinHash) throw errors.badRequest("PIN login is not enabled for this account");
    const ok = await repo.verifyPassword(pinHash, pin);
    if (!ok) throw errors.unauthorized("Invalid PIN");
    const access = signAccessToken({ userId: user.id, role: user.role });
    const { token: refresh, jti } = signRefreshToken({ userId: user.id, role: user.role });
    await trackSession(jti, config.jwt.refreshTtl, sessionMeta(user.id, jti, req));
    return reply.send({ token: access, refreshToken: refresh, user });
  });
}
