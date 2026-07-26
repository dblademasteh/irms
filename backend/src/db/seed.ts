import { pool } from "./index.js";
import { hashPassword } from "../modules/common/password.js";
import { query } from "../db/index.js";

async function waitForDb(maxRetries = 15, delayMs = 2000) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await pool.query("SELECT 1;");
      console.log("[seed] Connected to PostgreSQL database successfully.");
      return;
    } catch (err: any) {
      console.log(`[seed] Waiting for database (attempt ${attempt}/${maxRetries}): ${err.message}`);
      if (attempt === maxRetries) {
        throw err;
      }
      await new Promise((res) => setTimeout(res, delayMs));
    }
  }
}

async function main() {
  await waitForDb();

  const email = "admin@irms.local";
  const { rows } = await query<{ n: number }>(
    `SELECT 1 AS n FROM users WHERE email = $1 LIMIT 1`,
    [email]
  );

  if (rows.length > 0) {
    console.log("[seed] Admin user already exists, skipping.");
    await pool.end();
    return;
  }

  const passwordHash = await hashPassword("admin123");
  await query(
    `INSERT INTO users (name, email, password_hash, role, lang)
     VALUES ($1, $2, $3, $4, $5)`,
    ["System Admin", email, passwordHash, "admin", "en"]
  );

  console.log("[seed] Admin user created: admin@irms.local / admin123");
  await pool.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});