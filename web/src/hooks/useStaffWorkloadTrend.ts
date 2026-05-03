import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';

export interface WorkloadTrendRow {
  week_start:      string;
  staff_user_id:   string;
  first_name:      string;
  last_name:       string;
  completed_count: number;
  cancelled_count: number;
}

function parseError(e: unknown): string {
  if (e instanceof Error) return e.message;
  return (e as { message?: string })?.message ?? String(e);
}

export function useStaffWorkloadTrend(
  dateFrom:       string,
  dateTo:         string,
  serviceCenter:  string | null = null,
  staffUserId:    string | null = null,
) {
  const [data, setData]       = useState<WorkloadTrendRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState<string | null>(null);

  const fetch = useCallback(async () => {
    if (!dateFrom || !dateTo) return;
    setLoading(true);
    setError(null);
    try {
      const from = new Date(dateFrom);
      const to   = new Date(dateTo);
      to.setHours(23, 59, 59, 999);

      const { data: rows, error: rpcError } = await supabase.rpc('get_staff_workload_trend', {
        p_date_from:      from.toISOString(),
        p_date_to:        to.toISOString(),
        p_service_center: serviceCenter ?? null,
        p_staff_user_id:  staffUserId   ?? null,
      });
      if (rpcError) throw rpcError;
      setData((rows as WorkloadTrendRow[]) ?? []);
    } catch (e) {
      setError(parseError(e));
    } finally {
      setLoading(false);
    }
  }, [dateFrom, dateTo, serviceCenter, staffUserId]);

  useEffect(() => { fetch(); }, [fetch]);

  return { data, loading, error, refetch: fetch };
}
