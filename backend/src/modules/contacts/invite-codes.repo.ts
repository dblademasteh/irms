import { query } from "../../db/index.js";

export interface InviteCodeRow {
  id: string;
  code: string;
  role: string;
  created_by: string;
  created_by_name: string | null;
  used_by: string | null;
  used_by_name: string | null;
  used_at: string | null;
  expires_at: string | null;
  created_at: string;
}

const BASE_COLS = "ic.id, ic.code, ic.role, ic.created_by, cu.name as created_by_name, ic.used_by, uu.name as used_by_name, ic.used_at, ic.expires_at, ic.created_at";
const SIMPLE_COLS = "id, code, role, created_by, used_by, used_at, expires_at, created_at";

export async function listCodes(): Promise<InviteCodeRow[]> {
  const { rows } = await query<InviteCodeRow>(
    `SELECT ${BASE_COLS} FROM invite_codes ic
     LEFT JOIN users cu ON cu.id = ic.created_by
     LEFT JOIN users uu ON uu.id = ic.used_by
     ORDER BY ic.created_at DESC`
  );
  return rows;
}

export async function createCode(
  code: string,
  role: string,
  createdBy: string,
  expiresAt: string | null
): Promise<InviteCodeRow> {
  const { rows } = await query<InviteCodeRow>(
    `INSERT INTO invite_codes (code, role, created_by, expires_at) VALUES ($1, $2, $3, $4)
     RETURNING id, code, role, created_by, used_by, used_at, expires_at, created_at`,
    [code, role, createdBy, expiresAt]
  );
  const result: InviteCodeRow = { ...rows[0], created_by_name: null, used_by_name: null };
  return result;
}

export async function findByCode(code: string): Promise<InviteCodeRow | null> {
  const { rows } = await query<InviteCodeRow>(
    `SELECT ${SIMPLE_COLS} FROM invite_codes WHERE code = $1`,
    [code]
  );
  return rows[0] ?? null;
}

export async function redeemCode(code: string, userId: string): Promise<boolean> {
  const { rowCount } = await query(
    `UPDATE invite_codes SET used_by = $1, used_at = now() WHERE code = $2 AND used_by IS NULL AND (expires_at IS NULL OR expires_at > now())`,
    [userId, code]
  );
  return (rowCount ?? 0) > 0;
}

export async function deleteCode(id: string): Promise<boolean> {
  const { rowCount } = await query(`DELETE FROM invite_codes WHERE id = $1 AND used_by IS NULL`, [id]);
  return (rowCount ?? 0) > 0;
}
