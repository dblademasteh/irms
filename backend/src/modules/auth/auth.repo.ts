import { query, withClient } from "../../db/index.js";
import { hashPassword, verifyPassword } from "../common/password.js";

export interface UserRow {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  address: string | null;
  role: string;
  lang: string;
}

const USER_COLS = "id, name, email, phone, role, lang, address";

export async function createUser(input: {
  name: string;
  email?: string;
  phone?: string;
  address?: string;
  passwordHash?: string;
  role: string;
  inviteCode?: string;
  lang?: string;
}): Promise<UserRow> {
  const { rows } = await query<UserRow>(
    `INSERT INTO users (name, email, phone, password_hash, role, invite_code, lang, address)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING ${USER_COLS}`,
    [
      input.name,
      input.email ?? null,
      input.phone ?? null,
      input.passwordHash,
      input.role,
      input.inviteCode ?? null,
      input.lang ?? "en",
      input.address ?? null,
    ]
  );
  return rows[0];
}

export async function findByEmail(
  email: string
): Promise<(UserRow & { password_hash: string }) | null> {
  const { rows } = await query<{ password_hash: string } & UserRow>(
    `SELECT ${USER_COLS}, password_hash FROM users WHERE email = $1`,
    [email]
  );
  return rows[0] ?? null;
}

export async function findById(id: string): Promise<UserRow | null> {
  const { rows } = await query<UserRow>(
    `SELECT ${USER_COLS} FROM users WHERE id = $1`,
    [id]
  );
  return rows[0] ?? null;
}

export async function emailExists(email: string): Promise<boolean> {
  const { rows } = await query<{ n: number }>(
    `SELECT 1 AS n FROM users WHERE email = $1 LIMIT 1`,
    [email]
  );
  return rows.length > 0;
}

export async function storeDeviceToken(
  userId: string,
  token: string,
  kind: "fcm" | "apns"
): Promise<void> {
  const col = kind === "fcm" ? "fcm_token" : "apns_token";
  await query(`UPDATE users SET ${col} = $1 WHERE id = $2`, [token, userId]);
}

export async function updateUser(
  id: string,
  input: { name?: string; phone?: string; address?: string }
): Promise<UserRow | null> {
  const updates: string[] = [];
  const vals: any[] = [];
  let idx = 1;
  if (input.name !== undefined) {
    updates.push(`name = $${idx++}`);
    vals.push(input.name);
  }
  if (input.phone !== undefined) {
    updates.push(`phone = $${idx++}`);
    vals.push(input.phone);
  }
  if (input.address !== undefined) {
    updates.push(`address = $${idx++}`);
    vals.push(input.address);
  }
  if (!updates.length) return findById(id);
  vals.push(id);
  const { rows } = await query<UserRow>(
    `UPDATE users SET ${updates.join(", ")} WHERE id = $${idx} RETURNING ${USER_COLS}`,
    vals
  );
  return rows[0] ?? null;
}

export async function findByIdWithPassword(id: string): Promise<(UserRow & { password_hash: string }) | null> {
  const { rows } = await query<{ password_hash: string } & UserRow>(
    `SELECT ${USER_COLS}, password_hash FROM users WHERE id = $1`,
    [id]
  );
  return rows[0] ?? null;
}

export async function updateUserPassword(id: string, passwordHash: string): Promise<void> {
  await query(`UPDATE users SET password_hash = $1 WHERE id = $2`, [passwordHash, id]);
}

export async function save2FaSecret(userId: string, secret: string): Promise<void> {
  await query(`UPDATE users SET two_factor_secret = $1 WHERE id = $2`, [secret, userId]);
}

export async function enable2Fa(userId: string): Promise<void> {
  await query(`UPDATE users SET two_factor_enabled = true WHERE id = $1`, [userId]);
}

export async function disable2Fa(userId: string): Promise<void> {
  await query(`UPDATE users SET two_factor_enabled = false, two_factor_secret = NULL WHERE id = $1`, [userId]);
}

export async function get2FaInfo(userId: string): Promise<{ two_factor_enabled: boolean; two_factor_secret: string | null } | null> {
  const { rows } = await query<{ two_factor_enabled: boolean; two_factor_secret: string | null }>(
    `SELECT COALESCE(two_factor_enabled, false) AS two_factor_enabled, two_factor_secret FROM users WHERE id = $1`,
    [userId]
  );
  return rows[0] ?? null;
}

export async function findByPhone(
  phone: string
): Promise<(UserRow & { password_hash: string }) | null> {
  const { rows } = await query<{ password_hash: string } & UserRow>(
    `SELECT ${USER_COLS}, password_hash FROM users WHERE phone = $1`,
    [phone]
  );
  return rows[0] ?? null;
}

export async function findDispatchers(): Promise<UserRow[]> {
  const { rows } = await query<UserRow>(
    `SELECT ${USER_COLS} FROM users WHERE role IN ('dispatcher','admin')`
  );
  return rows;
}

export { hashPassword, verifyPassword, withClient };
