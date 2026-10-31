-- ============================================================
-- 02_shared_functions.sql — MyCareNK
-- Role helpers (is_staff / is_admin / is_superadmin),
-- service-center scope helper (get_my_service_centers),
-- and the shared updated_at trigger function.
-- Apply order: 2 of 8 (must precede tables and RPCs that call these)
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
SECURITY DEFINER
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
SECURITY DEFINER
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
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.staff_profiles
    WHERE staff_user_id = auth.uid() AND role = 'superadmin'
  );
END;
$$;

-- Returns NULL for superadmin (no SC restriction) or text[] of SCs for staff/admin
CREATE OR REPLACE FUNCTION public.get_my_service_centers()
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_role public.role;
  v_scs  text[];
BEGIN
  SELECT role, service_centers
    INTO v_role, v_scs
    FROM public.staff_profiles
   WHERE staff_user_id = auth.uid();
  IF v_role = 'superadmin' THEN RETURN NULL; END IF;
  RETURN COALESCE(v_scs, ARRAY[]::text[]);
END;
$$;

-- True for superadmin, or staff/admin whose SC has a request or consultation from the user
CREATE OR REPLACE FUNCTION public.can_read_user_contact(p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN is_superadmin()
    OR EXISTS (
      SELECT 1 FROM public.condom_requests cr
      WHERE cr.user_id = p_user_id
        AND cr.selected_service_center = ANY(get_my_service_centers())
    )
    OR EXISTS (
      SELECT 1 FROM public.consultations c
      WHERE c.user_id = p_user_id
        AND c.selected_service_center = ANY(get_my_service_centers())
    );
END;
$$;


