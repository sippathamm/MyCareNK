import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';

export interface InventoryForecastRow {
  service_center: string;
  is_active: boolean;
  condom_qty: number;
  lubricant_qty: number;
  condom_daily_burn: number;
  lubricant_daily_burn: number;
  condom_days_left: number | null;
  lubricant_days_left: number | null;
}

export interface ConsumptionTrendPoint {
  day: string;
  service_center: string;
  condom_used: number;
  lubricant_used: number;
}

export function useInventoryForecast() {
  const [forecast, setForecast] = useState<InventoryForecastRow[]>([]);
  const [trend, setTrend] = useState<ConsumptionTrendPoint[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);

    const [{ data: forecastData, error: forecastErr }, { data: trendData, error: trendErr }] =
      await Promise.all([
        supabase.rpc('get_inventory_forecast'),
        supabase.rpc('get_consumption_trend'),
      ]);

    if (forecastErr || trendErr) {
      setError((forecastErr ?? trendErr)!.message);
      setLoading(false);
      return;
    }

    setForecast((forecastData as InventoryForecastRow[]) ?? []);
    setTrend((trendData as ConsumptionTrendPoint[]) ?? []);
    setLoading(false);
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    fetchData();
  }, [fetchData]);

  return { forecast, trend, loading, error, refetch: fetchData };
}
