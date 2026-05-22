-- Fix recovery code functions: add 'extensions' to search_path so that
-- crypt(), gen_salt(), and gen_random_bytes() from pgcrypto are found.

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
