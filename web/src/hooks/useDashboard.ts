import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';

export interface StatusCounts {
  pending: number;
  preparing: number;
  ready: number;
  completed: number;
  cancelled: number;
}

export interface WeeklyDataPoint {
  date: string;
  requests: number;
}

export interface DashboardData {
  statusCounts: StatusCounts;
  weeklyData: WeeklyDataPoint[];
}

const EMPTY_COUNTS: StatusCounts = {
  pending: 0,
  preparing: 0,
  ready: 0,
  completed: 0,
  cancelled: 0,
};

function getLast7Days(): Date[] {
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    d.setDate(d.getDate() - (6 - i));
    return d;
  });
}

function toLocalDateString(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

export function useDashboard() {
  const [data, setData] = useState<DashboardData>({
    statusCounts: EMPTY_COUNTS,
    weeklyData: [],
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDashboard = useCallback(async () => {
    setLoading(true);
    setError(null);

    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
    sevenDaysAgo.setHours(0, 0, 0, 0);

    const { data: rows, error: err } = await supabase
      .from('condom_requests')
      .select('status, created_at');

    if (err) {
      setError(err.message);
      setLoading(false);
      return;
    }

    const counts: StatusCounts = { ...EMPTY_COUNTS };
    const days = getLast7Days();
    const dailyMap: Record<string, number> = {};
    days.forEach(d => { dailyMap[toLocalDateString(d)] = 0; });

    for (const row of rows ?? []) {
      const status = row.status as keyof StatusCounts;
      if (status in counts) counts[status]++;

      const createdAt = new Date(row.created_at);
      if (createdAt >= sevenDaysAgo) {
        const key = toLocalDateString(createdAt);
        if (key in dailyMap) dailyMap[key]++;
      }
    }

    const weeklyData: WeeklyDataPoint[] = days.map(d => ({
      date: d.toLocaleDateString('th-TH', { day: 'numeric', month: 'short' }),
      requests: dailyMap[toLocalDateString(d)],
    }));

    setData({ statusCounts: counts, weeklyData });
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchDashboard();
  }, [fetchDashboard]);

  return { ...data, loading, error };
}
