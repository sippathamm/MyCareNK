import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { Enums } from '../lib/database.types';

export interface StaffWorkloadRow {
  staff_user_id: string;
  first_name: string;
  last_name: string;
  service_center: Enums<'service_center'>;
  completed_count: number;
  cancelled_count: number;
  overdue_count: number;
  avg_lead_time_minutes: number | null;
}

export function useStaffWorkload(dateFrom: string, dateTo: string, serviceCenter: string | null = null) {
  const [data, setData] = useState<StaffWorkloadRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const from = new Date(dateFrom);
      const to = new Date(dateTo);
      to.setHours(23, 59, 59, 999);

      const { data: rows, error: rpcError } = await supabase.rpc('get_staff_workload', {
        p_date_from: from.toISOString(),
        p_date_to: to.toISOString(),
        p_service_center: serviceCenter ?? null,
      });

      if (rpcError) throw rpcError;
      setData((rows as StaffWorkloadRow[]) ?? []);
    } catch (e) {
      const msg = e instanceof Error
        ? e.message
        : (e as { message?: string })?.message ?? String(e);
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [dateFrom, dateTo, serviceCenter]);

  useEffect(() => { fetchData(); }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
}
