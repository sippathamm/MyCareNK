import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { RequestData } from '../components/requests/RequestDetailDialog';

type ContactInfo = { phone_number: string | null; nickname: string | null };

function formatRow(row: RequestData, contact?: ContactInfo, handledByName?: string | null): RequestData {
  return {
    ...row,
    selected_time: row.selected_time?.slice(0, 5) ?? null,
    phone_number: contact?.phone_number ?? null,
    nickname: contact?.nickname ?? null,
    handled_by_name: handledByName ?? null,
  };
}

async function fetchStaffName(staffUserId: string): Promise<string | null> {
  const { data } = await supabase
    .from('staff_profiles')
    .select('staff_user_id, first_name, last_name')
    .eq('staff_user_id', staffUserId)
    .single();
  return data ? `${data.first_name} ${data.last_name}` : null;
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

    const userIds = [...new Set(rows.map(r => r.user_id).filter((id): id is string => Boolean(id)))];
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

    const handledByIds = [...new Set(rows.map(r => r.handled_by).filter((id): id is string => Boolean(id)))];
    let staffNameMap: Record<string, string> = {};
    if (handledByIds.length > 0) {
      const { data: staffData } = await supabase
        .from('staff_profiles')
        .select('staff_user_id, first_name, last_name')
        .in('staff_user_id', handledByIds);
      for (const s of staffData ?? []) {
        staffNameMap[s.staff_user_id] = `${s.first_name} ${s.last_name}`;
      }
    }

    setRequests(rows.map(r => formatRow(
      r,
      r.user_id ? contactMap[r.user_id] : undefined,
      r.handled_by ? staffNameMap[r.handled_by] : null,
    )));
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
            const newRow = payload.new as unknown as RequestData;
            (newRow.user_id
              ? supabase
                  .from('user_profiles')
                  .select('user_id, phone_number, nickname')
                  .eq('user_id', newRow.user_id)
                  .single()
              : Promise.resolve({ data: null })
            )
              .then(({ data: profile }) => {
                const contact = profile
                  ? { phone_number: profile.phone_number, nickname: profile.nickname }
                  : undefined;
                setRequests(prev => [formatRow(newRow, contact, null), ...prev]);
              });
          } else if (payload.eventType === 'UPDATE') {
            const updatedRow = payload.new as unknown as RequestData;
            const namePromise = updatedRow.handled_by
              ? fetchStaffName(updatedRow.handled_by)
              : Promise.resolve(null);
            namePromise.then(handled_by_name => {
              setRequests(prev =>
                prev.map(r => r.id === updatedRow.id
                  ? {
                      ...formatRow(updatedRow),
                      phone_number: r.phone_number,
                      nickname: r.nickname,
                      handled_by_name: handled_by_name ?? r.handled_by_name,
                    }
                  : r)
              );
            });
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
