-- FrameFlow Day 37: authenticated self-delete (client-safe; no service role in app)
-- Deletes auth.users for auth.uid(); ON DELETE CASCADE removes public.users → subscriptions.

CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.delete_user() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated;

COMMENT ON FUNCTION public.delete_user() IS
  'Authenticated user deletes own auth.users row; CASCADE cleans public.users/subscriptions.';
