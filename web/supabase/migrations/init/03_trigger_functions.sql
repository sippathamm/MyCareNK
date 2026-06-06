-- ============================================================
-- 03_trigger_functions.sql — MyCareNK
-- All trigger function bodies, grouped by the table they fire on.
-- Created before tables because PL/pgSQL bodies are not validated
-- at definition time — the trigger attachment in 04_tables.sql
-- will fail if these functions do not exist.
-- Apply order: 3 of 8
-- ============================================================
--
-- Covers:
--   staff_profiles   — protect_staff_role_column
--   condom_requests  — set_is_delay, set_handled_by_and_completed_at,
--                      check_staff_update_columns, track_request_status,
--                      deduct_inventory_on_complete,
--                      restore_quota_on_staff_cancel_pending,
--                      handle_staff_request_notification,
--                      handle_user_request_notification
--   inventory_logs   — apply_inventory_adjustment
--   doctor_appts     — handle_staff_appointment_notification,
--                      handle_user_appointment_notification,
--                      track_appointment_status
--   auth.users       — handle_user_deleted (cascade nullify)
-- ============================================================


-- ── staff_profiles ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.protect_staff_role_column()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Allow service_role (auth.uid() IS NULL) — Edge Functions use the service key
  -- and legitimately update roles on behalf of authenticated admins.
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;
  IF NOT is_superadmin() THEN
    IF OLD.role IS DISTINCT FROM NEW.role THEN
      RAISE EXCEPTION 'Only superadmin can update role';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- ── condom_requests ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_is_delay()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.selected_date IS NOT NULL
     AND NEW.selected_date < (NOW() AT TIME ZONE 'Asia/Bangkok')::date THEN
    NEW.is_delay := true;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_handled_by_and_completed_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.request_status = 'preparing' AND OLD.handled_by IS NULL THEN
    NEW.handled_by = auth.uid();
  END IF;
  IF NEW.request_status IN ('completed', 'cancelled_by_user', 'cancelled_by_staff') THEN
    NEW.completed_at = now();
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.check_staff_update_columns()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT is_staff() THEN
    RETURN NEW;
  END IF;
  IF NEW.id IS DISTINCT FROM OLD.id OR
     NEW.user_id IS DISTINCT FROM OLD.user_id OR
     NEW.condom_quantities IS DISTINCT FROM OLD.condom_quantities OR
     NEW.lubricant_quantity IS DISTINCT FROM OLD.lubricant_quantity OR
     NEW.selected_service_center IS DISTINCT FROM OLD.selected_service_center OR
     NEW.selected_date IS DISTINCT FROM OLD.selected_date OR
     NEW.selected_time IS DISTINCT FROM OLD.selected_time OR
     NEW.message IS DISTINCT FROM OLD.message OR
     NEW.reference_number IS DISTINCT FROM OLD.reference_number OR
     NEW.created_at IS DISTINCT FROM OLD.created_at
  THEN
    RAISE EXCEPTION 'Staff are only allowed to update the status column.';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.track_request_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.request_status_logs (request_id, from_status, to_status, changed_by, changed_at)
  VALUES (NEW.id, OLD.request_status, NEW.request_status, auth.uid(), now());
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.deduct_inventory_on_complete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_condom_total      int;
  v_current_condom    int;
  v_current_lubricant int;
BEGIN
  IF NEW.request_status = 'completed' AND OLD.request_status <> 'completed' THEN
    SELECT COALESCE(SUM(value::int), 0)
      INTO v_condom_total
      FROM jsonb_each_text(NEW.condom_quantities);

    SELECT condom_qty, lubricant_qty
      INTO v_current_condom, v_current_lubricant
      FROM public.service_center_inventory
     WHERE service_center = NEW.selected_service_center;

    IF v_current_condom IS NULL THEN
      RAISE EXCEPTION 'ไม่พบข้อมูลสต็อกของสถานบริการนี้';
    END IF;

    IF v_current_condom < v_condom_total THEN
      RAISE EXCEPTION 'สต็อกถุงยางอนามัยไม่เพียงพอ (มี % ชิ้น ต้องใช้ % ชิ้น) กรุณาไปที่หน้า "สต็อกและพยากรณ์" เพื่อเติมสต็อกก่อน',
        v_current_condom, v_condom_total;
    END IF;

    IF v_current_lubricant < NEW.lubricant_quantity THEN
      RAISE EXCEPTION 'สต็อกเจลหล่อลื่นไม่เพียงพอ (มี % ชิ้น ต้องใช้ % ชิ้น) กรุณาไปที่หน้า "สต็อกและพยากรณ์" เพื่อเติมสต็อกก่อน',
        v_current_lubricant, NEW.lubricant_quantity;
    END IF;

    UPDATE public.service_center_inventory
       SET condom_qty    = condom_qty    - v_condom_total,
           lubricant_qty = lubricant_qty - NEW.lubricant_quantity,
           updated_at    = now()
     WHERE service_center = NEW.selected_service_center;

    INSERT INTO public.inventory_logs
      (service_center, action, condom_delta, lubricant_delta, reference_request_id, performed_by)
    VALUES
      (NEW.selected_service_center, 'fulfillment', -v_condom_total, -NEW.lubricant_quantity, NEW.id, NEW.handled_by);
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.restore_quota_on_staff_cancel_pending()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_condom_total integer;
    v_quota_month  date;
