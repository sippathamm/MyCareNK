import { useMemo } from 'react';
import { Box, Typography, CircularProgress } from '@mui/material';
import {
  ResponsiveContainer, LineChart, Line, XAxis, YAxis,
  CartesianGrid, Tooltip, Legend,
} from 'recharts';
import type { WorkloadTrendRow } from '../../hooks/useStaffWorkloadTrend';

const LINE_COLORS = ['#FF9F6B', '#64B5F6', '#81C784', '#BA68C8', '#EF7070'];
const MAX_LINES   = 5;

interface Props {
  data:    WorkloadTrendRow[];
  loading: boolean;
}

function formatWeek(isoDate: string): string {
  const d = new Date(isoDate);
  const day = String(d.getDate()).padStart(2, '0');
  const mon = String(d.getMonth() + 1).padStart(2, '0');
  return `${day}/${mon}`;
}

export default function StaffWeeklyTrendChart({ data, loading }: Props) {
  // Pick top MAX_LINES staff by total completed in the period
  const topStaff = useMemo(() => {
    const totals = new Map<string, { name: string; total: number }>();
    for (const row of data) {
      const key  = row.staff_user_id;
      const name = `${row.first_name} ${row.last_name}`;
      const prev = totals.get(key);
      totals.set(key, { name, total: (prev?.total ?? 0) + row.completed_count });
    }
    return [...totals.entries()]
      .sort((a, b) => b[1].total - a[1].total)
      .slice(0, MAX_LINES)
      .map(([id, { name }]) => ({ id, name }));
  }, [data]);

  // Pivot data: [{ week_start, [staffName]: count, ... }]
  const chartData = useMemo(() => {
    const topIds = new Set(topStaff.map(s => s.id));
    const byWeek = new Map<string, Record<string, number>>();

    for (const row of data) {
      if (!topIds.has(row.staff_user_id)) continue;
      const name = `${row.first_name} ${row.last_name}`;
      const week = row.week_start.slice(0, 10); // 'YYYY-MM-DD'
      const entry = byWeek.get(week) ?? {};
      entry[name] = row.completed_count;
      byWeek.set(week, entry);
    }

    return [...byWeek.entries()]
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([week, counts]) => ({ week, ...counts }));
  }, [data, topStaff]);

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 220 }}>
        <CircularProgress size={32} />
      </Box>
    );
  }

  if (chartData.length === 0) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 220 }}>
        <Typography variant="body2" color="text.disabled">ไม่มีข้อมูลในช่วงที่เลือก</Typography>
      </Box>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={220}>
      <LineChart data={chartData} margin={{ top: 4, right: 16, left: -8, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#F0F0F0" />
        <XAxis
          dataKey="week"
          tickFormatter={formatWeek}
          tick={{ fontSize: 11 }}
          tickLine={false}
        />
        <YAxis
          allowDecimals={false}
          tick={{ fontSize: 11 }}
          tickLine={false}
          axisLine={false}
        />
        <Tooltip
          formatter={(value: number, name: string) => [value, name]}
          labelFormatter={(label: string) => `สัปดาห์ ${formatWeek(label)}`}
          contentStyle={{ fontSize: 12, borderRadius: 8 }}
        />
        <Legend wrapperStyle={{ fontSize: 12 }} />
        {topStaff.map((staff, i) => (
          <Line
            key={staff.id}
            type="monotone"
            dataKey={staff.name}
            stroke={LINE_COLORS[i % LINE_COLORS.length]}
            strokeWidth={2}
            dot={{ r: 3 }}
            activeDot={{ r: 5 }}
            connectNulls
          />
        ))}
      </LineChart>
    </ResponsiveContainer>
  );
}
