import { useMemo } from 'react';
import { Box, Card, CardContent, Typography, Skeleton } from '@mui/material';
import {
  ResponsiveContainer, LineChart, Line, XAxis, YAxis,
  CartesianGrid, Tooltip, Legend,
} from 'recharts';
import type { ConsumptionTrendPoint } from '../../hooks/useInventoryForecast';
import { getServiceCenterColor } from '../../lib/serviceCenterColor';
import { useColorMode } from '../../contexts/ThemeContext';

interface ConsumptionTrendChartProps {
  trend: ConsumptionTrendPoint[];
  loading: boolean;
}

type ProductType = 'condom' | 'lubricant';

function buildChartData(
  trend: ConsumptionTrendPoint[],
  product: ProductType,
): Record<string, unknown>[] {
  const days = [...new Set(trend.map((t) => t.day))].sort();
  const centers = [...new Set(trend.map((t) => t.service_center))] as string[];

  return days.map((day) => {
    const entry: Record<string, unknown> = {
      day: day.slice(5), // MM-DD
    };
    centers.forEach((center) => {
      const point = trend.find((t) => t.day === day && t.service_center === center);
      entry[center] = product === 'condom'
        ? (point?.condom_used ?? 0)
        : (point?.lubricant_used ?? 0);
    });
    return entry;
  });
}

function TrendPanel({
  title,
  data,
  centers,
}: {
  title: string;
  data: Record<string, unknown>[];
  centers: string[];
}) {
  const { mode } = useColorMode();
  const tick       = mode === 'dark' ? '#A0AEC0' : '#666666';
  const grid       = mode === 'dark' ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)';
  const tooltipBg  = mode === 'dark' ? '#1E2433' : '#ffffff';
  const tooltipBorder = mode === 'dark' ? '#2D3748' : '#e0e0e0';
  const tooltipText = mode === 'dark' ? '#E2E8F0' : '#000000';

  return (
    <Box>
      <Typography variant="subtitle2" fontWeight={600} color="text.secondary" mb={1}>
        {title}
      </Typography>
      <Box sx={{ height: 320, '& .recharts-wrapper': { overflow: 'visible' } }}>
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data} margin={{ top: 4, right: 16, left: 0, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={grid} />
            <XAxis
              dataKey="day"
              tick={{ fontSize: 11, fill: tick }}
              interval={4}
              tickLine={false}
            />
            <YAxis
              allowDecimals={false}
              tick={{ fontSize: 11, fill: tick }}
              tickLine={false}
              axisLine={false}
              width={32}
            />
            <Tooltip
              cursor={{ stroke: mode === 'dark' ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.08)', strokeWidth: 2 }}
              contentStyle={{ borderRadius: 8, fontSize: 12, background: tooltipBg, border: `1px solid ${tooltipBorder}`, color: tooltipText }}
            />
            <Legend
              wrapperStyle={{ fontSize: 12, paddingTop: 8, color: tick }}
              iconType="circle"
              iconSize={8}
            />
            {centers.map((center) => (
              <Line
                key={center}
                type="monotone"
                dataKey={center}
                stroke={getServiceCenterColor(center)}
                strokeWidth={2}
                dot={false}
                activeDot={{ r: 4 }}
              />
            ))}
          </LineChart>
        </ResponsiveContainer>
      </Box>
    </Box>
  );
}

export default function ConsumptionTrendChart({ trend, loading }: ConsumptionTrendChartProps) {
  const centers = useMemo(
    () => [...new Set(trend.map((t) => t.service_center))] as string[],
    [trend],
  );

  const condomData = useMemo(() => buildChartData(trend, 'condom'), [trend]);
  const lubricantData = useMemo(() => buildChartData(trend, 'lubricant'), [trend]);

  return (
    <Card elevation={1} sx={{ borderRadius: 2, overflow: 'visible' }}>
      <CardContent sx={{ p: 2.5 }}>
        <Typography variant="h6" fontWeight="bold" sx={{ mb: 2 }}>
          อัตราการใช้ 30 วันย้อนหลัง
        </Typography>

        {loading ? (
          <Skeleton variant="rounded" height={320} />
        ) : trend.length === 0 ? (
          <Box sx={{ height: 320, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Typography color="text.secondary" variant="body2">
              ไม่มีข้อมูลการใช้ในช่วง 30 วันที่ผ่านมา
            </Typography>
          </Box>
        ) : (
          <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 3 }}>
            <Box sx={{ flex: 1 }}>
              <TrendPanel title="ถุงยางอนามัย (ชิ้น/วัน)" data={condomData} centers={centers} />
            </Box>
            <Box sx={{ flex: 1 }}>
              <TrendPanel title="เจลหล่อลื่น (ชิ้น/วัน)" data={lubricantData} centers={centers} />
            </Box>
          </Box>
        )}
      </CardContent>
    </Card>
  );
}
