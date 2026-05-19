import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';

export interface AppointmentStatusLogRow {
  id:               string;
  appointment_id:   string;
  reference_number: string | null;
  performed_by:     string | null;
  full_name:        string;
  from_status:      string | null;
  to_status:        string;
  changed_at:       string;
}

export interface AppointmentStatusLogFilters {
  performedBy:     string | null;
  fromStatus:      string | null;
  toStatus:        string | null;
  referenceNumber: string | null;
  dateFrom:        string | null;
  dateTo:          string | null;
}

function parseError(e: unknown): string {
  if (e instanceof Error) return e.message;
  return (e as { message?: string })?.message ?? String(e);
}

export function useAppointmentStatusLog(
  filters:  AppointmentStatusLogFilters,
  page:     number,
  pageSize: number,
) {
  const [rows, setRows]       = useState<AppointmentStatusLogRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState<string | null>(null);

  const fetch = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      let dateTo: string | null = null;
      if (filters.dateTo) {
        const d = new Date(filters.dateTo);
        d.setHours(23, 59, 59, 999);
        dateTo = d.toISOString();
      }

      const { data, error: rpcError } = await supabase.rpc('get_appointment_status_log', {
        p_performed_by:     filters.performedBy     ?? undefined,
        p_from_status:      filters.fromStatus      ?? undefined,
        p_to_status:        filters.toStatus        ?? undefined,
        p_reference_number: filters.referenceNumber ?? undefined,
        p_date_from:        filters.dateFrom ? new Date(filters.dateFrom).toISOString() : undefined,
        p_date_to:          dateTo ?? undefined,
        p_limit:            pageSize,
        p_offset:           page * pageSize,
      });

      if (rpcError) throw rpcError;
      setRows((data as AppointmentStatusLogRow[]) ?? []);
    } catch (e) {
      setError(parseError(e));
    } finally {
      setLoading(false);
    }
  }, [filters, page, pageSize]);

  useEffect(() => { fetch(); }, [fetch]);

  return { rows, loading, error, refetch: fetch };
}
