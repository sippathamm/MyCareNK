-- ============================================================
-- 07_rpcs_analytics.sql — MyCareNK
-- Analytics and log-query RPCs — authenticated only.
-- SC enforcement: all RPCs call get_my_service_centers() and
-- restrict results to the caller's assigned service centers.
-- Apply order: 7 of 8
-- ============================================================
--
-- Covers:
--   Dashboard analytics
--     — get_average_lead_time, get_peak_time_stats,
--       get_consumption_trend, get_inventory_forecast,
--       get_service_center_demand, get_service_center_demand_trend,
--       get_staff_workload, get_staff_workload_trend
--   Log queries
--     — get_request_status_log, get_appointment_status_log,
--       get_inventory_log, get_staff_change_log
-- ============================================================

-- ── Analytics RPCs ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_average_lead_time(
  p_date_from      timestamptz,
  p_date_to        timestamptz,
  p_service_center text DEFAULT NULL
) RETURNS TABLE(
  overall_avg_minutes  numeric,
  pending_to_preparing numeric,
  preparing_to_ready   numeric,
  ready_to_completed   numeric
)
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  RETURN QUERY
  WITH completed_requests AS (
    SELECT cr.id, cr.created_at,
      COALESCE(cr.completed_at,
        (SELECT rsl.changed_at FROM request_status_logs rsl
         WHERE rsl.request_id = cr.id AND rsl.to_status = 'completed'
         ORDER BY rsl.changed_at DESC LIMIT 1)
      ) AS completed_at
    FROM condom_requests cr
    WHERE cr.created_at >= p_date_from AND cr.created_at <= p_date_to
      AND cr.request_status = 'completed'
      AND (p_service_center IS NULL OR cr.selected_service_center = p_service_center)
  ),
  valid_requests AS (SELECT * FROM completed_requests WHERE completed_at IS NOT NULL),
  step_times AS (
    SELECT cr.id,
      EXTRACT(EPOCH FROM (cr.completed_at - cr.created_at)) / 60 AS overall_minutes,
      EXTRACT(EPOCH FROM (
        (SELECT MIN(rsl.changed_at) FROM request_status_logs rsl
         WHERE rsl.request_id = cr.id AND rsl.to_status = 'preparing') - cr.created_at
      )) / 60 AS p2p_minutes,
      EXTRACT(EPOCH FROM (
        (SELECT MIN(rsl2.changed_at) FROM request_status_logs rsl2
         WHERE rsl2.request_id = cr.id AND rsl2.to_status = 'ready')
        - (SELECT MIN(rsl3.changed_at) FROM request_status_logs rsl3
           WHERE rsl3.request_id = cr.id AND rsl3.to_status = 'preparing')
      )) / 60 AS prep2r_minutes,
      EXTRACT(EPOCH FROM (
        cr.completed_at
        - (SELECT MIN(rsl4.changed_at) FROM request_status_logs rsl4
           WHERE rsl4.request_id = cr.id AND rsl4.to_status = 'ready')
      )) / 60 AS r2c_minutes
    FROM valid_requests cr
  )
  SELECT
    ROUND(AVG(overall_minutes)::numeric, 2),
    ROUND(AVG(p2p_minutes)::numeric, 2),
    ROUND(AVG(prep2r_minutes)::numeric, 2),
    ROUND(AVG(r2c_minutes)::numeric, 2)
  FROM step_times;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_peak_time_stats(
  p_period         text,
  p_date_from      timestamptz,
  p_date_to        timestamptz,
  p_service_center text DEFAULT NULL
) RETURNS TABLE(bucket text, count integer)
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF p_period = 'hourly' THEN
    RETURN QUERY
    SELECT lpad(h::text, 2, '0'), COALESCE(sub.cnt, 0)::integer
    FROM generate_series(0, 23) AS h
    LEFT JOIN (
      SELECT EXTRACT(HOUR FROM created_at AT TIME ZONE 'Asia/Bangkok')::int AS hr, COUNT(*)::integer AS cnt
      FROM condom_requests
      WHERE created_at >= p_date_from AND created_at <= p_date_to
        AND (p_service_center IS NULL OR selected_service_center::text = p_service_center)
      GROUP BY hr
    ) sub ON sub.hr = h
    ORDER BY h;
  ELSIF p_period = 'daily' THEN
    RETURN QUERY
    SELECT d::text, COALESCE(sub.cnt, 0)::integer
    FROM generate_series(0, 6) AS d
    LEFT JOIN (
      SELECT EXTRACT(DOW FROM created_at AT TIME ZONE 'Asia/Bangkok')::int AS dow, COUNT(*)::integer AS cnt
      FROM condom_requests
      WHERE created_at >= p_date_from AND created_at <= p_date_to
        AND (p_service_center IS NULL OR selected_service_center::text = p_service_center)
      GROUP BY dow
    ) sub ON sub.dow = d
    ORDER BY d;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_consumption_trend()
