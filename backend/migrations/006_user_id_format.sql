-- 1. Drop foreign key constraints that reference users(id)
ALTER TABLE incidents DROP CONSTRAINT IF EXISTS incidents_reporter_id_fkey;
ALTER TABLE incidents DROP CONSTRAINT IF EXISTS incidents_dispatcher_id_fkey;
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
ALTER TABLE action_log DROP CONSTRAINT IF EXISTS action_log_actor_id_fkey;
ALTER TABLE broadcasts DROP CONSTRAINT IF EXISTS broadcasts_author_id_fkey;

-- 2. Alter columns from UUID to TEXT
ALTER TABLE users ALTER COLUMN id TYPE TEXT USING id::text;
ALTER TABLE incidents ALTER COLUMN reporter_id TYPE TEXT USING reporter_id::text;
ALTER TABLE incidents ALTER COLUMN dispatcher_id TYPE TEXT USING dispatcher_id::text;
ALTER TABLE notifications ALTER COLUMN user_id TYPE TEXT USING user_id::text;
ALTER TABLE action_log ALTER COLUMN actor_id TYPE TEXT USING actor_id::text;

-- 3. Re-add foreign key constraints with CASCADE
ALTER TABLE incidents ADD CONSTRAINT incidents_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES users(id) ON UPDATE CASCADE;
ALTER TABLE incidents ADD CONSTRAINT incidents_dispatcher_id_fkey FOREIGN KEY (dispatcher_id) REFERENCES users(id) ON UPDATE CASCADE;
ALTER TABLE notifications ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE;
ALTER TABLE action_log ADD CONSTRAINT action_log_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES users(id) ON UPDATE CASCADE;
ALTER TABLE broadcasts ADD CONSTRAINT broadcasts_author_id_fkey FOREIGN KEY (author_id) REFERENCES users(id) ON UPDATE CASCADE;

-- 4. Create sequence for the numeric portion of the ID
CREATE SEQUENCE IF NOT EXISTS user_id_seq START 10000;

-- 5. Set default value for users.id
ALTER TABLE users ALTER COLUMN id DROP DEFAULT;
ALTER TABLE users ALTER COLUMN id SET DEFAULT (to_char(now(), 'YYYY') || '-' || nextval('user_id_seq')::text);

-- 6. Update existing admin account to use the new ID format
UPDATE users SET id = (to_char(now(), 'YYYY') || '-' || nextval('user_id_seq')::text);
