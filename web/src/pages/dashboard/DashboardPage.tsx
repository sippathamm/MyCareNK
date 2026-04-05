import { Box, Typography, Card, CardContent, Grid } from '@mui/material';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, PieChart, Pie, Cell, Legend } from 'recharts';
import type { Session } from '@supabase/supabase-js';

// Mock Data
const weeklyData = [
  { date: '1 เม.ย.', requests: 12 },
  { date: '2 เม.ย.', requests: 19 },
  { date: '3 เม.ย.', requests: 15 },
  { date: '4 เม.ย.', requests: 22 },
  { date: '5 เม.ย.', requests: 30 },
  { date: '6 เม.ย.', requests: 25 },
  { date: '7 เม.ย.', requests: 18 },
];

const statusData = [
  { name: 'รอดำเนินการ', value: 15, color: '#FF9800' }, // Orange
  { name: 'กำลังเตรียม', value: 8, color: '#2196F3' }, // Blue
  { name: 'รอรับ', value: 12, color: '#9C27B0' }, // Purple
  { name: 'เสร็จสิ้น', value: 45, color: '#4CAF50' }, // Green
  { name: 'ยกเลิก', value: 5, color: '#9E9E9E' }, // Grey
];

interface DashboardPageProps {
  session: Session;
  loading?: boolean;
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

export default function DashboardPage({ session }: DashboardPageProps) {
  const emailName = session?.user?.email?.split('@')[0] || 'เจ้าหน้าที่';

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Typography variant="h5" fontWeight="bold" gutterBottom>
        ยินดีต้อนรับคุณ {emailName}
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        ข้อมูลสรุป
      </Typography>

      {/* Summary Cards: 5 columns on desktop */}
      <Grid container spacing={2} columns={10} sx={{ mb: 4 }}>
        <Grid size={{ xs: 10, sm: 5, md: 2 }}>
          <SummaryCard title="รอดำเนินการ" value={15} color="#FF9800" />
        </Grid>
        <Grid size={{ xs: 10, sm: 5, md: 2 }}>
          <SummaryCard title="กำลังเตรียม" value={8} color="#2196F3" />
        </Grid>
        <Grid size={{ xs: 10, sm: 5, md: 2 }}>
          <SummaryCard title="รอรับ" value={12} color="#9C27B0" />
        </Grid>
        <Grid size={{ xs: 10, sm: 5, md: 2 }}>
          <SummaryCard title="เสร็จสิ้น" value={45} color="#4CAF50" />
        </Grid>
        <Grid size={{ xs: 10, sm: 5, md: 2 }}>
          <SummaryCard title="ยกเลิก" value={5} color="#9E9E9E" />
        </Grid>
      </Grid>

      {/* Charts */}
      <Grid container spacing={3} columns={12}>
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
                  <YAxis tickLine={false} axisLine={false} />
                  <Tooltip
                    cursor={{ fill: 'rgba(0,0,0,0.05)' }}
                    contentStyle={{ borderRadius: 8, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
                  />
                  <Bar name="คำขอ" dataKey="requests" fill="#FF8A50" radius={[4, 4, 0, 0]} />
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
                สัดส่วนสถานะคำขอ
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
    </Box>
  );
}
