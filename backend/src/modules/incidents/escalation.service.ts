import { escalateStaleIncidents } from "./incidents.repo.js";
import { notifyDispatchers } from "../notifications/notifications.repo.js";
import { emitQueueUpdate } from "../realtime/realtime.js";

let intervalId: NodeJS.Timeout | null = null;

export function startAutoEscalationTask(checkIntervalMs: number = 60000, minutesThreshold: number = 15) {
  if (intervalId) return;

  intervalId = setInterval(async () => {
    try {
      const escalated = await escalateStaleIncidents(minutesThreshold);
      for (const inc of escalated) {
        emitQueueUpdate(inc.id, inc.status);
        await notifyDispatchers({
          incidentId: inc.id,
          title: "🚨 AUTO-ESCALATED INCIDENT",
          body: `Incident [${inc.tracking_code}] escalated to CRITICAL due to inactivity.`,
        });
      }
    } catch (err) {
      console.error("[AutoEscalation] Error running escalation task:", err);
    }
  }, checkIntervalMs);
}

export function stopAutoEscalationTask() {
  if (intervalId) {
    clearInterval(intervalId);
    intervalId = null;
  }
}
