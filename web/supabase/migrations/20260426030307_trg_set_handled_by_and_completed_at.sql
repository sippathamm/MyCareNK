-- Trigger function: auto-populate handled_by and completed_at on status change
CREATE OR REPLACE FUNCTION set_handled_by_and_completed_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Set handled_by to the current staff user on first transition to 'preparing'
  IF NEW.request_status = 'preparing' AND OLD.handled_by IS NULL THEN
    NEW.handled_by = auth.uid();
  END IF;

  -- Set completed_at when the request reaches a terminal status
  IF NEW.request_status IN ('completed', 'cancelled_by_user', 'cancelled_by_staff') THEN
    NEW.completed_at = now();
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_set_handled_by_and_completed_at
BEFORE UPDATE OF request_status ON condom_requests
FOR EACH ROW WHEN (OLD.request_status IS DISTINCT FROM NEW.request_status)
EXECUTE FUNCTION set_handled_by_and_completed_at();
