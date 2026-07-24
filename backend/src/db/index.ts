import { Pool, PoolClient } from "pg";
import { config } from "../modules/common/config.js";

export const pool = new Pool({
  host: config.pg.host,
  port: config.pg.port,
  database: config.pg.database,
  user: config.pg.user,
  password: config.pg.password,
});

pool.on("error", (err) => {
  console.error("[pg] unexpected error on idle client", err);
});

export async function query<T = any>(
  text: string,
  params?: any[]
): Promise<{ rows: T[]; rowCount: number | null }> {
  const res = await pool.query(text, params);
  return { rows: res.rows as T[], rowCount: res.rowCount };
}

export async function withClient<T>(fn: (client: PoolClient) => Promise<T>): Promise<T> {
  const client = await pool.connect();
  try {
    return await fn(client);
  } finally {
    client.release();
  }
}
