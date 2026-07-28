import { Server } from "socket.io";
import type { Server as HttpServer } from "http";
import { config } from "../common/config.js";
import { verifyToken } from "../common/jwt.js";

export let io: Server | null = null;

export function initRealtime(server: HttpServer) {
  io = new Server(server, {
    cors: { origin: config.corsOrigin, methods: ["GET", "POST"] },
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) return next(new Error("unauthorized"));
    try {
      const payload = verifyToken(token);
      (socket.data as any).userId = payload.userId;
      (socket.data as any).role = payload.role;
      next();
    } catch {
      next(new Error("unauthorized"));
    }
  });

  io.on("connection", (socket) => {
    socket.on("join_queue", () => {
      if ((socket.data as any).role === "dispatcher" || (socket.data as any).role === "admin") {
        socket.join("queue");
      }
    });
    socket.on("track_incident", (incidentId: string) => {
      if (incidentId) socket.join(`incident:${incidentId}`);
    });
    socket.on("untrack_incident", (incidentId: string) => {
      if (incidentId) socket.leave(`incident:${incidentId}`);
    });
  });

  return io;
}

export function emitQueueNew(incident: any) {
  io?.to("queue").emit("queue:new_incident", incident);
}

export function emitQueueUpdate(id: string, status: string) {
  io?.to("queue").emit("queue:update", { id, status });
}

export function emitIncidentStatus(id: string, status: string) {
  io?.to(`incident:${id}`).emit("incident:status", { id, status });
}

export function emitBroadcast(id: string, message: string, authorName: string, targetRole: string = "all", category: string = "emergency") {
  const payload = { id, message, authorName, category, timestamp: new Date().toISOString(), targetRole };

  if (targetRole === "all") {
    io?.emit("system:broadcast", payload);
  } else if (targetRole === "dispatchers") {
    io?.emit("system:broadcast", { ...payload, targetRole: "dispatchers" });
  } else if (targetRole === "reporters") {
    io?.emit("system:broadcast", { ...payload, targetRole: "reporters" });
  }
}

export function emitUnitDispatched(incidentId: string, units: any[]) {
  io?.to(`incident:${incidentId}`).emit("incident:unit_dispatched", { incidentId, units });
  io?.to("queue").emit("queue:update", { id: incidentId, status: "units_updated" });
}

export function emitNewChatMessage(incidentId: string, chatMessage: any) {
  io?.to(`incident:${incidentId}`).emit("incident:new_chat_message", chatMessage);
}

export function emitChatToQueue(chatMessage: any) {
  io?.to("queue").emit("incident:new_chat_message", chatMessage);
}