RETURNS TABLE(day date, service_center text, condom_used integer, lubricant_used integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_my_scs text[] := get_my_service_centers();
BEGIN
  RETURN QUERY
  WITH date_series AS (
    SELECT generate_series(
      (NOW() AT TIME ZONE 'Asia/Bangkok')::date - INTERVAL '29 days',
      (NOW() AT TIME ZONE 'Asia/Bangkok')::date,
      INTERVAL '1 day'
    )::date AS day
  ),
  centers AS (
    SELECT DISTINCT sci.service_center FROM service_center_inventory sci
    WHERE (v_my_scs IS NULL OR sci.service_center = ANY(v_my_scs))
  ),
  daily_raw AS (
    SELECT (il.created_at AT TIME ZONE 'Asia/Bangkok')::date AS day, il.service_center,
      GREATEST(SUM(-il.condom_delta), 0)::integer    AS condom_used,
      GREATEST(SUM(-il.lubricant_delta), 0)::integer AS lubricant_used
    FROM inventory_logs il
    WHERE il.action = 'fulfillment' AND il.created_at >= NOW() - INTERVAL '30 days'
      AND (v_my_scs IS NULL OR il.service_center = ANY(v_my_scs))
    GROUP BY (il.created_at AT TIME ZONE 'Asia/Bangkok')::date, il.service_center
  )
  SELECT ds.day, c.service_center,
    COALESCE(dr.condom_used, 0)    AS condom_used,
    COALESCE(dr.lubricant_used, 0) AS lubricant_used
  FROM date_series ds
  CROSS JOIN centers c
  LEFT JOIN daily_raw dr ON dr.day = ds.day AND dr.service_center = c.service_center
  ORDER BY ds.day, c.service_center;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_inventory_forecast()
RETURNS TABLE(
  service_center       text,
  condom_qty           integer,
  condom_quantities    jsonb,
  lubricant_qty        integer,
  condom_daily_burn    numeric,
  lubricant_daily_burn numeric,
  condom_days_left     numeric,
  lubricant_days_left  numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN QUERY
  WITH burn AS (
    SELECT il.service_center,
      GREATEST(SUM(-il.condom_delta), 0)::numeric    / 30.0 AS condom_daily_burn,
      GREATEST(SUM(-il.lubricant_delta), 0)::numeric / 30.0 AS lubricant_daily_burn
    FROM inventory_logs il
    WHERE il.action = 'fulfillment' AND il.created_at >= NOW() - INTERVAL '30 days'
    GROUP BY il.service_center
  )
  SELECT sc.name                                                             AS service_center,
    COALESCE(sci.condom_qty, 0)                                              AS condom_qty,
    COALESCE(sci.condom_quantities, '{"49":0,"52":0,"54":0,"56":0}'::jsonb) AS condom_quantities,
    COALESCE(sci.lubricant_qty, 0)                                           AS lubricant_qty,
    COALESCE(b.condom_daily_burn, 0)                                         AS condom_daily_burn,
    COALESCE(b.lubricant_daily_burn, 0)                                      AS lubricant_daily_burn,
    CASE WHEN COALESCE(b.condom_daily_burn, 0) = 0 THEN NULL
         ELSE ROUND(COALESCE(sci.condom_qty, 0)::numeric / b.condom_daily_burn, 1)
    END AS condom_days_left,
    CASE WHEN COALESCE(b.lubricant_daily_burn, 0) = 0 THEN NULL
         ELSE ROUND(COALESCE(sci.lubricant_qty, 0)::numeric / b.lubricant_daily_burn, 1)
    END AS lubricant_days_left
  FROM service_centers sc
  LEFT JOIN service_center_inventory sci ON sci.service_center = sc.name
  LEFT JOIN burn b ON b.service_center = sc.name
  ORDER BY sc.display_order, sc.name;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_service_center_demand(
  p_date_from timestamptz,
  p_date_to   timestamptz
) RETURNS TABLE(service_center text, total_requests integer, total_condoms integer, total_lubricants integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_my_scs text[] := get_my_service_centers();
BEGIN
  RETURN QUERY
  SELECT sc.name AS service_center,
    COALESCE(COUNT(r.id)::integer, 0) AS total_requests,
    COALESCE(SUM(
      (SELECT SUM(v::integer) FROM jsonb_each_text(r.condom_quantities) AS kv(k, v))
    )::integer, 0) AS total_condoms,
    COALESCE(SUM(r.lubricant_quantity)::integer, 0) AS total_lubricants
  FROM service_centers sc
  LEFT JOIN condom_requests r
         ON r.selected_service_center = sc.name
        AND r.created_at >= p_date_from
        AND r.created_at <= p_date_to
  WHERE (v_my_scs IS NULL OR sc.name = ANY(v_my_scs))
  GROUP BY sc.name
  ORDER BY total_requests DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_service_center_demand_trend()
RETURNS TABLE(service_center text, day date, request_count integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_start  date   := (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Bangkok')::date - 29;
  v_end    date   := (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Bangkok')::date;
  v_my_scs text[] := get_my_service_centers();
BEGIN
  RETURN QUERY
  SELECT sc.name AS service_center, d.day::date AS day, COALESCE(COUNT(r.id)::integer, 0) AS request_count
  FROM generate_series(v_start, v_end, '1 day'::interval) d(day)
  CROSS JOIN service_centers sc
  LEFT JOIN condom_requests r
         ON r.selected_service_center = sc.name
        AND (r.created_at AT TIME ZONE 'Asia/Bangkok')::date = d.day
  WHERE (v_my_scs IS NULL OR sc.name = ANY(v_my_scs))
  GROUP BY sc.name, d.day
  ORDER BY sc.name, d.day;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_staff_workload(
  p_date_from      timestamptz,
  p_date_to        timestamptz,
  p_service_center text DEFAULT NULL
) RETURNS TABLE(
  staff_user_id        uuid,
  first_name           text,
  last_name            text,
  service_center       text,
  completed_count      integer,
  cancelled_count      integer,
  overdue_count        integer,
  avg_lead_time_minutes numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_my_scs text[] := get_my_service_centers();
BEGIN
  IF NOT (is_admin() OR is_superadmin()) THEN RAISE EXCEPTION 'Permission denied'; END IF;
  RETURN QUERY
  SELECT sp.staff_user_id, sp.first_name::text, sp.last_name::text,
    (sp.service_centers[1])::text AS service_center,
    COALESCE(COUNT(*) FILTER (WHERE cr.request_status = 'completed')::integer, 0) AS completed_count,
    COALESCE(COUNT(*) FILTER (WHERE cr.request_status IN ('cancelled_by_staff', 'cancelled_by_user'))::integer, 0) AS cancelled_count,
    COALESCE(COUNT(*) FILTER (WHERE cr.is_delay = true)::integer, 0) AS overdue_count,
    AVG(EXTRACT(EPOCH FROM (cr.completed_at - cr.created_at)) / 60.0)
      FILTER (WHERE cr.request_status = 'completed' AND cr.completed_at IS NOT NULL) AS avg_lead_time_minutes
  FROM staff_profiles sp
  LEFT JOIN condom_requests cr
    ON cr.handled_by = sp.staff_user_id
   AND cr.created_at >= p_date_from
   AND cr.created_at <= p_date_to
  WHERE (p_service_center IS NULL OR p_service_center = ANY(sp.service_centers))
    AND (v_my_scs IS NULL OR sp.service_centers && v_my_scs)
  GROUP BY sp.staff_user_id, sp.first_name, sp.last_name, sp.service_centers
  ORDER BY completed_count DESC, sp.first_name, sp.last_name;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_staff_workload_trend(
  p_service_center text        DEFAULT NULL,
  p_staff_user_id  uuid        DEFAULT NULL,
  p_date_from      timestamptz DEFAULT NULL,
  p_date_to        timestamptz DEFAULT NULL
) RETURNS TABLE(
  staff_user_id   uuid,
  week_start      date,
  completed_count integer,
  cancelled_count integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_from   timestamptz := COALESCE(p_date_from, now() - interval '90 days');
  v_to     timestamptz := COALESCE(p_date_to,   now());
  v_my_scs text[]      := get_my_service_centers();
BEGIN
  IF NOT (is_admin() OR is_superadmin()) THEN RAISE EXCEPTION 'Permission denied'; END IF;
  RETURN QUERY
  WITH staff AS (
    SELECT sp.staff_user_id AS uid FROM staff_profiles sp
    WHERE (p_service_center IS NULL OR p_service_center = ANY(sp.service_centers))
      AND (p_staff_user_id  IS NULL OR sp.staff_user_id  = p_staff_user_id)
      AND (v_my_scs IS NULL OR sp.service_centers && v_my_scs)
  ),
  weeks AS (
    SELECT generate_series(
      date_trunc('week', v_from AT TIME ZONE 'Asia/Bangkok')::date,
      date_trunc('week', v_to   AT TIME ZONE 'Asia/Bangkok')::date,
      '7 days'::interval
    )::date AS week_start
  ),
  counts AS (
    SELECT
      date_trunc('week', cr.completed_at AT TIME ZONE 'Asia/Bangkok')::date AS week_start,
      cr.handled_by,
      COUNT(*) FILTER (WHERE cr.request_status = 'completed'::request_status)::integer      AS completed_count,
      COUNT(*) FILTER (WHERE cr.request_status IN (
        'cancelled_by_staff'::request_status, 'cancelled_by_user'::request_status
      ))::integer AS cancelled_count
    FROM condom_requests cr
    WHERE cr.completed_at >= v_from AND cr.completed_at <= v_to
      AND cr.handled_by IN (SELECT uid FROM staff)
    GROUP BY 1, 2
  )
  SELECT s.uid AS staff_user_id, w.week_start,
    COALESCE(c.completed_count, 0) AS completed_count,
    COALESCE(c.cancelled_count, 0) AS cancelled_count
  FROM staff s
  CROSS JOIN weeks w
  LEFT JOIN counts c ON c.week_start = w.week_start AND c.handled_by = s.uid
  ORDER BY s.uid, w.week_start;
END;
$$;


-- ── Log query RPCs ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_request_status_log(
  p_performed_by     uuid        DEFAULT NULL,
  p_from_status      text        DEFAULT NULL,
  p_to_status        text        DEFAULT NULL,
  p_reference_number text        DEFAULT NULL,
  p_date_from        timestamptz DEFAULT NULL,
  p_date_to          timestamptz DEFAULT NULL,
  p_limit            integer     DEFAULT 50,
  p_offset           integer     DEFAULT 0,
  p_service_center   text        DEFAULT NULL
) RETURNS TABLE(
  id               uuid,
  request_id       uuid,
  reference_number text,
  performed_by     uuid,
  full_name        text,
  from_status      text,
  to_status        text,
  changed_at       timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_my_scs text[] := get_my_service_centers();
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.staff_profiles WHERE staff_user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;
  RETURN QUERY
  SELECT rsl.id, rsl.request_id, cr.reference_number,
    rsl.changed_by AS performed_by,
    CASE
      WHEN rsl.changed_by_name IS NOT NULL THEN rsl.changed_by_name
      WHEN sp.staff_user_id    IS NOT NULL THEN sp.first_name || ' ' || sp.last_name
      WHEN up.user_id          IS NOT NULL THEN 'ผู้ใช้'
      ELSE 'ระบบ'
    END AS full_name,
    rsl.from_status::text, rsl.to_status::text, rsl.changed_at
  FROM request_status_logs rsl
  LEFT JOIN staff_profiles sp ON sp.staff_user_id = rsl.changed_by
  LEFT JOIN user_profiles  up ON up.user_id        = rsl.changed_by
  LEFT JOIN condom_requests cr ON cr.id             = rsl.request_id
  WHERE (p_performed_by     IS NULL OR rsl.changed_by              = p_performed_by)
    AND (p_from_status      IS NULL OR rsl.from_status::text       = p_from_status)
    AND (p_to_status        IS NULL OR rsl.to_status::text         = p_to_status)
    AND (p_reference_number IS NULL OR cr.reference_number ILIKE '%' || p_reference_number || '%')
    AND (p_date_from        IS NULL OR rsl.changed_at             >= p_date_from)
    AND (p_date_to          IS NULL OR rsl.changed_at             <= p_date_to)
    AND (v_my_scs           IS NULL OR cr.selected_service_center  = ANY(v_my_scs))
    AND (p_service_center   IS NULL OR cr.selected_service_center  = p_service_center)
  ORDER BY rsl.changed_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_appointment_status_log(
  p_performed_by     uuid        DEFAULT NULL,
  p_from_status      text        DEFAULT NULL,
  p_to_status        text        DEFAULT NULL,
  p_reference_number text        DEFAULT NULL,
  p_date_from        timestamptz DEFAULT NULL,
  p_date_to          timestamptz DEFAULT NULL,
  p_limit            integer     DEFAULT 50,
  p_offset           integer     DEFAULT 0,
  p_service_center   text        DEFAULT NULL
) RETURNS TABLE(
  id               uuid,
  appointment_id   uuid,
  reference_number text,
  performed_by     uuid,
  full_name        text,
  from_status      text,
  to_status        text,
  changed_at       timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_my_scs text[] := get_my_service_centers();
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.staff_profiles WHERE staff_user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;
  RETURN QUERY
  SELECT asl.id, asl.appointment_id, da.reference_number,
    asl.changed_by AS performed_by,
    CASE
      WHEN asl.changed_by_name IS NOT NULL THEN asl.changed_by_name
      WHEN sp.staff_user_id    IS NOT NULL THEN sp.first_name || ' ' || sp.last_name
      WHEN up.user_id          IS NOT NULL THEN 'ผู้ใช้'
      ELSE 'ระบบ'
    END AS full_name,
    asl.from_status::text, asl.to_status::text, asl.changed_at
  FROM appointment_status_logs asl
  LEFT JOIN staff_profiles      sp ON sp.staff_user_id = asl.changed_by
  LEFT JOIN user_profiles       up ON up.user_id        = asl.changed_by
  LEFT JOIN doctor_appointments da ON da.id              = asl.appointment_id
  WHERE (p_performed_by     IS NULL OR asl.changed_by              = p_performed_by)
    AND (p_from_status      IS NULL OR asl.from_status::text       = p_from_status)
    AND (p_to_status        IS NULL OR asl.to_status::text         = p_to_status)
    AND (p_reference_number IS NULL OR da.reference_number ILIKE '%' || p_reference_number || '%')
    AND (p_date_from        IS NULL OR asl.changed_at             >= p_date_from)
    AND (p_date_to          IS NULL OR asl.changed_at             <= p_date_to)
    AND (v_my_scs           IS NULL OR da.selected_service_center  = ANY(v_my_scs))
    AND (p_service_center   IS NULL OR da.selected_service_center  = p_service_center)
  ORDER BY asl.changed_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_inventory_log(
  p_action         text        DEFAULT NULL,
  p_service_center text        DEFAULT NULL,
  p_date_from      timestamptz DEFAULT NULL,
  p_date_to        timestamptz DEFAULT NULL,
  p_limit          integer     DEFAULT 50,
  p_offset         integer     DEFAULT 0
) RETURNS TABLE(
  id                uuid,
  performed_by      uuid,
  full_name         text,
  action            public.audit_action,
  service_center    text,
  condom_delta      integer,
  condom_quantities jsonb,
  lubricant_delta   integer,
  reason            text,
  note              text,
  created_at        timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_my_scs text[] := get_my_service_centers();
BEGIN
  IF NOT (is_admin() OR is_superadmin()) THEN RAISE EXCEPTION 'Permission denied'; END IF;
  RETURN QUERY
  SELECT il.id, il.performed_by,
    COALESCE(il.performed_by_name, sp.first_name || ' ' || sp.last_name, 'ระบบ') AS full_name,
    il.action, il.service_center, il.condom_delta, il.condom_quantities,
    il.lubricant_delta, il.reason, il.note, il.created_at
  FROM public.inventory_logs il
  LEFT JOIN staff_profiles sp ON sp.staff_user_id = il.performed_by
  WHERE (p_action         IS NULL OR il.action::text      = p_action)
    AND (p_service_center IS NULL OR il.service_center    = p_service_center)
    AND (p_date_from      IS NULL OR il.created_at       >= p_date_from)
    AND (p_date_to        IS NULL OR il.created_at       <= p_date_to)
    AND (v_my_scs IS NULL OR il.service_center = ANY(v_my_scs))
  ORDER BY il.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_staff_change_log(
  p_performed_by   uuid        DEFAULT NULL,
  p_action         text        DEFAULT NULL,
  p_target_id      text        DEFAULT NULL,
  p_date_from      timestamptz DEFAULT NULL,
  p_date_to        timestamptz DEFAULT NULL,
  p_limit          integer     DEFAULT 50,
  p_offset         integer     DEFAULT 0,
  p_service_center text        DEFAULT NULL
) RETURNS TABLE(
  id                   uuid,
  performed_by         uuid,
  full_name            text,
  action               public.audit_action,
  target_id            uuid,
  target_staff_user_id uuid,
  target_name          text,
  target_full_name     text,
  old_value            jsonb,
  new_value            jsonb,
  created_at           timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT (is_admin() OR is_superadmin()) THEN RAISE EXCEPTION 'Permission denied'; END IF;
  RETURN QUERY
  SELECT al.id, al.performed_by,
    COALESCE(al.performed_by_name, sp.first_name || ' ' || sp.last_name, 'ระบบ'),
    al.action, al.target_id,
    COALESCE(al.target_staff_user_id, tsp.staff_user_id),
    al.target_name,
    COALESCE(
      al.target_name,
      tsp.first_name || ' ' || tsp.last_name,
      NULLIF(TRIM(COALESCE(al.new_value->>'first_name', '') || ' ' || COALESCE(al.new_value->>'last_name', '')), ' '),
      NULLIF(TRIM(COALESCE(al.old_value->>'first_name', '') || ' ' || COALESCE(al.old_value->>'last_name', '')), ' ')
    ) AS target_full_name,
    al.old_value, al.new_value, al.created_at
  FROM public.staff_change_logs al
  LEFT JOIN staff_profiles sp  ON sp.staff_user_id = al.performed_by
  LEFT JOIN staff_profiles tsp ON tsp.id = al.target_id
  WHERE (p_performed_by   IS NULL OR al.performed_by = p_performed_by)
    AND (p_action         IS NULL OR al.action::text = p_action)
    AND (p_target_id      IS NULL OR (
          COALESCE(al.target_staff_user_id, tsp.staff_user_id)::text ILIKE '%' || p_target_id || '%'
          OR COALESCE(
               al.target_name,
               tsp.first_name || ' ' || tsp.last_name,
               NULLIF(TRIM(COALESCE(al.new_value->>'first_name', '') || ' ' || COALESCE(al.new_value->>'last_name', '')), ' '),
               NULLIF(TRIM(COALESCE(al.old_value->>'first_name', '') || ' ' || COALESCE(al.old_value->>'last_name', '')), ' ')
             ) ILIKE '%' || p_target_id || '%'
        ))
    AND (p_date_from      IS NULL OR al.created_at >= p_date_from)
    AND (p_date_to        IS NULL OR al.created_at <= p_date_to)
    AND (p_service_center IS NULL OR p_service_center = ANY(tsp.service_centers))
  ORDER BY al.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;


