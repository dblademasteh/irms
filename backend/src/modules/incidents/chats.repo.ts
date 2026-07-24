import { query } from "../../db/index.js";

export interface IncidentChatMessageRow {
  id: string;
  incident_id: string;
  sender_id: string | null;
  sender_name: string;
  sender_role: string;
  message: string;
  is_ai: boolean;
  created_at: string;
}

export async function getIncidentMessages(incidentId: string): Promise<IncidentChatMessageRow[]> {
  const { rows } = await query<IncidentChatMessageRow>(
    `SELECT id, incident_id, sender_id, sender_name, sender_role, message, is_ai, created_at
     FROM incident_chats
     WHERE incident_id = $1
     ORDER BY created_at ASC`,
    [incidentId]
  );
  return rows;
}

export async function addChatMessage(input: {
  incidentId: string;
  senderId?: string | null;
  senderName: string;
  senderRole: string;
  message: string;
  isAi?: boolean;
}): Promise<IncidentChatMessageRow> {
  const { rows } = await query<IncidentChatMessageRow>(
    `INSERT INTO incident_chats (incident_id, sender_id, sender_name, sender_role, message, is_ai)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING id, incident_id, sender_id, sender_name, sender_role, message, is_ai, created_at`,
    [
      input.incidentId,
      input.senderId ?? null,
      input.senderName,
      input.senderRole,
      input.message,
      input.isAi ?? false,
    ]
  );
  return rows[0];
}
