-- ============================================================
-- 04_tables.sql — MyCareNK
-- All 19 tables in FK dependency order, each with RLS policies
-- and inline trigger attachments.
-- Apply order: 4 of 8
-- ============================================================
--
-- Table order:
--   1.  service_centers            2.  user_profiles
--   3.  user_monthly_quotas        4.  user_recovery_codes
--   5.  recovery_attempts          6.  staff_profiles
--   7.  staff_change_logs          8.  staff_notifications
--   9.  staff_notification_reads   10. user_notifications
--   11. user_notification_reads    12. service_center_inventory
--   13. condom_requests            14. request_status_logs
--   15. inventory_logs             16. doctor_appointments
--   17. appointment_status_logs    18. articles
--   19. app_versions               20. web_changelogs
--       + auth.users cascade trigger
-- ============================================================


-- ── 1. service_centers ─────────────────────────────────────
CREATE TABLE public.service_centers (
  name                        text        NOT NULL,
  image_url                   text,
  description                 text,
  contacts                    jsonb       NOT NULL DEFAULT '[]',
  latitude                    numeric,
  longitude                   numeric,
  display_order               smallint    NOT NULL DEFAULT 0,
  created_at                  timestamptz NOT NULL DEFAULT now(),
  updated_at                  timestamptz NOT NULL DEFAULT now(),
  operating_hours             text,
  address                     text,
  condom_service_enabled      boolean     NOT NULL DEFAULT true,
  appointment_service_enabled boolean     NOT NULL DEFAULT false,
  pickup_times                text[]      NOT NULL DEFAULT '{08:00}',
  appointment_times           text[]      NOT NULL DEFAULT '{08:00}',
  staff_count                 int         NOT NULL DEFAULT 0,
  admin_count                 int         NOT NULL DEFAULT 0,
  superadmin_count            int         NOT NULL DEFAULT 0,
  CONSTRAINT service_centers_pkey            PRIMARY KEY (name)
);

ALTER TABLE public.service_centers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read service centers"
  ON public.service_centers FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "Admins can update service centers"
  ON public.service_centers FOR UPDATE
  TO authenticated USING (is_admin() OR is_superadmin());

CREATE POLICY "Superadmins can insert service centers"
  ON public.service_centers FOR INSERT
  TO authenticated WITH CHECK (is_superadmin());

CREATE TRIGGER trigger_update_updated_at_column_service_centers
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

CREATE POLICY "Staff can read all user profiles"
  ON public.user_profiles FOR SELECT
  TO authenticated USING (is_staff());


