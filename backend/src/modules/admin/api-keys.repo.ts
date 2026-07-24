import { query } from "../../db/index.js";
import crypto from "crypto";

export interface ApiKeyRow {
  id: string;
  name: string;
  user_id: string;
  created_at: string;
}

export async function listApiKeys(): Promise<ApiKeyRow[]> {
  const { rows } = await query<ApiKeyRow>(
    `SELECT id, name, user_id, created_at FROM api_keys ORDER BY created_at DESC`
  );
  return rows;
}

export async function createApiKey(name: string, userId: string): Promise<{ apiKey: string; key: ApiKeyRow }> {
  const rawKey = `irms_live_${crypto.randomBytes(24).toString("hex")}`;
  const keyHash = crypto.createHash("sha256").update(rawKey).digest("hex");

  const { rows } = await query<ApiKeyRow>(
    `INSERT INTO api_keys (name, key_hash, user_id) VALUES ($1, $2, $3) RETURNING id, name, user_id, created_at`,
    [name, keyHash, userId]
  );

  return { apiKey: rawKey, key: rows[0] };
}

export async function revokeApiKey(id: string): Promise<void> {
  await query(`DELETE FROM api_keys WHERE id = $1`, [id]);
}
