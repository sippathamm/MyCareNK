import { useState, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { Enums } from '../lib/database.types';

export interface StaffMember {
  staff_user_id: string;
  first_name: string;
  last_name: string;
  service_centers: string[];
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
  let { data: { session } } = await supabase.auth.getSession();
  if (!session) return { data: null, error: 'กรุณาเข้าสู่ระบบ' };

  // Refresh the token if it has expired or will expire within 60 seconds
  const expiresAt = session.expires_at ?? 0;
  if (expiresAt - Math.floor(Date.now() / 1000) < 60) {
    const { data: refreshed } = await supabase.auth.refreshSession();
    if (!refreshed.session) return { data: null, error: 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่' };
    session = refreshed.session;
  }

  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string;
  const res = await fetch(`${supabaseUrl}/functions/v1/staff-management`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${session.access_token}`,
    },
    body: JSON.stringify({ action, ...payload }),
  });

  const json = await res.json().catch(() => null);
  if (!json || !res.ok || json.status === 'error') {
    return { data: null, error: json?.message ?? 'เกิดข้อผิดพลาดของระบบ' };
  }
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
    service_centers: string[];
    role: Enums<'role'>;
  }): Promise<string | null> => {
    const { error: err } = await callStaffManagement('create', payload);
    if (!err) await fetchStaff();
    return err;
  }, [fetchStaff]);

  const updateStaff = useCallback(async (payload: {
    staff_user_id: string;
    first_name?: string;
    last_name?: string;
    service_centers?: string[];
    role?: Enums<'role'>;
    email?: string;
  }): Promise<string | null> => {
    const { error: err } = await callStaffManagement('update', payload);
    if (!err) await fetchStaff();
    return err;
  }, [fetchStaff]);

  const deleteStaff = useCallback(async (userId: string): Promise<string | null> => {
    const { error: err } = await callStaffManagement('delete', { user_id: userId });
    if (!err) setStaff(prev => prev.filter(s => s.staff_user_id !== userId));
    return err;
  }, []);

  return { staff, loading, error, fetchStaff, createStaff, updateStaff, deleteStaff };
}