-- ── 3. user_monthly_quotas ─────────────────────────────────
CREATE TABLE public.user_monthly_quotas (
  id              uuid        NOT NULL DEFAULT gen_random_uuid(),
  user_id         uuid        NOT NULL,
  month           date        NOT NULL,
  used_condoms    integer              DEFAULT 0,
  used_lubricants integer              DEFAULT 0,
  updated_at      timestamptz          DEFAULT now(),
  CONSTRAINT user_monthly_quotas_pkey       PRIMARY KEY (id),
  CONSTRAINT user_monthly_quotas_user_id_month_key UNIQUE (user_id, month),
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
  id                uuid              NOT NULL DEFAULT gen_random_uuid(),
  staff_user_id     uuid              NOT NULL,
  first_name        varchar(255),
  last_name         varchar(255),
  service_centers   text[],
  created_at        timestamptz                DEFAULT now(),
  updated_at        timestamptz                DEFAULT now(),
  role              public.role       NOT NULL DEFAULT 'staff',
  line_user_id      text,
  line_display_name text,
  line_picture_url  text,
  CONSTRAINT staff_profiles_pkey               PRIMARY KEY (id),
  CONSTRAINT staff_profiles_staff_user_id_key  UNIQUE (staff_user_id),
  CONSTRAINT staff_profiles_line_user_id_key   UNIQUE (line_user_id),
  CONSTRAINT staff_profiles_staff_user_id_fkey FOREIGN KEY (staff_user_id)
    REFERENCES auth.users(id) ON DELETE CASCADE
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

CREATE POLICY "Staff can view all staff profiles"
  ON public.staff_profiles FOR SELECT
  USING (is_staff());

CREATE TRIGGER trigger_protect_staff_role_column
  BEFORE UPDATE ON public.staff_profiles
  FOR EACH ROW EXECUTE FUNCTION protect_staff_role_column();

CREATE TRIGGER trigger_refresh_service_center_staff_counts
  AFTER INSERT OR UPDATE OR DELETE ON public.staff_profiles
  FOR EACH STATEMENT EXECUTE FUNCTION refresh_service_center_staff_counts();


-- ── 7. staff_change_logs ────────────────────────────────────
CREATE TABLE public.staff_change_logs (
  id                   uuid                NOT NULL DEFAULT gen_random_uuid(),
  performed_by         uuid,
  performed_by_name    text,
  action               public.audit_action NOT NULL,
  target_table         text                NOT NULL,
  target_id            uuid                NOT NULL,
  old_value            jsonb,
  new_value            jsonb,
  created_at           timestamptz         NOT NULL DEFAULT now(),
  target_staff_user_id uuid,
  target_name          text,
  CONSTRAINT staff_change_logs_pkey              PRIMARY KEY (id),
  CONSTRAINT staff_change_logs_performed_by_fkey FOREIGN KEY (performed_by)
    REFERENCES auth.users(id)
);

ALTER TABLE public.staff_change_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins and superadmins can read change logs"
  ON public.staff_change_logs FOR SELECT
  TO authenticated USING (is_admin() OR is_superadmin());

CREATE POLICY "No one can insert change logs directly"
  ON public.staff_change_logs FOR INSERT
  TO authenticated WITH CHECK (false);

CREATE POLICY "No one can update change logs"
  ON public.staff_change_logs FOR UPDATE
  TO authenticated USING (false);

CREATE POLICY "No one can delete change logs"
  ON public.staff_change_logs FOR DELETE
  TO authenticated USING (false);


-- ── 8. staff_notifications ─────────────────────────────────
CREATE TABLE public.staff_notifications (
  id                uuid        NOT NULL DEFAULT gen_random_uuid(),
  created_at        timestamptz NOT NULL DEFAULT timezone('utc', now()),
  event_type        text        NOT NULL,
  source_type       text        NOT NULL,
  source_id         uuid        NOT NULL,
  metadata          jsonb       NOT NULL DEFAULT '{}',
  service_center    text,
  notify_staff      boolean     NOT NULL DEFAULT true,
  notify_admin      boolean     NOT NULL DEFAULT true,
  notify_superadmin boolean     NOT NULL DEFAULT true,
  CONSTRAINT staff_notifications_pkey PRIMARY KEY (id)
);

ALTER TABLE public.staff_notifications ENABLE ROW LEVEL SECURITY;

-- staff: own SC; admin: own SC; superadmin: all — each filtered by notify_* flag and join date cutoff
CREATE POLICY "Staff can read their own notifications"
  ON public.staff_notifications FOR SELECT TO authenticated
  USING (
    staff_notifications.created_at >= (
      SELECT COALESCE(sp.created_at, '-infinity'::timestamptz)
      FROM public.staff_profiles sp
      WHERE sp.staff_user_id = (SELECT auth.uid())
    )
    AND (
      (is_superadmin() AND notify_superadmin)
      OR (is_admin() AND NOT is_superadmin() AND notify_admin
          AND service_center = ANY(get_my_service_centers()))
      OR (NOT is_admin() AND NOT is_superadmin() AND notify_staff
          AND service_center = ANY(get_my_service_centers()))
    )
  );

CREATE POLICY "Staff can delete their own notifications"
  ON public.staff_notifications FOR DELETE TO authenticated
  USING (
    is_staff() AND (NOT is_admin()) AND (NOT is_superadmin())
    AND service_center = ANY(get_my_service_centers())
  );

CREATE TRIGGER trigger_notify_line_on_staff_notification
  AFTER INSERT ON public.staff_notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_line_on_staff_notification();


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

CREATE POLICY "Staff can manage their own notification reads"
  ON public.staff_notification_reads
  TO authenticated
  USING (staff_user_id = (SELECT auth.uid()))
  WITH CHECK (staff_user_id = (SELECT auth.uid()));


-- ── 10. staff_notification_hidden ──────────────────────────
CREATE TABLE public.staff_notification_hidden (
  notification_id uuid        NOT NULL,
  staff_user_id   uuid        NOT NULL,
  hidden_at       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT staff_notification_hidden_pkey PRIMARY KEY (notification_id, staff_user_id),
  CONSTRAINT fk_notification FOREIGN KEY (notification_id)
    REFERENCES public.staff_notifications(id) ON DELETE CASCADE,
  CONSTRAINT fk_staff FOREIGN KEY (staff_user_id)
    REFERENCES auth.users(id) ON DELETE CASCADE
);

ALTER TABLE public.staff_notification_hidden ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can manage their own hidden notifications"
  ON public.staff_notification_hidden TO authenticated
  USING (staff_user_id = (SELECT auth.uid()))
  WITH CHECK (staff_user_id = (SELECT auth.uid()));


-- ── 11. user_notifications ─────────────────────────────────
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

CREATE POLICY "Users can read their own notifications"
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

CREATE POLICY "Users can read their own notification reads"
  ON public.user_notification_reads FOR SELECT
  TO authenticated USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can insert their own notification reads"
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

CREATE POLICY "No one can insert inventory directly"
  ON public.service_center_inventory FOR INSERT
  TO authenticated WITH CHECK (false);

-- NOTE: TO PUBLIC (not TO authenticated) — matches production DB
CREATE POLICY "Admins can update inventory"
  ON public.service_center_inventory FOR UPDATE
  TO PUBLIC
  USING (is_admin() OR is_superadmin())
  WITH CHECK (is_admin() OR is_superadmin());

CREATE POLICY "No one can delete inventory directly"
  ON public.service_center_inventory FOR DELETE
  TO authenticated USING (false);

CREATE TRIGGER trigger_update_updated_at_column_service_center_inventory
  BEFORE UPDATE ON public.service_center_inventory
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ── 13. condom_requests ────────────────────────────────────
CREATE TABLE public.condom_requests (
  id                      uuid                  NOT NULL DEFAULT gen_random_uuid(),
  user_id                 uuid,
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
    REFERENCES auth.users(id) ON DELETE SET NULL,
  CONSTRAINT condom_requests_handled_by_fkey FOREIGN KEY (handled_by)
    REFERENCES auth.users(id) ON DELETE SET NULL
);

ALTER TABLE public.condom_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own requests"
  ON public.condom_requests FOR INSERT
  TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users and staff can read requests"
  ON public.condom_requests FOR SELECT
  TO authenticated USING (
    is_superadmin()
    OR (
      is_staff()
      AND (
        get_my_service_centers() IS NULL
        OR selected_service_center = ANY(get_my_service_centers())
      )
    )
    OR (SELECT auth.uid()) = user_id
  );

CREATE POLICY "Users and staff can update requests"
  ON public.condom_requests FOR UPDATE
  TO authenticated
  USING (
    is_superadmin()
    OR (
      is_staff()
      AND (
        get_my_service_centers() IS NULL
        OR selected_service_center = ANY(get_my_service_centers())
      )
    )
    OR (SELECT auth.uid()) = user_id
  )
  WITH CHECK (
    is_superadmin()
    OR (
      is_staff()
      AND (
        get_my_service_centers() IS NULL
        OR selected_service_center = ANY(get_my_service_centers())
      )
    )
    OR (
      (SELECT auth.uid()) = user_id
      AND request_status = 'cancelled_by_user'::public.request_status
    )
  );

CREATE TRIGGER trigger_update_updated_at_column_condom_requests
  BEFORE UPDATE ON public.condom_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_set_is_delay
  BEFORE UPDATE ON public.condom_requests
  FOR EACH ROW EXECUTE FUNCTION set_is_delay();

CREATE TRIGGER trigger_set_handled_by_and_completed_at
  BEFORE UPDATE OF request_status ON public.condom_requests
  FOR EACH ROW WHEN (OLD.request_status IS DISTINCT FROM NEW.request_status)
  EXECUTE FUNCTION set_handled_by_and_completed_at();

CREATE TRIGGER trigger_check_staff_update_columns
  BEFORE UPDATE ON public.condom_requests
  FOR EACH ROW EXECUTE FUNCTION check_staff_update_columns();

CREATE TRIGGER trigger_track_request_status
  AFTER UPDATE ON public.condom_requests
  FOR EACH ROW WHEN (OLD.request_status IS DISTINCT FROM NEW.request_status)
  EXECUTE FUNCTION track_request_status();

CREATE TRIGGER trigger_deduct_inventory_on_complete
  AFTER UPDATE OF request_status ON public.condom_requests
  FOR EACH ROW WHEN (
    NEW.request_status = 'completed'::public.request_status
    AND OLD.request_status <> 'completed'::public.request_status
  ) EXECUTE FUNCTION deduct_inventory_on_complete();

CREATE TRIGGER trigger_restore_quota_on_staff_cancel_pending
  AFTER UPDATE OF request_status ON public.condom_requests
  FOR EACH ROW WHEN (
    NEW.request_status = 'cancelled_by_staff'::public.request_status
    AND OLD.request_status = 'pending'::public.request_status
  ) EXECUTE FUNCTION restore_quota_on_staff_cancel_pending();

CREATE TRIGGER trigger_handle_staff_request_notification
  AFTER INSERT OR UPDATE OF request_status ON public.condom_requests
  FOR EACH ROW EXECUTE FUNCTION handle_staff_request_notification();

CREATE TRIGGER trigger_handle_user_request_notification
  AFTER INSERT OR UPDATE ON public.condom_requests
  FOR EACH ROW EXECUTE FUNCTION handle_user_request_notification();


-- ── 14. request_status_logs ────────────────────────────────
CREATE TABLE public.request_status_logs (
  id              uuid                  NOT NULL DEFAULT gen_random_uuid(),
  request_id      uuid                  NOT NULL,
  from_status     public.request_status,
  to_status       public.request_status NOT NULL,
  changed_by      uuid,
  changed_by_name text,
  changed_at      timestamptz           NOT NULL DEFAULT now(),
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
  performed_by_name    text,
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

CREATE POLICY "Admins can insert inventory logs"
  ON public.inventory_logs FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (
      SELECT 1 FROM staff_profiles
      WHERE staff_user_id = (SELECT auth.uid())
        AND role = ANY (ARRAY['admin'::public.role, 'superadmin'::public.role])
    )
  );

CREATE POLICY "Superadmins can read inventory logs"
  ON public.inventory_logs FOR SELECT
  TO authenticated USING (is_superadmin());

CREATE TRIGGER trigger_set_inventory_log_performer_name
  BEFORE INSERT ON public.inventory_logs
  FOR EACH ROW EXECUTE FUNCTION set_inventory_log_performer_name();

CREATE TRIGGER trigger_apply_inventory_adjustment
  AFTER INSERT ON public.inventory_logs
  FOR EACH ROW EXECUTE FUNCTION apply_inventory_adjustment();

CREATE TRIGGER trigger_notify_staff_on_stock_operation
  AFTER INSERT ON public.inventory_logs
  FOR EACH ROW EXECUTE FUNCTION notify_staff_on_stock_operation();


-- ── 16. doctor_appointments ────────────────────────────────
CREATE TABLE public.doctor_appointments (
  id                      uuid                      NOT NULL DEFAULT gen_random_uuid(),
  user_id                 uuid,
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
    REFERENCES auth.users(id) ON DELETE SET NULL,
  CONSTRAINT doctor_appointments_handled_by_fkey FOREIGN KEY (handled_by)
    REFERENCES auth.users(id)
);

ALTER TABLE public.doctor_appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own appointments"
  ON public.doctor_appointments FOR INSERT
  TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users and staff can read appointments"
  ON public.doctor_appointments FOR SELECT
  TO authenticated USING (
    is_superadmin()
    OR (
      is_staff()
      AND (
        get_my_service_centers() IS NULL
        OR selected_service_center = ANY(get_my_service_centers())
      )
    )
    OR (SELECT auth.uid()) = user_id
  );

CREATE POLICY "Users and staff can update appointments"
  ON public.doctor_appointments FOR UPDATE
  TO authenticated
  USING (
    is_superadmin()
    OR (
      is_staff()
      AND (
        get_my_service_centers() IS NULL
        OR selected_service_center = ANY(get_my_service_centers())
      )
    )
    OR (SELECT auth.uid()) = user_id
  )
  WITH CHECK (
    is_superadmin()
    OR (
      is_staff()
      AND (
        get_my_service_centers() IS NULL
        OR selected_service_center = ANY(get_my_service_centers())
      )
    )
    OR (
      (SELECT auth.uid()) = user_id
      AND appointment_status = 'cancelled_by_user'::public.appointment_status
    )
  );

CREATE TRIGGER trigger_update_updated_at_column_doctor_appointments
  BEFORE UPDATE ON public.doctor_appointments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_set_appointment_handled_by
  BEFORE UPDATE OF appointment_status ON public.doctor_appointments
  FOR EACH ROW EXECUTE FUNCTION set_appointment_handled_by();

CREATE TRIGGER trigger_track_appointment_status
  AFTER UPDATE OF appointment_status ON public.doctor_appointments
  FOR EACH ROW EXECUTE FUNCTION track_appointment_status();

CREATE TRIGGER trigger_handle_staff_appointment_notification
  AFTER INSERT OR UPDATE OF appointment_status ON public.doctor_appointments
  FOR EACH ROW EXECUTE FUNCTION handle_staff_appointment_notification();

CREATE TRIGGER trigger_handle_user_appointment_notification
  AFTER INSERT OR UPDATE ON public.doctor_appointments
  FOR EACH ROW EXECUTE FUNCTION handle_user_appointment_notification();


-- ── 17. appointment_status_logs ────────────────────────────
CREATE TABLE public.appointment_status_logs (
  id              uuid                      NOT NULL DEFAULT gen_random_uuid(),
  appointment_id  uuid                      NOT NULL,
  from_status     public.appointment_status,
  to_status       public.appointment_status NOT NULL,
  changed_by      uuid,
  changed_by_name text,
  changed_at      timestamptz               NOT NULL DEFAULT now(),
  CONSTRAINT appointment_status_logs_pkey                PRIMARY KEY (id),
  CONSTRAINT appointment_status_logs_appointment_id_fkey FOREIGN KEY (appointment_id)
    REFERENCES public.doctor_appointments(id) ON DELETE CASCADE
);

ALTER TABLE public.appointment_status_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can read appointment status logs"
  ON public.appointment_status_logs FOR SELECT
  TO authenticated USING (
    EXISTS (
      SELECT 1 FROM staff_profiles
      WHERE staff_user_id = (SELECT auth.uid())
    )
  );


-- ── 18. articles ───────────────────────────────────────────
-- status is stored directly by the application (no trigger).
-- auto-save writes updated_by/updated_at (same as manual save).
CREATE TABLE public.articles (
  id                   uuid                  NOT NULL DEFAULT gen_random_uuid(),
  title                text                  NOT NULL,
  body                 text                  NOT NULL DEFAULT '',
  category             text                  NOT NULL DEFAULT '',
  thumbnail_url        text,
  status               public.article_status NOT NULL DEFAULT 'draft',
  draft_title          text,
  draft_body           text,
  draft_category       text,
  draft_thumbnail_url  text,
  created_by           uuid,
  created_at           timestamptz                    DEFAULT now(),
  updated_by           uuid,
  updated_at           timestamptz,
  published_by         uuid,
  published_at         timestamptz,
  hidden_by            uuid,
  hidden_at            timestamptz,
  CONSTRAINT articles_pkey              PRIMARY KEY (id),
  CONSTRAINT articles_created_by_fkey   FOREIGN KEY (created_by)   REFERENCES auth.users(id),
  CONSTRAINT articles_updated_by_fkey   FOREIGN KEY (updated_by)   REFERENCES auth.users(id),
  CONSTRAINT articles_published_by_fkey FOREIGN KEY (published_by) REFERENCES auth.users(id),
  CONSTRAINT articles_hidden_by_fkey    FOREIGN KEY (hidden_by)    REFERENCES auth.users(id)
);

ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;

-- Anon: published articles only (app users not logged in)
CREATE POLICY "Anyone can read published articles"
  ON public.articles FOR SELECT
  TO anon USING (status = 'published');

-- Admin / Superadmin: full read (all statuses)
CREATE POLICY "Admins can read all articles"
  ON public.articles FOR SELECT
  TO authenticated USING (is_admin() OR is_superadmin());

-- Staff (non-admin/superadmin): published only
CREATE POLICY "Staff can read published articles"
  ON public.articles FOR SELECT
  TO authenticated USING (is_staff() AND status = 'published');

-- Admin / Superadmin: write access
CREATE POLICY "Admins can insert articles"
  ON public.articles FOR INSERT
  TO authenticated WITH CHECK (is_admin() OR is_superadmin());

CREATE POLICY "Admins can update articles"
  ON public.articles FOR UPDATE
  TO authenticated USING (is_admin() OR is_superadmin());

CREATE POLICY "Admins can delete articles"
  ON public.articles FOR DELETE
  TO authenticated USING (is_admin() OR is_superadmin());


-- ── App versions ──────────────────────────────────────────────
CREATE TABLE public.app_versions (
  id            serial      PRIMARY KEY,
  version       text,                                    -- NULL until Claude stamps after CI
  build_number  int,                                     -- NULL until Claude stamps after CI
  download_url  text        NOT NULL,
  force_update  boolean     NOT NULL DEFAULT false,
  branch        text        NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  release_date  date        NOT NULL DEFAULT CURRENT_DATE,
  additions     text[]      NOT NULL DEFAULT '{}',
  fixes         text[]      NOT NULL DEFAULT '{}',
  improvements  text[]      NOT NULL DEFAULT '{}',
  others        text[]      NOT NULL DEFAULT '{}'
);

ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read app versions"
  ON public.app_versions FOR SELECT
  USING (true);


CREATE TABLE public.web_changelogs (
  id           serial      PRIMARY KEY,
  version      text        NOT NULL,
  build_number int         NOT NULL,
  branch       text        NOT NULL,
  release_date date        NOT NULL,
  additions    text[]      NOT NULL DEFAULT '{}',
  fixes        text[]      NOT NULL DEFAULT '{}',
  improvements text[]      NOT NULL DEFAULT '{}',
  others       text[]      NOT NULL DEFAULT '{}',
  created_at   timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.web_changelogs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read web changelogs"
  ON public.web_changelogs FOR SELECT TO authenticated USING (true);


-- ── Cascade delete trigger on auth.users ───────────────────
CREATE TRIGGER trigger_handle_user_deleted
  BEFORE DELETE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_deleted();


