-- Allow end-users (@mycarenk.local) to delete their own account.
-- SECURITY DEFINER runs as postgres so it can DELETE from auth.users.
-- The existing BEFORE DELETE trigger (handle_user_deleted) cascades to
-- all related public tables before the auth.users row is removed.

CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  v_user_id := (SELECT auth.uid());
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = v_user_id AND email LIKE '%@mycarenk.local'
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
