-- Cascade delete all user-related data when an auth user is deleted.
-- Uses BEFORE DELETE so child records are removed before FK constraints fire.
CREATE OR REPLACE FUNCTION public.handle_user_deleted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Nullify staff audit/log references to preserve history
  UPDATE public.condom_requests SET handled_by = NULL WHERE handled_by = OLD.id;
  UPDATE public.doctor_appointments SET handled_by = NULL WHERE handled_by = OLD.id;
  UPDATE public.request_status_logs SET changed_by = NULL WHERE changed_by = OLD.id;
  UPDATE public.appointment_status_logs SET changed_by = NULL WHERE changed_by = OLD.id;
  UPDATE public.inventory_logs SET performed_by = NULL WHERE performed_by = OLD.id;
  UPDATE public.staff_audit_logs SET performed_by = NULL WHERE performed_by = OLD.id;
  UPDATE public.articles SET created_by = NULL WHERE created_by = OLD.id;

  -- Delete staff data (no-op for end-users)
  DELETE FROM public.staff_notification_reads WHERE staff_user_id = OLD.id;
  DELETE FROM public.staff_profiles WHERE staff_user_id = OLD.id;

  -- Delete end-user notification data
  DELETE FROM public.user_notification_reads WHERE user_id = OLD.id;
  DELETE FROM public.user_notifications WHERE user_id = OLD.id;

  -- Delete auth/recovery data
  DELETE FROM public.user_recovery_codes WHERE user_id = OLD.id;
  DELETE FROM public.recovery_attempts WHERE user_id = OLD.id;

  -- Delete quota data
  DELETE FROM public.user_monthly_quotas WHERE user_id = OLD.id;

  -- Delete request status logs before condom_requests (no FK cascade)
  DELETE FROM public.request_status_logs
    WHERE request_id IN (SELECT id FROM public.condom_requests WHERE user_id = OLD.id);

  -- Delete condom requests
  DELETE FROM public.condom_requests WHERE user_id = OLD.id;

  -- Delete doctor appointments (appointment_status_logs cascades automatically)
  DELETE FROM public.doctor_appointments WHERE user_id = OLD.id;

  -- Delete user profile last
  DELETE FROM public.user_profiles WHERE user_id = OLD.id;

  RETURN OLD;
END;
$$;

CREATE TRIGGER on_auth_user_deleted
  BEFORE DELETE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_deleted();
