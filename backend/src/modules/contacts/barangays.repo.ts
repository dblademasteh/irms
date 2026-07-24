import { query } from "../../db/index.js";

export interface BarangayRow {
  id: string;
  name: string;
  psgc_code: string | null;
  is_urban: boolean;
  sort_order: number;
}

const COLS = "id, name, psgc_code, is_urban, sort_order";

export async function listBarangays(): Promise<BarangayRow[]> {
  const { rows } = await query<BarangayRow>(
    `SELECT ${COLS} FROM barangays ORDER BY sort_order`
  );
  return rows;
}

export async function createBarangay(name: string, psgcCode?: string, isUrban?: boolean, sortOrder?: number): Promise<BarangayRow> {
  const { rows } = await query<BarangayRow>(
    `INSERT INTO barangays (name, psgc_code, is_urban, sort_order) VALUES ($1, $2, $3, $4) RETURNING ${COLS}`,
    [name, psgcCode ?? null, isUrban ?? false, sortOrder ?? 0]
  );
  return rows[0];
}

export async function updateBarangay(id: string, name: string, psgcCode?: string, isUrban?: boolean, sortOrder?: number): Promise<BarangayRow | null> {
  const { rows } = await query<BarangayRow>(
    `UPDATE barangays SET name = $2, psgc_code = $3, is_urban = $4, sort_order = $5 WHERE id = $1 RETURNING ${COLS}`,
    [id, name, psgcCode ?? null, isUrban ?? false, sortOrder ?? 0]
  );
  return rows[0] ?? null;
}

export async function deleteBarangay(id: string): Promise<boolean> {
  const { rowCount } = await query(`DELETE FROM barangays WHERE id = $1`, [id]);
  return (rowCount ?? 0) > 0;
}
