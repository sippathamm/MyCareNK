import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { ConsultationData } from '../components/consultations/ConsultationDetailDialog';

async function fetchStaffName(staffUserId: string): Promise<string | null> {
  const { data } = await supabase
    .from('staff_profiles')
    .select('staff_user_id, first_name, last_name')
    .eq('staff_user_id', staffUserId)
    .single();
  return data ? `${data.first_name} ${data.last_name}` : null;
}

export function useConsultations() {
  const [consultations, setConsultations] = useState<ConsultationData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchConsultations = useCallback(async () => {
    setLoading(true);
    setError(null);
    const { data, error } = await supabase
      .from('consultations')
      .select(
        'id, reference_number, user_id, reason, selected_service_center, ' +
        'selected_date, selected_time, note, consultation_status, cancel_reason, ' +
        'handled_by, created_at, updated_at'
      )
      .order('created_at', { ascending: false });

    if (error) {
      setError(error.message);
      setLoading(false);
      return;
    }

    const rows = (data ?? []) as unknown as ConsultationData[];

    const userIds = [...new Set(rows.map(a => a.user_id).filter((id): id is string => Boolean(id)))];
    let contactMap: Record<string, { phone_number: string | null; nickname: string | null }> = {};
    if (userIds.length > 0) {
      const { data: profiles } = await supabase
        .from('user_profiles')
        .select('user_id, phone_number, nickname')
        .in('user_id', userIds);
      for (const p of profiles ?? []) {
        contactMap[p.user_id] = { phone_number: p.phone_number, nickname: p.nickname };
      }
    }

    const handledByIds = [...new Set(rows.map(a => a.handled_by).filter((id): id is string => Boolean(id)))];
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

    setConsultations(rows.map(a => ({
      ...a,
      phone_number: (a.user_id ? contactMap[a.user_id]?.phone_number : null) ?? null,
      nickname: (a.user_id ? contactMap[a.user_id]?.nickname : null) ?? null,
      handled_by_name: a.handled_by ? (staffNameMap[a.handled_by] ?? null) : null,
    })));
    setLoading(false);
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    fetchConsultations();
  }, [fetchConsultations]);

  useEffect(() => {
    const channel = supabase
      .channel('consultations-consultations')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'consultations' },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            const newRow = payload.new as unknown as ConsultationData;
            (newRow.user_id
              ? supabase
                  .from('user_profiles')
                  .select('user_id, phone_number, nickname')
                  .eq('user_id', newRow.user_id)
                  .single()
              : Promise.resolve({ data: null })
            )
              .then(({ data: profile }) => {
                setConsultations(prev => [{
                  ...newRow,
                  phone_number: profile?.phone_number ?? null,
                  nickname: profile?.nickname ?? null,
                  handled_by_name: null,
                }, ...prev]);
              });
          } else if (payload.eventType === 'UPDATE') {
            const updated = payload.new as unknown as ConsultationData;
            const namePromise = updated.handled_by
              ? fetchStaffName(updated.handled_by)
              : Promise.resolve(null);
            namePromise.then(handled_by_name => {
              setConsultations(prev =>
                prev.map(a => a.id === updated.id
                  ? {
                      ...updated,
                      phone_number: a.phone_number,
                      nickname: a.nickname,
                      handled_by_name: handled_by_name ?? a.handled_by_name,
                    }
                  : a)
              );
            });
          } else if (payload.eventType === 'DELETE') {
            const deletedId = (payload.old as { id?: string }).id;
            if (deletedId) setConsultations(prev => prev.filter(a => a.id !== deletedId));
          }
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, []);

  return { consultations, setConsultations, loading, error, refetch: fetchConsultations };
}
