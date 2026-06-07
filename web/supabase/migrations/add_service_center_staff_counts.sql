-- Adds staff_count, admin_count, superadmin_count to service_centers
-- and fixes delete_service_center which referenced the dropped
-- service_center (singular) column on staff_profiles.

-- ── 1. New columns ───────────────────────────────────────────
ALTER TABLE public.service_centers
  ADD COLUMN IF NOT EXISTS staff_count      int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS admin_count      int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS superadmin_count int NOT NULL DEFAULT 0;

-- ── 2. Trigger function ──────────────────────────────────────
CREATE OR REPLACE FUNCTION public.refresh_service_center_staff_counts()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
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
    );
  RETURN NULL;
END;
$$;

-- ── 3. Trigger ───────────────────────────────────────────────
DROP TRIGGER IF EXISTS trigger_refresh_service_center_staff_counts ON public.staff_profiles;
CREATE TRIGGER trigger_refresh_service_center_staff_counts
  AFTER INSERT OR UPDATE OR DELETE ON public.staff_profiles
  FOR EACH STATEMENT EXECUTE FUNCTION public.refresh_service_center_staff_counts();

-- ── 4. Backfill ──────────────────────────────────────────────
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
  );

-- ── 5. Fix delete_service_center ─────────────────────────────
-- The live DB has an old version that queries staff_profiles.service_center
-- (singular, text) which was dropped and replaced with service_centers (text[]).
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
  DELETE FROM service_centers WHERE name = p_name AND is_active = false;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'สถานบริการต้องถูกปิดใช้งานก่อนจึงจะสามารถลบได้';
  END IF;
END;
$$;
