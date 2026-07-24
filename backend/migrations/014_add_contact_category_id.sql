ALTER TABLE emergency_contacts ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES contact_categories(id) ON DELETE SET NULL;
