import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { AppointmentData } from '../components/appointments/AppointmentDetailDialog';

export function useAppointments() {
  const [appointments, setAppointments] = useState<AppointmentData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAppointments = useCallback(async () => {
    setLoading(true);
    setError(null);
    const { data, error } = await supabase
      .from('doctor_appointments')
      .select(
        'id, reference_number, user_id, reason, selected_service_center, ' +
        'selected_date, selected_time, note, appointment_status, cancel_reason, ' +
        'handled_by, created_at, updated_at'
      )
      .order('created_at', { ascending: false });

    if (error) {
      setError(error.message);
      setLoading(false);
      return;
    }

    const rows = (data ?? []) as unknown as AppointmentData[];
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

    setAppointments(rows.map(a => ({
      ...a,
      phone_number: (a.user_id ? contactMap[a.user_id]?.phone_number : null) ?? null,
      nickname: (a.user_id ? contactMap[a.user_id]?.nickname : null) ?? null,
    })));
    setLoading(false);
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    fetchAppointments();
  }, [fetchAppointments]);

  useEffect(() => {
    const channel = supabase
      .channel('appointments-doctor-appointments')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'doctor_appointments' },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            const newRow = payload.new as unknown as AppointmentData;
            (newRow.user_id
              ? supabase
                  .from('user_profiles')
                  .select('user_id, phone_number, nickname')
                  .eq('user_id', newRow.user_id)
                  .single()
              : Promise.resolve({ data: null })
            )
              .then(({ data: profile }) => {
                setAppointments(prev => [{
                  ...newRow,
                  phone_number: profile?.phone_number ?? null,
                  nickname: profile?.nickname ?? null,
                }, ...prev]);
              });
          } else if (payload.eventType === 'UPDATE') {
            const updated = payload.new as unknown as AppointmentData;
            setAppointments(prev =>
              prev.map(a => a.id === updated.id
                ? { ...updated, phone_number: a.phone_number, nickname: a.nickname }
                : a)
            );
          } else if (payload.eventType === 'DELETE') {
            const deletedId = (payload.old as { id?: string }).id;
            if (deletedId) setAppointments(prev => prev.filter(a => a.id !== deletedId));
          }
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, []);

  return { appointments, setAppointments, loading, error, refetch: fetchAppointments };
}
