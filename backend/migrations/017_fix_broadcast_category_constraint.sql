-- 017_fix_broadcast_category_constraint.sql
-- Fix broadcasts category CHECK to allow all supported categories
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'broadcasts' AND column_name = 'category'
  ) THEN
    ALTER TABLE broadcasts DROP CONSTRAINT IF EXISTS broadcasts_category_check;
    ALTER TABLE broadcasts ADD CONSTRAINT broadcasts_category_check
      CHECK (category IN ('emergency', 'system', 'safety', 'traffic', 'earthquake', 'flood', 'tsunami', 'weather'));
  END IF;
END $$;