-- Grant schema usage
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Grant all table privileges to authenticated (RLS policies enforce fine-grained access)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant no direct table access to anon (all anon-accessible data goes through SECURITY DEFINER RPCs)
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;

-- Ensure future tables also get these grants
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO authenticated;
