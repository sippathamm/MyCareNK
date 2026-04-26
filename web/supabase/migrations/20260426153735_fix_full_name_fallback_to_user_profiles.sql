-- Fix: full_name fallback should show 'ผู้ใช้' for user-initiated actions instead of 'ระบบ'
-- Affects get_request_status_log (both overloads) and get_audit_log (both overloads)
-- user_profiles has no first_name/last_name; use CASE to detect user vs system

-- get_request_status_log (without p_reference_number)
CREATE OR REPLACE FUNCTION public.get_request_status_log(
  p_performed_by uuid                     DEFAULT NULL::uuid,
  p_from_status  text                     DEFAULT NULL::text,
  p_to_status    text                     DEFAULT NULL::text,
  p_date_from    timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_date_to      timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_limit        integer                  DEFAULT 50,
  p_offset       integer                  DEFAULT 0
)
RETURNS TABLE(
  id           uuid,
  request_id   uuid,
  performed_by uuid,
  full_name    text,
  from_status  text,
  to_status    text,
  changed_at   timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT is_superadmin() THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;

  RETURN QUERY
  SELECT
    rsl.id,
    rsl.request_id,
    rsl.changed_by                                              AS performed_by,
    CASE
      WHEN sp.user_id IS NOT NULL THEN sp.first_name || ' ' || sp.last_name
      WHEN up.user_id IS NOT NULL THEN 'ผู้ใช้'
      ELSE 'ระบบ'
    END                                                         AS full_name,
    rsl.from_status::text,
    rsl.to_status::text,
    rsl.changed_at
  FROM request_status_logs rsl
  LEFT JOIN staff_profiles sp ON sp.user_id = rsl.changed_by
  LEFT JOIN user_profiles  up ON up.user_id = rsl.changed_by
  WHERE
    (p_performed_by IS NULL OR rsl.changed_by         = p_performed_by)
    AND (p_from_status  IS NULL OR rsl.from_status::text = p_from_status)
    AND (p_to_status    IS NULL OR rsl.to_status::text   = p_to_status)
    AND (p_date_from    IS NULL OR rsl.changed_at       >= p_date_from)
    AND (p_date_to      IS NULL OR rsl.changed_at       <= p_date_to)
  ORDER BY rsl.changed_at DESC
  LIMIT  p_limit
  OFFSET p_offset;
END;
$$;

-- get_request_status_log (with p_reference_number)
CREATE OR REPLACE FUNCTION public.get_request_status_log(
  p_performed_by     uuid                     DEFAULT NULL::uuid,
  p_from_status      text                     DEFAULT NULL::text,
  p_to_status        text                     DEFAULT NULL::text,
  p_reference_number text                     DEFAULT NULL::text,
  p_date_from        timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_date_to          timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_limit            integer                  DEFAULT 50,
  p_offset           integer                  DEFAULT 0
)
RETURNS TABLE(
  id               uuid,
  request_id       uuid,
  reference_number text,
  performed_by     uuid,
  full_name        text,
  from_status      text,
  to_status        text,
  changed_at       timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.staff_profiles WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;

  RETURN QUERY
  SELECT
    rsl.id,
    rsl.request_id,
    cr.reference_number,
    rsl.changed_by                                              AS performed_by,
    CASE
      WHEN sp.user_id IS NOT NULL THEN sp.first_name || ' ' || sp.last_name
      WHEN up.user_id IS NOT NULL THEN 'ผู้ใช้'
      ELSE 'ระบบ'
    END                                                         AS full_name,
    rsl.from_status::text,
    rsl.to_status::text,
    rsl.changed_at
  FROM request_status_logs rsl
  LEFT JOIN staff_profiles  sp ON sp.user_id = rsl.changed_by
  LEFT JOIN user_profiles   up ON up.user_id = rsl.changed_by
  LEFT JOIN condom_requests  cr ON cr.id     = rsl.request_id
  WHERE
    (p_performed_by     IS NULL OR rsl.changed_by              = p_performed_by)
    AND (p_from_status  IS NULL OR rsl.from_status::text       = p_from_status)
    AND (p_to_status    IS NULL OR rsl.to_status::text         = p_to_status)
    AND (p_reference_number IS NULL OR cr.reference_number ILIKE '%' || p_reference_number || '%')
    AND (p_date_from    IS NULL OR rsl.changed_at             >= p_date_from)
    AND (p_date_to      IS NULL OR rsl.changed_at             <= p_date_to)
  ORDER BY rsl.changed_at DESC
  LIMIT  p_limit
  OFFSET p_offset;
END;
$$;

-- get_audit_log (without p_target_id)
CREATE OR REPLACE FUNCTION public.get_audit_log(
  p_performed_by uuid                     DEFAULT NULL::uuid,
  p_action       audit_action             DEFAULT NULL::audit_action,
  p_target_table text                     DEFAULT NULL::text,
  p_date_from    timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_date_to      timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_limit        integer                  DEFAULT 50,
  p_offset       integer                  DEFAULT 0
)
RETURNS TABLE(
  id               uuid,
  performed_by     uuid,
  full_name        text,
  action           audit_action,
  target_table     text,
  target_id        uuid,
  target_full_name text,
  old_value        jsonb,
  new_value        jsonb,
  created_at       timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT is_superadmin() THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;

  RETURN QUERY
  SELECT
    al.id,
    al.performed_by,
    CASE
      WHEN sp.user_id IS NOT NULL THEN sp.first_name || ' ' || sp.last_name
      WHEN up.user_id IS NOT NULL THEN 'ผู้ใช้'
      ELSE 'ระบบ'
    END                                                         AS full_name,
    al.action,
    al.target_table,
    al.target_id,
    COALESCE(
      tsp.first_name || ' ' || tsp.last_name,
      NULLIF(TRIM(
        COALESCE(al.new_value->>'first_name', '') || ' ' ||
        COALESCE(al.new_value->>'last_name',  '')
      ), ' '),
      NULLIF(TRIM(
        COALESCE(al.old_value->>'first_name', '') || ' ' ||
        COALESCE(al.old_value->>'last_name',  '')
      ), ' ')
    )                                                           AS target_full_name,
    al.old_value,
    al.new_value,
    al.created_at
  FROM audit_logs al
  LEFT JOIN staff_profiles sp  ON sp.user_id  = al.performed_by
  LEFT JOIN user_profiles  up  ON up.user_id  = al.performed_by
  LEFT JOIN staff_profiles tsp ON tsp.user_id = al.target_id
  WHERE
    (p_performed_by IS NULL OR al.performed_by  = p_performed_by)
    AND (p_action        IS NULL OR al.action       = p_action)
    AND (p_target_table  IS NULL OR al.target_table = p_target_table)
    AND (p_date_from     IS NULL OR al.created_at  >= p_date_from)
    AND (p_date_to       IS NULL OR al.created_at  <= p_date_to)
  ORDER BY al.created_at DESC
  LIMIT  p_limit
  OFFSET p_offset;
END;
$$;

-- get_audit_log (with p_target_id)
CREATE OR REPLACE FUNCTION public.get_audit_log(
  p_performed_by uuid                     DEFAULT NULL::uuid,
  p_action       audit_action             DEFAULT NULL::audit_action,
  p_target_table text                     DEFAULT NULL::text,
  p_target_id    text                     DEFAULT NULL::text,
  p_date_from    timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_date_to      timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_limit        integer                  DEFAULT 50,
  p_offset       integer                  DEFAULT 0
)
RETURNS TABLE(
  id               uuid,
  performed_by     uuid,
  full_name        text,
  action           audit_action,
  target_table     text,
  target_id        uuid,
  target_full_name text,
  old_value        jsonb,
  new_value        jsonb,
  created_at       timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT is_superadmin() THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;

  RETURN QUERY
  SELECT
    al.id,
    al.performed_by,
    CASE
      WHEN sp.user_id IS NOT NULL THEN sp.first_name || ' ' || sp.last_name
      WHEN up.user_id IS NOT NULL THEN 'ผู้ใช้'
      ELSE 'ระบบ'
    END                                                         AS full_name,
    al.action,
    al.target_table,
    al.target_id,
    COALESCE(
      tsp.first_name || ' ' || tsp.last_name,
      NULLIF(TRIM(
        COALESCE(al.new_value->>'first_name', '') || ' ' ||
        COALESCE(al.new_value->>'last_name',  '')
      ), ' '),
      NULLIF(TRIM(
        COALESCE(al.old_value->>'first_name', '') || ' ' ||
        COALESCE(al.old_value->>'last_name',  '')
      ), ' ')
    )                                                           AS target_full_name,
    al.old_value,
    al.new_value,
    al.created_at
  FROM audit_logs al
  LEFT JOIN staff_profiles sp  ON sp.user_id  = al.performed_by
  LEFT JOIN user_profiles  up  ON up.user_id  = al.performed_by
  LEFT JOIN staff_profiles tsp ON tsp.user_id = al.target_id
  WHERE
    (p_performed_by IS NULL OR al.performed_by             = p_performed_by)
    AND (p_action       IS NULL OR al.action               = p_action)
    AND (p_target_table IS NULL OR al.target_table         = p_target_table)
    AND (p_target_id    IS NULL OR al.target_id::text ILIKE '%' || p_target_id || '%')
    AND (p_date_from    IS NULL OR al.created_at          >= p_date_from)
    AND (p_date_to      IS NULL OR al.created_at          <= p_date_to)
  ORDER BY al.created_at DESC
  LIMIT  p_limit
  OFFSET p_offset;
END;
$$;
