import { useState } from 'react';
import {
  Box, Typography, Card, CardContent, TextField, MenuItem, Stack,
  Chip, Alert,
} from '@mui/material';
import type { Enums } from '../../lib/database.types';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useStaffWorkload, type StaffWorkloadRow } from '../../hooks/useStaffWorkload';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function toLocalDateString(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function getDefaultDateFrom(): string {
  const d = new Date();
  d.setMonth(d.getMonth() - 1);
  return toLocalDateString(d);
}

function getDefaultDateTo(): string {
  return toLocalDateString(new Date());
}

function formatLeadTime(minutes: number | null | undefined): string {
  if (minutes === null || minutes === undefined || minutes < 0) return '—';
  const mins = Number(minutes);
  if (mins < 1) {
    const secs = Math.round(mins * 60);
    return `${secs} วินาที`;
  }
  const total = Math.round(mins);
  const h = Math.floor(total / 60);
  const m = total % 60;
  if (h === 0) return `${m} นาที`;
  return `${h} ชม. ${m} นาที`;
}

// ─── Locale ──────────────────────────────────────────────────────────────────

const thGridLocale = {
  noRowsLabel: 'ไม่มีข้อมูลในช่วงที่เลือก',
  noResultsOverlayLabel: 'ไม่พบข้อมูล',
  MuiTablePagination: {
    labelRowsPerPage: 'จำนวนต่อหน้า:',
    labelDisplayedRows: ({ from, to, count }: { from: number; to: number; count: number }) =>
      `${from} - ${to} จาก ${count !== -1 ? count : `มากกว่า ${to}`}`,
  },
};

// ─── Columns ─────────────────────────────────────────────────────────────────

const columns: GridColDef<StaffWorkloadRow>[] = [
  {
    field: 'first_name',
    headerName: 'ชื่อ',
    flex: 1,
    minWidth: 120,
  },
  {
    field: 'last_name',
    headerName: 'นามสกุล',
    flex: 1,
    minWidth: 120,
  },
  {
    field: 'completed_count',
    headerName: 'เสร็จสิ้น',
    flex: 0.8,
    minWidth: 100,
    type: 'number',
    headerAlign: 'left',
    align: 'left',
    renderCell: (params) => (
      <Chip
        label={params.value}
        size="small"
        sx={{ bgcolor: '#EBF7EC', color: '#2E7D32', fontWeight: 600, minWidth: 44 }}
      />
    ),
  },
  {
    field: 'cancelled_count',
    headerName: 'ยกเลิก',
    flex: 0.8,
    minWidth: 100,
    type: 'number',
    headerAlign: 'left',
    align: 'left',
    renderCell: (params) => (
      <Chip
        label={params.value}
        size="small"
        sx={{
          bgcolor: params.value > 0 ? '#FFF0F0' : '#F5F5F5',
          color: params.value > 0 ? '#C62828' : '#9E9E9E',
          fontWeight: 600,
          minWidth: 44,
        }}
      />
    ),
  },
  {
    field: 'overdue_count',
    headerName: 'ล่าช้า',
    flex: 0.8,
    minWidth: 100,
    type: 'number',
    headerAlign: 'left',
    align: 'left',
    renderCell: (params) => (
      <Chip
        label={params.value}
        size="small"
        sx={{
          bgcolor: params.value > 0 ? '#FFF8E1' : '#F5F5F5',
          color: params.value > 0 ? '#E65100' : '#9E9E9E',
          fontWeight: 600,
          minWidth: 44,
        }}
      />
    ),
  },
  {
    field: 'avg_lead_time_minutes',
    headerName: 'เวลาในการดำเนินการเฉลี่ย',
    flex: 1.2,
    minWidth: 160,
    type: 'number',
    headerAlign: 'left',
    align: 'left',
    renderCell: (params) => (
      <Box sx={{ display: 'flex', alignItems: 'center', height: '100%' }}>
        <Typography variant="body2" color={params.value === null ? 'text.disabled' : 'text.primary'}>
          {formatLeadTime(params.value as number | null)}
        </Typography>
      </Box>
    ),
  },
];

const SERVICE_CENTERS: Enums<'service_center'>[] = [
  'รพ.โพนพิสัย',
  'รพ.สต.วัดหลวง',
  'อบต.วัดหลวง',
  'สสจ.หนองคาย',
];

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function StaffWorkloadPage() {
  const { role, loading: roleLoading } = useRoleAccess();
  const [dateFrom, setDateFrom] = useState(getDefaultDateFrom);
  const [dateTo, setDateTo] = useState(getDefaultDateTo);
  const [serviceCenter, setServiceCenter] = useState<string>('all');
  const selectedSC = serviceCenter === 'all' ? null : serviceCenter;
  const { data, loading, error } = useStaffWorkload(dateFrom, dateTo, selectedSC);

  if (roleLoading) return null;

  if (role !== 'superadmin') {
    return (
      <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', gap: 2, color: 'text.secondary' }}>
        <LockOutlinedIcon sx={{ fontSize: 72, opacity: 0.3 }} />
        <Typography variant="h6" color="error">คุณไม่มีสิทธิ์เข้าถึงหน้านี้</Typography>
      </Box>
    );
  }

  const rowsWithId = data.map(row => ({ ...row, id: row.staff_user_id }));

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Typography variant="h5" fontWeight="bold" gutterBottom>
        ภาระงานเจ้าหน้าที่
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        สรุปจำนวนคำขอที่แต่ละคนดำเนินการในช่วงเวลาที่เลือก
      </Typography>

      {/* Filter */}
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
            <TextField
              label="สถานบริการ"
              select
              size="small"
              value={serviceCenter}
              onChange={e => setServiceCenter(e.target.value)}
              sx={{ minWidth: 180 }}
            >
              <MenuItem value="all">ทั้งหมด</MenuItem>
              {SERVICE_CENTERS.map(sc => (
                <MenuItem key={sc} value={sc}>{sc}</MenuItem>
              ))}
            </TextField>
          </Stack>
        </CardContent>
      </Card>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          เกิดข้อผิดพลาด: {error}
        </Alert>
      )}

      {/* Leaderboard Table */}
      <Card sx={{ borderRadius: 2 }} elevation={1}>
        <CardContent sx={{ p: 0, '&:last-child': { pb: 0 } }}>
          <Box sx={{ height: 500 }}>
            <DataGrid
              rows={rowsWithId}
              columns={columns}
              loading={loading}
              localeText={thGridLocale}
              initialState={{
                pagination: { paginationModel: { pageSize: 25, page: 0 } },
                sorting: { sortModel: [{ field: 'completed_count', sort: 'desc' }] },
              }}
              pageSizeOptions={[25, 50]}
              disableRowSelectionOnClick
              sx={{
                border: 'none',
                borderRadius: 2,
                '& .MuiDataGrid-columnHeaders': { bgcolor: 'grey.50' },
              }}
            />
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
}
