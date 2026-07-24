import { query } from "../../db/index.js";
import * as authRepo from "../auth/auth.repo.js";

export interface NotificationRow {
  id: string;
  user_id: string;
  incident_id: string | null;
  title: string;
  body: string;
  is_read: boolean;
  created_at: string;
}

export async function createNotification(input: {
  userId: string;
  incidentId?: string;
  title: string;
  body: string;
}): Promise<void> {
  await query(
    `INSERT INTO notifications (user_id, incident_id, title, body)
     VALUES ($1,$2,$3,$4)`,
    [input.userId, input.incidentId ?? null, input.title, input.body]
  );
}

export async function listForUser(
  userId: string,
  unreadOnly: boolean
): Promise<NotificationRow[]> {
  const { rows } = await query<NotificationRow>(
    `SELECT * FROM notifications WHERE user_id = $1
     ${unreadOnly ? "AND is_read = false" : ""}
     ORDER BY created_at DESC LIMIT 100`,
    [userId]
  );
  return rows;
}

export async function markRead(id: string, userId: string): Promise<void> {
  await query(
    `UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2`,
    [id, userId]
  );
}

export async function sendEmailNotification(email: string, subject: string, body: string): Promise<void> {
  // Simulated SMTP / Nodemailer email delivery logger
  console.log(`[Email Notification] Sent to ${email}: "${subject}" - ${body}`);
}

export async function sendFcmPushNotification(fcmToken: string, title: string, body: string): Promise<void> {
  // Simulated Firebase Admin FCM push delivery logger
  console.log(`[FCM Push Notification] Pushed to ${fcmToken}: "${title}" - ${body}`);
}

export async function notifyDispatchers(input: {
  incidentId: string;
  title: string;
  body: string;
}): Promise<void> {
  const dispatchers = await authRepo.findDispatchers();
  for (const d of dispatchers) {
    await createNotification({
      userId: d.id,
      incidentId: input.incidentId,
      title: input.title,
      body: input.body,
    });
    if (d.email) {
      await sendEmailNotification(d.email, input.title, input.body);
    }
  }
  // Real push (FCM/APNs) is wired here in production using d.fcm_token / d.apns_token.
  // Stubbed for Phase 1 local dev (no provider credentials).
}
