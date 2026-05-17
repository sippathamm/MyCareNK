import { useState, useMemo } from 'react';
import {
  Box, Typography, Paper, TextField, MenuItem, Stack,
  Chip, Alert, Switch, FormControlLabel, Divider, IconButton, Tooltip,
} from '@mui/material';
import VisibilityIcon from '@mui/icons-material/Visibility';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useStaffWorkload, type EnrichedRow } from '../../hooks/useStaffWorkload';
import StaffWorkloadDetailDialog from '../../components/staff/StaffWorkloadDetailDialog';
import { toLocalDateString } from '../../utils/staffWorkloadUtils';
import { createThGridLocale } from '../../constants/datagrid';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function getDefaultDateFrom(): string {
  const d = new Date();
  d.setDate(d.getDate() - 31);
  return toLocalDateString(d);
}

function getDefaultDateTo(): string {
  return toLocalDateString(new Date());
}

// ─── Delta Chip ───────────────────────────────────────────────────────────────

function DeltaChip({ delta, positiveIsGood = true }: { delta: number | null; positiveIsGood?: boolean }) {
  if (delta === null) return null;
  const isGood = positiveIsGood ? delta > 0 : delta < 0;
  const color = delta === 0 ? '#9E9E9E' : isGood ? '#2E7D32' : '#C62828';
  return (
    <Typography variant="caption" sx={{ fontSize: '0.7rem', fontWeight: 700, color, lineHeight: 1 }}>
      {delta > 0 ? `+${delta}` : delta < 0 ? `${delta}` : '±0'}
    </Typography>
  );
}

// ─── Locale ──────────────────────────────────────────────────────────────────

const thGridLocale = createThGridLocale('ไม่มีข้อมูลในช่วงที่เลือก');

// ─── Constants ────────────────────────────────────────────────────────────────

