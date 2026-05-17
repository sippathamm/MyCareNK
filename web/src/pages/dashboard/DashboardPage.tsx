import { useState } from 'react';
import { Box, Typography, Card, CardContent, Grid, TextField, MenuItem, Stack } from '@mui/material';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, PieChart, Pie, Cell, Legend, LineChart, Line, type TooltipProps } from 'recharts';
import type { Session } from '@supabase/supabase-js';
import { useDashboard } from '../../hooks/useDashboard';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useLeadTime } from '../../hooks/useLeadTime';
import { usePeakTime } from '../../hooks/usePeakTime';
import { useServiceCenterDemand } from '../../hooks/useServiceCenterDemand';
import { useServiceCenters } from '../../hooks/useServiceCenters';

const STATUS_COLORS = {
  pending: '#FF9F6B',
  preparing: '#64B5F6',
  ready: '#BA68C8',
  completed: '#81C784',
  cancelled: '#BDBDBD',
} as const;

const LEAD_TIME_COLORS = {
  pending_to_preparing: '#64B5F6',
  preparing_to_ready: '#BA68C8',
  ready_to_completed: '#81C784',
} as const;

interface DashboardPageProps {
  session: Session;
}

const BAR_STATUS_ITEMS = [
  { key: 'pending',   name: 'รอดำเนินการ' },
  { key: 'preparing', name: 'กำลังเตรียม' },
  { key: 'ready',     name: 'รอรับ' },
  { key: 'completed', name: 'เสร็จสิ้น' },
  { key: 'cancelled', name: 'ยกเลิก' },
] as const;

const BREAKDOWN_COLORS = [
  LEAD_TIME_COLORS.pending_to_preparing,
  LEAD_TIME_COLORS.preparing_to_ready,
  LEAD_TIME_COLORS.ready_to_completed,
];

function ColoredYTick({ x, y, payload, index }: { x?: number; y?: number; payload?: { value: string }; index?: number }) {
  return (
    <text x={x} y={y} dy={4} textAnchor="end" fontSize={12} fontWeight="bold" fill={BREAKDOWN_COLORS[index ?? 0]}>
      {payload?.value}
    </text>
  );
}

function BarTooltip({ active, payload, label }: TooltipProps<number, string>) {
  if (!active || !payload?.length) return null;
  return (
    <Box sx={{ bgcolor: 'white', border: 'none', borderRadius: 2, boxShadow: '0 4px 12px rgba(0,0,0,0.1)', p: 1.5, minWidth: 140 }}>
      <Typography variant="caption" fontWeight="bold" display="block" sx={{ mb: 0.5 }}>{label}</Typography>
      {payload.map((entry) => (
        <Box key={entry.dataKey} sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.25 }}>
          <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: entry.fill }} />
          <Typography variant="caption">{entry.name}: {entry.value}</Typography>
        </Box>
      ))}
    </Box>
  );
}

function formatLeadTime(minutes: number | null | undefined): string {
  if (minutes === null || minutes === undefined || minutes < 0) return 'ไม่มีข้อมูล';
  const mins = Number(minutes);
  if (mins < 1) {
    const secs = Math.round(mins * 60);
    return `${secs} วินาที`;
  }
  const total = Math.round(mins);
  const h = Math.floor(total / 60);
  const m = total % 60;
  if (h === 0) return `${m} นาที`;
  return `${h} ชั่วโมง ${m} นาที`;
}

const SummaryCard = ({ title, value, color }: { title: string; value: string | number; color: string }) => (
  <Card sx={{ height: '100%', borderRadius: 2 }} elevation={1}>
    <CardContent>
      <Typography variant="subtitle2" color="text.secondary" fontWeight="medium" gutterBottom>
        {title}
      </Typography>
      <Typography variant="h4" fontWeight="bold" sx={{ color }}>
        {value}
      </Typography>
    </CardContent>
  </Card>
);

