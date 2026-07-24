-- Add tracking_code for anonymous/public incident reporting
ALTER TABLE incidents ADD COLUMN IF NOT EXISTS tracking_code TEXT UNIQUE;

-- Generate tracking codes for existing incidents
UPDATE incidents SET tracking_code = upper(
  substr(md5(random()::text), 1, 4) || '-' || substr(md5(random()::text), 1, 4)
) WHERE tracking_code IS NULL;

-- Make tracking_code NOT NULL after backfill
ALTER TABLE incidents ALTER COLUMN tracking_code SET NOT NULL;

-- Unique index for fast lookups
CREATE INDEX IF NOT EXISTS idx_incidents_tracking_code ON incidents(tracking_code);