-- Fix get_staff_audit_log: the JOIN was matching tsp.staff_user_id = al.target_id
-- but target_id stores staff_profiles.id (internal PK), not staff_user_id.
-- Also adds target_staff_user_id (auth UUID) to the result set.
DROP FUNCTION IF EXISTS public.get_staff_audit_log(uuid,text,text,timestamp with time zone,timestamp with time zone,integer,integer);

CREATE FUNCTION public.get_staff_audit_log(
  p_performed_by uuid DEFAULT NULL,
  p_action       text DEFAULT NULL,
  p_target_id    text DEFAULT NULL,
  p_date_from    timestamp with time zone DEFAULT NULL,
  p_date_to      timestamp with time zone DEFAULT NULL,
  p_limit        integer DEFAULT 50,
  p_offset       integer DEFAULT 0
)
RETURNS TABLE(
  id                   uuid,
  performed_by         uuid,
  full_name            text,
  action               audit_action,
  target_id            uuid,
  target_staff_user_id uuid,
  target_full_name     text,
  old_value            jsonb,
  new_value            jsonb,
  created_at           timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT is_superadmin() THEN RAISE EXCEPTION 'Permission denied'; END IF;
  RETURN QUERY
  SELECT
    al.id,
    al.performed_by,
    COALESCE(sp.first_name || ' ' || sp.last_name, 'ระบบ'),
    al.action,
    al.target_id,
    tsp.staff_user_id,
    COALESCE(
      tsp.first_name || ' ' || tsp.last_name,
      NULLIF(TRIM(COALESCE(al.new_value->>'first_name','') || ' ' || COALESCE(al.new_value->>'last_name','')), ' '),
      NULLIF(TRIM(COALESCE(al.old_value->>'first_name','') || ' ' || COALESCE(al.old_value->>'last_name','')), ' ')
    ),
    al.old_value,
    al.new_value,
    al.created_at
  FROM public.staff_audit_logs al
  LEFT JOIN staff_profiles sp  ON sp.staff_user_id = al.performed_by
  LEFT JOIN staff_profiles tsp ON tsp.id = al.target_id
  WHERE (p_performed_by IS NULL OR al.performed_by = p_performed_by)
    AND (p_action     IS NULL OR al.action::text = p_action)
    AND (p_target_id  IS NULL OR tsp.staff_user_id::text ILIKE '%' || p_target_id || '%')
    AND (p_date_from  IS NULL OR al.created_at >= p_date_from)
    AND (p_date_to    IS NULL OR al.created_at <= p_date_to)
  ORDER BY al.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;
