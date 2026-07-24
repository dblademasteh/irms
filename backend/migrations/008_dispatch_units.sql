CREATE TABLE IF NOT EXISTS dispatch_units (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  unit_type   TEXT NOT NULL CHECK (unit_type IN ('fire', 'medical', 'police')),
  status      TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'dispatched', 'maintenance')),
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS incident_units (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id   UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
  unit_id       UUID NOT NULL REFERENCES dispatch_units(id),
  status        TEXT NOT NULL DEFAULT 'dispatched' CHECK (status IN ('dispatched', 'en_route', 'on_scene', 'returned')),
  dispatched_at TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (incident_id, unit_id)
);

ALTER TABLE action_log DROP CONSTRAINT IF EXISTS action_log_action_check;
ALTER TABLE action_log ADD CONSTRAINT action_log_action_check
  CHECK (action IN ('created', 'verified', 'rejected', 'resolved', 'dispatched', 'claimed', 'declined'));
