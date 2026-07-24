-- Add 'declined' status to incidents CHECK constraint
ALTER TABLE incidents DROP CONSTRAINT IF EXISTS incidents_status_check;
ALTER TABLE incidents ADD CONSTRAINT incidents_status_check
  CHECK (status IN ('submitted','under_review','verified','rejected','resolved','declined'));

-- Add 'declined' action to action_log CHECK constraint
ALTER TABLE action_log DROP CONSTRAINT IF EXISTS action_log_action_check;
ALTER TABLE action_log ADD CONSTRAINT action_log_action_check
  CHECK (action IN ('created','verified','rejected','resolved','dispatched','claimed','declined'));
