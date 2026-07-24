import { FastifyInstance } from "fastify";
import { z } from "zod";
import { authGuard } from "../common/auth-guard.js";
import { errors } from "../common/errors.js";
import * as repo from "./categories.repo.js";

const categorySchema = z.object({
  name: z.string().min(1).max(100),
  icon: z.string().min(1).max(60),
  color: z.string().min(1).max(20),
  sort_order: z.number().int().min(0).default(0),
});

export async function registerCategoriesRoutes(app: FastifyInstance) {
  app.get("/contact-categories", async (req, reply) => {
    const categories = await repo.listCategories();
    return { categories };
  });

  app.post("/contact-categories", { preHandler: authGuard(["admin"]) }, async (req, reply) => {
    const body = categorySchema.parse(req.body);
    const category = await repo.createCategory(body.name, body.icon, body.color, body.sort_order);
    return reply.code(201).send({ category });
  });

  app.put("/contact-categories/:id", { preHandler: authGuard(["admin"]) }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const body = categorySchema.parse(req.body);
    const category = await repo.updateCategory(id, body.name, body.icon, body.color, body.sort_order);
    if (!category) throw errors.notFound("Category not found");
    return { category };
  });

  app.delete("/contact-categories/:id", { preHandler: authGuard(["admin"]) }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const success = await repo.deleteCategory(id);
    if (!success) throw errors.notFound("Category not found");
    return reply.code(204).send();
  });
}
