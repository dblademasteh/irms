import { query } from "../../db/index.js";

export interface CategoryRow {
  id: string;
  name: string;
  icon: string;
  color: string;
  sort_order: number;
  created_at: string;
}

const COLS = "id, name, icon, color, sort_order, created_at";

export async function listCategories(): Promise<CategoryRow[]> {
  const { rows } = await query<CategoryRow>(
    `SELECT ${COLS} FROM contact_categories ORDER BY sort_order ASC, name ASC`
  );
  return rows;
}

export async function createCategory(
  name: string,
  icon: string,
  color: string,
  sortOrder: number
): Promise<CategoryRow> {
  const { rows } = await query<CategoryRow>(
    `INSERT INTO contact_categories (name, icon, color, sort_order) VALUES ($1, $2, $3, $4) RETURNING ${COLS}`,
    [name, icon, color, sortOrder]
  );
  return rows[0];
}

export async function updateCategory(
  id: string,
  name: string,
  icon: string,
  color: string,
  sortOrder: number
): Promise<CategoryRow | null> {
  const { rows } = await query<CategoryRow>(
    `UPDATE contact_categories SET name = $1, icon = $2, color = $3, sort_order = $4 WHERE id = $5 RETURNING ${COLS}`,
    [name, icon, color, sortOrder, id]
  );
  return rows[0] ?? null;
}

export async function deleteCategory(id: string): Promise<boolean> {
  const { rowCount } = await query(`DELETE FROM contact_categories WHERE id = $1`, [id]);
  return (rowCount ?? 0) > 0;
}