BEGIN
    SELECT COALESCE(SUM(value::integer), 0)
    INTO v_condom_total
    FROM jsonb_each_text(OLD.condom_quantities);

    v_quota_month := date_trunc('month', OLD.created_at)::date;

    UPDATE public.user_monthly_quotas
    SET used_condoms    = GREATEST(0, used_condoms    - v_condom_total),
        used_lubricants = GREATEST(0, used_lubricants - OLD.lubricant_quantity),
        updated_at      = now()
    WHERE user_id = OLD.user_id
      AND month   = v_quota_month;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_staff_request_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'INSERT' OR OLD.request_status IS DISTINCT FROM NEW.request_status THEN
    INSERT INTO staff_notifications
      (source_type, source_id, reference_number, event_type, service_center, notify_staff)
    VALUES (
      'condom_request',
      NEW.id,
      NEW.reference_number,
      NEW.request_status::text,
      NEW.selected_service_center,
      NEW.request_status = 'pending'
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_user_request_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_metadata jsonb := '{}';
BEGIN
  -- Account deleted: user_id was SET NULL, no recipient to notify. Skip.
  IF NEW.user_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    INSERT INTO user_notifications (user_id, source_type, source_id, reference_number, event_type, metadata)
    VALUES (NEW.user_id, 'condom_request', NEW.id, NEW.reference_number, NEW.request_status::text, '{}');
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.request_status IS DISTINCT FROM NEW.request_status THEN
    IF NEW.request_status::text = 'ready' THEN
      v_metadata := jsonb_build_object(
        'selected_date',           NEW.selected_date,
        'selected_time',           NEW.selected_time,
        'selected_service_center', NEW.selected_service_center
      );
    END IF;
    INSERT INTO user_notifications (user_id, source_type, source_id, reference_number, event_type, metadata)
    VALUES (NEW.user_id, 'condom_request', NEW.id, NEW.reference_number, NEW.request_status::text, v_metadata);
  END IF;
  RETURN NEW;
END;
$$;

-- ── inventory_logs ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.apply_inventory_adjustment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.action = 'restock' THEN
    UPDATE public.service_center_inventory
    SET condom_qty        = GREATEST(0, condom_qty    + NEW.condom_delta),
        lubricant_qty     = GREATEST(0, lubricant_qty + NEW.lubricant_delta),
        last_restocked_at = NOW(),
        updated_at        = NOW(),
        updated_by        = NEW.performed_by
    WHERE service_center = NEW.service_center;
  ELSIF NEW.action = 'adjustment' THEN
    UPDATE public.service_center_inventory
    SET condom_qty    = GREATEST(0, condom_qty    + NEW.condom_delta),
        lubricant_qty = GREATEST(0, lubricant_qty + NEW.lubricant_delta),
        updated_at    = NOW()
    WHERE service_center = NEW.service_center;
  END IF;
  RETURN NEW;
END;
$$;

-- ── doctor_appointments ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_staff_appointment_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'INSERT' OR OLD.appointment_status IS DISTINCT FROM NEW.appointment_status THEN
    INSERT INTO staff_notifications
      (source_type, source_id, reference_number, event_type, service_center, notify_staff)
    VALUES (
      'doctor_appointment',
      NEW.id,
      NEW.reference_number,
      NEW.appointment_status::text,
      NEW.selected_service_center,
      NEW.appointment_status = 'pending'
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_user_appointment_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_metadata jsonb := '{}'::jsonb;
BEGIN
  -- Account deleted: user_id was SET NULL, no recipient to notify. Skip.
  IF NEW.user_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    INSERT INTO user_notifications (user_id, source_type, source_id, reference_number, event_type, metadata)
    VALUES (NEW.user_id, 'doctor_appointment', NEW.id, NEW.reference_number, NEW.appointment_status::text, '{}'::jsonb);
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.appointment_status IS DISTINCT FROM NEW.appointment_status THEN
    IF NEW.appointment_status::text = 'confirmed' THEN
      v_metadata := jsonb_build_object(
        'selected_date',           NEW.selected_date,
        'selected_time',           NEW.selected_time,
        'selected_service_center', NEW.selected_service_center,
        'reason',                  NEW.reason
      );
    END IF;
    INSERT INTO user_notifications (user_id, source_type, source_id, reference_number, event_type, metadata)
    VALUES (NEW.user_id, 'doctor_appointment', NEW.id, NEW.reference_number, NEW.appointment_status::text, v_metadata);
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.track_appointment_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF OLD.appointment_status IS DISTINCT FROM NEW.appointment_status THEN
    INSERT INTO appointment_status_logs (appointment_id, from_status, to_status, changed_by, changed_at)
    VALUES (NEW.id, OLD.appointment_status, NEW.appointment_status, auth.uid(), now());
  END IF;
  RETURN NEW;
END;
$$;

-- ── auth.users cascade ─────────────────────────────────────
-- Fires BEFORE DELETE on auth.users.
-- Nullifies audit/history references so records are preserved.
-- condom_requests and doctor_appointments are NOT deleted here;
-- their user_id FKs use ON DELETE SET NULL, which fires after this trigger.
CREATE OR REPLACE FUNCTION public.handle_user_deleted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Nullify staff audit/log references to preserve history
  UPDATE public.condom_requests         SET handled_by   = NULL WHERE handled_by   = OLD.id;
  UPDATE public.doctor_appointments     SET handled_by   = NULL WHERE handled_by   = OLD.id;
  UPDATE public.request_status_logs     SET changed_by   = NULL WHERE changed_by   = OLD.id;
  UPDATE public.appointment_status_logs SET changed_by   = NULL WHERE changed_by   = OLD.id;
  UPDATE public.inventory_logs          SET performed_by = NULL WHERE performed_by = OLD.id;
  UPDATE public.staff_change_logs       SET performed_by = NULL WHERE performed_by = OLD.id;
  UPDATE public.articles SET created_by   = NULL WHERE created_by   = OLD.id;
  UPDATE public.articles SET updated_by   = NULL WHERE updated_by   = OLD.id;
  UPDATE public.articles SET published_by = NULL WHERE published_by = OLD.id;
  UPDATE public.articles SET hidden_by    = NULL WHERE hidden_by    = OLD.id;

  -- Delete staff data (no-op for end-users)
  DELETE FROM public.staff_notification_reads WHERE staff_user_id = OLD.id;
  DELETE FROM public.staff_profiles           WHERE staff_user_id = OLD.id;

  -- Delete end-user personal data
  DELETE FROM public.user_notification_reads WHERE user_id = OLD.id;
  DELETE FROM public.user_notifications      WHERE user_id = OLD.id;
  DELETE FROM public.user_recovery_codes     WHERE user_id = OLD.id;
  DELETE FROM public.recovery_attempts       WHERE user_id = OLD.id;
  DELETE FROM public.user_monthly_quotas     WHERE user_id = OLD.id;

  -- Delete user profile
  -- condom_requests, doctor_appointments and their logs are preserved;
  -- user_id will be SET NULL by FK after this trigger returns.
  DELETE FROM public.user_profiles WHERE user_id = OLD.id;

  RETURN OLD;
END;
$$;

-- ── staff_profiles ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.refresh_service_center_staff_counts()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- WHERE sc.name IS NOT NULL is always true (PK, NOT NULL) but is required
  -- because pg_safeupdate rejects UPDATE statements without a WHERE clause.
  UPDATE public.service_centers sc SET
    staff_count = (
      SELECT COUNT(*) FROM public.staff_profiles sp
      WHERE sp.role = 'staff' AND sp.service_centers @> ARRAY[sc.name]
    ),
    admin_count = (
      SELECT COUNT(*) FROM public.staff_profiles sp
      WHERE sp.role = 'admin' AND sp.service_centers @> ARRAY[sc.name]
    ),
    superadmin_count = (
      SELECT COUNT(*) FROM public.staff_profiles WHERE role = 'superadmin'
    )
  WHERE sc.name IS NOT NULL;
  RETURN NULL;
END;
$$;


