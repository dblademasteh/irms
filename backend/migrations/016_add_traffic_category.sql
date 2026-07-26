-- Add traffic, earthquake, flood, tsunami, weather as valid broadcast categories
ALTER TABLE broadcasts DROP CONSTRAINT IF EXISTS broadcasts_category_check;
ALTER TABLE broadcasts ADD CONSTRAINT broadcasts_category_check CHECK (category IN ('emergency', 'system', 'safety', 'traffic', 'earthquake', 'flood', 'tsunami', 'weather'));