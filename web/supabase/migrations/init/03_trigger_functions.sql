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
--   inventory_logs   — apply_inventory_adjustment, notify_staff_on_stock_operation
--   service_center_inventory — sync_inventory_condom_qty
--   consultations    — handle_staff_consultation_notification,
--                      handle_user_consultation_notification,
--                      track_consultation_status
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
  IF NEW.request_status = 'cancelled_by_staff' THEN
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
  INSERT INTO public.request_status_logs (request_id, from_status, to_status, changed_by, changed_by_name, changed_at)
  VALUES (
    NEW.id,
    OLD.request_status,
    NEW.request_status,
    auth.uid(),
    (SELECT first_name || ' ' || last_name FROM public.staff_profiles WHERE staff_user_id = auth.uid()),
    now()
  );
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
  v_condom_total        int;
  v_current_lubricant   int;
  v_current_condom_qtys jsonb;
  v_size                text;
  v_req_qty             int;
  v_inv_qty             int;
BEGIN
  IF NEW.request_status = 'completed' AND OLD.request_status <> 'completed' THEN
    SELECT COALESCE(SUM(value::int), 0)
      INTO v_condom_total
      FROM jsonb_each_text(NEW.condom_quantities);

    SELECT condom_quantities, lubricant_qty
      INTO v_current_condom_qtys, v_current_lubricant
      FROM public.service_center_inventory
     WHERE service_center = NEW.selected_service_center;

    IF v_current_condom_qtys IS NULL THEN
      RAISE EXCEPTION 'ไม่พบข้อมูลสต็อกของสถานบริการนี้';
    END IF;

    -- Per-size availability check (block if any requested size is insufficient)
    FOREACH v_size IN ARRAY ARRAY['49','52','54','56']
    LOOP
      v_req_qty := COALESCE((NEW.condom_quantities->>v_size)::int, 0);
      IF v_req_qty > 0 THEN
        v_inv_qty := COALESCE((v_current_condom_qtys->>v_size)::int, 0);
        IF v_inv_qty < v_req_qty THEN
          RAISE EXCEPTION 'สต็อกถุงยางอนามัยขนาด %mm ไม่เพียงพอ (มี % ชิ้น ต้องใช้ % ชิ้น) กรุณาเติมสต็อกขนาด %mm ก่อน',
            v_size, v_inv_qty, v_req_qty, v_size;
        END IF;
      END IF;
    END LOOP;

    IF v_current_lubricant < NEW.lubricant_quantity THEN
      RAISE EXCEPTION 'สต็อกเจลหล่อลื่นไม่เพียงพอ (มี % ชิ้น ต้องใช้ % ชิ้น) กรุณาไปที่หน้า "สต็อกและพยากรณ์" เพื่อเติมสต็อกก่อน',
        v_current_lubricant, NEW.lubricant_quantity;
    END IF;

    -- Deduct per-size (trigger_sync_condom_qty_from_quantities auto-updates condom_qty total)
    UPDATE public.service_center_inventory
       SET condom_quantities = jsonb_build_object(
             '49', GREATEST(0, COALESCE((condom_quantities->>'49')::int, 0) - COALESCE((NEW.condom_quantities->>'49')::int, 0)),
             '52', GREATEST(0, COALESCE((condom_quantities->>'52')::int, 0) - COALESCE((NEW.condom_quantities->>'52')::int, 0)),
             '54', GREATEST(0, COALESCE((condom_quantities->>'54')::int, 0) - COALESCE((NEW.condom_quantities->>'54')::int, 0)),
             '56', GREATEST(0, COALESCE((condom_quantities->>'56')::int, 0) - COALESCE((NEW.condom_quantities->>'56')::int, 0))
           ),
           lubricant_qty = lubricant_qty - NEW.lubricant_quantity,
           updated_at    = now()
     WHERE service_center = NEW.selected_service_center;

    INSERT INTO public.inventory_logs
      (service_center, action, condom_delta, lubricant_delta, condom_quantities, reference_request_id, performed_by)
    VALUES (
      NEW.selected_service_center,
      'fulfillment',
      -v_condom_total,
      -NEW.lubricant_quantity,
      jsonb_build_object(
        '49', -COALESCE((NEW.condom_quantities->>'49')::int, 0),
        '52', -COALESCE((NEW.condom_quantities->>'52')::int, 0),
        '54', -COALESCE((NEW.condom_quantities->>'54')::int, 0),
        '56', -COALESCE((NEW.condom_quantities->>'56')::int, 0)
      ),
      NEW.id,
      NEW.handled_by
    );
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
DECLARE
  v_ns RECORD;
