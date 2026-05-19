import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';

export interface ServiceCenterRow {
  name: string;
  image_url: string | null;
  description: string | null;
  address: string | null;
  contacts: { label: string; value: string }[];
  latitude: number | null;
  longitude: number | null;
  is_active: boolean;
  display_order: number;
  operating_hours: string | null;
  condom_service_enabled: boolean;
  appointment_service_enabled: boolean;
  pickup_times: string[];
  appointment_times: string[];
}

export function useServiceCenters(enabled = true) {
  const [centers, setCenters] = useState<ServiceCenterRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    const { data, error: fetchError } = await supabase.rpc('get_service_centers');
    if (fetchError) {
      setError(fetchError.message);
    } else {
      setCenters((data as unknown as ServiceCenterRow[]) ?? []);
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    if (enabled) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      fetchData();
    }
  }, [enabled, fetchData]);

  return { centers, loading, error, refetch: fetchData };
}
