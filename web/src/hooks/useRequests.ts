import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { RequestData } from '../components/requests/RequestDetailDialog';

function formatRow(row: Record<string, unknown>): RequestData {
  return {
    ...row,
    selected_time: (row.selected_time as string)?.slice(0, 5) ?? '',
  } as RequestData;
}

export function useRequests() {
  const [requests, setRequests] = useState<RequestData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchRequests = useCallback(async () => {
    setLoading(true);
    setError(null);
    const { data, error } = await supabase
      .from('condom_requests')
      .select(
        'id, reference_number, selected_date, selected_time, selected_service_center, ' +
        'condom_quantities, lubricant_quantity, message, request_status, cancel_reason, ' +
        'handled_by, completed_at, created_at, updated_at'
      )
      .order('created_at', { ascending: false });

    if (error) {
      setError(error.message);
    } else {
      setRequests(
        (data ?? []).map(r => formatRow(r as unknown as Record<string, unknown>))
      );
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchRequests();
  }, [fetchRequests]);

  useEffect(() => {
    const channel = supabase
      .channel('requests-condom-requests')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'condom_requests' },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            const newRow = formatRow(payload.new as unknown as Record<string, unknown>);
            setRequests(prev => [newRow, ...prev]);
          } else if (payload.eventType === 'UPDATE') {
            const updatedRow = formatRow(payload.new as unknown as Record<string, unknown>);
            setRequests(prev =>
              prev.map(r => r.id === updatedRow.id ? updatedRow : r)
            );
          } else if (payload.eventType === 'DELETE') {
            const deletedId = (payload.old as { id?: string }).id;
            if (deletedId) {
              setRequests(prev => prev.filter(r => r.id !== deletedId));
            }
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  return { requests, setRequests, loading, error, refetch: fetchRequests };
}
