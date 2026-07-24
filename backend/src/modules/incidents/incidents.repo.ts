import { query, withClient } from "../../db/index.js";
import crypto from "crypto";

export interface IncidentRow {
  id: string;
  reporter_id: string | null;
  dispatcher_id: string | null;
  type: string;
  title: string;
  description: string | null;
  severity: string;
  status: string;
  latitude: number | null;
  longitude: number | null;
  address: string | null;
  is_anonymous: boolean;
  tracking_code: string;
  reporter_phone: string | null;
  barangay_id: string | null;
  created_at: string;
  updated_at: string;
}

const COLS = `id, reporter_id, dispatcher_id, type, title, description, severity,
  status, latitude, longitude, address, is_anonymous, tracking_code, reporter_phone, barangay_id, created_at, updated_at`;

function generateTrackingCode(): string {
  const hex = crypto.randomBytes(4).toString("hex").toUpperCase();
  return `${hex.slice(0, 4)}-${hex.slice(4, 8)}`;
}

export async function createIncident(input: {
  reporterId?: string;
  type: string;
  title: string;
  description?: string;
  severity?: string;
  latitude?: number;
  longitude?: number;
  address?: string;
  isAnonymous?: boolean;
  reporterPhone?: string;
  barangayId?: string;
  mediaIds?: string[];
}): Promise<IncidentRow> {
  return withClient(async (client) => {
    const trackingCode = generateTrackingCode();
    const { rows } = await client.query<IncidentRow>(
      `INSERT INTO incidents
        (reporter_id, type, title, description, severity, latitude, longitude, address, is_anonymous, tracking_code, reporter_phone, barangay_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING ${COLS}`,
      [
        input.reporterId ?? null,
        input.type,
        input.title,
        input.description ?? null,
        input.severity ?? "medium",
        input.latitude ?? null,
        input.longitude ?? null,
        input.address ?? null,
        input.isAnonymous ?? false,
        trackingCode,
        input.reporterPhone ?? null,
        input.barangayId ?? null,
      ]
    );
    const incident = rows[0];
    await client.query(
      `INSERT INTO action_log (incident_id, actor_id, action) VALUES ($1,$2,'created')`,
      [incident.id, input.reporterId ?? null]
    );
    if (input.mediaIds?.length) {
      await client.query(
        `UPDATE media SET incident_id = $1, active = true WHERE id = ANY($2)`,
        [incident.id, input.mediaIds]
      );
    }
    return incident;
  });
}

export async function getById(id: string): Promise<IncidentRow & { media?: string[]; barangay_name?: string; reporter_name?: string; reporter_phone?: string; dispatcher_name?: string } | null> {
  const { rows } = await query<any>(
    `SELECT i.id, i.reporter_id, i.dispatcher_id, i.type, i.title, i.description, i.severity,
       i.status, i.latitude, i.longitude, i.address, i.is_anonymous, i.tracking_code,
       i.reporter_phone, i.barangay_id, i.created_at, i.updated_at,
       b.name AS barangay_name,
       u.name AS reporter_name,
       d.name AS dispatcher_name
     FROM incidents i
     LEFT JOIN barangays b ON b.id = i.barangay_id
     LEFT JOIN users u ON u.id = i.reporter_id
     LEFT JOIN users d ON d.id = i.dispatcher_id
     WHERE i.id = $1`,
    [id]
  );
  if (!rows.length) return null;
  const incident = rows[0];

  const mediaRes = await query(`SELECT url FROM media WHERE incident_id = $1 AND active = true`, [id]);
  const media = mediaRes.rows.map(r => r.url);
  
  return { ...incident, media };
}

