import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';

export interface PeakTimeStat {
  bucket: string;
  count: number;
}

export function usePeakTime(
  dateFrom: string,
  dateTo: string,
  serviceCenter: string | null
) {
  const [hourlyData, setHourlyData] = useState<PeakTimeStat[]>([]);
  const [dailyData, setDailyData] = useState<PeakTimeStat[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPeakTime = useCallback(async () => {
    if (!dateFrom || !dateTo) return;

    setLoading(true);
    setError(null);

    const from = new Date(dateFrom);
    const to = new Date(dateTo);
    to.setHours(23, 59, 59, 999);

    const args = {
      p_date_from: from.toISOString(),
      p_date_to: to.toISOString(),
      ...(serviceCenter ? { p_service_center: serviceCenter } : {}),
    };

    const [
      { data: hourlyRaw, error: hourlyErr },
      { data: dailyRaw, error: dailyErr },
    ] = await Promise.all([
      supabase.rpc('get_peak_time_stats', { ...args, p_period: 'hourly' }),
      supabase.rpc('get_peak_time_stats', { ...args, p_period: 'daily' }),
    ]);

    if (hourlyErr || dailyErr) {
      setError((hourlyErr ?? dailyErr)!.message);
      setLoading(false);
      return;
    }

    setHourlyData(hourlyRaw ?? []);
    setDailyData(dailyRaw ?? []);
    setLoading(false);
  }, [dateFrom, dateTo, serviceCenter]);

  useEffect(() => {
    fetchPeakTime();
  }, [fetchPeakTime]);

  return { hourlyData, dailyData, loading, error };
}
