import { FastifyInstance } from "fastify";
import { z } from "zod";
import { authGuard, optionalAuthGuard } from "../common/auth-guard.js";
import { errors } from "../common/errors.js";
import * as repo from "./incidents.repo.js";
import * as chatsRepo from "./chats.repo.js";
import { notifyDispatchers } from "../notifications/notifications.repo.js";
import { emitQueueNew, emitQueueUpdate, emitIncidentStatus, emitUnitDispatched, emitNewChatMessage } from "../realtime/realtime.js";
import { listForExport } from "./incidents.repo.js";
import { classifyIncidentText } from "./ai-classifier.service.js";
import { analyzeIncidentReport, handleAiChatQuery } from "./ai.service.js";

const INCIDENT_TYPES = ["fire", "accident", "crime", "medical", "natural_disaster", "infrastructure"] as const;
const SEVERITIES = ["low", "medium", "high", "critical"] as const;
const STATUSES = ["submitted", "under_review", "verified", "rejected", "resolved"] as const;

const createSchema = z.object({
  type: z.enum(INCIDENT_TYPES),
  title: z.string().min(1).max(200),
  description: z.string().max(5000).optional(),
  severity: z.enum(SEVERITIES).optional(),
  latitude: z.number().min(-90).max(90).optional(),
  longitude: z.number().min(-180).max(180).optional(),
  address: z.string().max(500).optional(),
  is_anonymous: z.boolean().optional(),
  reporter_phone: z.string().max(20).optional(),
  barangay_id: z.string().uuid().optional(),
  media_ids: z.array(z.string().uuid()).optional(),
});

const statusSchema = z.object({
  status: z.enum(STATUSES),
});

const verifySchema = z.object({
  severity: z.enum(SEVERITIES).optional(),
  dispatcher_note: z.string().max(2000).optional(),
});

