import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { pool } from "./index.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function waitForDb(maxRetries = 15, delayMs = 2000) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await pool.query("SELECT 1;");
      console.log("[migrate] Connected to PostgreSQL database successfully.");
      return;
    } catch (err: any) {
      console.log(`[migrate] Waiting for database (attempt ${attempt}/${maxRetries}): ${err.message}`);
      if (attempt === maxRetries) {
        throw err;
      }
      await new Promise((res) => setTimeout(res, delayMs));
    }
  }
}

async function main() {
  await waitForDb();

  const dir = path.resolve(__dirname, "../../migrations");
  const files = fs
    .readdirSync(dir)
    .filter((f) => f.endsWith(".sql"))
    .sort();

  for (const file of files) {
    const sql = fs.readFileSync(path.join(dir, file), "utf8");
    console.log(`[migrate] applying ${file}`);
    try {
      await pool.query(sql);
    } catch (err: any) {
      if (err.code === "42P07" || err.code === "42701" || err.code === "42710") {
        console.log(`[migrate] skipping ${file}: ${err.code} (${err.message?.split("\n")[0]})`);
      } else {
        console.error(`[migrate] error in ${file}:`, err.message);
        process.exit(1);
      }
    }
  }
  console.log("[migrate] done");
  await pool.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
