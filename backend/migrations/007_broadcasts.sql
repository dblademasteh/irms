DROP INDEX IF EXISTS idx_broadcasts_created_at;

CREATE TABLE IF NOT EXISTS broadcasts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id    TEXT REFERENCES users(id),
  author_name  TEXT NOT NULL,
  message      TEXT NOT NULL,
  target_role  TEXT CHECK (target_role IN ('all', 'dispatchers', 'reporters')) DEFAULT 'all',
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_broadcasts_created_at ON broadcasts(created_at DESC);
