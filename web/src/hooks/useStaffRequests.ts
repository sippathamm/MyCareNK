import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';

export interface StaffRequestRow {
  id:                      string;
  reference_number:        string;
  request_status:          string;
  created_at:              string;
  updated_at:              string;
  completed_at:            string | null;
  selected_date:           string | null;
  selected_time:           string | null;
  selected_service_center: string;
  condom_quantities:       Record<string, number>;
  lubricant_quantity:      number;
  message:                 string | null;
  cancel_reason:           string | null;
  handled_by:              string | null;
}

function parseError(e: unknown): string {
  if (e instanceof Error) return e.message;
  return (e as { message?: string })?.message ?? String(e);
}

export function useStaffRequests(
  staffUserId: string | null,
  dateFrom:    string,
  dateTo:      string,
) {
  const [data, setData]       = useState<StaffRequestRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError]     = useState<string | null>(null);

  const fetch = useCallback(async () => {
    if (!staffUserId || !dateFrom || !dateTo) { setData([]); return; }
    setLoading(true);
    setError(null);
    try {
      const from = new Date(dateFrom);
      const to   = new Date(dateTo);
      to.setHours(23, 59, 59, 999);

      const { data: rows, error: dbError } = await supabase
        .from('condom_requests')
        .select(`
          id, reference_number, request_status,
          created_at, updated_at, completed_at,
          selected_date, selected_time, selected_service_center,
          condom_quantities, lubricant_quantity, message, cancel_reason, handled_by
        `)
        .eq('handled_by', staffUserId)
        .gte('created_at', from.toISOString())
        .lte('created_at', to.toISOString())
        .order('created_at', { ascending: false });

      if (dbError) throw dbError;
      setData((rows as StaffRequestRow[]) ?? []);
    } catch (e) {
      setError(parseError(e));
    } finally {
      setLoading(false);
    }
  }, [staffUserId, dateFrom, dateTo]);

  useEffect(() => { fetch(); }, [fetch]);

  return { data, setData, loading, error, refetch: fetch };
}