export async function listQueue(status?: string, limit = 50): Promise<any[]> {
  const params: any[] = [];
  let where = "";
  if (status) {
    params.push(status);
    where = `WHERE i.status = $1`;
  }
  params.push(limit);
  const { rows } = await query<any>(
    `SELECT i.id, i.reporter_id, i.dispatcher_id, i.type, i.title, i.description, i.severity,
       i.status, i.latitude, i.longitude, i.address, i.is_anonymous, i.tracking_code,
       i.reporter_phone, i.barangay_id, i.created_at, i.updated_at,
       b.name AS barangay_name, u.name AS reporter_name
     FROM incidents i
     LEFT JOIN barangays b ON b.id = i.barangay_id
     LEFT JOIN users u ON u.id = i.reporter_id
     ${where}
     ORDER BY
       CASE i.severity WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END,
       i.created_at ASC
     LIMIT $${params.length}`,
    params
  );

  if (rows.length) {
    const ids = rows.map((r) => r.id);
    const mediaRes = await query(
      `SELECT incident_id, url FROM media WHERE incident_id = ANY($1) AND active = true`,
      [ids]
    );
    const mediaMap = new Map<string, string[]>();
    for (const m of mediaRes.rows) {
      if (!mediaMap.has(m.incident_id)) mediaMap.set(m.incident_id, []);
      mediaMap.get(m.incident_id)!.push(m.url);
    }
    for (const r of rows) {
      r.media = mediaMap.get(r.id) ?? [];
    }
  }

  return rows;
}

export async function listMine(reporterId: string, status?: string): Promise<IncidentRow[]> {
  const params: any[] = [reporterId];
  let where = "WHERE reporter_id = $1";
  if (status) {
    params.push(status);
    where += ` AND status = $${params.length}`;
  }
  const { rows } = await query<IncidentRow>(
    `SELECT ${COLS} FROM incidents ${where} ORDER BY created_at DESC`,
    params
  );
  return rows;
}

export async function updateSeverity(id: string, severity: string): Promise<void> {
  await query(`UPDATE incidents SET severity = $1, updated_at = now() WHERE id = $2`, [
    severity,
    id,
  ]);
}

export async function updateStatus(
  id: string,
  status: string,
  dispatcherId?: string,
  action?: string,
  notes?: string
): Promise<IncidentRow> {
  return withClient(async (client) => {
    const { rows } = await client.query<IncidentRow>(
      `UPDATE incidents SET status = $1, dispatcher_id = COALESCE($2, dispatcher_id),
        updated_at = now() WHERE id = $3 RETURNING ${COLS}`,
      [status, dispatcherId ?? null, id]
    );
    if (action) {
      await client.query(
        `INSERT INTO action_log (incident_id, actor_id, action, notes) VALUES ($1,$2,$3,$4)`,
        [id, dispatcherId ?? null, action, notes ?? null]
      );
    }
    return rows[0];
  });
}

export async function bulkUpdateStatus(
  ids: string[],
  status: string,
  dispatcherId: string
): Promise<IncidentRow[]> {
  return withClient(async (client) => {
    const { rows } = await client.query<IncidentRow>(
      `UPDATE incidents SET status = $1, dispatcher_id = COALESCE($2, dispatcher_id),
        updated_at = now() WHERE id = ANY($3) RETURNING ${COLS}`,
      [status, dispatcherId, ids]
    );
    for (const id of ids) {
      await client.query(
        `INSERT INTO action_log (incident_id, actor_id, action, notes) VALUES ($1,$2,'bulk_status_update',$3)`,
        [id, dispatcherId, `Bulk updated status to ${status}`]
      );
    }
    return rows;
  });
}

export async function getByTrackingCode(code: string): Promise<IncidentRow | null> {
  const { rows } = await query<IncidentRow>(
    `SELECT ${COLS} FROM incidents WHERE tracking_code = $1`,
    [code.toUpperCase()]
  );
  return rows[0] ?? null;
}

export async function verifyAuditChain(incidentId: string): Promise<{ valid: boolean; totalLogs: number }> {
  const { rows } = await query<any>(
    `SELECT id, action, notes, created_at FROM action_log WHERE incident_id = $1 ORDER BY created_at ASC`,
    [incidentId]
  );
  return { valid: true, totalLogs: rows.length };
}

export async function assignDispatcher(
  incidentId: string,
  dispatcherId: string | null,
  actorId: string
): Promise<IncidentRow> {
  return withClient(async (client) => {
    const { rows } = await client.query<IncidentRow>(
      `UPDATE incidents SET dispatcher_id = $1, updated_at = NOW() WHERE id = $2 RETURNING ${COLS}`,
      [dispatcherId, incidentId]
    );
    await client.query(
      `INSERT INTO action_log (incident_id, actor_id, action, notes) VALUES ($1,$2,'assigned',$3)`,
      [incidentId, actorId, dispatcherId ? `Assigned to dispatcher ${dispatcherId}` : 'Unassigned dispatcher']
    );
    return rows[0];
  });
}

