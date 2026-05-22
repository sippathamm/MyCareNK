-- Refactor staff notification system for role-based filtering.
--
-- notify_staff=true  → pending events only → staff (own SC) + admin + superadmin
-- notify_staff=false → all other events   → admin + superadmin only

-- A. Add notify_staff column (table is empty — no backfill needed)
ALTER TABLE public.staff_notifications
  ADD COLUMN notify_staff boolean NOT NULL DEFAULT false;

-- B. Replace RLS policies
--    staff: see only notify_staff=true at own SC
--    admin/superadmin: see everything
DROP POLICY IF EXISTS "Staff can view their notifications"   ON public.staff_notifications;
DROP POLICY IF EXISTS "Staff can delete their notifications" ON public.staff_notifications;

CREATE POLICY "staff_notifications_select"
  ON public.staff_notifications FOR SELECT TO authenticated
  USING (
    is_admin() OR is_superadmin()
    OR (
      notify_staff = true
      AND service_center = (
        SELECT sp.service_center FROM staff_profiles sp
        WHERE sp.staff_user_id = (SELECT auth.uid())
      )
    )
  );

CREATE POLICY "staff_notifications_delete"
  ON public.staff_notifications FOR DELETE TO authenticated
  USING (
    is_admin() OR is_superadmin()
    OR (
      notify_staff = true
      AND service_center = (
        SELECT sp.service_center FROM staff_profiles sp
        WHERE sp.staff_user_id = (SELECT auth.uid())
      )
    )
  );

-- C. Update trigger functions — notify_staff=true only for pending events
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

-- D. Narrow trigger scope — fire only on status column changes (reduces overhead)
DROP TRIGGER IF EXISTS notify_staff_on_request_change ON public.condom_requests;
CREATE TRIGGER notify_staff_on_request_change
  AFTER INSERT OR UPDATE OF request_status ON public.condom_requests
  FOR EACH ROW EXECUTE FUNCTION handle_staff_request_notification();

DROP TRIGGER IF EXISTS notify_staff_on_appointment_change ON public.doctor_appointments;
CREATE TRIGGER notify_staff_on_appointment_change
  AFTER INSERT OR UPDATE OF appointment_status ON public.doctor_appointments
  FOR EACH ROW EXECUTE FUNCTION handle_staff_appointment_notification();
