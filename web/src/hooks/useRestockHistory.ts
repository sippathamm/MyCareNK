import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { Enums } from '../lib/database.types';

export interface RestockHistoryRow {
  id: string;
  service_center: Enums<'service_center'>;
  transaction_type: 'restock' | 'adjustment';
  condom_delta: number;
  lubricant_delta: number;
  created_at: string;
  performed_by: string;
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

    const [{ data: transactions, error: txErr }, { data: profiles, error: profileErr }] =
      await Promise.all([
        supabase
          .from('inventory_transactions')
          .select('id, service_center, transaction_type, condom_delta, lubricant_delta, created_at, note, performed_by')
          .in('transaction_type', ['restock', 'adjustment'])
          .order('created_at', { ascending: false })
          .limit(200),
        supabase
          .from('staff_profiles')
          .select('user_id, first_name, last_name'),
      ]);

    if (txErr || profileErr) {
      setError((txErr ?? profileErr)!.message);
      setLoading(false);
      return;
    }

    const profileMap = new Map(
      (profiles ?? []).map((p) => [
        p.user_id,
        [p.first_name, p.last_name].filter(Boolean).join(' ') || 'ไม่ทราบชื่อ',
      ]),
    );

    setRows(
      (transactions ?? []).map((t) => ({
        ...t,
        performer_name: profileMap.get(t.performed_by) ?? 'ไม่ทราบชื่อ',
      })) as RestockHistoryRow[],
    );
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { rows, loading, error, refetch: fetchData };
}
