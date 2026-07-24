import { FastifyInstance } from "fastify";
import { authGuard } from "../common/auth-guard.js";
import { z } from "zod";
import * as repo from "./notifications.repo.js";

export async function registerNotificationRoutes(app: FastifyInstance) {
  app.get(
    "/notifications",
    { preHandler: authGuard() },
    async (req) => {
      const unreadOnly =
        typeof req.query === "object" &&
        (req.query as any).unreadOnly === "true";
      const notifications = await repo.listForUser(req.user!.userId, unreadOnly);
      return { notifications };
    }
  );

  app.post(
    "/notifications/:id/read",
    { preHandler: authGuard() },
    async (req, reply) => {
      const { id } = z.object({ id: z.string().uuid() }).parse(req.params);
      await repo.markRead(id, req.user!.userId);
      return reply.send({ ok: true });
    }
  );
}
