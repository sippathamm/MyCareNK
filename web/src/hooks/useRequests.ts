import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { RequestData } from '../components/requests/RequestDetailDialog';

type ContactInfo = { phone_number: string | null; nickname: string | null };

function formatRow(row: RequestData, contact?: ContactInfo): RequestData {
  return {
    ...row,
    selected_time: row.selected_time?.slice(0, 5) ?? null,
    phone_number: contact?.phone_number ?? null,
    nickname: contact?.nickname ?? null,
  };
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
        'id, reference_number, user_id, selected_date, selected_time, selected_service_center, ' +
        'condom_quantities, lubricant_quantity, message, request_status, cancel_reason, ' +
        'handled_by, completed_at, created_at, updated_at'
      )
      .order('created_at', { ascending: false });

    if (error) {
      setError(error.message);
      setLoading(false);
      return;
    }

    const rows = (data ?? []) as unknown as RequestData[];
    const userIds = [...new Set(rows.map(r => r.user_id).filter(Boolean))];

    let contactMap: Record<string, ContactInfo> = {};
    if (userIds.length > 0) {
      const { data: profiles } = await supabase
        .from('user_profiles')
        .select('user_id, phone_number, nickname')
        .in('user_id', userIds);
      for (const p of profiles ?? []) {
        contactMap[p.user_id] = { phone_number: p.phone_number, nickname: p.nickname };
      }
    }

    setRequests(rows.map(r => formatRow(r, contactMap[r.user_id])));
    setLoading(false);
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
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
            const newRow = formatRow(payload.new as unknown as RequestData);
            setRequests(prev => [newRow, ...prev]);
          } else if (payload.eventType === 'UPDATE') {
            const updatedRow = formatRow(payload.new as unknown as RequestData);
            setRequests(prev =>
              prev.map(r => r.id === updatedRow.id ? { ...r, ...updatedRow } : r)
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
