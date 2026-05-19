-- ============================================================
-- SQUASH MIGRATION — MyCareNK
-- Project: timuuxjeffzqtsqnjbnz | ap-southeast-1
-- Generated: 2026-05-19
-- Replaces 131 individual migrations with a single clean schema.
-- Apply to a CLEAN Supabase project (no data preservation needed).
-- ============================================================


-- ============================================================
-- SECTION 1: ENUMS
-- ============================================================

CREATE TYPE public.request_status AS ENUM (
  'pending',
  'preparing',
  'ready',
  'completed',
  'cancelled_by_user',
  'cancelled_by_staff'
);

CREATE TYPE public.role AS ENUM (
  'staff',
  'admin',
  'superadmin'
);

CREATE TYPE public.transaction_type AS ENUM (
  'restock',
  'fulfillment',
  'adjustment'
);

CREATE TYPE public.audit_action AS ENUM (
  'role_updated',
  'staff_profile_updated',
  'restock',
  'fulfillment',
  'adjustment',
  'staff_created',
  'staff_deleted',
  'email_updated'
);

CREATE TYPE public.appointment_status AS ENUM (
  'pending',
  'confirmed',
  'completed',
  'cancelled_by_user',
  'cancelled_by_staff'
);

CREATE TYPE public.article_status AS ENUM (
  'draft',
  'scheduled',
  'published',
  'hidden'
);


-- ============================================================
-- SECTION 2: SHARED FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.staff_profiles
    WHERE staff_user_id = auth.uid()
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.staff_profiles
    WHERE staff_user_id = auth.uid() AND role = 'admin'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_superadmin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.staff_profiles
    WHERE staff_user_id = auth.uid() AND role = 'superadmin'
  );
END;
$$;


-- ============================================================
-- SECTION 3: TRIGGER FUNCTIONS (created before tables;
--             PL/pgSQL bodies not validated at definition time)
-- ============================================================

-- ── staff_profiles ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.protect_staff_role_column()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
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
    INSERT INTO staff_notifications (source_type, source_id, reference_number, event_type, service_center)
    VALUES ('condom_request', NEW.id, NEW.reference_number, NEW.request_status::text, NEW.selected_service_center);
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
    INSERT INTO staff_notifications (source_type, source_id, reference_number, event_type, service_center)
    VALUES ('doctor_appointment', NEW.id, NEW.reference_number, NEW.appointment_status::text, NEW.selected_service_center);
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

-- ── articles ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_article_status()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.publish_at IS NULL THEN
    NEW.status := 'draft';
  ELSIF NOT NEW.is_visible THEN
    NEW.status := 'hidden';
  ELSIF NEW.publish_at > NOW() THEN
    NEW.status := 'scheduled';
  ELSE
    NEW.status := 'published';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.snapshot_published_content()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF OLD.has_draft = TRUE AND NEW.has_draft = FALSE THEN
    NEW.published_content_html := NEW.content_html;
    NEW.published_content_json := NEW.content_json;
  END IF;
  RETURN NEW;
END;
$$;


-- ============================================================
-- SECTION 4: TABLES (in FK dependency order)
-- ============================================================

-- ── 1. service_centers ─────────────────────────────────────
CREATE TABLE public.service_centers (
  name                        text        NOT NULL,
  image_url                   text,
  description                 text,
  contacts                    jsonb       NOT NULL DEFAULT '[]',
  latitude                    numeric,
  longitude                   numeric,
  is_active                   boolean     NOT NULL DEFAULT true,
  display_order               smallint    NOT NULL DEFAULT 0,
  created_at                  timestamptz NOT NULL DEFAULT now(),
  updated_at                  timestamptz NOT NULL DEFAULT now(),
  operating_hours             text,
  address                     text,
  condom_service_enabled      boolean     NOT NULL DEFAULT true,
  appointment_service_enabled boolean     NOT NULL DEFAULT false,
  pickup_times                text[]      NOT NULL DEFAULT '{08:00}',
  appointment_times           text[]      NOT NULL DEFAULT '{08:00}',
  CONSTRAINT service_centers_pkey PRIMARY KEY (name)
);

ALTER TABLE public.service_centers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated read"
  ON public.service_centers FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "admin can update"
  ON public.service_centers FOR UPDATE
  TO authenticated USING (is_admin() OR is_superadmin());

CREATE POLICY "superadmin can insert"
  ON public.service_centers FOR INSERT
  TO authenticated WITH CHECK (is_superadmin());

CREATE TRIGGER update_service_centers_updated_at
  BEFORE UPDATE ON public.service_centers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ── 2. user_profiles ───────────────────────────────────────
