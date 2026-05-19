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
    } else {
      setAppointments(data as unknown as AppointmentData[]);
    }
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
            setAppointments(prev => [payload.new as AppointmentData, ...prev]);
          } else if (payload.eventType === 'UPDATE') {
            setAppointments(prev =>
              prev.map(a => a.id === (payload.new as AppointmentData).id ? payload.new as AppointmentData : a)
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
