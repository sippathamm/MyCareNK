import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
export interface RestockHistoryRow {
  id: string;
  service_center: string;
  action: 'restock' | 'adjustment';
  condom_delta: number;
  lubricant_delta: number;
  created_at: string;
  performed_by: string | null;
  performer_name: string;
  note: string | null;
}

export function useRestockHistory() {
  const [rows, setRows] = useState<RestockHistoryRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);

    const [{ data: logs, error: logsErr }, { data: profiles, error: profileErr }] =
      await Promise.all([
        supabase
          .from('inventory_logs')
          .select('id, service_center, action, condom_delta, lubricant_delta, created_at, note, performed_by')
          .in('action', ['restock', 'adjustment'])
          .order('created_at', { ascending: false })
          .limit(200),
        supabase
          .from('staff_profiles')
          .select('staff_user_id, first_name, last_name'),
      ]);

    if (logsErr || profileErr) {
      setError((logsErr ?? profileErr)!.message);
      setLoading(false);
      return;
    }

    const profileMap = new Map(
      (profiles ?? []).map((p) => [
        p.staff_user_id,
        [p.first_name, p.last_name].filter(Boolean).join(' ') || 'ไม่ทราบชื่อ',
      ]),
    );

    setRows(
      (logs ?? []).map((t) => ({
        ...t,
        action: t.action as 'restock' | 'adjustment',
        performer_name: profileMap.get(t.performed_by ?? '') ?? 'ไม่ทราบชื่อ',
      })),
    );
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { rows, loading, error, refetch: fetchData };
}
