import { query, withClient } from "../../db/index.js";

const USER_COLS = "id, name, email, phone, role, created_at, lang";

export async function getAllUsers() {
  const { rows } = await query(`SELECT ${USER_COLS} FROM users ORDER BY created_at DESC`);
  return rows;
}

export async function getUserById(id: string) {
  const { rows } = await query(`SELECT ${USER_COLS} FROM users WHERE id = $1`, [id]);
  return rows[0] ?? null;
}

export async function updateUserRole(id: string, role: string) {
  const { rows } = await query(
    `UPDATE users SET role = $1 WHERE id = $2 RETURNING ${USER_COLS}`,
    [role, id]
  );
  return rows[0];
}

export interface BroadcastRow {
  id: string;
  author_id: string | null;
  author_name: string;
  message: string;
  category: string;
  target_role: string;
  created_at: string;
}

export async function createBroadcast(input: {
  authorId: string;
  authorName: string;
  message: string;
  category?: string;
  targetRole?: string;
}): Promise<BroadcastRow> {
  return withClient(async (client) => {
    const { rows } = await client.query<BroadcastRow>(
      `INSERT INTO broadcasts (author_id, author_name, message, category, target_role)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [input.authorId, input.authorName, input.message, input.category ?? "emergency", input.targetRole ?? "all"]
    );
    return rows[0];
  });
}

export async function getBroadcasts(limit = 50): Promise<BroadcastRow[]> {
  try {
    const { rows } = await query<BroadcastRow>(
      `SELECT * FROM broadcasts ORDER BY created_at DESC LIMIT $1`,
      [limit]
    );
    return rows;
  } catch (err) {
    console.error("[admin.repo] getBroadcasts error:", err);
    return [];
  }
}

export async function getDispatchUnits() {
  try {
    const { rows } = await query(`SELECT * FROM dispatch_units ORDER BY created_at DESC`);
    return rows;
  } catch (err) {
    console.error("[admin.repo] getDispatchUnits error:", err);
    return [];
  }
}

export async function getAvailableDispatchUnits() {
  try {
    const { rows } = await query(
      `SELECT * FROM dispatch_units WHERE status = 'available' ORDER BY name`
    );
    return rows;
  } catch (err) {
    console.error("[admin.repo] getAvailableDispatchUnits error:", err);
    return [];
  }
}

export async function createDispatchUnit(input: { name: string; unitType: string }) {
  const { rows } = await query(
    `INSERT INTO dispatch_units (name, unit_type) VALUES ($1, $2) RETURNING *`,
    [input.name, input.unitType]
  );
  return rows[0];
}

export async function updateDispatchUnitStatus(id: string, status: string) {
  const { rows } = await query(
    `UPDATE dispatch_units SET status = $1 WHERE id = $2 RETURNING *`,
    [status, id]
  );
  return rows[0] ?? null;
}

export async function deleteDispatchUnit(id: string) {
  await query(`DELETE FROM dispatch_units WHERE id = $1`, [id]);
}

export async function getAnalytics() {
  let barangayRows: any[] = [];
  try {
    const barangayRes = await query(`SELECT b.name, COUNT(i.id) as count
           FROM barangays b
           LEFT JOIN incidents i ON i.barangay_id = b.id
           GROUP BY b.name, b.sort_order
           ORDER BY b.sort_order`);
    barangayRows = barangayRes.rows;
  } catch (e) {
    console.error("[admin.repo] barangayBreakdown query error:", e);
  }

  const [statusRes, typeRes, totalUsersRes, totalIncidentsRes] = await Promise.all([
    query(`SELECT status, COUNT(*) as count FROM incidents GROUP BY status`).catch(() => ({ rows: [] })),
    query(`SELECT type, COUNT(*) as count FROM incidents GROUP BY type`).catch(() => ({ rows: [] })),
    query(`SELECT COUNT(*) as count FROM users`).catch(() => ({ rows: [{ count: "0" }] })),
    query(`SELECT COUNT(*) as count FROM incidents`).catch(() => ({ rows: [{ count: "0" }] })),
  ]);

  return {
    statusBreakdown: statusRes.rows,
    typeBreakdown: typeRes.rows,
    totalUsers: parseInt(totalUsersRes.rows[0]?.count ?? "0", 10),
    totalIncidents: parseInt(totalIncidentsRes.rows[0]?.count ?? "0", 10),
    barangayBreakdown: barangayRows,
  };
}
