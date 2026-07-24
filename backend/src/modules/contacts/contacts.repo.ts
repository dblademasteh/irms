import { query } from "../../db/index.js";

export interface ContactRow {
  id: string;
  name: string;
  phone: string;
  department: string;
  category_id: string;
  created_at: string;
  updated_at: string;
}

const COLS = "ec.id, ec.name, ec.phone, ec.department, ec.category_id, ec.created_at, ec.updated_at";

export async function listContacts(): Promise<any[]> {
  try {
    const { rows } = await query(
      `SELECT ec.id, ec.name, ec.phone, ec.department, ec.category_id, ec.created_at, ec.updated_at,
              cc.name AS category_name, cc.icon AS category_icon, cc.color AS category_color
       FROM emergency_contacts ec
       LEFT JOIN contact_categories cc ON cc.id = ec.category_id
       ORDER BY COALESCE(cc.sort_order, 999) ASC, ec.name ASC`
    );
    return rows;
  } catch (err: any) {
    console.error("[contacts.repo] listContacts join query failed, trying basic query:", err);
    try {
      const { rows } = await query(
        `SELECT id, name, phone, department, created_at, updated_at FROM emergency_contacts ORDER BY name ASC`
      );
      return rows;
    } catch (err2: any) {
      console.error("[contacts.repo] listContacts basic query failed:", err2);
      return [];
    }
  }
}

export async function createContact(
  name: string,
  phone: string,
  department: string,
  categoryId: string
): Promise<any> {
  const { rows } = await query(
    `INSERT INTO emergency_contacts (name, phone, department, category_id) VALUES ($1, $2, $3, $4) RETURNING id, name, phone, department, category_id, created_at, updated_at`,
    [name, phone, department, categoryId]
  );
  return rows[0];
}

export async function updateContact(
  id: string,
  name: string,
  phone: string,
  department: string,
  categoryId: string
): Promise<any | null> {
  const { rows } = await query(
    `UPDATE emergency_contacts SET name = $1, phone = $2, department = $3, category_id = $4, updated_at = now() WHERE id = $5 RETURNING id, name, phone, department, category_id, created_at, updated_at`,
    [name, phone, department, categoryId, id]
  );
  return rows[0] ?? null;
}

export async function deleteContact(id: string): Promise<boolean> {
  const { rowCount } = await query(`DELETE FROM emergency_contacts WHERE id = $1`, [id]);
  return (rowCount ?? 0) > 0;
}

export async function batchCreateContacts(
  contacts: { name: string; phone: string; department: string; category_id: string }[]
): Promise<{ imported: number; errors: string[] }> {
  const errors: string[] = [];
  let imported = 0;
  for (let i = 0; i < contacts.length; i++) {
    const c = contacts[i];
    try {
      await query(
        `INSERT INTO emergency_contacts (name, phone, department, category_id) VALUES ($1, $2, $3, $4)`,
        [c.name, c.phone, c.department, c.category_id]
      );
      imported++;
    } catch (e: any) {
      errors.push(`Row ${i + 1} (${c.name}): ${e.message}`);
    }
  }
  return { imported, errors };
}