function toLocalDateString(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function getDefaultDateFrom(): string {
  const d = new Date();
  d.setDate(d.getDate() - 31);
  return toLocalDateString(d);
}

function getDefaultDateTo(): string {
  return toLocalDateString(new Date());
}

export default function DashboardPage({ session }: DashboardPageProps) {
  const { profile, role } = useRoleAccess();
  const displayName = profile?.first_name || session?.user?.email?.split('@')[0] || 'เจ้าหน้าที่';
  const { statusCounts, monthlyStatusCounts, weeklyData, loading } = useDashboard();

  const [dateFrom, setDateFrom] = useState(getDefaultDateFrom);
  const [dateTo, setDateTo] = useState(getDefaultDateTo);
  const [serviceCenter, setServiceCenter] = useState<string>('all');

  const isSuperadmin = role === 'superadmin';
  const { centers } = useServiceCenters(isSuperadmin);
  const selectedSC = serviceCenter === 'all' ? null : serviceCenter;

  const { current: leadTime, previous: prevLeadTime, loading: ltLoading } = useLeadTime(dateFrom, dateTo, selectedSC);
  const { hourlyData, dailyData, loading: ptLoading } = usePeakTime(dateFrom, dateTo, selectedSC);
  const { demand, trend, loading: demandLoading } = useServiceCenterDemand(dateFrom, dateTo);

  const THAI_DAYS = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];

  const hourlyChartData = hourlyData.map(d => ({
    label: `${d.bucket}:00`,
    count: d.count,
    bucket: d.bucket,
  }));

  const dailyChartData = dailyData.map(d => ({
    label: THAI_DAYS[Number(d.bucket)] ?? d.bucket,
    count: d.count,
    bucket: d.bucket,
  }));

  const peakHourBucket = hourlyData.length
    ? hourlyData.reduce((m, d) => (d.count > m.count ? d : m)).bucket
    : null;

  const peakDayBucket = dailyData.length
    ? dailyData.reduce((m, d) => (d.count > m.count ? d : m)).bucket
    : null;

  const statusData = [
    { name: 'รอดำเนินการ', value: monthlyStatusCounts.pending, color: STATUS_COLORS.pending },
    { name: 'กำลังเตรียม', value: monthlyStatusCounts.preparing, color: STATUS_COLORS.preparing },
    { name: 'รอรับ', value: monthlyStatusCounts.ready, color: STATUS_COLORS.ready },
    { name: 'เสร็จสิ้น', value: monthlyStatusCounts.completed, color: STATUS_COLORS.completed },
    { name: 'ยกเลิก', value: monthlyStatusCounts.cancelled, color: STATUS_COLORS.cancelled },
  ];

  const overallCurrent = leadTime.overall_avg_minutes;
  const overallPrevious = prevLeadTime.overall_avg_minutes;
  const hasComparison = overallCurrent !== null && overallPrevious !== null;
  const improved = hasComparison && overallCurrent <= overallPrevious;
  const diffMinutes = hasComparison ? Math.abs(overallCurrent - overallPrevious) : null;

  const breakdownData = [
    { name: 'รอดำเนินการ → กำลังเตรียม', minutes: leadTime.pending_to_preparing, fill: LEAD_TIME_COLORS.pending_to_preparing },
    { name: 'กำลังเตรียม → รอรับ', minutes: leadTime.preparing_to_ready, fill: LEAD_TIME_COLORS.preparing_to_ready },
    { name: 'รอรับ → เสร็จสิ้น', minutes: leadTime.ready_to_completed, fill: LEAD_TIME_COLORS.ready_to_completed },
  ];

  const hasBreakdownData = breakdownData.some(d => d.minutes !== null);

  function LeadTimeBarTooltip({ active, payload }: TooltipProps<number, string>) {
    if (!active || !payload?.length) return null;
    return (
      <Box sx={{ bgcolor: 'white', borderRadius: 2, boxShadow: '0 4px 12px rgba(0,0,0,0.1)', p: 1.5 }}>
        <Typography variant="caption" fontWeight="bold" display="block" sx={{ mb: 0.5 }}>
          {payload[0]?.payload?.name}
        </Typography>
        <Typography variant="caption">{formatLeadTime(payload[0]?.value as number)}</Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Typography variant="h5" fontWeight="bold" gutterBottom>
        ยินดีต้อนรับคุณ {displayName}
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        ข้อมูลสรุป
      </Typography>

      {/* Summary Cards: 5 columns on desktop */}
      <Grid container spacing={2} columns={10} sx={{ mb: 4 }}>
        <Grid size={{ xs: 10, sm: 5, md: 2 }}>
          <SummaryCard title="รอดำเนินการ" value={loading ? '-' : statusCounts.pending} color={STATUS_COLORS.pending} />
        </Grid>
        <Grid size={{ xs: 10, sm: 5, md: 2 }}>
          <SummaryCard title="กำลังเตรียม" value={loading ? '-' : statusCounts.preparing} color={STATUS_COLORS.preparing} />
        </Grid>
        <Grid size={{ xs: 10, sm: 5, md: 2 }}>
          <SummaryCard title="รอรับ" value={loading ? '-' : statusCounts.ready} color={STATUS_COLORS.ready} />
        </Grid>
        <Grid size={{ xs: 10, sm: 5, md: 2 }}>
          <SummaryCard title="เสร็จสิ้น" value={loading ? '-' : statusCounts.completed} color={STATUS_COLORS.completed} />
        </Grid>
        <Grid size={{ xs: 10, sm: 5, md: 2 }}>
          <SummaryCard title="ยกเลิก" value={loading ? '-' : statusCounts.cancelled} color={STATUS_COLORS.cancelled} />
        </Grid>
      </Grid>

      {/* Charts */}
      <Grid container spacing={3} columns={12} sx={{ mb: 3 }}>
        {/* Bar Chart - Weekly Trend */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Card sx={{ borderRadius: 2, height: 420 }} elevation={1}>
            <CardContent sx={{ height: '100%' }}>
              <Typography variant="h6" fontWeight="bold" sx={{ mb: 2 }}>
                คำขอย้อนหลัง 7 วัน
              </Typography>
              <ResponsiveContainer width="100%" height="85%">
                <BarChart data={weeklyData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="date" tickLine={false} axisLine={false} />
                  <YAxis tickLine={false} axisLine={false} allowDecimals={false} />
                  <Tooltip cursor={{ fill: 'rgba(0,0,0,0.05)' }} content={<BarTooltip />} />
                  <Legend wrapperStyle={{ fontSize: '12px', paddingTop: '8px' }} iconType="circle" />
                  {BAR_STATUS_ITEMS.map(({ key, name }, idx) => (
                    <Bar
                      key={key}
                      name={name}
                      dataKey={key}
                      fill={STATUS_COLORS[key]}
                      stackId="a"
                      radius={idx === BAR_STATUS_ITEMS.length - 1 ? [4, 4, 0, 0] : [0, 0, 0, 0]}
                    />
                  ))}
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </Grid>

        {/* Pie Chart - Status Distribution */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Card sx={{ borderRadius: 2, height: 420 }} elevation={1}>
            <CardContent sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
              <Typography variant="h6" fontWeight="bold" sx={{ mb: 2 }}>
                สัดส่วนสถานะคำขอในเดือนนี้
              </Typography>
              <ResponsiveContainer width="100%" height="85%">
                <PieChart>
                  <Pie
                    data={statusData}
                    cx="50%"
                    cy="45%"
                    innerRadius={50}
                    outerRadius={90}
                    paddingAngle={3}
                    dataKey="value"
                  >
                    {statusData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip
                    contentStyle={{ borderRadius: 8, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
                  />
                  <Legend
                    layout="horizontal"
                    verticalAlign="bottom"
                    align="center"
                    height={72}
                    iconType="circle"
                    wrapperStyle={{ fontSize: '13px', paddingTop: '10px' }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {(role === 'admin' || role === 'superadmin') && (
      <>
      {/* ── Analysis Section ─────────────────────────────────────── */}
      <Typography variant="h6" fontWeight="bold" sx={{ mt: 4, mb: 1.5 }}>
        การวิเคราะห์คำขอ
      </Typography>

      {/* Shared Filter Card */}
      <Card sx={{ borderRadius: 2, mb: 3 }} elevation={1}>
        <CardContent>
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems={{ xs: 'stretch', sm: 'center' }}>
            <TextField
              label="ตั้งแต่วันที่"
              type="date"
              size="small"
              value={dateFrom}
              onChange={e => setDateFrom(e.target.value)}
              slotProps={{ inputLabel: { shrink: true } }}
              sx={{ minWidth: 160 }}
            />
            <TextField
              label="ถึงวันที่"
              type="date"
              size="small"
              value={dateTo}
              onChange={e => setDateTo(e.target.value)}
              slotProps={{ inputLabel: { shrink: true } }}
              sx={{ minWidth: 160 }}
            />
            {isSuperadmin && (
              <TextField
                label="สถานบริการ"
                select
                size="small"
                value={serviceCenter}
                onChange={e => setServiceCenter(e.target.value)}
                sx={{ minWidth: 180 }}
              >
                <MenuItem value="all">ทั้งหมด</MenuItem>
                {centers.map(c => (
                  <MenuItem key={c.name} value={c.name}>{c.name}</MenuItem>
                ))}
              </TextField>
            )}
          </Stack>
        </CardContent>
      </Card>

      {/* Row 1: Lead Time cards */}
      <Grid container spacing={3} columns={12} sx={{ mb: 3 }}>
        {/* Lead Time Summary */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Card sx={{ borderRadius: 2, height: '100%' }} elevation={1}>
            <CardContent sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
              <Typography variant="h6" fontWeight="bold" sx={{ mb: 2 }}>
                เวลาเฉลี่ยในการดำเนินการ
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 0.5 }}>
                <Typography variant="caption" fontWeight="bold" sx={{ color: STATUS_COLORS.pending }}>รอดำเนินการ</Typography>
                <Typography variant="caption" color="text.secondary">→</Typography>
                <Typography variant="caption" fontWeight="bold" sx={{ color: STATUS_COLORS.completed }}>สำเร็จ</Typography>
              </Box>
              <Typography variant="h4" fontWeight="bold" sx={{ color: overallCurrent === null && !ltLoading ? '#9E9E9E' : STATUS_COLORS.completed }}>
                {ltLoading ? '-' : formatLeadTime(overallCurrent)}
              </Typography>
              {!ltLoading && hasComparison && (
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 1 }}>
                  <Typography
                    variant="body2"
                    fontWeight="medium"
                    sx={{ color: improved ? STATUS_COLORS.completed : '#f44336' }}
                  >
                    {improved ? '↓' : '↑'} {formatLeadTime(diffMinutes)}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {improved ? 'ดีขึ้น' : 'นานขึ้น'}จากช่วงก่อนหน้า
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Lead Time Breakdown Bar Chart */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Card sx={{ borderRadius: 2, height: '100%', minHeight: 220 }} elevation={1}>
            <CardContent sx={{ height: '100%' }}>
              <Typography variant="h6" fontWeight="bold" sx={{ mb: 2 }}>
                เวลาแต่ละสถานะ
              </Typography>
              {ltLoading ? (
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '80%' }}>
                  <Typography variant="body2" color="text.secondary">กำลังโหลด...</Typography>
                </Box>
              ) : !hasBreakdownData ? (
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '80%' }}>
                  <Typography variant="body2" color="text.secondary">ไม่มีข้อมูลในช่วงที่เลือก</Typography>
                </Box>
              ) : (
                <ResponsiveContainer width="100%" height="80%">
                  <BarChart
                    layout="vertical"
                    data={breakdownData}
                    margin={{ top: 4, right: 120, left: 8, bottom: 4 }}
                  >
                    <CartesianGrid strokeDasharray="3 3" horizontal={false} />
                    <XAxis type="number" tickLine={false} axisLine={false} allowDecimals={false} unit=" นาที" />
                    <YAxis type="category" dataKey="name" tickLine={false} axisLine={false} width={180} tick={<ColoredYTick />} />
                    <Tooltip content={<LeadTimeBarTooltip />} cursor={{ fill: 'rgba(0,0,0,0.05)' }} />
                    <Bar dataKey="minutes" radius={[0, 4, 4, 0]} minPointSize={4} label={{ position: 'right', fontSize: 11, fill: '#666', formatter: (v: number) => formatLeadTime(v) }}>
                      {breakdownData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.fill} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Row 2: Peak Time Charts */}
      <Grid container spacing={3} columns={12}>
        {/* Hourly Chart */}
        <Grid size={{ xs: 12, md: 8 }}>
          <Card sx={{ borderRadius: 2, height: 320 }} elevation={1}>
            <CardContent sx={{ height: '100%' }}>
              <Typography variant="h6" fontWeight="bold" sx={{ mb: 2 }}>
                เวลาที่มีคำขอมากที่สุด
              </Typography>
              {ptLoading ? (
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '75%' }}>
                  <Typography variant="body2" color="text.secondary">กำลังโหลด...</Typography>
                </Box>
              ) : hourlyChartData.every(d => d.count === 0) ? (
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '75%' }}>
                  <Typography variant="body2" color="text.secondary">ไม่มีข้อมูลในช่วงที่เลือก</Typography>
                </Box>
              ) : (
                <ResponsiveContainer width="100%" height="85%">
                  <BarChart data={hourlyChartData} margin={{ top: 4, right: 8, left: -20, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                    <XAxis dataKey="label" tickLine={false} axisLine={false} tick={{ fontSize: 11 }} interval={1} />
                    <YAxis tickLine={false} axisLine={false} allowDecimals={false} />
                    <Tooltip
                      cursor={{ fill: 'rgba(0,0,0,0.05)' }}
                      content={({ active, payload }) => {
                        if (!active || !payload?.length) return null;
                        const d = payload[0].payload;
                        const h = d.bucket;
                        const hNext = String(Number(h) + 1).padStart(2, '0');
                        return (
                          <Box sx={{ bgcolor: 'white', borderRadius: 2, boxShadow: '0 4px 12px rgba(0,0,0,0.1)', p: 1.5 }}>
                            <Typography variant="caption" fontWeight="bold" display="block" sx={{ mb: 0.5 }}>
                              {h}:00 น. – {hNext}:00 น.
                            </Typography>
                            <Typography variant="caption">{d.count} คำขอ</Typography>
                          </Box>
                        );
                      }}
                    />
                    <Bar dataKey="count" radius={[4, 4, 0, 0]}>
                      {hourlyChartData.map((entry) => (
                        <Cell
                          key={entry.bucket}
                          fill={entry.bucket === peakHourBucket ? '#FF9F6B' : '#64B5F6'}
                        />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Day-of-week Chart */}
        <Grid size={{ xs: 12, md: 4 }}>
          <Card sx={{ borderRadius: 2, height: 320 }} elevation={1}>
            <CardContent sx={{ height: '100%' }}>
              <Typography variant="h6" fontWeight="bold" sx={{ mb: 2 }}>
                วันที่มีคำขอมากที่สุด
              </Typography>
              {ptLoading ? (
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '75%' }}>
                  <Typography variant="body2" color="text.secondary">กำลังโหลด...</Typography>
                </Box>
              ) : dailyChartData.every(d => d.count === 0) ? (
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '75%' }}>
                  <Typography variant="body2" color="text.secondary">ไม่มีข้อมูลในช่วงที่เลือก</Typography>
                </Box>
              ) : (
                <ResponsiveContainer width="100%" height="85%">
                  <BarChart data={dailyChartData} margin={{ top: 4, right: 8, left: -20, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                    <XAxis dataKey="label" tickLine={false} axisLine={false} tick={{ fontSize: 12 }} />
                    <YAxis tickLine={false} axisLine={false} allowDecimals={false} />
                    <Tooltip
                      cursor={{ fill: 'rgba(0,0,0,0.05)' }}
                      content={({ active, payload }) => {
                        if (!active || !payload?.length) return null;
                        const d = payload[0].payload;
                        return (
                          <Box sx={{ bgcolor: 'white', borderRadius: 2, boxShadow: '0 4px 12px rgba(0,0,0,0.1)', p: 1.5 }}>
                            <Typography variant="caption" fontWeight="bold" display="block" sx={{ mb: 0.5 }}>
                              {d.label}
                            </Typography>
                            <Typography variant="caption">{d.count} คำขอ</Typography>
                          </Box>
                        );
                      }}
                    />
                    <Bar dataKey="count" radius={[4, 4, 0, 0]}>
                      {dailyChartData.map((entry) => (
                        <Cell
                          key={entry.bucket}
                          fill={entry.bucket === peakDayBucket ? '#FF9F6B' : '#81C784'}
                        />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Row 3: Service Center Demand Ranking */}
      <Card sx={{ borderRadius: 2, mt: 3 }} elevation={1}>
        <CardContent>
          <Typography variant="h6" fontWeight="bold" sx={{ mb: 2 }}>
            อันดับความต้องการตามสถานบริการ
          </Typography>
          {demandLoading ? (
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 80 }}>
              <Typography variant="body2" color="text.secondary">กำลังโหลด...</Typography>
            </Box>
          ) : (
            <Box sx={{ overflowX: 'auto' }}>
              <Box component="table" sx={{ width: '100%', borderCollapse: 'collapse' }}>
                <Box component="thead">
                  <Box component="tr">
                    {['อันดับ', 'สถานบริการ', 'คำขอทั้งหมด', 'ถุงยางอนามัย', 'เจลหล่อลื่น', 'สัดส่วน', 'แนวโน้ม 30 วัน'].map(h => (
                      <Box component="th" key={h} sx={{ textAlign: 'left', pb: 1.5, pr: 2, fontSize: 12, color: 'text.secondary', fontWeight: 'medium', whiteSpace: 'nowrap' }}>
                        {h}
                      </Box>
                    ))}
                  </Box>
                </Box>
                <Box component="tbody">
                  {demand.map((row, idx) => {
                    const RANK_COLORS = ['#FF9F6B', '#64B5F6', '#BA68C8', '#81C784'];
                    const totalRequests = demand.reduce((sum, d) => sum + d.total_requests, 0);
                    const barPct = totalRequests > 0 ? (row.total_requests / totalRequests) * 100 : 0;
                    const sparkData = trend
                      .filter(t => t.service_center === row.service_center)
                      .map(t => ({ v: t.request_count }));
                    return (
                      <Box component="tr" key={row.service_center} sx={{ borderTop: '1px solid', borderColor: 'divider' }}>
                        <Box component="td" sx={{ py: 1.5, pr: 2, width: 40 }}>
                          <Box sx={{
                            width: 28, height: 28, borderRadius: '50%',
                            bgcolor: RANK_COLORS[idx] ?? '#BDBDBD',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                          }}>
                            <Typography variant="caption" fontWeight="bold" sx={{ color: '#fff', lineHeight: 1 }}>
                              {idx + 1}
                            </Typography>
                          </Box>
                        </Box>
                        <Box component="td" sx={{ py: 1.5, pr: 3, whiteSpace: 'nowrap' }}>
                          <Typography variant="body2" fontWeight="medium">{row.service_center}</Typography>
                        </Box>
                        <Box component="td" sx={{ py: 1.5, pr: 3, whiteSpace: 'nowrap' }}>
                          <Typography variant="body2" fontWeight="bold" sx={{ color: RANK_COLORS[idx] ?? '#BDBDBD' }}>
                            {row.total_requests.toLocaleString()}
                          </Typography>
                        </Box>
                        <Box component="td" sx={{ py: 1.5, pr: 3, whiteSpace: 'nowrap' }}>
                          <Typography variant="body2" color="text.secondary">{row.total_condoms.toLocaleString()}</Typography>
                        </Box>
                        <Box component="td" sx={{ py: 1.5, pr: 3, whiteSpace: 'nowrap' }}>
                          <Typography variant="body2" color="text.secondary">{row.total_lubricants.toLocaleString()}</Typography>
                        </Box>
                        <Box component="td" sx={{ py: 1.5, pr: 3, minWidth: 200 }}>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Box sx={{ flex: 1, bgcolor: 'grey.100', borderRadius: 1, height: 8, overflow: 'hidden' }}>
                              <Box sx={{ width: `${barPct}%`, height: '100%', bgcolor: RANK_COLORS[idx] ?? '#BDBDBD', borderRadius: 1, transition: 'width 0.4s ease' }} />
                            </Box>
                            <Typography variant="caption" color="text.secondary" sx={{ minWidth: 36, textAlign: 'right' }}>
                              {barPct.toFixed(0)}%
                            </Typography>
                          </Box>
                        </Box>
                        <Box component="td" sx={{ py: 1.5, width: 120 }}>
                          {sparkData.length > 0 ? (
                            <ResponsiveContainer width={120} height={36}>
                              <LineChart data={sparkData} margin={{ top: 2, right: 2, left: 2, bottom: 2 }}>
                                <Line type="monotone" dataKey="v" stroke={RANK_COLORS[idx] ?? '#BDBDBD'} dot={false} strokeWidth={1.5} />
                              </LineChart>
                            </ResponsiveContainer>
                          ) : (
                            <Typography variant="caption" color="text.secondary">—</Typography>
                          )}
                        </Box>
                      </Box>
                    );
                  })}
                </Box>
              </Box>
            </Box>
          )}
        </CardContent>
      </Card>
      </>
      )}
    </Box>
  );
}
