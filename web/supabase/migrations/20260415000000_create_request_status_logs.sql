-- Migration: Create request_status_logs table
-- Issue: #92 [DB] Create `request_status_logs` Table

-- Create table
CREATE TABLE public.request_status_logs (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id  uuid        NOT NULL REFERENCES public.condom_requests(id) ON DELETE CASCADE,
  from_status public.status,
  to_status   public.status NOT NULL,
  changed_by  uuid        REFERENCES auth.users(id),
  changed_at  timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_status_logs_request_id ON public.request_status_logs (request_id);
CREATE INDEX idx_status_logs_changed_at ON public.request_status_logs (changed_at DESC);
CREATE INDEX idx_status_logs_changed_by ON public.request_status_logs (changed_by);

-- Trigger function
CREATE OR REPLACE FUNCTION public.fn_log_status_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.request_status_logs (
    request_id,
    from_status,
    to_status,
    changed_by,
    changed_at
  ) VALUES (
    NEW.id,
    OLD.request_status,
    NEW.request_status,
    auth.uid(),
    now()
  );
  RETURN NEW;
END;
$$;

-- Trigger
CREATE TRIGGER trg_log_status_change
  AFTER UPDATE OF request_status ON public.condom_requests
  FOR EACH ROW
  WHEN (OLD.request_status IS DISTINCT FROM NEW.request_status)
  EXECUTE FUNCTION public.fn_log_status_change();

-- Enable RLS
ALTER TABLE public.request_status_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Staff can read all status logs
CREATE POLICY "Staff can read all status logs"
  ON public.request_status_logs
  FOR SELECT
  TO authenticated
  USING (public.is_staff());

-- No one can update (immutable)
CREATE POLICY "No one can update status logs"
  ON public.request_status_logs
  FOR UPDATE
  TO authenticated
  USING (false);

-- No one can delete (immutable)
CREATE POLICY "No one can delete status logs"
  ON public.request_status_logs
  FOR DELETE
  TO authenticated
  USING (false);
