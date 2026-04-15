import { useState, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { Enums } from '../lib/database.types';

export interface StaffMember {
  user_id: string;
  first_name: string;
  last_name: string;
  service_center: Enums<'service_center'>;
  role: Enums<'role'>;
  email: string;
  created_at: string;
  updated_at: string | null;
  last_sign_in_at: string | null;
}

async function callStaffManagement<T = undefined>(
  action: string,
  payload?: Record<string, unknown>
): Promise<{ data: T | null; error: string | null }> {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return { data: null, error: 'กรุณาเข้าสู่ระบบ' };

  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string;
  const res = await fetch(`${supabaseUrl}/functions/v1/staff-management`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${session.access_token}`,
    },
    body: JSON.stringify({ action, ...payload }),
  });

  const json = await res.json();
  if (json.status === 'error') return { data: null, error: json.message };
  return { data: json.result as T, error: null };
}

export function useStaffManagement() {
  const [staff, setStaff] = useState<StaffMember[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchStaff = useCallback(async () => {
    setLoading(true);
    setError(null);
    const { data, error: err } = await callStaffManagement<{ staff: StaffMember[] }>('list');
    if (err) {
      setError(err);
    } else {
      setStaff(data?.staff ?? []);
    }
    setLoading(false);
  }, []);

  const createStaff = useCallback(async (payload: {
    email: string;
    password: string;
    first_name: string;
    last_name: string;
    service_center: Enums<'service_center'>;
    role: Enums<'role'>;
  }): Promise<string | null> => {
    const { error: err } = await callStaffManagement('create', payload);
    if (!err) await fetchStaff();
    return err;
  }, [fetchStaff]);

  const updateStaff = useCallback(async (payload: {
    user_id: string;
    first_name?: string;
    last_name?: string;
    service_center?: Enums<'service_center'>;
    role?: Enums<'role'>;
    email?: string;
  }): Promise<string | null> => {
    const { error: err } = await callStaffManagement('update', payload);
    if (!err) await fetchStaff();
    return err;
  }, [fetchStaff]);

  const deleteStaff = useCallback(async (userId: string): Promise<string | null> => {
    const { error: err } = await callStaffManagement('delete', { user_id: userId });
    if (!err) setStaff(prev => prev.filter(s => s.user_id !== userId));
    return err;
  }, []);

  return { staff, loading, error, fetchStaff, createStaff, updateStaff, deleteStaff };
}
