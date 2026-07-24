import { FastifyInstance } from "fastify";
import { z } from "zod";
import { authGuard } from "../common/auth-guard.js";
import { errors } from "../common/errors.js";
import * as repo from "./barangays.repo.js";

const createSchema = z.object({
  name: z.string().min(1).max(100),
  psgc_code: z.string().max(20).optional(),
  is_urban: z.boolean().optional(),
  sort_order: z.number().int().optional(),
});

export async function registerBarangayRoutes(app: FastifyInstance) {
  app.get("/barangays", async () => {
    const barangays = await repo.listBarangays();
    return { barangays };
  });

  app.post(
    "/barangays",
    { preHandler: authGuard(["admin"]) },
    async (req, reply) => {
      const body = createSchema.parse(req.body);
      const barangay = await repo.createBarangay(
        body.name,
        body.psgc_code,
        body.is_urban,
        body.sort_order
      );
      return reply.code(201).send({ barangay });
    }
  );

  app.put(
    "/barangays/:id",
    { preHandler: authGuard(["admin"]) },
    async (req) => {
      const { id } = req.params as { id: string };
      const body = createSchema.parse(req.body);
      const barangay = await repo.updateBarangay(
        id,
        body.name,
        body.psgc_code,
        body.is_urban,
        body.sort_order
      );
      if (!barangay) throw errors.notFound("Barangay not found");
      return { barangay };
    }
  );

  app.delete(
    "/barangays/:id",
    { preHandler: authGuard(["admin"]) },
    async (req) => {
      const { id } = req.params as { id: string };
      const deleted = await repo.deleteBarangay(id);
      if (!deleted) throw errors.notFound("Barangay not found");
      return { ok: true };
    }
  );
}
