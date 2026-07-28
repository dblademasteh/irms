import { FastifyInstance } from "fastify";
import { z } from "zod";
import { authGuard, optionalAuthGuard } from "../common/auth-guard.js";
import { errors } from "../common/errors.js";
import * as repo from "./admin.repo.js";
import { emitBroadcast } from "../realtime/realtime.js";
import { hashPassword, updateUserPassword } from "../auth/auth.repo.js";
import { generateAnnouncement, getAvailableTemplates } from "./broadcast-generator.service.js";
import { fetchNationalAdvisories } from "./advisories.service.js";

const updateRoleSchema = z.object({
  role: z.enum(["reporter", "dispatcher", "admin"]),
});

const broadcastRateLimit = new Map<string, number>();
const BROADCAST_COOLDOWN_MS = 30_000;

export async function registerAdminRoutes(app: FastifyInstance) {
  app.get(
    "/admin/users",
    { preHandler: authGuard(["admin"]) },
    async () => {
      const users = await repo.getAllUsers();
      return { users };
    }
  );

  app.put(
    "/admin/users/:id/role",
    { preHandler: authGuard(["admin"]) },
    async (req, reply) => {
      const { id } = req.params as { id: string };
      const { role } = updateRoleSchema.parse(req.body);
      const user = await repo.updateUserRole(id, role);
      if (!user) throw errors.notFound("User not found");
      return { user };
    }
  );

  app.post(
    "/admin/users/:id/reset-password",
    { preHandler: authGuard(["admin"]) },
    async (req, reply) => {
      const { id } = req.params as { id: string };
      const { newPassword } = z.object({ newPassword: z.string().min(8).max(200) }).parse(req.body);
      const user = await repo.getUserById(id);
      if (!user) throw errors.notFound("User not found");
      const passwordHash = await hashPassword(newPassword);
      await updateUserPassword(id, passwordHash);
      return { ok: true, message: `Password reset successfully for ${user.name}` };
    }
  );

  app.get(
    "/admin/analytics",
    { preHandler: authGuard(["admin"]) },
    async () => {
      const analytics = await repo.getAnalytics();
      return { analytics };
    }
  );

  app.get(
    "/dispatch-units",
    { preHandler: authGuard(["admin", "dispatcher"]) },
    async () => {
      const units = await repo.getDispatchUnits();
      return { units };
    }
  );

  app.get(
    "/dispatch-units/available",
    { preHandler: authGuard(["admin", "dispatcher"]) },
    async () => {
      const units = await repo.getAvailableDispatchUnits();
      return { units };
    }
  );

  app.post(
    "/dispatch-units",
    { preHandler: authGuard(["admin"]) },
    async (req, reply) => {
      const body = z.object({
        name: z.string().min(1).max(100),
        unit_type: z.enum(["fire", "medical", "police"]),
      }).parse(req.body);
      const unit = await repo.createDispatchUnit({ name: body.name, unitType: body.unit_type });
      return reply.code(201).send({ unit });
    }
  );

  app.patch(
    "/dispatch-units/:id/status",
    { preHandler: authGuard(["admin"]) },
    async (req) => {
      const { id } = req.params as { id: string };
      const body = z.object({ status: z.enum(["available", "dispatched", "maintenance"]) }).parse(req.body);
      const unit = await repo.updateDispatchUnitStatus(id, body.status);
      if (!unit) throw errors.notFound("Unit not found");
      return { unit };
    }
  );

  app.delete(
    "/dispatch-units/:id",
    { preHandler: authGuard(["admin"]) },
    async (req) => {
      const { id } = req.params as { id: string };
      await repo.deleteDispatchUnit(id);
      return { ok: true };
    }
  );

  const getBroadcastsHandler = async (req: any) => {
    const role = req.user?.role ?? "reporter";
    const broadcasts = await repo.getBroadcasts();
    if (role === "admin") return { broadcasts };
    if (role === "dispatcher") {
      return {
        broadcasts: broadcasts.filter(
          (b) => !b.target_role || b.target_role === "all" || b.target_role === "dispatchers"
        ),
      };
    }
    return {
      broadcasts: broadcasts.filter(
        (b) => !b.target_role || b.target_role === "all" || b.target_role === "reporters"
      ),
    };
  };

  app.get("/admin/broadcasts", { preHandler: optionalAuthGuard() }, getBroadcastsHandler);
  app.get("/broadcasts", { preHandler: optionalAuthGuard() }, getBroadcastsHandler);

  app.get(
    "/admin/broadcast-templates",
    { preHandler: authGuard(["admin", "dispatcher"]) },
    async () => {
      const templates = getAvailableTemplates();
      return { templates };
    }
  );

  app.post(
    "/admin/broadcast/generate",
    { preHandler: authGuard(["admin", "dispatcher"]) },
    async (req) => {
      const body = z.object({
        template: z.string().min(1),
        details: z.string().max(500).optional(),
        barangay: z.string().max(200).optional(),
      }).parse(req.body);

      const result = await generateAnnouncement({
        template: body.template as any,
        details: body.details,
        barangay: body.barangay,
      });

      return { message: result.message, category: result.category };
    }
  );

  app.post(
    "/admin/broadcast",
    { preHandler: authGuard(["admin", "dispatcher"]) },
    async (req, reply) => {
      const body = z.object({
        message: z.string().min(1).max(500),
        category: z.enum(["emergency", "system", "safety", "traffic", "earthquake", "flood", "tsunami", "weather"]).optional(),
        target_role: z.enum(["all", "dispatchers", "reporters"]).optional(),
      }).parse(req.body);

      const now = Date.now();
      const lastSent = broadcastRateLimit.get(req.user!.userId) ?? 0;
      if (now - lastSent < BROADCAST_COOLDOWN_MS) {
        const waitSec = Math.ceil((BROADCAST_COOLDOWN_MS - (now - lastSent)) / 1000);
        throw errors.badRequest(`Please wait ${waitSec}s before sending another broadcast`);
      }
      broadcastRateLimit.set(req.user!.userId, now);

      const user = await repo.getUserById(req.user!.userId);
      const authorName = user?.name ?? (req.user!.role === "dispatcher" ? "Dispatcher Control" : "System Admin");

      const broadcast = await repo.createBroadcast({
        authorId: req.user!.userId,
        authorName,
        message: body.message,
        category: body.category,
        targetRole: body.target_role,
      });

      emitBroadcast(broadcast.id, body.message, authorName, body.target_role ?? "all", body.category ?? "emergency");
      return { ok: true, broadcast };
    }
  );

  app.get("/national-advisories", async () => {
    const advisories = await fetchNationalAdvisories();
    return { advisories };
  });
}
