import { query } from "../../db/index.js";
import fs from "fs/promises";
import path from "path";
import { config } from "../common/config.js";

export interface MediaRow {
  id: string;
  incident_id: string | null;
  type: string;
  url: string;
  active: boolean;
}

export async function createPending(input: {
  type: string;
  url: string;
}): Promise<MediaRow> {
  const { rows } = await query<MediaRow>(
    `INSERT INTO media (type, url) VALUES ($1,$2) RETURNING id, incident_id, type, url, active`,
    [input.type, input.url]
  );
  return rows[0];
}

export async function saveFileLocally(
  buffer: Buffer,
  filename: string
): Promise<string> {
  const uploadsDir = path.resolve(config.s3.endpoint || ".", "public", "uploads");
  await fs.mkdir(uploadsDir, { recursive: true });
  const fullPath = path.join(uploadsDir, filename);
  await fs.writeFile(fullPath, buffer);
  return `/public/uploads/${filename}`;
}

export async function confirm(id: string): Promise<void> {
  await query(`UPDATE media SET active = true WHERE id = $1`, [id]);
}
