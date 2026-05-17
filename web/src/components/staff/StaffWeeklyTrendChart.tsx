import { useMemo } from 'react';
import { Box, Typography, CircularProgress } from '@mui/material';
import {
  ResponsiveContainer, LineChart, Line, XAxis, YAxis,
  CartesianGrid, Tooltip,
} from 'recharts';
import type { WorkloadTrendRow } from '../../hooks/useStaffWorkloadTrend';

const LINE_COLOR = '#66BB6A';
const DATA_KEY   = 'จำนวนคำขอ';

interface Props {
  data:    WorkloadTrendRow[];
  loading: boolean;
  error?:  string | null;
}

function formatWeek(isoDate: string): string {
  const d = new Date(isoDate);
  const day = String(d.getDate()).padStart(2, '0');
  const mon = String(d.getMonth() + 1).padStart(2, '0');
  return `${day}/${mon}`;
}

export default function StaffWeeklyTrendChart({ data, loading, error }: Props) {
  // Pivot data: [{ week, จำนวนคำขอ: count }]
  const chartData = useMemo(() => {
    const byWeek = new Map<string, number>();
    for (const row of data) {
      const week = row.week_start.slice(0, 10);
      byWeek.set(week, (byWeek.get(week) ?? 0) + row.completed_count);
    }
    return [...byWeek.entries()]
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([week, count]) => ({ week, [DATA_KEY]: count }));
  }, [data]);

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 220 }}>
        <CircularProgress size={32} />
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 220 }}>
        <Typography variant="body2" color="error.main">{error}</Typography>
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
        <Line
          type="monotone"
          dataKey={DATA_KEY}
          stroke={LINE_COLOR}
          strokeWidth={2}
          dot={{ r: 3 }}
          activeDot={{ r: 5 }}
          connectNulls
        />
      </LineChart>
    </ResponsiveContainer>
  );
}
