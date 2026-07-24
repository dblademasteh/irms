import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { pool } from "./index.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function main() {
  const dir = path.resolve(__dirname, "../../migrations");
  const files = fs
    .readdirSync(dir)
    .filter((f) => f.endsWith(".sql"))
    .sort();

  for (const file of files) {
    const sql = fs.readFileSync(path.join(dir, file), "utf8");
    console.log(`[migrate] applying ${file}`);
    await pool.query(sql);
  }
  console.log("[migrate] done");
  await pool.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
