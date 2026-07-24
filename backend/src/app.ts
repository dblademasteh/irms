import Fastify from "fastify";
import cors from "@fastify/cors";
import multipart from "@fastify/multipart";
import fastifyStatic from "@fastify/static";
import path from "path";
import { ZodError } from "zod";
import { config } from "./modules/common/config.js";
import { errors, AppError } from "./modules/common/errors.js";
import { connectRedis } from "./modules/common/redis.js";
import { registerAuthRoutes } from "./modules/auth/auth.routes.js";
import { registerIncidentRoutes } from "./modules/incidents/incidents.routes.js";
import { registerMediaRoutes } from "./modules/media/media.routes.js";
import { registerNotificationRoutes } from "./modules/notifications/notifications.routes.js";
import { registerAdminRoutes } from "./modules/admin/admin.routes.js";
import { registerContactsRoutes } from "./modules/contacts/contacts.routes.js";
import { registerCategoriesRoutes } from "./modules/contacts/categories.routes.js";
import { registerInviteCodeRoutes } from "./modules/contacts/invite-codes.routes.js";
import { registerBarangayRoutes } from "./modules/contacts/barangays.routes.js";
import { registerApiKeyRoutes } from "./modules/admin/api-keys.routes.js";
import { initRealtime } from "./modules/realtime/realtime.js";
import { startAutoEscalationTask } from "./modules/incidents/escalation.service.js";

async function build() {
  const app = Fastify({ logger: true });

  await app.register(cors, {
    origin: config.corsOrigin === "*" ? true : config.corsOrigin,
    methods: ["GET", "POST", "PUT", "PATCH", "OPTIONS", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"],
    credentials: true,
  });

  await app.register(multipart, {
    limits: { fileSize: config.s3.maxBytes },
  });

  await app.register(fastifyStatic, {
    root: path.resolve("public"),
    prefix: "/public/",
    decorateReply: false,
  });

  app.setErrorHandler((err, req, reply) => {
    if (err instanceof AppError) {
      return reply.code(err.status).send({ error: err.code, message: err.message });
    }
    if (err instanceof ZodError) {
      const msg = err.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join(", ");
      console.error("Zod Validation Error:", msg);
      return reply
        .code(400)
        .send({ error: "VALIDATION", message: msg });
    }
    if ((err as any).code === "FST_JWT_NO_AUTHORIZATION_HEADER" || (err as any).statusCode === 401) {
      return reply.code(401).send({ error: "UNAUTHORIZED", message: "Unauthorized" });
    }
    const statusCode = (err as any).statusCode || (err as any).status || 500;
    if (statusCode < 500) {
      return reply.code(statusCode).send({ error: (err as any).code || "BAD_REQUEST", message: err.message });
    }
    app.log.error(err);
    return reply.code(500).send({ error: "INTERNAL", message: "Internal server error" });
  });

  app.get("/health", async () => ({ ok: true }));
  app.get("/", async () => ({ service: "irms-backend", phase: 1 }));

  await registerAuthRoutes(app);
  await registerIncidentRoutes(app);
  await registerMediaRoutes(app);
  await registerNotificationRoutes(app);
  await registerAdminRoutes(app);
  await registerContactsRoutes(app);
  await registerCategoriesRoutes(app);
  await registerInviteCodeRoutes(app);
  await registerBarangayRoutes(app);
  await registerApiKeyRoutes(app);

  return app;
}

async function start() {
  const app = await build();
  try {
    await connectRedis();
    await app.listen({ port: config.port, host: "0.0.0.0" });
    initRealtime(app.server);
    startAutoEscalationTask();
    console.log(`[irms] API listening on :${config.port}`);
    console.log(`[irms] realtime (socket.io) & auto-escalation active`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}

start();