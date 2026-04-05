import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { RequestData } from '../components/requests/RequestDetailDialog';

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
        'id, reference_number, selected_date, selected_time, selected_location, ' +
        'condom_quantities, lubricant_quantity, message, status, created_at, updated_at'
      )
      .order('created_at', { ascending: false });

    if (error) {
      setError(error.message);
    } else {
      setRequests(
        (data ?? []).map(r => ({
          ...r,
          selected_time: (r.selected_time as string)?.slice(0, 5) ?? '',
        } as RequestData))
      );
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchRequests();
  }, [fetchRequests]);

  return { requests, setRequests, loading, error, refetch: fetchRequests };
}
