CREATE TABLE IF NOT EXISTS barangays (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  psgc_code   TEXT,
  is_urban    BOOLEAN DEFAULT false,
  sort_order  INTEGER DEFAULT 0
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'incidents' AND column_name = 'barangay_id'
  ) THEN
    ALTER TABLE incidents ADD COLUMN barangay_id UUID REFERENCES barangays(id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_incidents_barangay ON incidents(barangay_id);
