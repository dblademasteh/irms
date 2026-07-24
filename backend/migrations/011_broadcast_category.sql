DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'broadcasts' AND column_name = 'category'
  ) THEN
    ALTER TABLE broadcasts ADD COLUMN category TEXT CHECK (category IN ('emergency', 'system', 'safety')) DEFAULT 'emergency';
  END IF;
END $$;
