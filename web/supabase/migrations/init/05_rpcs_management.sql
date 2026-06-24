-- ============================================================
-- 05_rpcs_management.sql — MyCareNK
-- Staff-facing management RPCs that require elevated roles.
-- Apply order: 5 of 8
-- ============================================================
--
-- Covers:
--   Audit logging  — write_audit_log, write_staff_change_log
--                    (service_role only; no GRANT to authenticated)
--   SC management  — add_service_center, delete_service_center,
--                    init_service_center_inventory,
--                    toggle_service_center_active,
--                    upsert_service_center
-- ============================================================


-- ── Audit (service_role only — no explicit GRANT) ───────────
CREATE OR REPLACE FUNCTION public.write_staff_change_log(
  p_action                public.audit_action,
  p_target_table          text,
  p_target_id             uuid,
  p_old_value             jsonb DEFAULT NULL,
  p_new_value             jsonb DEFAULT NULL,
  p_performed_by          uuid  DEFAULT NULL,
  p_target_staff_user_id  uuid  DEFAULT NULL,
  p_target_name           text  DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_performer_id uuid := COALESCE(p_performed_by, auth.uid());
BEGIN
  INSERT INTO public.staff_change_logs (
    performed_by, performed_by_name, action, target_table, target_id,
    old_value, new_value,
    target_staff_user_id, target_name
  )
  VALUES (
    v_performer_id,
    (SELECT first_name || ' ' || last_name FROM public.staff_profiles WHERE staff_user_id = v_performer_id),
    p_action, p_target_table, p_target_id,
    p_old_value, p_new_value,
    p_target_staff_user_id, p_target_name
  );
END;
$$;


-- ── Service center management ───────────────────────────────
CREATE OR REPLACE FUNCTION public.add_service_center(p_name text)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT (is_admin() OR is_superadmin()) THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  INSERT INTO service_centers (name, display_order)
    VALUES (p_name, (SELECT COALESCE(MAX(display_order), 0) + 1 FROM service_centers))
    ON CONFLICT (name) DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_service_center(p_name text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_staff_count int;
BEGIN
  IF NOT is_superadmin() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  SELECT COUNT(*) INTO v_staff_count FROM staff_profiles WHERE service_centers @> ARRAY[p_name];
  IF v_staff_count > 0 THEN
    RAISE EXCEPTION 'ไม่สามารถลบสถานบริการที่ยังมีเจ้าหน้าที่อยู่ได้ กรุณาย้ายเจ้าหน้าที่ออกก่อน';
  END IF;
  DELETE FROM service_center_inventory WHERE service_center = p_name;
  DELETE FROM service_centers WHERE name = p_name;
END;
$$;

CREATE OR REPLACE FUNCTION public.init_service_center_inventory(p_name text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT (is_admin() OR is_superadmin()) THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  INSERT INTO service_center_inventory (service_center, condom_qty, lubricant_qty)
    VALUES (p_name, 0, 0) ON CONFLICT DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION public.upsert_service_center(
  p_name                        text,
  p_image_url                   text             DEFAULT NULL,
  p_description                 text             DEFAULT NULL,
  p_contacts                    jsonb            DEFAULT NULL,
  p_latitude                    double precision DEFAULT NULL,
  p_longitude                   double precision DEFAULT NULL,
  p_display_order               smallint         DEFAULT NULL,
  p_operating_hours             text             DEFAULT NULL,
  p_address                     text             DEFAULT NULL,
  p_condom_service_enabled      boolean          DEFAULT NULL,
  p_appointment_service_enabled boolean          DEFAULT NULL,
  p_pickup_times                text[]           DEFAULT NULL,
  p_appointment_times           text[]           DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT (is_admin() OR is_superadmin()) THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  UPDATE public.service_centers SET
    image_url                   = COALESCE(p_image_url,                   image_url),
    description                 = COALESCE(p_description,                 description),
    contacts                    = COALESCE(p_contacts,                    contacts),
    latitude                    = p_latitude,
    longitude                   = p_longitude,
    display_order               = COALESCE(p_display_order,               display_order),
    operating_hours             = p_operating_hours,
    address                     = p_address,
    condom_service_enabled      = COALESCE(p_condom_service_enabled,      condom_service_enabled),
    appointment_service_enabled = COALESCE(p_appointment_service_enabled, appointment_service_enabled),
    pickup_times                = COALESCE(p_pickup_times,                pickup_times),
    appointment_times           = COALESCE(p_appointment_times,           appointment_times),
    updated_at                  = now()
  WHERE name = p_name;
  IF NOT FOUND THEN RAISE EXCEPTION 'สถานบริการไม่พบ: %', p_name; END IF;
END;
$$;


