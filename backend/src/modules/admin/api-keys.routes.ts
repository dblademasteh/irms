import { FastifyInstance } from "fastify";
import { z } from "zod";
import { authGuard } from "../common/auth-guard.js";
import { errors } from "../common/errors.js";
import * as repo from "./api-keys.repo.js";

export async function registerApiKeyRoutes(app: FastifyInstance) {
  app.get("/admin/api-keys", { preHandler: authGuard(["admin"]) }, async (req, reply) => {
    const keys = await repo.listApiKeys();
    return reply.send({ keys });
  });

  app.post("/admin/api-keys", { preHandler: authGuard(["admin"]) }, async (req, reply) => {
    const schema = z.object({
      name: z.string().min(1).max(100),
    });
    const body = schema.parse(req.body);
    const result = await repo.createApiKey(body.name, req.user!.userId);
    return reply.code(201).send(result);
  });

  app.delete("/admin/api-keys/:id", { preHandler: authGuard(["admin"]) }, async (req, reply) => {
    const { id } = req.params as { id: string };
    await repo.revokeApiKey(id);
    return reply.send({ ok: true });
  });
}