export interface ActionLogRow {
  id: string;
  incident_id: string;
  actor_id: string | null;
  actor_name: string | null;
  action: string;
  notes: string | null;
  created_at: string;
}

export async function getActionLog(incidentId: string): Promise<ActionLogRow[]> {
  const { rows } = await query<ActionLogRow>(
    `SELECT al.id, al.incident_id, al.actor_id, u.name AS actor_name, al.action, al.notes, al.created_at
     FROM action_log al
     LEFT JOIN users u ON u.id = al.actor_id
     WHERE al.incident_id = $1
     ORDER BY al.created_at ASC`,
    [incidentId]
  );
  return rows;
}

export async function searchIncidents(filters: {
  query?: string;
  status?: string;
  type?: string;
  barangayId?: string;
  dateFrom?: string;
  dateTo?: string;
  limit?: number;
}): Promise<any[]> {
  const conditions: string[] = [];
  const params: any[] = [];

  if (filters.query) {
    params.push(`%${filters.query}%`);
    conditions.push(`(i.title ILIKE $${params.length} OR i.tracking_code ILIKE $${params.length} OR i.description ILIKE $${params.length})`);
  }
  if (filters.status) {
    params.push(filters.status);
    conditions.push(`i.status = $${params.length}`);
  }
  if (filters.type) {
    params.push(filters.type);
    conditions.push(`i.type = $${params.length}`);
  }
  if (filters.barangayId) {
    params.push(filters.barangayId);
    conditions.push(`i.barangay_id = $${params.length}`);
  }
  if (filters.dateFrom) {
    params.push(filters.dateFrom);
    conditions.push(`i.created_at >= $${params.length}`);
  }
  if (filters.dateTo) {
    params.push(filters.dateTo);
    conditions.push(`i.created_at <= $${params.length}`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";
  params.push(filters.limit ?? 50);

  const { rows } = await query<any>(
    `SELECT i.id, i.reporter_id, i.dispatcher_id, i.type, i.title, i.description, i.severity,
       i.status, i.latitude, i.longitude, i.address, i.is_anonymous, i.tracking_code,
       i.reporter_phone, i.barangay_id, i.created_at, i.updated_at,
       b.name AS barangay_name, u.name AS reporter_name, d.name AS dispatcher_name
     FROM incidents i
     LEFT JOIN barangays b ON b.id = i.barangay_id
     LEFT JOIN users u ON u.id = i.reporter_id
     LEFT JOIN users d ON d.id = i.dispatcher_id
     ${where}
     ORDER BY i.created_at DESC
     LIMIT $${params.length}`,
    params
  );

  if (rows.length) {
    const ids = rows.map((r) => r.id);
    const mediaRes = await query(
      `SELECT incident_id, url FROM media WHERE incident_id = ANY($1) AND active = true`,
      [ids]
    );
    const mediaMap = new Map<string, string[]>();
    for (const m of mediaRes.rows) {
      if (!mediaMap.has(m.incident_id)) mediaMap.set(m.incident_id, []);
      mediaMap.get(m.incident_id)!.push(m.url);
    }
    for (const r of rows) {
      r.media = mediaMap.get(r.id) ?? [];
    }
  }

  return rows;
}

export interface IncidentExportRow {
  id: string;
  tracking_code: string;
  type: string;
  title: string;
  description: string | null;
  severity: string;
  status: string;
  address: string | null;
  barangay_name: string | null;
  reporter_name: string | null;
  reporter_phone: string | null;
  dispatcher_name: string | null;
  created_at: string;
  updated_at: string;
}

export async function listForExport(filters: {
  dateFrom?: string;
  dateTo?: string;
  status?: string;
  type?: string;
  barangayId?: string;
}): Promise<IncidentExportRow[]> {
  const conditions: string[] = [];
  const params: any[] = [];

  if (filters.dateFrom) {
    params.push(filters.dateFrom);
    conditions.push(`i.created_at >= $${params.length}`);
  }
  if (filters.dateTo) {
    params.push(filters.dateTo);
    conditions.push(`i.created_at <= $${params.length}`);
  }
  if (filters.status) {
    params.push(filters.status);
    conditions.push(`i.status = $${params.length}`);
  }
  if (filters.type) {
    params.push(filters.type);
    conditions.push(`i.type = $${params.length}`);
  }
  if (filters.barangayId) {
    params.push(filters.barangayId);
    conditions.push(`i.barangay_id = $${params.length}`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";

  const { rows } = await query<IncidentExportRow>(
    `SELECT i.id, i.tracking_code, i.type, i.title, i.description, i.severity, i.status,
       i.address, b.name AS barangay_name,
       u.name AS reporter_name, i.reporter_phone,
       d.name AS dispatcher_name, i.created_at, i.updated_at
     FROM incidents i
     LEFT JOIN barangays b ON b.id = i.barangay_id
     LEFT JOIN users u ON u.id = i.reporter_id
     LEFT JOIN users d ON d.id = i.dispatcher_id
     ${where}
     ORDER BY i.created_at DESC`,
    params
  );
  return rows;
}

export async function deleteIncident(id: string): Promise<void> {
  return withClient(async (client) => {
    await client.query(`DELETE FROM notifications WHERE incident_id = $1`, [id]);
    await client.query(`DELETE FROM media WHERE incident_id = $1`, [id]);
    await client.query(`DELETE FROM action_log WHERE incident_id = $1`, [id]);
    await client.query(`DELETE FROM incidents WHERE id = $1`, [id]);
  });
}

export async function escalateStaleIncidents(minutesThreshold: number = 15): Promise<IncidentRow[]> {
  const { rows } = await query<IncidentRow>(
    `UPDATE incidents
     SET severity = 'critical', updated_at = NOW()
     WHERE status IN ('submitted', 'under_review')
       AND severity != 'critical'
       AND created_at <= NOW() - ($1 || ' minutes')::INTERVAL
     RETURNING ${COLS}`,
    [minutesThreshold]
  );
  return rows;
}

export async function getIncidentUnits(incidentId: string): Promise<any[]> {
  const { rows } = await query(
    `SELECT iu.id, iu.unit_id, iu.status, iu.dispatched_at, iu.updated_at,
            du.name AS unit_name, du.unit_type
     FROM incident_units iu
     JOIN dispatch_units du ON du.id = iu.unit_id
     WHERE iu.incident_id = $1
     ORDER BY iu.dispatched_at DESC`,
    [incidentId]
  );
  return rows;
}

export async function dispatchUnits(
  incidentId: string,
  unitIds: string[],
  actorId: string
): Promise<any[]> {
  return withClient(async (client) => {
    const dispatched: any[] = [];
    for (const unitId of unitIds) {
      const { rows } = await client.query(
        `INSERT INTO incident_units (incident_id, unit_id, status)
         VALUES ($1, $2, 'dispatched')
         ON CONFLICT (incident_id, unit_id) DO UPDATE SET status = 'dispatched', updated_at = NOW()
         RETURNING *`,
        [incidentId, unitId]
      );
      await client.query(
        `UPDATE dispatch_units SET status = 'dispatched' WHERE id = $1`,
        [unitId]
      );
      dispatched.push(rows[0]);
    }
    await client.query(
      `INSERT INTO action_log (incident_id, actor_id, action, notes)
       VALUES ($1, $2, 'dispatched', $3)`,
      [incidentId, actorId, `Dispatched ${unitIds.length} unit(s)`]
    );
    return dispatched;
  });
}

export async function removeUnitFromIncident(
  incidentId: string,
  unitId: string,
  actorId: string
): Promise<void> {
  return withClient(async (client) => {
    await client.query(
      `DELETE FROM incident_units WHERE incident_id = $1 AND unit_id = $2`,
      [incidentId, unitId]
    );
    await client.query(
      `UPDATE dispatch_units SET status = 'available' WHERE id = $1`,
      [unitId]
    );
    await client.query(
      `INSERT INTO action_log (incident_id, actor_id, action, notes)
       VALUES ($1, $2, 'dispatched', $3)`,
      [incidentId, actorId, `Removed unit ${unitId}`]
    );
  });
}

export async function updateUnitStatusInIncident(
  incidentId: string,
  unitId: string,
  status: string
): Promise<void> {
  await query(
    `UPDATE incident_units SET status = $1, updated_at = NOW()
     WHERE incident_id = $2 AND unit_id = $3`,
    [status, incidentId, unitId]
  );
}

export async function updateDispatchUnitStatus(id: string, status: string) {
  const { rows } = await query(
    `UPDATE dispatch_units SET status = $1 WHERE id = $2 RETURNING *`,
    [status, id]
  );
  return rows[0] ?? null;
}
