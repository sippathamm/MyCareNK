import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { Enums } from '../lib/database.types';

export interface ServiceCenterDemandRow {
  service_center: Enums<'service_center'>;
  total_requests: number;
  total_condoms: number;
  total_lubricants: number;
}

export interface ServiceCenterTrendPoint {
  service_center: Enums<'service_center'>;
  day: string;
  request_count: number;
}

export function useServiceCenterDemand(dateFrom: string, dateTo: string) {
  const [demand, setDemand] = useState<ServiceCenterDemandRow[]>([]);
  const [trend, setTrend] = useState<ServiceCenterTrendPoint[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    if (!dateFrom || !dateTo) return;

    setLoading(true);
    setError(null);

    const from = new Date(dateFrom);
    const to = new Date(dateTo);
    to.setHours(23, 59, 59, 999);

    const [{ data: demandData, error: demandErr }, { data: trendData, error: trendErr }] =
      await Promise.all([
        supabase.rpc('get_service_center_demand', {
          p_date_from: from.toISOString(),
          p_date_to: to.toISOString(),
        }),
        supabase.rpc('get_service_center_demand_trend'),
      ]);

    if (demandErr || trendErr) {
      setError((demandErr ?? trendErr)!.message);
      setLoading(false);
      return;
    }

    setDemand(demandData ?? []);
    setTrend(trendData ?? []);
    setLoading(false);
  }, [dateFrom, dateTo]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { demand, trend, loading, error };
}
