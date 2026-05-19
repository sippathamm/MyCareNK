import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { AuditAction } from '../constants/auditLogActions';

export interface StaffAuditLogRow {
  id: string;
  performed_by: string | null;
  full_name: string;
  action: AuditAction;
  target_id: string;
  target_full_name: string | null;
  old_value: Record<string, unknown> | null;
  new_value: Record<string, unknown> | null;
  created_at: string;
}

export interface StaffAuditLogFilters {
  performedBy: string | null;
  action:      AuditAction | null;
  targetId:    string | null;
  dateFrom:    string | null;
  dateTo:      string | null;
}

function parseError(e: unknown): string {
  if (e instanceof Error) return e.message;
  return (e as { message?: string })?.message ?? String(e);
}

export function useStaffAuditLog(
  filters: StaffAuditLogFilters,
  page: number,
  pageSize: number,
) {
  const [rows, setRows] = useState<StaffAuditLogRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

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

      const { data, error: rpcError } = await supabase.rpc('get_staff_audit_log', {
        p_performed_by: filters.performedBy ?? undefined,
        p_action:       filters.action      ?? undefined,
        p_target_id:    filters.targetId    ?? undefined,
        p_date_from:    filters.dateFrom    ? new Date(filters.dateFrom).toISOString() : undefined,
        p_date_to:      dateTo ?? undefined,
        p_limit:        pageSize,
        p_offset:       page * pageSize,
      });

      if (rpcError) throw rpcError;
      setRows((data as StaffAuditLogRow[]) ?? []);
    } catch (e) {
      setError(parseError(e));
    } finally {
      setLoading(false);
    }
  }, [filters, page, pageSize]);

  useEffect(() => { fetch(); }, [fetch]);

  return { rows, loading, error, refetch: fetch };
}
