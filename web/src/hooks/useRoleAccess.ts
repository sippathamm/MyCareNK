import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from './useAuth';
import type { Enums, Tables } from '../lib/database.types';

export type StaffRole = Enums<'role'> | null;

export type StaffProfile = Pick<Tables<'staff_profiles'>, 'first_name' | 'last_name' | 'service_center'> & {
  service_centers: string[];
};

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

        const { data, error } = await supabase
          .from('staff_profiles')
          .select('first_name, last_name, service_center, service_centers, role')
          .eq('staff_user_id', userId)
          .single();

        if (error) throw error;

        if (isMounted) {
          setRole(data?.role ?? null);
          setProfile(data ? {
            first_name: data.first_name,
            last_name: data.last_name,
            service_center: data.service_center,
            service_centers: (data.service_centers as string[] | null) ?? [],
          } : null);
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

  const isSuperadmin = role === 'superadmin';
  const isAdmin = role === 'admin';
  const isStaff = role === 'staff';
  // For superadmin: empty array means "all SCs" — always check isSuperadmin first
  const serviceCenters: string[] = profile?.service_centers ?? [];

  return { role, profile, loading, isSuperadmin, isAdmin, isStaff, serviceCenters };
}
