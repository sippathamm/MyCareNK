import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';

export interface StaffWorkloadRow {
  staff_user_id: string;
  first_name: string;
  last_name: string;
  service_center: string;
  completed_count: number;
  cancelled_count: number;
  overdue_count: number;
  avg_lead_time_minutes: number | null;
}

export interface EnrichedRow extends StaffWorkloadRow {
  id: string;
  delta_completed: number | null;
  delta_cancelled: number | null;
  delta_overdue: number | null;
}

function parseError(e: unknown): string {
  if (e instanceof Error) return e.message;
  return (e as { message?: string })?.message ?? String(e);
}

async function fetchWorkload(
  dateFrom: string,
  dateTo: string,
  serviceCenter: string | null,
): Promise<StaffWorkloadRow[]> {
  const from = new Date(dateFrom);
  const to = new Date(dateTo);
  to.setHours(23, 59, 59, 999);
  const { data, error } = await supabase.rpc('get_staff_workload', {
    p_date_from: from.toISOString(),
    p_date_to: to.toISOString(),
    p_service_center: serviceCenter ?? undefined,
  });
  if (error) throw error;
  return (data as StaffWorkloadRow[]) ?? [];
}

export function useStaffWorkload(
  dateFrom: string,
  dateTo: string,
  serviceCenter: string | null = null,
  compareDateFrom: string | null = null,
  compareDateTo: string | null = null,
) {
  const [data, setData] = useState<StaffWorkloadRow[]>([]);
  const [compareData, setCompareData] = useState<StaffWorkloadRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const queries: Promise<StaffWorkloadRow[]>[] = [
        fetchWorkload(dateFrom, dateTo, serviceCenter),
      ];
      if (compareDateFrom && compareDateTo) {
        queries.push(fetchWorkload(compareDateFrom, compareDateTo, serviceCenter));
      }
      const [main, compare] = await Promise.all(queries);
      setData(main);
      setCompareData(compare ?? []);
    } catch (e) {
      setError(parseError(e));
    } finally {
      setLoading(false);
    }
  }, [dateFrom, dateTo, serviceCenter, compareDateFrom, compareDateTo]);

  useEffect(() => { fetch(); }, [fetch]);

  return { data, compareData, loading, error, refetch: fetch };
}
