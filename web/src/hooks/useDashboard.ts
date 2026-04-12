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
  pending: number;
  preparing: number;
  ready: number;
  completed: number;
  cancelled: number;
}

export interface DashboardData {
  statusCounts: StatusCounts;
  monthlyStatusCounts: StatusCounts;
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
    monthlyStatusCounts: EMPTY_COUNTS,
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
      .select('request_status, created_at');

    if (err) {
      setError(err.message);
      setLoading(false);
      return;
    }

    const counts: StatusCounts = { ...EMPTY_COUNTS };
    const monthlyCounts: StatusCounts = { ...EMPTY_COUNTS };
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth();
    const days = getLast7Days();
    type DailyEntry = { pending: number; preparing: number; ready: number; completed: number; cancelled: number };
    const dailyMap: Record<string, DailyEntry> = {};
    days.forEach(d => { dailyMap[toLocalDateString(d)] = { pending: 0, preparing: 0, ready: 0, completed: 0, cancelled: 0 }; });

    for (const row of rows ?? []) {
      const status = row.request_status as string;
      const statusKey: keyof StatusCounts =
        status === 'cancelled_by_user' || status === 'cancelled_by_staff' ? 'cancelled' : status as keyof StatusCounts;
      if (statusKey in counts) counts[statusKey]++;

      const createdAt = new Date(row.created_at);
      if (createdAt.getFullYear() === currentYear && createdAt.getMonth() === currentMonth) {
        if (statusKey in monthlyCounts) monthlyCounts[statusKey]++;
      }

      if (createdAt >= sevenDaysAgo) {
        const dayKey = toLocalDateString(createdAt);
        if (dayKey in dailyMap) dailyMap[dayKey][statusKey]++;
      }
    }

    const weeklyData: WeeklyDataPoint[] = days.map(d => ({
      date: d.toLocaleDateString('th-TH', { day: 'numeric', month: 'short' }),
      ...dailyMap[toLocalDateString(d)],
    }));

    setData({ statusCounts: counts, monthlyStatusCounts: monthlyCounts, weeklyData });
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchDashboard();
  }, [fetchDashboard]);

  useEffect(() => {
    const channel = supabase
      .channel('dashboard-condom-requests')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'condom_requests' },
        () => {
          fetchDashboard();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchDashboard]);

  return { ...data, loading, error };
}