BEGIN
  IF TG_OP = 'INSERT' OR OLD.request_status IS DISTINCT FROM NEW.request_status THEN
    SELECT notify_staff, notify_admin, notify_superadmin INTO v_ns
      FROM notification_settings
     WHERE source_type = 'condom_request' AND event_type = NEW.request_status::text;

    INSERT INTO staff_notifications
      (source_type, source_id, event_type, service_centers,
       notify_staff, notify_admin, notify_superadmin, metadata)
    VALUES (
      'condom_request',
      NEW.id,
      NEW.request_status::text,
      ARRAY[NEW.selected_service_center],
      COALESCE(v_ns.notify_staff,      true),
      COALESCE(v_ns.notify_admin,      true),
      COALESCE(v_ns.notify_superadmin, true),
      jsonb_build_object('reference_number', NEW.reference_number)
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
    SET condom_quantities = jsonb_build_object(
          '49', GREATEST(0, COALESCE((condom_quantities->>'49')::int, 0) + COALESCE((NEW.condom_quantities->>'49')::int, 0)),
          '52', GREATEST(0, COALESCE((condom_quantities->>'52')::int, 0) + COALESCE((NEW.condom_quantities->>'52')::int, 0)),
          '54', GREATEST(0, COALESCE((condom_quantities->>'54')::int, 0) + COALESCE((NEW.condom_quantities->>'54')::int, 0)),
          '56', GREATEST(0, COALESCE((condom_quantities->>'56')::int, 0) + COALESCE((NEW.condom_quantities->>'56')::int, 0))
        ),
        lubricant_qty = GREATEST(0, lubricant_qty + NEW.lubricant_delta),
        updated_at    = NOW()
    WHERE service_center = NEW.service_center;
  ELSIF NEW.action = 'adjustment' THEN
    UPDATE public.service_center_inventory
    SET condom_quantities = jsonb_build_object(
          '49', GREATEST(0, COALESCE((condom_quantities->>'49')::int, 0) + COALESCE((NEW.condom_quantities->>'49')::int, 0)),
          '52', GREATEST(0, COALESCE((condom_quantities->>'52')::int, 0) + COALESCE((NEW.condom_quantities->>'52')::int, 0)),
          '54', GREATEST(0, COALESCE((condom_quantities->>'54')::int, 0) + COALESCE((NEW.condom_quantities->>'54')::int, 0)),
          '56', GREATEST(0, COALESCE((condom_quantities->>'56')::int, 0) + COALESCE((NEW.condom_quantities->>'56')::int, 0))
        ),
        lubricant_qty = GREATEST(0, lubricant_qty + NEW.lubricant_delta),
        updated_at    = NOW()
    WHERE service_center = NEW.service_center;
  END IF;
  RETURN NEW;
END;
$$;

-- ── service_center_inventory ─────────────────────────────────
CREATE OR REPLACE FUNCTION public.sync_inventory_condom_qty()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  NEW.condom_qty :=
      COALESCE((NEW.condom_quantities->>'49')::int, 0)
    + COALESCE((NEW.condom_quantities->>'52')::int, 0)
    + COALESCE((NEW.condom_quantities->>'54')::int, 0)
    + COALESCE((NEW.condom_quantities->>'56')::int, 0);
  RETURN NEW;
END;
$$;

-- ── inventory_logs (stock notifications) ───────────────────
CREATE OR REPLACE FUNCTION public.notify_staff_on_stock_operation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_actor_name text;
  v_ns         RECORD;
BEGIN
  IF NEW.action NOT IN ('restock', 'adjustment') THEN
    RETURN NEW;
  END IF;

  SELECT first_name || ' ' || last_name
    INTO v_actor_name
    FROM public.staff_profiles
   WHERE staff_user_id = NEW.performed_by;

  v_actor_name := COALESCE(v_actor_name, '');

  SELECT notify_staff, notify_admin, notify_superadmin INTO v_ns
    FROM notification_settings
   WHERE source_type = 'stock_operation' AND event_type = NEW.action::text;

  INSERT INTO public.staff_notifications
    (source_type, source_id, event_type, service_centers,
     notify_staff, notify_admin, notify_superadmin, metadata)
  VALUES (
    'stock_operation',
    NEW.id,
    NEW.action::text,
    ARRAY[NEW.service_center],
    COALESCE(v_ns.notify_staff,      true),
    COALESCE(v_ns.notify_admin,      true),
    COALESCE(v_ns.notify_superadmin, true),
    jsonb_build_object(
      'actor_name',          v_actor_name,
      'service_center_name', NEW.service_center,
      'action_type',         NEW.action::text
    )
  );

  RETURN NEW;
END;
$$;

-- ── consultations ───────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_staff_consultation_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_ns RECORD;
BEGIN
  IF TG_OP = 'INSERT' OR OLD.consultation_status IS DISTINCT FROM NEW.consultation_status THEN
    SELECT notify_staff, notify_admin, notify_superadmin INTO v_ns
      FROM notification_settings
     WHERE source_type = 'consultation' AND event_type = NEW.consultation_status::text;

    INSERT INTO staff_notifications
      (source_type, source_id, event_type, service_centers,
       notify_staff, notify_admin, notify_superadmin, metadata)
    VALUES (
      'consultation',
      NEW.id,
      NEW.consultation_status::text,
      ARRAY[NEW.selected_service_center],
      COALESCE(v_ns.notify_staff,      true),
      COALESCE(v_ns.notify_admin,      true),
      COALESCE(v_ns.notify_superadmin, true),
      jsonb_build_object('reference_number', NEW.reference_number)
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_user_consultation_notification()
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
    VALUES (NEW.user_id, 'consultation', NEW.id, NEW.reference_number, NEW.consultation_status::text, '{}'::jsonb);
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.consultation_status IS DISTINCT FROM NEW.consultation_status THEN
    IF NEW.consultation_status::text = 'confirmed' THEN
      v_metadata := jsonb_build_object(
        'selected_date',           NEW.selected_date,
        'selected_time',           NEW.selected_time,
        'selected_service_center', NEW.selected_service_center,
        'reason',                  NEW.reason
      );
    END IF;
    INSERT INTO user_notifications (user_id, source_type, source_id, reference_number, event_type, metadata)
    VALUES (NEW.user_id, 'consultation', NEW.id, NEW.reference_number, NEW.consultation_status::text, v_metadata);
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.track_consultation_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF OLD.consultation_status IS DISTINCT FROM NEW.consultation_status THEN
    INSERT INTO consultation_status_logs (consultation_id, from_status, to_status, changed_by, changed_by_name, changed_at)
    VALUES (
      NEW.id,
      OLD.consultation_status,
      NEW.consultation_status,
      auth.uid(),
      (SELECT first_name || ' ' || last_name FROM public.staff_profiles WHERE staff_user_id = auth.uid()),
      now()
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_inventory_log_performer_name()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.performed_by IS NOT NULL THEN
    SELECT first_name || ' ' || last_name
    INTO NEW.performed_by_name
    FROM public.staff_profiles
    WHERE staff_user_id = NEW.performed_by;
  END IF;
  RETURN NEW;
END;
$$;

-- ── auth.users cascade ─────────────────────────────────────
-- Fires BEFORE DELETE on auth.users.
-- Nullifies audit/history references so records are preserved.
-- condom_requests and consultations are NOT deleted here;
-- their user_id FKs use ON DELETE SET NULL, which fires after this trigger.
CREATE OR REPLACE FUNCTION public.handle_user_deleted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Nullify staff audit/log references to preserve history
  UPDATE public.condom_requests          SET handled_by   = NULL WHERE handled_by   = OLD.id;
  UPDATE public.consultations            SET handled_by   = NULL WHERE handled_by   = OLD.id;
  UPDATE public.request_status_logs      SET changed_by   = NULL WHERE changed_by   = OLD.id;
  UPDATE public.consultation_status_logs SET changed_by   = NULL WHERE changed_by   = OLD.id;
  UPDATE public.inventory_logs           SET performed_by = NULL WHERE performed_by = OLD.id;
  UPDATE public.staff_change_logs        SET performed_by = NULL WHERE performed_by = OLD.id;
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
  -- condom_requests, consultations and their logs are preserved;
  -- user_id will be SET NULL by FK after this trigger returns.
  DELETE FROM public.user_profiles WHERE user_id = OLD.id;

  RETURN OLD;
END;
$$;

-- ── consultations ───────────────────────────────────────────
-- Mirrors set_handled_by_and_completed_at for consultations:
-- sets handled_by = auth.uid() on first pending→confirmed transition.
CREATE OR REPLACE FUNCTION public.set_consultation_handled_by()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.consultation_status = 'confirmed' AND OLD.handled_by IS NULL THEN
    NEW.handled_by = auth.uid();
  END IF;
  IF NEW.consultation_status = 'cancelled_by_staff' THEN
    NEW.handled_by = auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

-- ── staff_notifications (LINE push) ────────────────────────
-- Calls line-notify Edge Function via pg_net for pending notifications.
--
-- ⚠️ REQUIRES a Vault secret named 'project_url' holding this project's base
-- URL (e.g. https://<project-ref>.supabase.co, no trailing slash). Without it
-- the trigger logs a WARNING and skips the push — inserts still succeed, but
-- LINE notifications silently stop. When standing up a new project, create it:
--
--   SELECT vault.create_secret(
--     'https://<project-ref>.supabase.co',
--     'project_url',
--     'Base URL of this Supabase project. Read by notify_line_on_staff_notification().'
--   );
CREATE OR REPLACE FUNCTION public.notify_line_on_staff_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_project_url text;
BEGIN
  IF NEW.event_type <> 'pending' OR cardinality(NEW.service_centers) = 0 THEN
    RETURN NEW;
  END IF;

  SELECT rtrim(decrypted_secret, '/')
    INTO v_project_url
    FROM vault.decrypted_secrets
   WHERE name = 'project_url';

  IF v_project_url IS NULL OR v_project_url = '' THEN
    RAISE WARNING 'notify_line_on_staff_notification: vault secret "project_url" is missing or empty; skipping LINE push for staff_notification %', NEW.id;
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url     := v_project_url || '/functions/v1/line-notify',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body    := to_jsonb(NEW),
    timeout_milliseconds := 5000
  );

  RETURN NEW;
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


