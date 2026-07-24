ALTER TABLE broadcasts ADD COLUMN category TEXT CHECK (category IN ('emergency', 'system', 'safety')) DEFAULT 'emergency';
