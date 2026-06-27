-- ============================================================
-- 08_grants_realtime_storage.sql — MyCareNK
-- GRANTs, Realtime publication, backfill, and Storage buckets.
-- Apply order: 8 of 8 (must be last — GRANTs reference all
-- functions defined in earlier files)
-- ============================================================

-- ============================================================
-- SECTION 6: REVOKE + GRANTs
-- ============================================================

-- ── Schema + table grants ───────────────────────────────────
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- authenticated: full table access (RLS enforces fine-grained control)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO authenticated;

-- service_role: bypasses RLS — needs explicit table-level grants
GRANT ALL ON ALL TABLES    IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL ROUTINES  IN SCHEMA public TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES    TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES  TO service_role;

-- Start from a clean slate: revoke PUBLIC pseudo-role AND explicit Supabase grants
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC, anon, authenticated;

-- Role helper functions (required by RLS policies)
GRANT EXECUTE ON FUNCTION public.is_staff()                   TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin()                   TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_superadmin()              TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_updated_at_column()   TO authenticated;

-- Recovery RPCs
GRANT EXECUTE ON FUNCTION public.get_days_until_reset()       TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_recovery_codes(text[])  TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_recovery_code(text, text)                         TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_recovery_code_and_reset_password(text, text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_own_account()        TO authenticated;

-- Public article + version RPCs (accessible to unauthenticated app users)
GRANT EXECUTE ON FUNCTION public.get_published_articles(integer, integer) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_article_detail(uuid)                 TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_latest_web_changelog(text)           TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_latest_app_version(text)             TO anon, authenticated;

-- Analytics — staff/admin only (require authenticated session)
GRANT EXECUTE ON FUNCTION public.get_average_lead_time(timestamptz, timestamptz, text)          TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_peak_time_stats(text, timestamptz, timestamptz, text)      TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_service_center_demand(timestamptz, timestamptz)            TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_service_center_demand_trend()                              TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_consumption_trend()                                        TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_inventory_forecast()                                       TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_staff_workload(timestamptz, timestamptz, text)             TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_staff_workload_trend(text, uuid, timestamptz, timestamptz) TO authenticated;

-- Service center RPCs
GRANT EXECUTE ON FUNCTION public.get_service_centers()                                          TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_service_center(text)                                       TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_service_center(text)                                    TO authenticated;
GRANT EXECUTE ON FUNCTION public.init_service_center_inventory(text)                            TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_service_center(text, text, text, jsonb, double precision, double precision, smallint, text, text, boolean, boolean, text[], text[]) TO authenticated;

-- Request / appointment creation
GRANT EXECUTE ON FUNCTION public.create_condom_request(uuid, jsonb, integer, text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_doctor_appointment(uuid, text, text, date, text, text)        TO authenticated;

-- Log query RPCs
GRANT EXECUTE ON FUNCTION public.get_request_status_log(uuid, text, text, text, timestamptz, timestamptz, integer, integer, text)     TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_appointment_status_log(uuid, text, text, text, timestamptz, timestamptz, integer, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_inventory_log(text, text, timestamptz, timestamptz, integer, integer)                            TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_staff_change_log(uuid, text, text, timestamptz, timestamptz, integer, integer, text)             TO authenticated;

GRANT EXECUTE ON FUNCTION public.get_my_service_centers()                                         TO authenticated;

-- Notification settings RPC (superadmin only — enforced inside the function)
GRANT EXECUTE ON FUNCTION public.update_notification_settings(jsonb) TO authenticated;

-- write_staff_change_log: intentionally NOT granted to anon/authenticated
-- (service_role access only — used by Edge Functions)


-- ============================================================
-- SECTION 7: REALTIME
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.condom_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.doctor_appointments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.staff_notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.staff_notification_reads;
ALTER PUBLICATION supabase_realtime ADD TABLE public.staff_notification_hidden;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_notification_reads;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_monthly_quotas;

-- ============================================================
-- SECTION: BACKFILL
-- ============================================================

-- Backfill service_centers array from service_center for existing staff/admin.
UPDATE public.staff_profiles
SET service_centers = ARRAY[service_center]
WHERE service_center IS NOT NULL
  AND (service_centers IS NULL OR service_centers = '{}');

-- Ensure every service center has a corresponding inventory row.
-- Guards against centers created before init_service_center_inventory was wired up.
INSERT INTO public.service_center_inventory (service_center, condom_qty, lubricant_qty)
SELECT sc.name, 0, 0
FROM public.service_centers sc
WHERE NOT EXISTS (
  SELECT 1 FROM public.service_center_inventory sci
  WHERE sci.service_center = sc.name
);

-- ============================================================
-- SECTION: STORAGE
-- ============================================================

-- Public image buckets; 5MB limit; image mime types only.
-- service-center-assets: cover images for service centers (root path).
-- article-assets: article cover/ and content/ images.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('service-center-assets', 'service-center-assets', true, 5242880,
   ARRAY['image/jpeg','image/png','image/webp','image/gif']),
  ('article-assets', 'article-assets', true, 5242880,
   ARRAY['image/jpeg','image/png','image/webp','image/gif'])
ON CONFLICT (id) DO NOTHING;

-- Public read; authenticated (staff) write/update/delete.
CREATE POLICY "service_center_assets_public_read"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'service-center-assets');

CREATE POLICY "service_center_assets_authenticated_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'service-center-assets');

CREATE POLICY "service_center_assets_authenticated_update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'service-center-assets')
  WITH CHECK (bucket_id = 'service-center-assets');

CREATE POLICY "service_center_assets_authenticated_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'service-center-assets');

CREATE POLICY "article_assets_public_read"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'article-assets');

CREATE POLICY "article_assets_authenticated_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'article-assets');

CREATE POLICY "article_assets_authenticated_update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'article-assets')
  WITH CHECK (bucket_id = 'article-assets');

CREATE POLICY "article_assets_authenticated_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'article-assets');