CREATE TABLE public.user_profiles (
  id            uuid         NOT NULL DEFAULT gen_random_uuid(),
  user_id       uuid         NOT NULL,
  gender        varchar(20),
  nationality   varchar(100),
  date_of_birth date,
  created_at    timestamptz           DEFAULT now(),
  username      text         NOT NULL DEFAULT '',
  CONSTRAINT user_profiles_pkey         PRIMARY KEY (id),
  CONSTRAINT user_profiles_user_id_key  UNIQUE (user_id),
  CONSTRAINT user_profiles_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
  ON public.user_profiles FOR SELECT
  TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert their own profile"
  ON public.user_profiles FOR INSERT
  TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own profile"
  ON public.user_profiles FOR UPDATE
  TO authenticated USING ((SELECT auth.uid()) = user_id);


-- ── 3. user_monthly_quotas ─────────────────────────────────
CREATE TABLE public.user_monthly_quotas (
  id              uuid        NOT NULL DEFAULT gen_random_uuid(),
  user_id         uuid        NOT NULL,
  month           date        NOT NULL,
  used_condoms    integer              DEFAULT 0,
  used_lubricants integer              DEFAULT 0,
  updated_at      timestamptz          DEFAULT now(),
  CONSTRAINT user_monthly_quotas_pkey       PRIMARY KEY (id),
  CONSTRAINT user_monthly_quotas_user_month UNIQUE (user_id, month),
  CONSTRAINT user_monthly_quotas_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE public.user_monthly_quotas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own monthly quotas"
  ON public.user_monthly_quotas FOR SELECT
  TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert their own monthly quotas"
  ON public.user_monthly_quotas FOR INSERT
  TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own monthly quotas"
  ON public.user_monthly_quotas FOR UPDATE
  TO authenticated USING ((SELECT auth.uid()) = user_id);


-- ── 4. user_recovery_codes ─────────────────────────────────
CREATE TABLE public.user_recovery_codes (
  id         uuid        NOT NULL DEFAULT gen_random_uuid(),
  user_id    uuid        NOT NULL,
  code_hash  text        NOT NULL,
  used       boolean              DEFAULT false,
  created_at timestamptz          DEFAULT now(),
  used_at    timestamptz,
  CONSTRAINT user_recovery_codes_pkey         PRIMARY KEY (id),
  CONSTRAINT user_recovery_codes_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE public.user_recovery_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own recovery codes"
  ON public.user_recovery_codes FOR SELECT
  TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert their own recovery codes"
  ON public.user_recovery_codes FOR INSERT
  TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);


-- ── 5. recovery_attempts ───────────────────────────────────
CREATE TABLE public.recovery_attempts (
  id           uuid        NOT NULL DEFAULT gen_random_uuid(),
  user_id      uuid        NOT NULL,
  attempted_at timestamptz          DEFAULT now(),
  success      boolean              DEFAULT false,
  CONSTRAINT recovery_attempts_pkey         PRIMARY KEY (id),
  CONSTRAINT recovery_attempts_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE public.recovery_attempts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own recovery attempts"
  ON public.recovery_attempts FOR SELECT
  TO authenticated USING ((SELECT auth.uid()) = user_id);


-- ── 6. staff_profiles ──────────────────────────────────────
CREATE TABLE public.staff_profiles (
  id             uuid              NOT NULL DEFAULT gen_random_uuid(),
  staff_user_id  uuid              NOT NULL,
  first_name     varchar(255),
  last_name      varchar(255),
  service_center text,
  created_at     timestamptz                DEFAULT now(),
  updated_at     timestamptz                DEFAULT now(),
  role           public.role       NOT NULL DEFAULT 'staff',
  CONSTRAINT staff_profiles_pkey               PRIMARY KEY (id),
  CONSTRAINT staff_profiles_staff_user_id_key  UNIQUE (staff_user_id),
  CONSTRAINT staff_profiles_staff_user_id_fkey FOREIGN KEY (staff_user_id)
    REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT staff_profiles_service_center_fkey FOREIGN KEY (service_center)
    REFERENCES public.service_centers(name)
);

ALTER TABLE public.staff_profiles ENABLE ROW LEVEL SECURITY;

-- NOTE: TO PUBLIC (not TO authenticated) — matches production DB
CREATE POLICY "Staff can view their own profile"
  ON public.staff_profiles FOR SELECT
  TO PUBLIC USING ((SELECT auth.uid()) = staff_user_id);

CREATE POLICY "Staff can insert their own profile"
  ON public.staff_profiles FOR INSERT
  TO PUBLIC WITH CHECK ((SELECT auth.uid()) = staff_user_id);

CREATE POLICY "Staff can update their own profile"
  ON public.staff_profiles FOR UPDATE
  TO PUBLIC
  USING ((SELECT auth.uid()) = staff_user_id)
  WITH CHECK ((SELECT auth.uid()) = staff_user_id);

CREATE TRIGGER protect_role_update
  BEFORE UPDATE ON public.staff_profiles
  FOR EACH ROW EXECUTE FUNCTION protect_staff_role_column();


-- ── 7. staff_audit_logs ────────────────────────────────────
CREATE TABLE public.staff_audit_logs (
  id           uuid                NOT NULL DEFAULT gen_random_uuid(),
  performed_by uuid,
  action       public.audit_action NOT NULL,
  target_table text                NOT NULL,
  target_id    uuid                NOT NULL,
  old_value    jsonb,
  new_value    jsonb,
  created_at   timestamptz         NOT NULL DEFAULT now(),
  CONSTRAINT staff_audit_logs_pkey              PRIMARY KEY (id),
  CONSTRAINT staff_audit_logs_performed_by_fkey FOREIGN KEY (performed_by)
    REFERENCES auth.users(id)
);

ALTER TABLE public.staff_audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "superadmin_select_audit_logs"
  ON public.staff_audit_logs FOR SELECT
  TO authenticated USING (is_superadmin());

CREATE POLICY "deny_client_insert_audit_logs"
  ON public.staff_audit_logs FOR INSERT
  TO authenticated WITH CHECK (false);

CREATE POLICY "deny_update_audit_logs"
  ON public.staff_audit_logs FOR UPDATE
  TO authenticated USING (false);

CREATE POLICY "deny_delete_audit_logs"
  ON public.staff_audit_logs FOR DELETE
  TO authenticated USING (false);


-- ── 8. staff_notifications ─────────────────────────────────
CREATE TABLE public.staff_notifications (
  id               uuid        NOT NULL DEFAULT gen_random_uuid(),
  reference_number text        NOT NULL DEFAULT '',
  created_at       timestamptz NOT NULL DEFAULT timezone('utc', now()),
  event_type       text        NOT NULL,
  source_type      text        NOT NULL,
  source_id        uuid        NOT NULL,
  metadata         jsonb       NOT NULL DEFAULT '{}',
  service_center   text,
  CONSTRAINT staff_notifications_pkey PRIMARY KEY (id)
);

ALTER TABLE public.staff_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view their notifications"
  ON public.staff_notifications FOR SELECT
  TO authenticated USING (
    is_superadmin() OR
    service_center = (
      SELECT sp.service_center FROM staff_profiles sp
      WHERE sp.staff_user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Staff can delete their notifications"
  ON public.staff_notifications FOR DELETE
  TO authenticated USING (
    is_superadmin() OR
    service_center = (
      SELECT sp.service_center FROM staff_profiles sp
      WHERE sp.staff_user_id = (SELECT auth.uid())
    )
  );


-- ── 9. staff_notification_reads ────────────────────────────
CREATE TABLE public.staff_notification_reads (
  notification_id uuid        NOT NULL,
  staff_user_id   uuid        NOT NULL,
  read_at         timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT staff_notification_reads_pkey PRIMARY KEY (notification_id, staff_user_id),
  CONSTRAINT staff_notification_reads_notification_id_fkey FOREIGN KEY (notification_id)
    REFERENCES public.staff_notifications(id) ON DELETE CASCADE,
  CONSTRAINT staff_notification_reads_staff_user_id_fkey FOREIGN KEY (staff_user_id)
    REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE public.staff_notification_reads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow staff to manage their reads"
  ON public.staff_notification_reads
  TO authenticated
  USING (staff_user_id = (SELECT auth.uid()))
  WITH CHECK (staff_user_id = (SELECT auth.uid()));


-- ── 10. user_notifications ─────────────────────────────────
CREATE TABLE public.user_notifications (
  id               uuid        NOT NULL DEFAULT gen_random_uuid(),
  user_id          uuid        NOT NULL,
  source_type      text        NOT NULL,
  source_id        uuid        NOT NULL,
  reference_number text        NOT NULL DEFAULT '',
  event_type       text        NOT NULL,
  metadata         jsonb       NOT NULL DEFAULT '{}',
  created_at       timestamptz NOT NULL DEFAULT timezone('utc', now()),
  CONSTRAINT user_notifications_pkey         PRIMARY KEY (id),
  CONSTRAINT user_notifications_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE public.user_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select_own"
  ON public.user_notifications FOR SELECT
  TO authenticated USING (user_id = (SELECT auth.uid()));


-- ── 11. user_notification_reads ────────────────────────────
CREATE TABLE public.user_notification_reads (
  notification_id uuid        NOT NULL,
  user_id         uuid        NOT NULL,
  read_at         timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_notification_reads_pkey PRIMARY KEY (notification_id, user_id),
  CONSTRAINT user_notification_reads_notification_id_fkey FOREIGN KEY (notification_id)
    REFERENCES public.user_notifications(id) ON DELETE CASCADE,
  CONSTRAINT user_notification_reads_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE public.user_notification_reads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select_own_reads"
  ON public.user_notification_reads FOR SELECT
  TO authenticated USING (user_id = (SELECT auth.uid()));

CREATE POLICY "users_insert_own_reads"
  ON public.user_notification_reads FOR INSERT
  TO authenticated WITH CHECK (user_id = (SELECT auth.uid()));


-- ── 12. service_center_inventory ───────────────────────────
CREATE TABLE public.service_center_inventory (
  id                uuid        NOT NULL DEFAULT gen_random_uuid(),
  service_center    text        NOT NULL,
  condom_qty        integer     NOT NULL DEFAULT 0,
  lubricant_qty     integer     NOT NULL DEFAULT 0,
  last_restocked_at timestamptz,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        uuid,
  CONSTRAINT service_center_inventory_pkey                PRIMARY KEY (id),
  CONSTRAINT service_center_inventory_service_center_key  UNIQUE (service_center),
  CONSTRAINT service_center_inventory_service_center_fkey FOREIGN KEY (service_center)
    REFERENCES public.service_centers(name),
  CONSTRAINT service_center_inventory_updated_by_fkey FOREIGN KEY (updated_by)
    REFERENCES auth.users(id)
);

ALTER TABLE public.service_center_inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can read inventory"
  ON public.service_center_inventory FOR SELECT
  TO authenticated USING (is_staff());

CREATE POLICY "No direct insert"
  ON public.service_center_inventory FOR INSERT
  TO authenticated WITH CHECK (false);

-- NOTE: TO PUBLIC (not TO authenticated) — matches production DB
CREATE POLICY "Admin or superadmin can update inventory"
  ON public.service_center_inventory FOR UPDATE
  TO PUBLIC
  USING (is_admin() OR is_superadmin())
  WITH CHECK (is_admin() OR is_superadmin());

CREATE POLICY "No direct delete"
  ON public.service_center_inventory FOR DELETE
  TO authenticated USING (false);

CREATE TRIGGER update_service_center_inventory_updated_at
  BEFORE UPDATE ON public.service_center_inventory
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ── 13. condom_requests ────────────────────────────────────
CREATE TABLE public.condom_requests (
  id                      uuid                  NOT NULL DEFAULT gen_random_uuid(),
  user_id                 uuid                  NOT NULL,
  condom_quantities       jsonb                 NOT NULL DEFAULT '{"49":0,"52":0,"54":0,"56":0}',
  lubricant_quantity      integer               NOT NULL DEFAULT 0,
  selected_date           date                           DEFAULT CURRENT_DATE,
  selected_time           time                           DEFAULT CURRENT_TIME,
  message                 text,
  reference_number        text                  NOT NULL,
  created_at              timestamptz           NOT NULL DEFAULT timezone('utc', now()),
  updated_at              timestamptz           NOT NULL DEFAULT timezone('utc', now()),
  selected_service_center text                  NOT NULL,
  request_status          public.request_status NOT NULL DEFAULT 'pending',
  cancel_reason           text,
  handled_by              uuid,
  completed_at            timestamptz,
  is_delay                boolean               NOT NULL DEFAULT false,
  CONSTRAINT condom_requests_pkey                 PRIMARY KEY (id),
  CONSTRAINT condom_requests_reference_number_key UNIQUE (reference_number),
  CONSTRAINT condom_requests_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES auth.users(id),
  CONSTRAINT condom_requests_handled_by_fkey FOREIGN KEY (handled_by)
    REFERENCES auth.users(id) ON DELETE SET NULL
);

ALTER TABLE public.condom_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own requests"
  ON public.condom_requests FOR INSERT
  TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "condom_requests_select"
  ON public.condom_requests FOR SELECT
  TO authenticated USING (
    is_admin() OR is_superadmin()
    OR (
      is_staff() AND (NOT is_admin()) AND (NOT is_superadmin())
      AND selected_service_center = (
        SELECT sp.service_center FROM staff_profiles sp
        WHERE sp.staff_user_id = (SELECT auth.uid())
      )
    )
    OR (SELECT auth.uid()) = user_id
  );

CREATE POLICY "condom_requests_update"
  ON public.condom_requests FOR UPDATE
  TO authenticated
  USING (
    is_admin() OR is_superadmin()
    OR (
      is_staff() AND (NOT is_admin()) AND (NOT is_superadmin())
      AND selected_service_center = (
        SELECT sp.service_center FROM staff_profiles sp
        WHERE sp.staff_user_id = (SELECT auth.uid())
      )
    )
    OR (SELECT auth.uid()) = user_id
  )
  WITH CHECK (
    is_admin() OR is_superadmin()
    OR (
      is_staff() AND (NOT is_admin()) AND (NOT is_superadmin())
      AND selected_service_center = (
        SELECT sp.service_center FROM staff_profiles sp
        WHERE sp.staff_user_id = (SELECT auth.uid())
      )
    )
    OR (
      (SELECT auth.uid()) = user_id
      AND request_status = 'cancelled_by_user'::public.request_status
    )
  );

CREATE TRIGGER update_condom_requests_updated_at
  BEFORE UPDATE ON public.condom_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_request_is_delay
  BEFORE UPDATE ON public.condom_requests
  FOR EACH ROW EXECUTE FUNCTION set_is_delay();

CREATE TRIGGER set_handled_by_and_completed_at
  BEFORE UPDATE OF request_status ON public.condom_requests
  FOR EACH ROW WHEN (OLD.request_status IS DISTINCT FROM NEW.request_status)
  EXECUTE FUNCTION set_handled_by_and_completed_at();

CREATE TRIGGER prevent_staff_full_update
  BEFORE UPDATE ON public.condom_requests
  FOR EACH ROW EXECUTE FUNCTION check_staff_update_columns();

CREATE TRIGGER track_request_status
  AFTER UPDATE ON public.condom_requests
  FOR EACH ROW WHEN (OLD.request_status IS DISTINCT FROM NEW.request_status)
  EXECUTE FUNCTION track_request_status();

CREATE TRIGGER deduct_inventory_on_request_complete
  AFTER UPDATE OF request_status ON public.condom_requests
  FOR EACH ROW WHEN (
    NEW.request_status = 'completed'::public.request_status
    AND OLD.request_status <> 'completed'::public.request_status
  ) EXECUTE FUNCTION deduct_inventory_on_complete();

CREATE TRIGGER restore_quota_on_staff_cancel_pending
  AFTER UPDATE OF request_status ON public.condom_requests
  FOR EACH ROW WHEN (
    NEW.request_status = 'cancelled_by_staff'::public.request_status
    AND OLD.request_status = 'pending'::public.request_status
  ) EXECUTE FUNCTION restore_quota_on_staff_cancel_pending();

CREATE TRIGGER notify_staff_on_request_change
  AFTER INSERT OR UPDATE ON public.condom_requests
  FOR EACH ROW EXECUTE FUNCTION handle_staff_request_notification();

CREATE TRIGGER notify_user_on_request_change
  AFTER INSERT OR UPDATE ON public.condom_requests
  FOR EACH ROW EXECUTE FUNCTION handle_user_request_notification();


-- ── 14. request_status_logs ────────────────────────────────
CREATE TABLE public.request_status_logs (
  id          uuid                  NOT NULL DEFAULT gen_random_uuid(),
  request_id  uuid                  NOT NULL,
  from_status public.request_status,
  to_status   public.request_status NOT NULL,
  changed_by  uuid,
  changed_at  timestamptz           NOT NULL DEFAULT now(),
  CONSTRAINT request_status_logs_pkey            PRIMARY KEY (id),
  CONSTRAINT request_status_logs_request_id_fkey FOREIGN KEY (request_id)
    REFERENCES public.condom_requests(id) ON DELETE CASCADE,
  CONSTRAINT request_status_logs_changed_by_fkey FOREIGN KEY (changed_by)
    REFERENCES auth.users(id)
);

ALTER TABLE public.request_status_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can read all status logs"
  ON public.request_status_logs FOR SELECT
  TO authenticated USING (is_staff());

CREATE POLICY "No one can update status logs"
  ON public.request_status_logs FOR UPDATE
  TO authenticated USING (false);

CREATE POLICY "No one can delete status logs"
  ON public.request_status_logs FOR DELETE
  TO authenticated USING (false);


-- ── 15. inventory_logs ─────────────────────────────────────
CREATE TABLE public.inventory_logs (
  id                   uuid                NOT NULL DEFAULT gen_random_uuid(),
  performed_by         uuid,
  action               public.audit_action NOT NULL,
  service_center       text                NOT NULL,
  condom_delta         integer             NOT NULL DEFAULT 0,
  lubricant_delta      integer             NOT NULL DEFAULT 0,
  reason               text,
  created_at           timestamptz         NOT NULL DEFAULT now(),
  note                 text,
  reference_request_id uuid,
  CONSTRAINT inventory_logs_pkey                       PRIMARY KEY (id),
  CONSTRAINT inventory_logs_performed_by_fkey FOREIGN KEY (performed_by)
    REFERENCES auth.users(id),
  CONSTRAINT inventory_logs_reference_request_id_fkey FOREIGN KEY (reference_request_id)
    REFERENCES public.condom_requests(id) ON DELETE SET NULL
);

ALTER TABLE public.inventory_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_insert_inventory_logs"
  ON public.inventory_logs FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (
      SELECT 1 FROM staff_profiles
      WHERE staff_user_id = (SELECT auth.uid())
        AND role = ANY (ARRAY['admin'::public.role, 'superadmin'::public.role])
    )
  );

CREATE POLICY "superadmin_read_inventory_logs"
  ON public.inventory_logs FOR SELECT
  TO authenticated USING (is_superadmin());

CREATE TRIGGER apply_inventory_adjustment
  AFTER INSERT ON public.inventory_logs
  FOR EACH ROW EXECUTE FUNCTION apply_inventory_adjustment();


-- ── 16. doctor_appointments ────────────────────────────────
CREATE TABLE public.doctor_appointments (
  id                      uuid                      NOT NULL DEFAULT gen_random_uuid(),
  user_id                 uuid                      NOT NULL,
  reference_number        text                      NOT NULL,
  reason                  text                      NOT NULL,
  selected_service_center text                      NOT NULL,
  selected_date           date                      NOT NULL,
  selected_time           text                      NOT NULL,
  note                    text,
  appointment_status      public.appointment_status NOT NULL DEFAULT 'pending',
  cancel_reason           text,
  handled_by              uuid,
  created_at              timestamptz               NOT NULL DEFAULT timezone('utc', now()),
  updated_at              timestamptz               NOT NULL DEFAULT timezone('utc', now()),
  CONSTRAINT doctor_appointments_pkey                  PRIMARY KEY (id),
  CONSTRAINT doctor_appointments_reference_number_key  UNIQUE (reference_number),
  CONSTRAINT doctor_appointments_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES auth.users(id),
  CONSTRAINT doctor_appointments_handled_by_fkey FOREIGN KEY (handled_by)
    REFERENCES auth.users(id)
);

ALTER TABLE public.doctor_appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own appointments"
  ON public.doctor_appointments FOR INSERT
  TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "doctor_appointments_select"
  ON public.doctor_appointments FOR SELECT
  TO authenticated USING (
    is_admin() OR is_superadmin()
    OR (
      is_staff()
      AND selected_service_center = (
        SELECT sp.service_center FROM staff_profiles sp
        WHERE sp.staff_user_id = (SELECT auth.uid())
      )
    )
    OR (SELECT auth.uid()) = user_id
  );

CREATE POLICY "doctor_appointments_update"
  ON public.doctor_appointments FOR UPDATE
  TO authenticated
  USING (
    is_admin() OR is_superadmin()
    OR (
      is_staff() AND (NOT is_admin()) AND (NOT is_superadmin())
      AND selected_service_center = (
        SELECT sp.service_center FROM staff_profiles sp
        WHERE sp.staff_user_id = (SELECT auth.uid())
      )
    )
    OR (SELECT auth.uid()) = user_id
  )
  WITH CHECK (
    is_admin() OR is_superadmin()
    OR (
      is_staff() AND (NOT is_admin()) AND (NOT is_superadmin())
      AND selected_service_center = (
        SELECT sp.service_center FROM staff_profiles sp
        WHERE sp.staff_user_id = (SELECT auth.uid())
      )
    )
    OR (
      (SELECT auth.uid()) = user_id
      AND appointment_status = 'cancelled_by_user'::public.appointment_status
    )
  );

CREATE TRIGGER update_doctor_appointments_updated_at
  BEFORE UPDATE ON public.doctor_appointments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER track_appointment_status
  AFTER UPDATE OF appointment_status ON public.doctor_appointments
  FOR EACH ROW EXECUTE FUNCTION track_appointment_status();

CREATE TRIGGER notify_staff_on_appointment_change
  AFTER INSERT OR UPDATE ON public.doctor_appointments
  FOR EACH ROW EXECUTE FUNCTION handle_staff_appointment_notification();

CREATE TRIGGER notify_user_on_appointment_change
  AFTER INSERT OR UPDATE ON public.doctor_appointments
  FOR EACH ROW EXECUTE FUNCTION handle_user_appointment_notification();


-- ── 17. appointment_status_logs ────────────────────────────
CREATE TABLE public.appointment_status_logs (
  id             uuid                      NOT NULL DEFAULT gen_random_uuid(),
  appointment_id uuid                      NOT NULL,
  from_status    public.appointment_status,
  to_status      public.appointment_status NOT NULL,
  changed_by     uuid,
  changed_at     timestamptz               NOT NULL DEFAULT now(),
  CONSTRAINT appointment_status_logs_pkey                PRIMARY KEY (id),
  CONSTRAINT appointment_status_logs_appointment_id_fkey FOREIGN KEY (appointment_id)
    REFERENCES public.doctor_appointments(id) ON DELETE CASCADE
);

ALTER TABLE public.appointment_status_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "staff can read appointment status logs"
  ON public.appointment_status_logs FOR SELECT
  TO authenticated USING (
    EXISTS (
      SELECT 1 FROM staff_profiles
      WHERE staff_user_id = (SELECT auth.uid())
    )
  );


-- ── 18. articles ───────────────────────────────────────────
CREATE TABLE public.articles (
  id                     uuid                  NOT NULL DEFAULT gen_random_uuid(),
  title                  text                  NOT NULL,
  cover_image_url        text,
  content_json           jsonb                 NOT NULL DEFAULT '{}',
  content_html           text                  NOT NULL DEFAULT '',
  publish_at             timestamptz,
  created_by             uuid,
  created_at             timestamptz                    DEFAULT now(),
  updated_at             timestamptz                    DEFAULT now(),
  has_draft              boolean               NOT NULL DEFAULT false,
  is_visible             boolean               NOT NULL DEFAULT true,
  status                 public.article_status NOT NULL DEFAULT 'draft',
  published_content_html text,
  published_content_json jsonb,
  CONSTRAINT articles_pkey         PRIMARY KEY (id),
  CONSTRAINT articles_created_by_fkey FOREIGN KEY (created_by)
    REFERENCES auth.users(id)
);

ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_read_published_articles"
  ON public.articles FOR SELECT
  TO anon USING (
    publish_at IS NOT NULL AND publish_at <= now() AND is_visible = true
  );

CREATE POLICY "auth_read_all_articles"
  ON public.articles FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "admin_insert_articles"
  ON public.articles FOR INSERT
  TO authenticated WITH CHECK (is_admin() OR is_superadmin());

CREATE POLICY "admin_update_articles"
  ON public.articles FOR UPDATE
  TO authenticated USING (is_admin() OR is_superadmin());

CREATE POLICY "admin_delete_articles"
  ON public.articles FOR DELETE
  TO authenticated USING (is_admin() OR is_superadmin());

CREATE TRIGGER update_articles_updated_at
  BEFORE UPDATE ON public.articles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_article_status_trigger
  BEFORE INSERT OR UPDATE OF publish_at, is_visible ON public.articles
  FOR EACH ROW EXECUTE FUNCTION set_article_status();

CREATE TRIGGER snapshot_published_content_trigger
  BEFORE UPDATE OF has_draft ON public.articles
  FOR EACH ROW EXECUTE FUNCTION snapshot_published_content();


-- ============================================================
-- SECTION 5: CROSS-TABLE RPCs
-- ============================================================

-- ── Audit (service_role only — no explicit GRANT) ───────────
CREATE OR REPLACE FUNCTION public.write_audit_log(
  p_action       public.audit_action,
  p_target_table text,
  p_target_id    uuid,
  p_old_value    jsonb DEFAULT NULL,
  p_new_value    jsonb DEFAULT NULL,
  p_performed_by uuid  DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.staff_audit_logs (performed_by, action, target_table, target_id, old_value, new_value)
  VALUES (COALESCE(p_performed_by, auth.uid()), p_action, p_target_table, p_target_id, p_old_value, p_new_value);
END;
$$;

CREATE OR REPLACE FUNCTION public.log_audit_event(
  p_performed_by uuid,
  p_action       text,
  p_target_table text,
  p_target_id    uuid,
  p_old_value    jsonb DEFAULT NULL,
  p_new_value    jsonb DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  PERFORM public.write_audit_log(
    p_action::public.audit_action, p_target_table, p_target_id,
    p_old_value, p_new_value, p_performed_by
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
  IF NOT is_superadmin() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
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
  SELECT COUNT(*) INTO v_staff_count FROM staff_profiles WHERE service_center = p_name;
  IF v_staff_count > 0 THEN
    RAISE EXCEPTION 'ไม่สามารถลบสถานบริการที่ยังมีเจ้าหน้าที่อยู่ได้ กรุณาย้ายเจ้าหน้าที่ออกก่อน';
  END IF;
  DELETE FROM service_center_inventory WHERE service_center = p_name;
  DELETE FROM service_centers WHERE name = p_name AND is_active = false;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'สถานบริการต้องถูกปิดใช้งานก่อนจึงจะสามารถลบได้';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.init_service_center_inventory(p_name text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT is_superadmin() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  INSERT INTO service_center_inventory (service_center, condom_qty, lubricant_qty)
    VALUES (p_name, 0, 0) ON CONFLICT DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION public.toggle_service_center_active(p_name text, p_is_active boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT is_superadmin() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  UPDATE service_centers SET is_active = p_is_active WHERE name = p_name;
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


-- ── Request / appointment creation ─────────────────────────
CREATE OR REPLACE FUNCTION public.create_condom_request(
  p_user_id                 uuid,
  p_condom_quantities       jsonb,
  p_lubricant_quantity      integer,
  p_selected_service_center text,
  p_selected_date           text,
  p_selected_time           text DEFAULT NULL,
  p_message                 text DEFAULT NULL
) RETURNS text
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
DECLARE
  v_ref_number text;
  v_attempts   int := 0;
BEGIN
  LOOP
    v_ref_number := 'NK-REQ-' || LPAD((10000 + floor(random() * 90000)::int)::text, 5, '0');
    BEGIN
      INSERT INTO public.condom_requests (
        user_id, reference_number, condom_quantities,
        lubricant_quantity, selected_service_center,
        selected_date, selected_time, message, request_status
      ) VALUES (
        p_user_id, v_ref_number, p_condom_quantities,
        p_lubricant_quantity, p_selected_service_center,
        p_selected_date::date, p_selected_time::time, p_message, 'pending'
      );
      RETURN v_ref_number;
    EXCEPTION WHEN unique_violation THEN
      v_attempts := v_attempts + 1;
      IF v_attempts >= 10 THEN
        RAISE EXCEPTION 'Failed to generate unique reference number';
      END IF;
    END;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_doctor_appointment(
  p_user_id        uuid,
  p_reason         text,
  p_service_center text,
  p_date           date,
  p_time           text,
  p_note           text DEFAULT NULL
) RETURNS text
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
DECLARE
  v_ref_number text;
  v_attempts   int := 0;
BEGIN
  LOOP
    v_ref_number := 'NK-APT-' || LPAD((10000 + floor(random() * 90000)::int)::text, 5, '0');
    BEGIN
      INSERT INTO doctor_appointments (
        user_id, reference_number, reason,
        selected_service_center, selected_date, selected_time, note
      ) VALUES (p_user_id, v_ref_number, p_reason, p_service_center, p_date, p_time, p_note);
      RETURN v_ref_number;
    EXCEPTION WHEN unique_violation THEN
      v_attempts := v_attempts + 1;
      IF v_attempts >= 10 THEN
        RAISE EXCEPTION 'Failed to generate unique reference number';
      END IF;
    END;
  END LOOP;
END;
$$;


-- ── Recovery code RPCs ──────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_days_until_reset()
RETURNS integer
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT (date_trunc('month', now()) + interval '1 month')::date - now()::date;
$$;

CREATE OR REPLACE FUNCTION public.save_recovery_codes(secret_codes text[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    current_user_id UUID;
    code            TEXT;
BEGIN
    current_user_id := auth.uid();
    IF current_user_id IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
    DELETE FROM public.user_recovery_codes WHERE user_id = current_user_id;
    FOREACH code IN ARRAY secret_codes LOOP
        INSERT INTO public.user_recovery_codes (user_id, code_hash, used)
        VALUES (current_user_id, crypt(code, gen_salt('bf')), FALSE);
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.verify_recovery_code(p_username text, p_recovery_code text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id           UUID;
    v_code_record       RECORD;
    v_code_matched      BOOLEAN := FALSE;
    v_attempt_count     INT;
    v_last_24h_failures INT;
    v_generic_error     TEXT := 'ชื่อผู้ใช้งานหรือรหัสกู้คืนไม่ถูกต้อง';
BEGIN
    SELECT id INTO v_user_id FROM auth.users WHERE email = p_username || '@mycarenk.local';

    IF v_user_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_last_24h_failures
        FROM public.recovery_attempts
        WHERE user_id = v_user_id
          AND attempted_at > now() - INTERVAL '24 hours'
          AND success = FALSE;

        IF v_last_24h_failures >= 10 THEN
            RETURN json_build_object(
                'success', FALSE,
                'error', 'บัญชีถูกล็อกชั่วคราว กรุณาลองใหม่ภายหลัง',
                'locked', TRUE
            );
        END IF;

        SELECT COUNT(*) INTO v_attempt_count
        FROM public.recovery_attempts
        WHERE user_id = v_user_id AND attempted_at > now() - INTERVAL '1 hour';

        IF v_attempt_count >= 5 THEN
            RETURN json_build_object(
                'success', FALSE,
                'error', 'คุณลองกู้คืนบัญชีมากเกินไป กรุณาลองใหม่อีกครั้งในอีก 1 ชั่วโมง',
                'rate_limited', TRUE
            );
        END IF;
    END IF;

    IF v_user_id IS NOT NULL THEN
        FOR v_code_record IN
            SELECT id, code_hash FROM public.user_recovery_codes
            WHERE user_id = v_user_id AND used = FALSE
        LOOP
            IF v_code_record.code_hash = crypt(p_recovery_code, v_code_record.code_hash) THEN
                v_code_matched := TRUE;
                EXIT;
            END IF;
        END LOOP;
    END IF;

    IF v_user_id IS NOT NULL THEN
        INSERT INTO public.recovery_attempts (user_id, success) VALUES (v_user_id, v_code_matched);
    END IF;

    IF NOT v_code_matched THEN
        RETURN json_build_object('success', FALSE, 'error', v_generic_error);
    END IF;

    RETURN json_build_object('success', TRUE);
END;
$function$;

CREATE OR REPLACE FUNCTION public.verify_recovery_code_and_reset_password(
  p_username      text,
  p_recovery_code text,
  p_new_password  text
) RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id           UUID;
    v_code_record       RECORD;
    v_code_matched      BOOLEAN := FALSE;
    v_matched_code_id   UUID;
    v_attempt_count     INT;
    v_last_24h_failures INT;
    v_new_codes         TEXT[];
    v_new_code          TEXT;
    v_hashed_password   TEXT;
    v_generic_error     TEXT := 'ชื่อผู้ใช้งานหรือรหัสกู้คืนไม่ถูกต้อง';
    i                   INT;
BEGIN
    SELECT id INTO v_user_id FROM auth.users WHERE email = p_username || '@mycarenk.local';

    IF v_user_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_last_24h_failures
        FROM public.recovery_attempts
        WHERE user_id = v_user_id
          AND attempted_at > now() - INTERVAL '24 hours'
          AND success = FALSE;

        IF v_last_24h_failures >= 10 THEN
            RETURN json_build_object(
                'success', FALSE,
                'error', 'บัญชีถูกล็อกชั่วคราว กรุณาลองใหม่ภายหลัง',
                'locked', TRUE
            );
        END IF;

        SELECT COUNT(*) INTO v_attempt_count
        FROM public.recovery_attempts
        WHERE user_id = v_user_id AND attempted_at > now() - INTERVAL '1 hour';

        IF v_attempt_count >= 5 THEN
            RETURN json_build_object(
                'success', FALSE,
                'error', 'คุณลองกู้คืนบัญชีมากเกินไป กรุณาลองใหม่อีกครั้งในอีก 1 ชั่วโมง',
                'rate_limited', TRUE
            );
        END IF;
    END IF;

    IF v_user_id IS NOT NULL THEN
        FOR v_code_record IN
            SELECT id, code_hash FROM public.user_recovery_codes
            WHERE user_id = v_user_id AND used = FALSE
        LOOP
            IF v_code_record.code_hash = crypt(p_recovery_code, v_code_record.code_hash) THEN
                v_code_matched := TRUE;
                v_matched_code_id := v_code_record.id;
                EXIT;
            END IF;
        END LOOP;
    END IF;

    IF v_user_id IS NOT NULL THEN
        INSERT INTO public.recovery_attempts (user_id, success) VALUES (v_user_id, v_code_matched);
    END IF;

    IF NOT v_code_matched THEN
        RETURN json_build_object('success', FALSE, 'error', v_generic_error);
    END IF;

    v_hashed_password := crypt(p_new_password, gen_salt('bf'));
    UPDATE auth.users
    SET encrypted_password = v_hashed_password, updated_at = now()
    WHERE id = v_user_id;

    UPDATE public.user_recovery_codes SET used = TRUE, used_at = now() WHERE id = v_matched_code_id;
    DELETE FROM public.user_recovery_codes WHERE user_id = v_user_id AND used = FALSE;

    v_new_codes := ARRAY[]::TEXT[];
    FOR i IN 1..6 LOOP
        v_new_code  := upper(substr(encode(gen_random_bytes(3), 'hex'), 1, 6));
        v_new_codes := array_append(v_new_codes, v_new_code);
        INSERT INTO public.user_recovery_codes (user_id, code_hash, used)
        VALUES (v_user_id, crypt(v_new_code, gen_salt('bf')), FALSE);
    END LOOP;

    RETURN json_build_object('success', TRUE, 'new_recovery_codes', to_json(v_new_codes));
END;
$function$;


-- ── Service centers ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_service_centers()
RETURNS SETOF public.service_centers
LANGUAGE sql
SECURITY INVOKER
SET search_path TO 'public'
AS $$
  SELECT * FROM service_centers ORDER BY display_order, name;
$$;


-- ── Article RPCs ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_published_articles(
  p_limit  integer DEFAULT 10,
  p_offset integer DEFAULT 0
) RETURNS TABLE(
  id             uuid,
  title          text,
  excerpt        text,
  cover_image_url text,
  publish_at     timestamptz,
  created_by_name text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    a.id,
    a.title,
    LEFT(regexp_replace(COALESCE(a.published_content_html, a.content_html), '<[^>]+>', '', 'g'), 120) AS excerpt,
    a.cover_image_url,
    a.publish_at,
    COALESCE(sp.first_name || ' ' || sp.last_name, '') AS created_by_name
  FROM articles a
  LEFT JOIN staff_profiles sp ON sp.staff_user_id = a.created_by
  WHERE a.status = 'published' AND a.publish_at <= now() AND a.is_visible = true
  ORDER BY a.publish_at DESC
  LIMIT p_limit OFFSET p_offset;
$$;

CREATE OR REPLACE FUNCTION public.get_article_detail(p_article_id uuid)
RETURNS TABLE(
  id              uuid,
  title           text,
  cover_image_url text,
  content_json    jsonb,
  publish_at      timestamptz,
  created_by_name text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    a.id,
    a.title,
    a.cover_image_url,
    COALESCE(a.published_content_json, a.content_json) AS content_json,
    a.publish_at,
    COALESCE(sp.first_name || ' ' || sp.last_name, '') AS created_by_name
  FROM articles a
  LEFT JOIN staff_profiles sp ON sp.staff_user_id = a.created_by
  WHERE a.id = p_article_id
    AND a.status = 'published'
    AND a.publish_at <= now()
    AND a.is_visible = true;
$$;


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
BEGIN
  RETURN QUERY
  WITH date_series AS (
    SELECT generate_series(
      (NOW() AT TIME ZONE 'Asia/Bangkok')::date - INTERVAL '29 days',
      (NOW() AT TIME ZONE 'Asia/Bangkok')::date,
      INTERVAL '1 day'
    )::date AS day
  ),
  centers AS (SELECT DISTINCT sci.service_center FROM service_center_inventory sci),
  daily_raw AS (
    SELECT (il.created_at AT TIME ZONE 'Asia/Bangkok')::date AS day, il.service_center,
      GREATEST(SUM(-il.condom_delta), 0)::integer    AS condom_used,
      GREATEST(SUM(-il.lubricant_delta), 0)::integer AS lubricant_used
    FROM inventory_logs il
    WHERE il.action = 'fulfillment' AND il.created_at >= NOW() - INTERVAL '30 days'
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
  service_center      text,
  is_active           boolean,
  condom_qty          integer,
  lubricant_qty       integer,
  condom_daily_burn   numeric,
  lubricant_daily_burn numeric,
  condom_days_left    numeric,
  lubricant_days_left numeric
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
  SELECT sci.service_center,
    COALESCE(sc.is_active, true)        AS is_active,
    sci.condom_qty,
    sci.lubricant_qty,
    COALESCE(b.condom_daily_burn, 0)    AS condom_daily_burn,
    COALESCE(b.lubricant_daily_burn, 0) AS lubricant_daily_burn,
    CASE WHEN COALESCE(b.condom_daily_burn, 0) = 0 THEN NULL
         ELSE ROUND(sci.condom_qty::numeric / b.condom_daily_burn, 1) END AS condom_days_left,
    CASE WHEN COALESCE(b.lubricant_daily_burn, 0) = 0 THEN NULL
         ELSE ROUND(sci.lubricant_qty::numeric / b.lubricant_daily_burn, 1) END AS lubricant_days_left
  FROM service_center_inventory sci
  LEFT JOIN service_centers sc ON sc.name = sci.service_center
  LEFT JOIN burn b ON b.service_center = sci.service_center
  ORDER BY sci.service_center;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_service_center_demand(
  p_date_from timestamptz,
  p_date_to   timestamptz
) RETURNS TABLE(service_center text, total_requests integer, total_condoms integer, total_lubricants integer)
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
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
  GROUP BY sc.name
  ORDER BY total_requests DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_service_center_demand_trend()
RETURNS TABLE(service_center text, day date, request_count integer)
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
  v_start date := (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Bangkok')::date - 29;
  v_end   date := (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Bangkok')::date;
BEGIN
  RETURN QUERY
  SELECT sc.name AS service_center, d.day::date AS day, COALESCE(COUNT(r.id)::integer, 0) AS request_count
  FROM generate_series(v_start, v_end, '1 day'::interval) d(day)
  CROSS JOIN service_centers sc
  LEFT JOIN condom_requests r
         ON r.selected_service_center = sc.name
        AND (r.created_at AT TIME ZONE 'Asia/Bangkok')::date = d.day
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
BEGIN
  IF NOT is_superadmin() THEN RAISE EXCEPTION 'Permission denied'; END IF;
  RETURN QUERY
  SELECT sp.staff_user_id, sp.first_name::text, sp.last_name::text, sp.service_center,
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
  WHERE (p_service_center IS NULL OR sp.service_center = p_service_center)
  GROUP BY sp.staff_user_id, sp.first_name, sp.last_name, sp.service_center
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
  v_from timestamptz := COALESCE(p_date_from, now() - interval '90 days');
  v_to   timestamptz := COALESCE(p_date_to,   now());
BEGIN
  IF NOT is_superadmin() THEN RAISE EXCEPTION 'Permission denied'; END IF;
  RETURN QUERY
  WITH staff AS (
    SELECT sp.staff_user_id AS uid FROM staff_profiles sp
    WHERE (p_service_center IS NULL OR sp.service_center = p_service_center)
      AND (p_staff_user_id  IS NULL OR sp.staff_user_id  = p_staff_user_id)
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
  p_offset           integer     DEFAULT 0
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
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.staff_profiles WHERE staff_user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;
  RETURN QUERY
  SELECT rsl.id, rsl.request_id, cr.reference_number,
    rsl.changed_by AS performed_by,
    CASE
      WHEN sp.staff_user_id IS NOT NULL THEN sp.first_name || ' ' || sp.last_name
      WHEN up.user_id       IS NOT NULL THEN 'ผู้ใช้'
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
  p_offset           integer     DEFAULT 0
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
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.staff_profiles WHERE staff_user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Permission denied';
  END IF;
  RETURN QUERY
  SELECT asl.id, asl.appointment_id, da.reference_number,
    asl.changed_by AS performed_by,
    CASE
      WHEN sp.staff_user_id IS NOT NULL THEN sp.first_name || ' ' || sp.last_name
      WHEN up.user_id       IS NOT NULL THEN 'ผู้ใช้'
      ELSE 'ระบบ'
    END AS full_name,
    asl.from_status::text, asl.to_status::text, asl.changed_at
  FROM appointment_status_logs asl
  LEFT JOIN staff_profiles      sp ON sp.staff_user_id = asl.changed_by
  LEFT JOIN user_profiles       up ON up.user_id        = asl.changed_by
  LEFT JOIN doctor_appointments da ON da.id              = asl.appointment_id
  WHERE (p_performed_by     IS NULL OR asl.changed_by           = p_performed_by)
    AND (p_from_status      IS NULL OR asl.from_status::text    = p_from_status)
    AND (p_to_status        IS NULL OR asl.to_status::text      = p_to_status)
    AND (p_reference_number IS NULL OR da.reference_number ILIKE '%' || p_reference_number || '%')
    AND (p_date_from        IS NULL OR asl.changed_at           >= p_date_from)
    AND (p_date_to          IS NULL OR asl.changed_at           <= p_date_to)
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
  id              uuid,
  performed_by    uuid,
  full_name       text,
  action          public.audit_action,
  service_center  text,
  condom_delta    integer,
  lubricant_delta integer,
  reason          text,
  note            text,
  created_at      timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT (is_admin() OR is_superadmin()) THEN RAISE EXCEPTION 'Permission denied'; END IF;
  RETURN QUERY
  SELECT il.id, il.performed_by,
    COALESCE(sp.first_name || ' ' || sp.last_name, 'ระบบ') AS full_name,
    il.action, il.service_center, il.condom_delta, il.lubricant_delta, il.reason, il.note, il.created_at
  FROM public.inventory_logs il
  LEFT JOIN staff_profiles sp ON sp.staff_user_id = il.performed_by
  WHERE (p_action         IS NULL OR il.action::text      = p_action)
    AND (p_service_center IS NULL OR il.service_center    = p_service_center)
    AND (p_date_from      IS NULL OR il.created_at       >= p_date_from)
    AND (p_date_to        IS NULL OR il.created_at       <= p_date_to)
  ORDER BY il.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_staff_audit_log(
  p_performed_by uuid        DEFAULT NULL,
  p_action       text        DEFAULT NULL,
  p_target_id    text        DEFAULT NULL,
  p_date_from    timestamptz DEFAULT NULL,
  p_date_to      timestamptz DEFAULT NULL,
  p_limit        integer     DEFAULT 50,
  p_offset       integer     DEFAULT 0
) RETURNS TABLE(
  id              uuid,
  performed_by    uuid,
  full_name       text,
  action          public.audit_action,
  target_id       uuid,
  target_full_name text,
  old_value       jsonb,
  new_value       jsonb,
  created_at      timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT is_superadmin() THEN RAISE EXCEPTION 'Permission denied'; END IF;
  RETURN QUERY
  SELECT al.id, al.performed_by,
    COALESCE(sp.first_name || ' ' || sp.last_name, 'ระบบ') AS full_name,
    al.action, al.target_id,
    COALESCE(
      tsp.first_name || ' ' || tsp.last_name,
      NULLIF(TRIM(COALESCE(al.new_value->>'first_name', '') || ' ' || COALESCE(al.new_value->>'last_name', '')), ' '),
      NULLIF(TRIM(COALESCE(al.old_value->>'first_name', '') || ' ' || COALESCE(al.old_value->>'last_name', '')), ' ')
    ) AS target_full_name,
    al.old_value, al.new_value, al.created_at
  FROM public.staff_audit_logs al
  LEFT JOIN staff_profiles sp  ON sp.staff_user_id = al.performed_by
  LEFT JOIN staff_profiles tsp ON tsp.staff_user_id = al.target_id
  WHERE (p_performed_by IS NULL OR al.performed_by                = p_performed_by)
    AND (p_action       IS NULL OR al.action::text                = p_action)
    AND (p_target_id    IS NULL OR al.target_id::text ILIKE '%' || p_target_id || '%')
    AND (p_date_from    IS NULL OR al.created_at                 >= p_date_from)
    AND (p_date_to      IS NULL OR al.created_at                 <= p_date_to)
  ORDER BY al.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_audit_log(
  p_performed_by uuid        DEFAULT NULL,
  p_action       text        DEFAULT NULL,
  p_target_table text        DEFAULT NULL,
  p_target_id    text        DEFAULT NULL,
  p_date_from    timestamptz DEFAULT NULL,
  p_date_to      timestamptz DEFAULT NULL,
  p_limit        integer     DEFAULT 50,
  p_offset       integer     DEFAULT 0
) RETURNS TABLE(
  id               uuid,
  performed_by     uuid,
  full_name        text,
  action           public.audit_action,
  target_table     text,
  target_id        text,
  target_full_name text,
  old_value        jsonb,
  new_value        jsonb,
  created_at       timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT is_superadmin() THEN RAISE EXCEPTION 'Permission denied'; END IF;
  RETURN QUERY
  SELECT al.id, al.performed_by,
    CASE
      WHEN sp.staff_user_id IS NOT NULL THEN sp.first_name || ' ' || sp.last_name
      WHEN up.user_id       IS NOT NULL THEN 'ผู้ใช้'
      ELSE 'ระบบ'
    END AS full_name,
    al.action, al.target_table,
    al.target_id::text,
    COALESCE(
      tsp.first_name || ' ' || tsp.last_name,
      NULLIF(TRIM(COALESCE(al.new_value->>'first_name', '') || ' ' || COALESCE(al.new_value->>'last_name', '')), ' '),
      NULLIF(TRIM(COALESCE(al.old_value->>'first_name', '') || ' ' || COALESCE(al.old_value->>'last_name', '')), ' ')
    ) AS target_full_name,
    al.old_value, al.new_value, al.created_at
  FROM staff_audit_logs al
  LEFT JOIN staff_profiles sp  ON sp.staff_user_id = al.performed_by
  LEFT JOIN user_profiles  up  ON up.user_id        = al.performed_by
  LEFT JOIN staff_profiles tsp ON tsp.staff_user_id = al.target_id
  WHERE (p_performed_by IS NULL OR al.performed_by             = p_performed_by)
    AND (p_action       IS NULL OR al.action::text             = p_action)
    AND (p_target_table IS NULL OR al.target_table             = p_target_table)
    AND (p_target_id    IS NULL OR al.target_id::text ILIKE '%' || p_target_id || '%')
    AND (p_date_from    IS NULL OR al.created_at              >= p_date_from)
    AND (p_date_to      IS NULL OR al.created_at              <= p_date_to)
  ORDER BY al.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$;


-- ============================================================
-- SECTION 6: REVOKE + GRANTs
-- ============================================================

-- Start from a clean slate: revoke PUBLIC pseudo-role AND explicit Supabase grants
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC, anon, authenticated;

-- Role helper functions (required by RLS policies)
GRANT EXECUTE ON FUNCTION public.is_staff()                   TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin()                   TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_superadmin()              TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_updated_at_column()   TO authenticated;

-- Recovery RPCs
GRANT EXECUTE ON FUNCTION public.get_days_until_reset()       TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_recovery_codes(text[])  TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_recovery_code(text, text)                         TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_recovery_code_and_reset_password(text, text, text) TO anon, authenticated;

-- Public article RPCs (accessible to unauthenticated app users)
GRANT EXECUTE ON FUNCTION public.get_published_articles(integer, integer) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_article_detail(uuid)                 TO anon, authenticated;

-- Analytics — staff/admin only (require authenticated session)
GRANT EXECUTE ON FUNCTION public.get_average_lead_time(timestamptz, timestamptz, text)          TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_peak_time_stats(text, timestamptz, timestamptz, text)      TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_service_center_demand(timestamptz, timestamptz)            TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_service_center_demand_trend()                              TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_consumption_trend()                                        TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_inventory_forecast()                                       TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_staff_workload(timestamptz, timestamptz, text)             TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_staff_workload_trend(text, uuid, timestamptz, timestamptz) TO authenticated;

-- Service center RPCs
GRANT EXECUTE ON FUNCTION public.get_service_centers()                                          TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_service_center(text)                                       TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_service_center(text)                                    TO authenticated;
GRANT EXECUTE ON FUNCTION public.init_service_center_inventory(text)                            TO authenticated;
GRANT EXECUTE ON FUNCTION public.toggle_service_center_active(text, boolean)                    TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_service_center(text, text, text, jsonb, double precision, double precision, smallint, text, text, boolean, boolean, text[], text[]) TO authenticated;

-- Request / appointment creation
GRANT EXECUTE ON FUNCTION public.create_condom_request(uuid, jsonb, integer, text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_doctor_appointment(uuid, text, text, date, text, text)        TO authenticated;

-- Log query RPCs
GRANT EXECUTE ON FUNCTION public.get_request_status_log(uuid, text, text, text, timestamptz, timestamptz, integer, integer)     TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_appointment_status_log(uuid, text, text, text, timestamptz, timestamptz, integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_inventory_log(text, text, timestamptz, timestamptz, integer, integer)                      TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_staff_audit_log(uuid, text, text, timestamptz, timestamptz, integer, integer)              TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_audit_log(uuid, text, text, text, timestamptz, timestamptz, integer, integer)              TO authenticated;

-- write_audit_log / log_audit_event: intentionally NOT granted to anon/authenticated
-- (service_role access only — used by Edge Functions)


-- ============================================================
-- SECTION 7: REALTIME
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.condom_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.doctor_appointments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.staff_notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.staff_notification_reads;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_notification_reads;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_monthly_quotas;
