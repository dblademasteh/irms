import { query } from "./src/db/index.js";
import { hashPassword } from "./src/modules/common/password.js";

async function main() {
  const email = "admin@irms.local";
  const name = "System Admin";
  const newPassword = "admin123";
  const role = "admin";
  
  const hashed = await hashPassword(newPassword);
  
  // Try UPDATE first
  const { rowCount } = await query(
    "UPDATE users SET password_hash = $1, role = $2 WHERE email = $3",
    [hashed, role, email]
  );
  
  if (rowCount === 1) {
    console.log(`Updated admin: ${email} / ${newPassword}`);
  } else {
    // INSERT if not found
    try {
      await query(
        "INSERT INTO users (name, email, password_hash, role, lang) VALUES ($1, $2, $3, $4, $5)",
        [name, email, hashed, role, "en"]
      );
      console.log(`Created admin: ${email} / ${newPassword}`);
    } catch (err: any) {
      if (err?.code === "23505") { // unique violation
        console.log(`Admin ${email} already exists but password was not updated. Use reset_pwd.ts for existing users.`);
      } else {
        throw err;
      }
    }
  }
  process.exit(0);
}

main();