import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';

export interface LeadTimeResult {
  overall_avg_minutes: number | null;
  pending_to_preparing: number | null;
  preparing_to_ready: number | null;
  ready_to_completed: number | null;
}

const EMPTY_RESULT: LeadTimeResult = {
  overall_avg_minutes: null,
  pending_to_preparing: null,
  preparing_to_ready: null,
  ready_to_completed: null,
};

export function useLeadTime(
  dateFrom: string,
  dateTo: string,
  serviceCenter: string | null
) {
  const [current, setCurrent] = useState<LeadTimeResult>(EMPTY_RESULT);
  const [previous, setPrevious] = useState<LeadTimeResult>(EMPTY_RESULT);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchLeadTime = useCallback(async () => {
    if (!dateFrom || !dateTo) return;

    setLoading(true);
    setError(null);

    const from = new Date(dateFrom);
    const to = new Date(dateTo);
    to.setHours(23, 59, 59, 999);

    const durationMs = to.getTime() - from.getTime();
    const prevTo = new Date(from.getTime() - 1);
    const prevFrom = new Date(prevTo.getTime() - durationMs);

    const args = {
      p_date_from: from.toISOString(),
      p_date_to: to.toISOString(),
      ...(serviceCenter ? { p_service_center: serviceCenter } : {}),
    };

    const prevArgs = {
      p_date_from: prevFrom.toISOString(),
      p_date_to: prevTo.toISOString(),
      ...(serviceCenter ? { p_service_center: serviceCenter } : {}),
    };

    const [{ data: curData, error: curErr }, { data: prevData, error: prevErr }] =
      await Promise.all([
        supabase.rpc('get_average_lead_time', args),
        supabase.rpc('get_average_lead_time', prevArgs),
      ]);

    if (curErr || prevErr) {
      setError((curErr ?? prevErr)!.message);
      setLoading(false);
      return;
    }

    setCurrent(curData?.[0] ?? EMPTY_RESULT);
    setPrevious(prevData?.[0] ?? EMPTY_RESULT);
    setLoading(false);
  }, [dateFrom, dateTo, serviceCenter]);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    fetchLeadTime();
  }, [fetchLeadTime]);

  return { current, previous, loading, error };
}
