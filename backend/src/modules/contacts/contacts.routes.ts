import { FastifyInstance } from "fastify";
import { z } from "zod";
import { authGuard } from "../common/auth-guard.js";
import { errors } from "../common/errors.js";
import * as repo from "./contacts.repo.js";

const contactSchema = z.object({
  name: z.string().min(1).max(100),
  phone: z.string().min(1).max(30),
  department: z.string().min(1).max(100),
  category_id: z.string().uuid(),
});

export async function registerContactsRoutes(app: FastifyInstance) {
  // Public: anyone can view emergency contacts (no auth required)
  app.get("/contacts", async (req, reply) => {
    const contacts = await repo.listContacts();
    return { contacts };
  });

  // Only admins can create, update, or delete contacts
  app.post("/contacts", { preHandler: authGuard(["admin"]) }, async (req, reply) => {
    const body = contactSchema.parse(req.body);
    const contact = await repo.createContact(body.name, body.phone, body.department, body.category_id);
    return reply.code(201).send({ contact });
  });

  app.put("/contacts/:id", { preHandler: authGuard(["admin"]) }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const body = contactSchema.parse(req.body);
    const contact = await repo.updateContact(id, body.name, body.phone, body.department, body.category_id);
    if (!contact) throw errors.notFound("Contact not found");
    return { contact };
  });

  app.delete("/contacts/:id", { preHandler: authGuard(["admin"]) }, async (req, reply) => {
    const { id } = req.params as { id: string };
    const success = await repo.deleteContact(id);
    if (!success) throw errors.notFound("Contact not found");
    return reply.code(204).send();
  });

  const batchImportSchema = z.object({
    contacts: z.array(z.object({
      name: z.string().min(1),
      phone: z.string().min(1),
      department: z.string().min(1),
      category: z.string().min(1),
    })),
  });

  app.post("/contacts/batch", { preHandler: authGuard(["admin"]) }, async (req, reply) => {
    const { contacts } = batchImportSchema.parse(req.body);

    const { rows: cats } = await import("../../db/index.js").then(m =>
      m.query<{ id: string; name: string }>(`SELECT id, name FROM contact_categories`)
    );
    const catMap = new Map(cats.map(c => [c.name.toLowerCase(), c.id]));

    const resolved = contacts.map(c => ({
      name: c.name,
      phone: c.phone,
      department: c.department,
      category_id: catMap.get(c.category.toLowerCase()) ?? catMap.values().next().value!,
    }));

    const result = await repo.batchCreateContacts(resolved);
    return { imported: result.imported, errors: result.errors, total: contacts.length };
  });
}
