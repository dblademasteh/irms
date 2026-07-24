-- IRMS Phase 1 schema (subset of full ERD)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  email         TEXT UNIQUE,
  phone         TEXT,
  password_hash TEXT,
  role          TEXT NOT NULL CHECK (role IN ('reporter','dispatcher','admin')),
  invite_code   TEXT,
  lang          TEXT DEFAULT 'en',
  fcm_token     TEXT,
  apns_token    TEXT,
  created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS incidents (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id   UUID REFERENCES users(id),
  dispatcher_id UUID REFERENCES users(id),
  type          TEXT NOT NULL CHECK (type IN
                  ('fire','accident','crime','medical','natural_disaster','infrastructure')),
  title         TEXT NOT NULL,
  description   TEXT,
  severity      TEXT DEFAULT 'medium' CHECK (severity IN ('low','medium','high','critical')),
  status        TEXT DEFAULT 'submitted' CHECK (status IN
                  ('submitted','under_review','verified','rejected','resolved')),
  latitude      DOUBLE PRECISION,
  longitude     DOUBLE PRECISION,
  address       TEXT,
  is_anonymous  BOOLEAN DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_incidents_status_created ON incidents(status, created_at);
CREATE INDEX IF NOT EXISTS idx_incidents_reporter ON incidents(reporter_id);

CREATE TABLE IF NOT EXISTS media (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID REFERENCES incidents(id) ON DELETE CASCADE,
  type        TEXT DEFAULT 'photo',
  url         TEXT NOT NULL,
  active      BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_media_incident ON media(incident_id);

CREATE TABLE IF NOT EXISTS notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id),
  incident_id UUID REFERENCES incidents(id),
  title       TEXT,
  body        TEXT,
  is_read     BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, is_read);

CREATE TABLE IF NOT EXISTS action_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID REFERENCES incidents(id),
  actor_id    UUID REFERENCES users(id),
  action      TEXT CHECK (action IN ('created','verified','rejected','resolved')),
  notes       TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_actionlog_incident ON action_log(incident_id);