export async function registerIncidentRoutes(app: FastifyInstance) {
  app.post(
    "/incidents",
    { preHandler: optionalAuthGuard() },
    async (req, reply) => {
      const body = createSchema.parse(req.body);
      const incident = await repo.createIncident({
        reporterId: req.user?.userId,
        type: body.type,
        title: body.title,
        description: body.description,
        severity: body.severity,
        latitude: body.latitude,
        longitude: body.longitude,
        address: body.address,
        isAnonymous: body.is_anonymous,
        reporterPhone: body.reporter_phone,
        barangayId: body.barangay_id,
        mediaIds: body.media_ids,
      });
      await notifyDispatchers({
        incidentId: incident.id,
        title: "New incident report",
        body: `${incident.type} — ${incident.title}`,
      });
      emitQueueNew(incident);
      return reply.code(201).send({ incident });
    }
  );

  app.get(
    "/incidents/track/:code",
    async (req, reply) => {
      const { code } = req.params as { code: string };
      const incident = await repo.getByTrackingCode(code);
      if (!incident) throw errors.notFound("Incident not found");
      return {
        id: incident.id,
        type: incident.type,
        title: incident.title,
        description: incident.description,
        severity: incident.severity,
        status: incident.status,
        address: incident.address,
        created_at: incident.created_at,
        updated_at: incident.updated_at,
      };
    }
  );

  app.get(
    "/incidents/queue",
    { preHandler: authGuard(["dispatcher", "admin"]) },
    async (req) => {
      const status = typeof req.query === "object" ? (req.query as any).status : undefined;
      const incidents = await repo.listQueue(status);
      return { incidents };
    }
  );

  app.get(
    "/incidents/mine",
    { preHandler: authGuard(["reporter", "dispatcher", "admin"]) },
    async (req) => {
      const status = typeof req.query === "object" ? (req.query as any).status : undefined;
      const incidents = await repo.listMine(req.user!.userId, status);
      return { incidents };
    }
  );

  app.get(
    "/incidents/:id",
    { preHandler: authGuard(["reporter", "dispatcher", "admin"]) },
    async (req, reply) => {
      const { id } = req.params as any;
      const incident = await repo.getById(id);
      if (!incident) throw errors.notFound("Incident not found");
      if (
        req.user!.role === "reporter" &&
        incident.reporter_id !== req.user!.userId
      ) {
        throw errors.forbidden("Not your incident");
      }
      return { incident };
    }
  );

  app.get(
    "/incidents/:id/action-log",
    { preHandler: authGuard(["reporter", "dispatcher", "admin"]) },
    async (req) => {
      const { id } = req.params as { id: string };
      const logs = await repo.getActionLog(id);
      return { logs };
    }
  );

  app.get(
    "/incidents/:id/units",
    { preHandler: authGuard(["reporter", "dispatcher", "admin"]) },
    async (req) => {
      const { id } = req.params as { id: string };
      const units = await repo.getIncidentUnits(id);
      return { units };
    }
  );

  app.post(
    "/incidents/:id/dispatch",
    { preHandler: authGuard(["dispatcher", "admin"]) },
    async (req, reply) => {
      const { id } = req.params as { id: string };
      const body = z.object({ unit_ids: z.array(z.string().uuid()).min(1) }).parse(req.body);
      const existing = await repo.getById(id);
      if (!existing) throw errors.notFound("Incident not found");
      const dispatched = await repo.dispatchUnits(id, body.unit_ids, req.user!.userId);
      emitUnitDispatched(id, dispatched);
      return reply.send({ ok: true, units: dispatched });
    }
  );

  app.delete(
    "/incidents/:id/units/:unitId",
    { preHandler: authGuard(["dispatcher", "admin"]) },
    async (req) => {
      const { id, unitId } = req.params as { id: string; unitId: string };
      await repo.removeUnitFromIncident(id, unitId, req.user!.userId);
      emitUnitDispatched(id, []);
      return { ok: true };
    }
  );

  app.patch(
    "/incidents/:id/units/:unitId/status",
    { preHandler: authGuard(["dispatcher", "admin"]) },
    async (req) => {
      const { id, unitId } = req.params as { id: string; unitId: string };
      const body = z.object({ status: z.enum(["dispatched", "en_route", "on_scene", "returned"]) }).parse(req.body);
      await repo.updateUnitStatusInIncident(id, unitId, body.status);
      if (body.status === "returned") {
        await repo.updateDispatchUnitStatus(unitId, "available");
      }
      emitUnitDispatched(id, await repo.getIncidentUnits(id));
      return { ok: true };
    }
  );

  app.get(
    "/incidents/search",
    { preHandler: authGuard(["dispatcher", "admin"]) },
    async (req) => {
      const q = (typeof req.query === "object" ? req.query : {}) as any;
      const incidents = await repo.searchIncidents({
        query: q.q,
        status: q.status,
        type: q.type,
        barangayId: q.barangay_id,
        dateFrom: q.date_from,
        dateTo: q.date_to,
        limit: q.limit ? parseInt(q.limit) : 50,
      });
      return { incidents };
    }
  );

  app.patch(
    "/incidents/:id/verify",
    { preHandler: authGuard(["dispatcher", "admin"]) },
    async (req, reply) => {
      const { id } = req.params as any;
      const body = verifySchema.parse(req.body);
      const existing = await repo.getById(id);
      if (!existing) throw errors.notFound("Incident not found");
      const incident = await repo.updateStatus(
        id,
        "verified",
        req.user!.userId,
        "verified",
        body.dispatcher_note
      );
      if (body.severity) {
        await repo.updateSeverity(id, body.severity);
      }
      const updated = body.severity ? await repo.getById(id) : incident;
      emitQueueUpdate(updated!.id, updated!.status);
      if (existing.reporter_id) emitIncidentStatus(updated!.id, updated!.status);
      return reply.send({ incident: updated });
    }
  );

  app.patch(
    "/incidents/:id/reject",
    { preHandler: authGuard(["dispatcher", "admin"]) },
    async (req, reply) => {
      const { id } = req.params as any;
      const body = z.object({ reason: z.string().max(2000) }).parse(req.body);
      const existing = await repo.getById(id);
      if (!existing) throw errors.notFound("Incident not found");
      const incident = await repo.updateStatus(
        id,
        "rejected",
        req.user!.userId,
        "rejected",
        body.reason
      );
      emitQueueUpdate(incident.id, incident.status);
      if (existing.reporter_id) emitIncidentStatus(incident.id, incident.status);
      return reply.send({ incident });
    }
  );

  app.patch(
    "/incidents/:id/decline",
    { preHandler: authGuard(["dispatcher", "admin"]) },
    async (req, reply) => {
      const { id } = req.params as any;
      const body = z.object({ reason: z.string().max(2000) }).parse(req.body);
      const existing = await repo.getById(id);
      if (!existing) throw errors.notFound("Incident not found");
      const incident = await repo.updateStatus(
        id,
        "declined",
        req.user!.userId,
        "declined",
        body.reason
      );
      emitQueueUpdate(incident.id, incident.status);
      if (existing.reporter_id) emitIncidentStatus(incident.id, incident.status);
      return reply.send({ incident });
    }
  );

  app.patch(
    "/incidents/:id/status",
    { preHandler: authGuard(["dispatcher", "admin"]) },
    async (req, reply) => {
      const { id } = req.params as any;
      const body = statusSchema.parse(req.body);
      const existing = await repo.getById(id);
      if (!existing) throw errors.notFound("Incident not found");
      const incident = await repo.updateStatus(
        id,
        body.status,
        req.user!.userId,
        body.status === "resolved" ? "resolved" : undefined
      );
      emitQueueUpdate(incident.id, incident.status);
      if (existing.reporter_id) emitIncidentStatus(incident.id, incident.status);
      return reply.send({ incident });
    }
  );

  app.patch(
    "/incidents/:id/assign",
    { preHandler: authGuard(["dispatcher", "admin"]) },
    async (req, reply) => {
      const { id } = req.params as any;
      const body = z.object({ dispatcher_id: z.string().min(1).nullable() }).parse(req.body);
      const existing = await repo.getById(id);
      if (!existing) throw errors.notFound("Incident not found");
      const incident = await repo.assignDispatcher(
        id,
        body.dispatcher_id,
        req.user!.userId
      );
      emitQueueUpdate(incident.id, incident.status);
      return reply.send({ incident });
    }
  );

  app.post(
    "/incidents/bulk-status",
    { preHandler: authGuard(["dispatcher", "admin"]) },
    async (req, reply) => {
      const bulkSchema = z.object({
        ids: z.array(z.string().min(1)),
        status: z.enum(STATUSES),
      });
      const { ids, status } = bulkSchema.parse(req.body);
      const updatedIncidents = await repo.bulkUpdateStatus(ids, status, req.user!.userId);
      for (const inc of updatedIncidents) {
        emitQueueUpdate(inc.id, inc.status);
        if (inc.reporter_id) emitIncidentStatus(inc.id, inc.status);
      }
      return reply.send({ count: updatedIncidents.length, incidents: updatedIncidents });
    }
  );

  app.delete(
    "/incidents/:id",
    { preHandler: authGuard(["admin"]) },
    async (req, reply) => {
      const { id } = req.params as { id: string };
      const existing = await repo.getById(id);
      if (!existing) throw errors.notFound("Incident not found");
      await repo.deleteIncident(id);
      return reply.send({ ok: true });
    }
  );

  app.post("/incidents/sms-webhook", async (req, reply) => {
    const smsSchema = z.object({
      from: z.string().min(1),
      message: z.string().min(1),
      location: z.string().optional(),
    });
    const body = smsSchema.parse(req.body);
    const parsedType = body.message.toLowerCase().includes("fire") ? "fire"
      : body.message.toLowerCase().includes("accident") ? "accident"
      : body.message.toLowerCase().includes("crime") ? "crime"
      : body.message.toLowerCase().includes("medical") ? "medical"
      : "natural_disaster";

    const incident = await repo.createIncident({
      type: parsedType,
      title: `SMS Report from ${body.from}`,
      description: body.message,
      reporterPhone: body.from,
      address: body.location ?? "Received via SMS Gateway",
      isAnonymous: false,
    });

    emitQueueNew(incident);
    return reply.code(201).send({
      ok: true,
      tracking_code: incident.tracking_code,
      message: `Report created successfully with tracking code: ${incident.tracking_code}`,
    });
  });

  app.post("/incidents/ai-classify", async (req, reply) => {
    const schema = z.object({
      description: z.string().min(1),
      title: z.string().optional(),
    });
    const { description, title } = schema.parse(req.body);
    const classification = classifyIncidentText(description, title);
    return reply.send({ classification });
  });

  app.get("/incidents/:id/audit-chain", async (req, reply) => {
    const { id } = req.params as { id: string };
    const audit = await repo.verifyAuditChain(id);
    return reply.send({ incident_id: id, audit });
  });

  app.get(
    "/incidents/export",
    { preHandler: authGuard(["admin"]) },
    async (req, reply) => {
      const q = (typeof req.query === "object" ? req.query : {}) as any;
      const rows = await listForExport({
        dateFrom: q.date_from,
        dateTo: q.date_to,
        status: q.status,
        type: q.type,
        barangayId: q.barangay_id,
      });

      const header = "ID,Tracking Code,Type,Title,Description,Severity,Status,Address,Barangay,Reporter,Phone,Dispatcher,Created,Updated\n";
      const csv = rows.map((r) =>
        [
          r.id,
          r.tracking_code,
          r.type,
          `"${(r.title ?? "").replace(/"/g, '""')}"`,
          `"${(r.description ?? "").replace(/"/g, '""')}"`,
          r.severity,
          r.status,
          `"${(r.address ?? "").replace(/"/g, '""')}"`,
          `"${(r.barangay_name ?? "").replace(/"/g, '""')}"`,
          `"${(r.reporter_name ?? "").replace(/"/g, '""')}"`,
          r.reporter_phone ?? "",
          `"${(r.dispatcher_name ?? "").replace(/"/g, '""')}"`,
          r.created_at,
          r.updated_at,
        ].join(",")
      ).join("\n");

      reply.header("Content-Type", "text/csv");
      reply.header("Content-Disposition", 'attachment; filename="incidents.csv"');
      return reply.send(header + csv);
    }
  );

  app.post(
    "/incidents/:id/analyze",
    { preHandler: authGuard(["dispatcher", "admin", "citizen"]) },
    async (req, reply) => {
      const { id } = req.params as any;
      const incident = await repo.getById(id);
      if (!incident) throw errors.notFound("Incident not found");
      const analysis = await analyzeIncidentReport(incident);
      return reply.send({ analysis });
    }
  );

  app.get(
    "/incidents/:id/messages",
    { preHandler: authGuard(["dispatcher", "admin", "citizen"]) },
    async (req, reply) => {
      const { id } = req.params as any;
      const messages = await chatsRepo.getIncidentMessages(id);
      return reply.send({ messages });
    }
  );

  app.post(
    "/incidents/:id/messages",
    { preHandler: authGuard(["dispatcher", "admin", "citizen"]) },
    async (req, reply) => {
      const { id } = req.params as any;
      const body = z.object({ message: z.string().min(1).max(2000) }).parse(req.body);
      const incident = await repo.getById(id);
      if (!incident) throw errors.notFound("Incident not found");

      const chatMsg = await chatsRepo.addChatMessage({
        incidentId: id,
        senderId: req.user!.userId,
        senderName: req.user!.role === "dispatcher" ? "Dispatcher" : req.user!.role === "admin" ? "Admin" : "Reporter",
        senderRole: req.user!.role,
        message: body.message,
      });

      emitNewChatMessage(id, chatMsg);
      return reply.code(201).send({ message: chatMsg });
    }
  );

  app.post(
    "/ai/chat",
    { preHandler: optionalAuthGuard() },
    async (req, reply) => {
      const body = z.object({
        prompt: z.string().min(1).max(1000),
        incident_id: z.string().nullable().optional(),
        history: z.array(z.object({
          role: z.enum(["user", "model", "assistant"]),
          text: z.string(),
        })).optional(),
      }).parse(req.body);

      let contextIncident = null;
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (body.incident_id && uuidRegex.test(body.incident_id.trim())) {
        contextIncident = await repo.getById(body.incident_id.trim());
      }

      const response = await handleAiChatQuery(body.prompt, contextIncident, body.history || []);
      return reply.send({ reply: response });
    }
  );
}
