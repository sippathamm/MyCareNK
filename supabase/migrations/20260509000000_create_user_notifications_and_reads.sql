-- ============================================================
-- Create user_notifications and user_notification_reads tables
-- with RLS policies and triggers for condom_requests and
-- doctor_appointments. Issue #132.
-- ============================================================

-- 1. user_notifications table
CREATE TABLE user_notifications (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  source_type      text        NOT NULL CHECK (source_type IN ('condom_request', 'doctor_appointment')),
  source_id        uuid        NOT NULL,
  reference_number text        NOT NULL DEFAULT '',
  event_type       text        NOT NULL,
  metadata         jsonb       NOT NULL DEFAULT '{}',
  created_at       timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX ON user_notifications(user_id, created_at DESC);

-- 2. user_notification_reads table
CREATE TABLE user_notification_reads (
  notification_id uuid        NOT NULL REFERENCES user_notifications(id) ON DELETE CASCADE,
  user_id         uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  read_at         timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (notification_id, user_id)
);

-- 3. RLS Policies
ALTER TABLE user_notifications       ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notification_reads  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select_own"
  ON user_notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "users_select_own_reads"
  ON user_notification_reads FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "users_insert_own_reads"
  ON user_notification_reads FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- 4. Trigger: condom_requests → user_notifications
CREATE OR REPLACE FUNCTION handle_user_request_notification()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_metadata jsonb := '{}';
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO user_notifications (user_id, source_type, source_id, reference_number, event_type, metadata)
    VALUES (
      NEW.user_id,
      'condom_request',
      NEW.id,
      NEW.reference_number,
      NEW.request_status::text,
      '{}'
    );
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.request_status IS DISTINCT FROM NEW.request_status THEN
    IF NEW.request_status::text = 'ready' THEN
      v_metadata := jsonb_build_object(
        'selected_date', NEW.selected_date,
        'selected_time', NEW.selected_time
      );
    END IF;

    INSERT INTO user_notifications (user_id, source_type, source_id, reference_number, event_type, metadata)
    VALUES (
      NEW.user_id,
      'condom_request',
      NEW.id,
      NEW.reference_number,
      NEW.request_status::text,
      v_metadata
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER notify_user_on_request_change
  AFTER INSERT OR UPDATE ON condom_requests
  FOR EACH ROW EXECUTE FUNCTION handle_user_request_notification();

-- 5. Trigger: doctor_appointments → user_notifications
CREATE OR REPLACE FUNCTION handle_user_appointment_notification()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_metadata jsonb := '{}';
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_metadata := jsonb_build_object(
      'selected_date', NEW.selected_date,
      'selected_time', NEW.selected_time,
      'reason',        NEW.reason
    );

    INSERT INTO user_notifications (user_id, source_type, source_id, reference_number, event_type, metadata)
    VALUES (
      NEW.user_id,
      'doctor_appointment',
      NEW.id,
      NEW.reference_number,
      NEW.appointment_status::text,
      v_metadata
    );
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.appointment_status IS DISTINCT FROM NEW.appointment_status THEN
    IF NEW.appointment_status::text IN ('pending', 'confirmed') THEN
      v_metadata := jsonb_build_object(
        'selected_date', NEW.selected_date,
        'selected_time', NEW.selected_time,
        'reason',        NEW.reason
      );
    END IF;

    INSERT INTO user_notifications (user_id, source_type, source_id, reference_number, event_type, metadata)
    VALUES (
      NEW.user_id,
      'doctor_appointment',
      NEW.id,
      NEW.reference_number,
      NEW.appointment_status::text,
      v_metadata
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER notify_user_on_appointment_change
  AFTER INSERT OR UPDATE ON doctor_appointments
  FOR EACH ROW EXECUTE FUNCTION handle_user_appointment_notification();

-- 6. Add user_notifications to Realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE user_notifications;
