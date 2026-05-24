-- Allow staff/admin/superadmin to read user profiles (for contact info in request/appointment dialogs)
CREATE POLICY "Staff can read all user profiles"
  ON public.user_profiles FOR SELECT
  TO authenticated USING (is_staff());
