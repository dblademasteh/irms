-- Seed default admin user (idempotent — skips if email already exists)
INSERT INTO users (name, email, password_hash, role, lang)
VALUES (
  'System Admin',
  'admin@irms.local',
  '$argon2id$v=19$m=65536,t=3,p=4$77hKP0pi/UFQjIno+jBTEA$jdQTLFSl6TicBvvr8Nw6mxQL1kbPgVKOK7bEHMxim1I',
  'admin',
  'en'
)
ON CONFLICT (email) DO NOTHING;