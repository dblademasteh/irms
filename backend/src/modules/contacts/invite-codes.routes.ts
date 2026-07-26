import { FastifyInstance } from "fastify";
import { z } from "zod";
import { authGuard } from "../common/auth-guard.js";
import { errors } from "../common/errors.js";
import * as repo from "./invite-codes.repo.js";
import crypto from "crypto";

function generateCode(): string {
  return "IRMS-" + crypto.randomBytes(4).toString("hex").toUpperCase();
}

const createCodeSchema = z.object({
  role: z.enum(["dispatcher", "admin"]).optional(),
  expires_at: z.string().datetime().nullable().optional(),
});

export async function registerInviteCodeRoutes(app: FastifyInstance) {
  app.get("/invite-codes", { preHandler: authGuard(["admin"]) }, async (req, reply) => {
    const codes = await repo.listCodes();
    return { codes };
  });

  app.post("/invite-codes", { preHandler: authGuard() }, async (req, reply) => {
    const body = createCodeSchema.parse(req.body);
    const userId = req.user!.userId;
    const code = generateCode();
    const role = (body.role && req.user!.role === "admin") ? body.role : "reporter";
    const expiresAt = body.expires_at ?? null;
    const created = await repo.createCode(code, role, userId, expiresAt);
    const baseUrl = `${req.protocol}://${req.headers.host ?? "irms.local"}`;
    const shareUrl = `${baseUrl}/register?code=${code}`;
    return reply.code(201).send({ code: created, shareUrl });
  });

  app.delete("/invite-codes/:id", { preHandler: authGuard(["admin"]) }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const success = await repo.deleteCode(id);
    if (!success) throw errors.notFound("Code not found or already used");
    return reply.code(204).send();
  });
}
