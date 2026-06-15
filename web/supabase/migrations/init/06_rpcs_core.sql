-- ============================================================
-- 06_rpcs_core.sql — MyCareNK
-- Core user-facing and public RPCs.
-- Apply order: 6 of 8
-- ============================================================
--
-- Covers:
--   Request / appointment creation
--     — create_condom_request, create_doctor_appointment
--   Recovery codes + account management
--     — get_days_until_reset, save_recovery_codes,
--       verify_recovery_code,
--       verify_recovery_code_and_reset_password,
--       delete_own_account
--   Public read RPCs (accessible to anon + authenticated)
--     — get_service_centers
--     — get_published_articles, get_article_detail
--     — get_latest_web_changelog, get_latest_app_version
-- ============================================================

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
SET search_path TO 'public', 'extensions'
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
SET search_path TO 'public', 'extensions'
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
SET search_path TO 'public', 'extensions'
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


-- ── Self-service account deletion ───────────────────────────
-- End-users (@mycarenk.local) delete their own account.
-- Blocks deletion while the user still has unfinished condom requests
-- (pending/preparing/ready) or doctor appointments (pending/confirmed) so
-- staff are not left handling records whose user_id will be SET NULL.
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  v_user_id := (SELECT auth.uid());
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = v_user_id AND email LIKE '%@mycarenk.local'
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.condom_requests
    WHERE user_id = v_user_id
      AND request_status IN ('pending', 'preparing', 'ready')
  ) OR EXISTS (
    SELECT 1 FROM public.doctor_appointments
    WHERE user_id = v_user_id
      AND appointment_status IN ('pending', 'confirmed')
  ) THEN
    RAISE EXCEPTION 'ACTIVE_RECORDS_EXIST';
  END IF;

  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;


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
  id              uuid,
  title           text,
  excerpt         text,
  thumbnail_url   text,
  category        text,
  published_at    timestamptz,
  created_by_name text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    a.id,
    a.title,
    LEFT(regexp_replace(a.body, '<[^>]+>', '', 'g'), 120) AS excerpt,
    a.thumbnail_url,
    a.category,
    a.published_at,
    COALESCE(sp.first_name || ' ' || sp.last_name, '') AS created_by_name
  FROM articles a
  LEFT JOIN staff_profiles sp ON sp.staff_user_id = a.created_by
  WHERE a.status = 'published'
  ORDER BY a.published_at DESC
  LIMIT p_limit OFFSET p_offset;
$$;

CREATE OR REPLACE FUNCTION public.get_article_detail(p_article_id uuid)
RETURNS TABLE(
  id              uuid,
  title           text,
  body            text,
  thumbnail_url   text,
  category        text,
  published_at    timestamptz,
  created_by_name text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    a.id,
    a.title,
    a.body,
    a.thumbnail_url,
    a.category,
    a.published_at,
    COALESCE(sp.first_name || ' ' || sp.last_name, '') AS created_by_name
  FROM articles a
  LEFT JOIN staff_profiles sp ON sp.staff_user_id = a.created_by
  WHERE a.id = p_article_id
    AND a.status = 'published';
$$;


-- ── App version RPC ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_latest_web_changelog(
  p_branch text DEFAULT 'main'
) RETURNS TABLE(
  id           int,
  version      text,
  build_number int,
  branch       text,
  release_date date,
  additions    text[],
  fixes        text[],
  improvements text[],
  others       text[]
)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT id, version, build_number, branch, release_date,
         additions, fixes, improvements, others
  FROM web_changelogs
  WHERE branch = p_branch
  ORDER BY created_at DESC LIMIT 1;
$$;


DROP FUNCTION IF EXISTS public.get_latest_app_version(text);

CREATE FUNCTION public.get_latest_app_version(
  p_branch text DEFAULT 'main'
) RETURNS TABLE(
  id            int,
  version       text,
  build_number  int,
  download_url  text,
  force_update  boolean,
  branch        text,
  release_date  date,
  additions     text[],
  fixes         text[],
  improvements  text[],
  others        text[],
  created_at    timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT
    av.id,
    av.version,
    av.build_number,
    av.download_url,
    av.force_update,
    av.branch,
    av.release_date,
    av.additions,
    av.fixes,
    av.improvements,
    av.others,
    av.created_at
  FROM app_versions av
  WHERE av.branch = p_branch
    AND av.version IS NOT NULL
    AND av.build_number IS NOT NULL
  ORDER BY av.created_at DESC
  LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_latest_app_version(text) TO anon, authenticated;


