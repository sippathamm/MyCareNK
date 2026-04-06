import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from './useAuth';

export type StaffRole = 'staff' | 'admin' | 'superadmin' | null;

export interface StaffProfile {
  first_name: string;
  last_name: string;
  service_center: string;
}

export function useRoleAccess() {
  const { session } = useAuth();
  const [role, setRole] = useState<StaffRole>(null);
  const [profile, setProfile] = useState<StaffProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;

    async function fetchAccess() {
      if (!session?.user) {
        if (isMounted) {
          setRole(null);
          setProfile(null);
          setLoading(false);
        }
        return;
      }

      setLoading(true);
      try {
        const userId = session.user.id;

        // Fetch role and profile in parallel
        const [
          { data: roleData, error: roleError },
          { data: profileData, error: profileError },
        ] = await Promise.all([
          supabase.from('staff_roles').select('role').eq('user_id', userId).single(),
          supabase.from('staff_profiles').select('first_name, last_name, service_center').eq('user_id', userId).single(),
        ]);

        if (roleError) throw roleError;
        if (profileError) throw profileError;

        if (isMounted) {
          setRole(roleData?.role as StaffRole);
          setProfile(profileData);
        }
      } catch (error) {
        console.error('Error fetching role or profile:', error);
        if (isMounted) {
          setRole(null);
          setProfile(null);
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    }

    fetchAccess();

    return () => {
      isMounted = false;
    };
  }, [session]);

  return { role, profile, loading };
}
