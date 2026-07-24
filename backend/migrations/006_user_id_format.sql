-- 1. Drop foreign key constraints that reference users(id)
ALTER TABLE incidents DROP CONSTRAINT IF EXISTS incidents_reporter_id_fkey;
ALTER TABLE incidents DROP CONSTRAINT IF EXISTS incidents_dispatcher_id_fkey;
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
ALTER TABLE action_log DROP CONSTRAINT IF EXISTS action_log_actor_id_fkey;
ALTER TABLE broadcasts DROP CONSTRAINT IF EXISTS broadcasts_author_id_fkey;
ALTER TABLE chats DROP CONSTRAINT IF EXISTS chats_user_id_fkey;
ALTER TABLE api_keys DROP CONSTRAINT IF EXISTS api_keys_user_id_fkey;

-- 2. Alter columns from UUID to TEXT
ALTER TABLE users ALTER COLUMN id TYPE TEXT USING id::text;
ALTER TABLE incidents ALTER COLUMN reporter_id TYPE TEXT USING reporter_id::text;
ALTER TABLE incidents ALTER COLUMN dispatcher_id TYPE TEXT USING dispatcher_id::text;
ALTER TABLE notifications ALTER COLUMN user_id TYPE TEXT USING user_id::text;
ALTER TABLE action_log ALTER COLUMN actor_id TYPE TEXT USING actor_id::text;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'broadcasts' AND column_name = 'author_id') THEN
    ALTER TABLE broadcasts ALTER COLUMN author_id TYPE TEXT USING author_id::text;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chats' AND column_name = 'user_id') THEN
    ALTER TABLE chats ALTER COLUMN user_id TYPE TEXT USING user_id::text;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'api_keys' AND column_name = 'user_id') THEN
    ALTER TABLE api_keys ALTER COLUMN user_id TYPE TEXT USING user_id::text;
  END IF;
END $$;

-- 3. Re-add foreign key constraints with CASCADE
ALTER TABLE incidents ADD CONSTRAINT incidents_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES users(id) ON UPDATE CASCADE;
ALTER TABLE incidents ADD CONSTRAINT incidents_dispatcher_id_fkey FOREIGN KEY (dispatcher_id) REFERENCES users(id) ON UPDATE CASCADE;
ALTER TABLE notifications ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE;
ALTER TABLE action_log ADD CONSTRAINT action_log_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES users(id) ON UPDATE CASCADE;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'broadcasts') THEN
    ALTER TABLE broadcasts ADD CONSTRAINT broadcasts_author_id_fkey FOREIGN KEY (author_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chats') THEN
    ALTER TABLE chats ADD CONSTRAINT chats_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'api_keys') THEN
    ALTER TABLE api_keys ADD CONSTRAINT api_keys_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;
  END IF;
END $$;

-- 4. Create sequence for the numeric portion of the ID
CREATE SEQUENCE IF NOT EXISTS user_id_seq START 10000;

-- 5. Set default value for users.id
ALTER TABLE users ALTER COLUMN id DROP DEFAULT;
ALTER TABLE users ALTER COLUMN id SET DEFAULT (to_char(now(), 'YYYY') || '-' || nextval('user_id_seq')::text);

-- 6. Update existing admin/user accounts to use the new ID format (skip already formatted IDs)
UPDATE users SET id = (to_char(now(), 'YYYY') || '-' || nextval('user_id_seq')::text) WHERE id !~ '^\d{4}-\d+$';