const SERVICE_CENTERS: string[] = [
  'รพ.โพนพิสัย',
  'รพ.สต.วัดหลวง',
  'อบต.วัดหลวง',
  'สสจ.หนองคาย',
];

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function StaffWorkloadPage() {
  const { role, loading: roleLoading } = useRoleAccess();

  // Main filter
  const [dateFrom, setDateFrom] = useState(getDefaultDateFrom);
  const [dateTo, setDateTo] = useState(getDefaultDateTo);
  const [serviceCenter, setServiceCenter] = useState<string>('all');

  // Comparison
  const [compareEnabled, setCompareEnabled] = useState(false);
  const [compareDateFrom, setCompareDateFrom] = useState('');
  const [compareDateTo, setCompareDateTo] = useState('');

  // Detail dialog
  const [detailRow, setDetailRow] = useState<EnrichedRow | null>(null);

  const selectedSC = serviceCenter === 'all' ? null : serviceCenter;

  const { data, compareData, loading, error } = useStaffWorkload(
    dateFrom, dateTo, selectedSC,
    compareEnabled ? compareDateFrom : null,
    compareEnabled ? compareDateTo : null,
  );

  // Enrich rows with delta
  const enrichedRows = useMemo<EnrichedRow[]>(() => {
    const map = new Map(compareData.map(r => [r.staff_user_id, r]));
    return data.map(row => {
      const cmp = compareEnabled ? map.get(row.staff_user_id) : undefined;
      return {
        ...row,
        id: row.staff_user_id,
        delta_completed: cmp != null ? row.completed_count - cmp.completed_count : null,
        delta_cancelled: cmp != null ? row.cancelled_count - cmp.cancelled_count : null,
        delta_overdue:   cmp != null ? row.overdue_count   - cmp.overdue_count   : null,
      };
    });
  }, [data, compareData, compareEnabled]);

  // Columns (inside component to capture compareEnabled + setDetailRow)
  const columns = useMemo<GridColDef<EnrichedRow>[]>(() => [
    { field: 'first_name', headerName: 'ชื่อ', flex: 1, minWidth: 120 },
    { field: 'last_name',  headerName: 'นามสกุล', flex: 1, minWidth: 120 },
    {
      field: 'completed_count',
      headerName: 'เสร็จสิ้น',
      flex: 0.8, minWidth: 100, type: 'number', headerAlign: 'left', align: 'left',
      renderCell: (params) => (
        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', justifyContent: 'center', height: '100%', gap: 0.3 }}>
          <Chip label={params.value} size="small" sx={{ bgcolor: params.value > 0 ? '#EBF7EC' : '#F5F5F5', color: params.value > 0 ? '#2E7D32' : '#9E9E9E', fontWeight: 600 }} />
          {compareEnabled && <DeltaChip delta={params.row.delta_completed} positiveIsGood />}
        </Box>
      ),
    },
    {
      field: 'cancelled_count',
      headerName: 'ยกเลิก',
      flex: 0.8, minWidth: 100, type: 'number', headerAlign: 'left', align: 'left',
      renderCell: (params) => (
        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', justifyContent: 'center', height: '100%', gap: 0.3 }}>
          <Chip label={params.value} size="small" sx={{ bgcolor: params.value > 0 ? '#FFF0F0' : '#F5F5F5', color: params.value > 0 ? '#C62828' : '#9E9E9E', fontWeight: 600 }} />
          {compareEnabled && <DeltaChip delta={params.row.delta_cancelled} positiveIsGood={false} />}
        </Box>
      ),
    },
    {
      field: 'overdue_count',
      headerName: 'ล่าช้า',
      flex: 0.8, minWidth: 100, type: 'number', headerAlign: 'left', align: 'left',
      renderCell: (params) => (
        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', justifyContent: 'center', height: '100%', gap: 0.3 }}>
          <Chip label={params.value} size="small" sx={{ bgcolor: params.value > 0 ? '#FFF8E1' : '#F5F5F5', color: params.value > 0 ? '#E65100' : '#9E9E9E', fontWeight: 600 }} />
          {compareEnabled && <DeltaChip delta={params.row.delta_overdue} positiveIsGood={false} />}
        </Box>
      ),
    },
    {
      field: 'avg_lead_time_minutes',
      headerName: 'เวลาในการดำเนินการเฉลี่ย',
      flex: 1.2, minWidth: 180, type: 'number', headerAlign: 'left', align: 'left',
      renderCell: (params) => (
        <Box sx={{ display: 'flex', alignItems: 'center', height: '100%' }}>
          <Typography variant="body2" color={params.value === null ? 'text.disabled' : 'text.primary'}>
            {params.value === null ? '—' : (() => {
              const mins = Number(params.value);
              if (mins < 1) return `${Math.round(mins * 60)} วินาที`;
              const total = Math.round(mins);
              const h = Math.floor(total / 60);
              const m = total % 60;
              return h === 0 ? `${m} นาที` : `${h} ชม. ${m} นาที`;
            })()}
          </Typography>
        </Box>
      ),
    },
    {
      field: '__detail',
      headerName: '',
      flex: 0.4, minWidth: 60, sortable: false, filterable: false, disableColumnMenu: true,
      align: 'center', headerAlign: 'center',
      renderCell: (params) => (
        <Tooltip title="ดูรายละเอียด">
          <IconButton
            size="small"
            onClick={(e) => { e.stopPropagation(); setDetailRow(params.row as EnrichedRow); }}
            onMouseDown={(e) => e.stopPropagation()}
            sx={{ color: 'primary.main' }}
          >
            <VisibilityIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      ),
    },
  ], [compareEnabled]);

  // Comparison toggle handler — auto-fill comparison dates
  const handleCompareToggle = (enabled: boolean) => {
    if (enabled && !compareDateFrom) {
      const from = new Date(dateFrom);
      const to   = new Date(dateTo);
      const duration = to.getTime() - from.getTime();
      const cTo   = new Date(from.getTime() - 86400000);
      const cFrom = new Date(cTo.getTime() - duration);
      setCompareDateFrom(toLocalDateString(cFrom));
      setCompareDateTo(toLocalDateString(cTo));
    }
    setCompareEnabled(enabled);
  };

  if (roleLoading) return null;
  if (role !== 'superadmin') {
    return (
      <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', gap: 2 }}>
        <LockOutlinedIcon sx={{ fontSize: 72, opacity: 0.3 }} />
        <Typography variant="h6" color="error">คุณไม่มีสิทธิ์เข้าถึงหน้านี้</Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Typography variant="h5" fontWeight="bold" gutterBottom>ภาระงานเจ้าหน้าที่</Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        สรุปจำนวนคำขอที่แต่ละคนดำเนินการในช่วงเวลาที่เลือก
      </Typography>

      {error && <Alert severity="error" sx={{ mb: 3 }}>เกิดข้อผิดพลาด: {error}</Alert>}

      {/* Filter + Table */}
      <Paper elevation={1} sx={{ p: 3, borderRadius: 2 }}>
        <Box sx={{ mb: 3 }}>
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems={{ xs: 'stretch', sm: 'center' }} flexWrap="wrap">
            <TextField label="ตั้งแต่วันที่" type="date" size="small" value={dateFrom} onChange={e => setDateFrom(e.target.value)} slotProps={{ inputLabel: { shrink: true } }} sx={{ minWidth: 160 }} />
            <TextField label="ถึงวันที่" type="date" size="small" value={dateTo} onChange={e => setDateTo(e.target.value)} slotProps={{ inputLabel: { shrink: true } }} sx={{ minWidth: 160 }} />
            <TextField label="สถานบริการ" select size="small" value={serviceCenter} onChange={e => setServiceCenter(e.target.value)} sx={{ minWidth: 180 }}>
              <MenuItem value="all">ทั้งหมด</MenuItem>
              {SERVICE_CENTERS.map(sc => <MenuItem key={sc} value={sc}>{sc}</MenuItem>)}
            </TextField>
            <FormControlLabel
              control={<Switch size="small" checked={compareEnabled} onChange={e => handleCompareToggle(e.target.checked)} />}
              label={<Typography variant="body2">เปรียบเทียบช่วงเวลา</Typography>}
              sx={{ ml: { sm: 'auto' } }}
            />
          </Stack>

          {compareEnabled && (
            <>
              <Divider sx={{ my: 1.5 }} />
              <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems={{ xs: 'stretch', sm: 'center' }}>
                <Typography variant="caption" color="text.secondary" sx={{ minWidth: 90, fontWeight: 600 }}>
                  ช่วงเปรียบเทียบ
                </Typography>
                <TextField label="ตั้งแต่วันที่" type="date" size="small" value={compareDateFrom} onChange={e => setCompareDateFrom(e.target.value)} slotProps={{ inputLabel: { shrink: true } }} sx={{ minWidth: 160 }} />
                <TextField label="ถึงวันที่" type="date" size="small" value={compareDateTo} onChange={e => setCompareDateTo(e.target.value)} slotProps={{ inputLabel: { shrink: true } }} sx={{ minWidth: 160 }} />
              </Stack>
            </>
          )}
        </Box>

        <Box sx={{ height: 500 }}>
          <DataGrid
            rows={enrichedRows}
            columns={columns}
            loading={loading}
            localeText={thGridLocale}
            getRowHeight={() => compareEnabled ? 64 : 52}
            initialState={{
              pagination: { paginationModel: { pageSize: 25, page: 0 } },
              sorting: { sortModel: [{ field: 'completed_count', sort: 'desc' }] },
            }}
            pageSizeOptions={[25, 50]}
            disableRowSelectionOnClick
            sx={{
              border: 'none',
              '& .MuiDataGrid-columnHeaders': { bgcolor: 'grey.50' },
              '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
            }}
          />
        </Box>
      </Paper>

      {/* Detail Dialog */}
      <StaffWorkloadDetailDialog
        open={detailRow !== null}
        row={detailRow}
        dateFrom={dateFrom}
        dateTo={dateTo}
        serviceCenter={selectedSC}
        onClose={() => setDetailRow(null)}
      />
    </Box>
  );
}
