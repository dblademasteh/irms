CREATE TABLE IF NOT EXISTS incident_chats (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID REFERENCES incidents(id) ON DELETE CASCADE,
  sender_id   TEXT REFERENCES users(id) ON DELETE SET NULL,
  sender_name TEXT NOT NULL,
  sender_role TEXT NOT NULL CHECK (sender_role IN ('citizen', 'dispatcher', 'admin', 'system', 'ai')),
  message     TEXT NOT NULL,
  is_ai       BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_incident_chats_incident ON incident_chats(incident_id, created_at ASC);
