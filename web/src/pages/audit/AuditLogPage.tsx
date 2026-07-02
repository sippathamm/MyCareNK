import React, { useState, useMemo, useCallback } from 'react';
import {
  Box, Typography, Paper, TextField, MenuItem, Stack,
  Alert, Chip, Tabs, Tab,
} from '@mui/material';
import { alpha } from '@mui/material/styles';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import { useRoleAccess, type StaffRole } from '../../hooks/useRoleAccess';
import { useIsMobile } from '../../hooks/useIsMobile';
import { useServiceCenterFilter } from '../../contexts/ServiceCenterFilterContext';
import { useStaffAuditLog, type StaffAuditLogRow, type StaffAuditLogFilters } from '../../hooks/useStaffAuditLog';
import { useInventoryLog, type InventoryLogRow, type InventoryLogFilters } from '../../hooks/useInventoryLog';
import { useRequestStatusLog, type RequestStatusLogRow, type RequestStatusLogFilters } from '../../hooks/useRequestStatusLog';
import { useConsultationStatusLog, type ConsultationStatusLogRow, type ConsultationStatusLogFilters } from '../../hooks/useConsultationStatusLog';
import StaffAuditLogDetailDialog from '../../components/audit/StaffAuditLogDetailDialog';
import InventoryLogDetailDrawer from '../../components/audit/InventoryLogDetailDrawer';
import {
  AUDIT_ACTION, AUDIT_ACTION_LABEL, AUDIT_ACTION_COLOR, AUDIT_ACTION_FALLBACK_COLOR,
} from '../../constants/auditLogActions';
import type { AuditAction } from '../../constants/auditLogActions';
import { formatDateTime } from '../../utils/requestUtils';
import { createThGridLocale } from '../../constants/datagrid';
import { useColorMode } from '../../contexts/ThemeContext';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function toLocalDateString(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function getDefaultDateFrom(): string {
  const d = new Date();
  d.setDate(d.getDate() - 31);
  return toLocalDateString(d);
}

// ─── Constants ────────────────────────────────────────────────────────────────

const PAGE_SIZE_OPTIONS = [25, 50, 100];

const thGridLocale = createThGridLocale('ไม่มีข้อมูลในช่วงที่เลือก');

// Staff-related actions (Tab 1)
const STAFF_AUDIT_ACTIONS = [
  AUDIT_ACTION.STAFF_CREATED,
  AUDIT_ACTION.STAFF_DELETED,
  AUDIT_ACTION.STAFF_PROFILE_UPDATED,
  AUDIT_ACTION.EMAIL_UPDATED,
  AUDIT_ACTION.ROLE_UPDATED,
] as const;

// Inventory actions (Tab 3)
const INVENTORY_AUDIT_ACTIONS = [
  AUDIT_ACTION.RESTOCK,
  AUDIT_ACTION.FULFILLMENT,
  AUDIT_ACTION.ADJUSTMENT,
] as const;

const STATUS_LABELS: Record<string, string> = {
  pending:            'รอดำเนินการ',
  preparing:          'กำลังเตรียม',
  ready:              'รอรับ',
  completed:          'เสร็จสิ้น',
  cancelled_by_staff: 'ยกเลิกโดยเจ้าหน้าที่',
  cancelled_by_user:  'ยกเลิกโดยผู้ใช้',
};

const CONSULTATION_STATUS_LABELS: Record<string, string> = {
  pending:            'รอยืนยัน',
  confirmed:          'ยืนยันแล้ว',
  completed:          'เสร็จสิ้น',
  cancelled_by_user:  'ยกเลิกโดยผู้ใช้',
  cancelled_by_staff: 'ยกเลิกโดยเจ้าหน้าที่',
};

const STATUS_OPTIONS = [
  { value: '', label: 'ทั้งหมด' },
  ...Object.entries(STATUS_LABELS).map(([v, l]) => ({ value: v, label: l })),
];

// ─── Shared sub-components ────────────────────────────────────────────────────

const AUDIT_ACTION_DARK_SX: Record<string, { bg: string; color: string }> = {
  staff_created:         { bg: alpha('#2E7D32', 0.2), color: '#81C784' },
  staff_deleted:         { bg: alpha('#B71C1C', 0.2), color: '#EF9A9A' },
  role_updated:          { bg: alpha('#7B1FA2', 0.2), color: '#CE93D8' },
  staff_profile_updated: { bg: alpha('#E65100', 0.2), color: '#FFBE9E' },
  email_updated:         { bg: alpha('#1565C0', 0.2), color: '#90CAF9' },
  restock:               { bg: alpha('#2E7D32', 0.2), color: '#81C784' },
  fulfillment:           { bg: alpha('#1565C0', 0.2), color: '#90CAF9' },
  adjustment:            { bg: alpha('#E65100', 0.2), color: '#FFBE9E' },
};
const AUDIT_ACTION_DARK_FALLBACK = { bg: alpha('#9E9E9E', 0.15), color: '#BDBDBD' };

function DateTimeCell({ value }: { value: string }) {
  return (
    <Typography variant="body2" sx={{ fontSize: '0.82rem' }}>
      {formatDateTime(value)}
    </Typography>
  );
}

function ActionChip({ action }: { action: string }) {
  const { mode } = useColorMode();
  const cfg = mode === 'dark'
    ? (AUDIT_ACTION_DARK_SX[action] ?? AUDIT_ACTION_DARK_FALLBACK)
    : (AUDIT_ACTION_COLOR[action as AuditAction] ?? AUDIT_ACTION_FALLBACK_COLOR);
  return (
    <Chip
      label={AUDIT_ACTION_LABEL[action as AuditAction] ?? action}
      size="small"
      sx={{ bgcolor: cfg.bg, color: cfg.color, fontWeight: 600, fontSize: '0.72rem' }}
    />
  );
}

function StatusChip({ status }: { status: string | null }) {
  const { mode } = useColorMode();
  if (!status) return <Typography variant="caption" color="text.disabled">—</Typography>;
  const d = mode === 'dark';
  switch (status) {
    case 'pending':   return <Chip label={STATUS_LABELS['pending']}   size="small" sx={{ bgcolor: d ? alpha('#E65100', 0.15) : '#FFF3E0', color: d ? '#FFBE9E' : '#E65100', fontWeight: 600, fontSize: '0.72rem' }} />;
    case 'preparing': return <Chip label={STATUS_LABELS['preparing']} size="small" sx={{ bgcolor: d ? alpha('#1565C0', 0.15) : '#E3F2FD', color: d ? '#90CAF9' : '#1565C0', fontWeight: 600, fontSize: '0.72rem' }} />;
    case 'ready':     return <Chip label={STATUS_LABELS['ready']}     size="small" sx={{ bgcolor: d ? alpha('#7B1FA2', 0.15) : '#F3E5F5', color: d ? '#CE93D8' : '#7B1FA2', fontWeight: 600, fontSize: '0.72rem' }} />;
    case 'completed': return <Chip label={STATUS_LABELS['completed']} size="small" sx={{ bgcolor: d ? alpha('#2E7D32', 0.15) : '#E8F5E9', color: d ? '#81C784' : '#2E7D32', fontWeight: 600, fontSize: '0.72rem' }} />;
    default:          return <Chip label={STATUS_LABELS[status] ?? status} size="small" sx={{ bgcolor: d ? alpha('#9E9E9E', 0.15) : '#F5F5F5', color: d ? '#BDBDBD' : '#616161', fontWeight: 600, fontSize: '0.72rem' }} />;
  }
}

function InventoryQtyChip({ value }: { value: unknown }) {
  const { mode } = useColorMode();
  const num = typeof value === 'number' ? value : Number(value);
  if (num === 0 || isNaN(num)) return <Typography variant="body2" color="text.disabled">—</Typography>;
  const isPositive = num > 0;
  const d = mode === 'dark';
  return (
    <Chip
      label={`${isPositive ? '+' : ''}${num.toLocaleString()}`}
      size="small"
      sx={{
        bgcolor: isPositive ? (d ? alpha('#2E7D32', 0.15) : '#EBF7EC') : (d ? alpha('#C62828', 0.15) : '#FFF0F0'),
        color:   isPositive ? (d ? '#81C784' : '#2E7D32') : (d ? '#EF9A9A' : '#C62828'),
        fontWeight: 600, fontSize: '0.78rem',
      }}
    />
  );
}

// ─── Tab 1: Staff Audit Log ───────────────────────────────────────────────────

function AuditLogTab() {
  const isMobile = useIsMobile();
  const { role } = useRoleAccess();
  const { selectedServiceCenter } = useServiceCenterFilter();
  const [dateFrom, setDateFrom] = useState(getDefaultDateFrom);
  const [dateTo, setDateTo] = useState(() => toLocalDateString(new Date()));
  const [actionFilter, setActionFilter] = useState('');
  const [targetIdFilter, setTargetIdFilter] = useState('');
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(25);
  const [detailRow, setDetailRow] = useState<StaffAuditLogRow | null>(null);

  const availableActions = STAFF_AUDIT_ACTIONS.filter(
    v => role !== 'admin' || v !== AUDIT_ACTION.ROLE_UPDATED
  );

  const resetPage = useCallback(() => setPage(0), []);

  const filters = useMemo<StaffAuditLogFilters>(() => ({
    performedBy:   null,
    action:        (actionFilter as AuditAction) || null,
    targetId:      targetIdFilter.trim() || null,
    dateFrom:      dateFrom  || null,
    dateTo:        dateTo    || null,
    serviceCenter: selectedServiceCenter,
  }), [actionFilter, targetIdFilter, dateFrom, dateTo, selectedServiceCenter]);

  const { rows, loading, error } = useStaffAuditLog(filters, page, pageSize);

  const columns = useMemo<GridColDef<StaffAuditLogRow>[]>(() => [
    {
      field: 'action', headerName: 'ประเภท', width: 180, minWidth: 160,
      renderCell: (p) => <ActionChip action={p.value} />,
    },
    {
      field: 'target_name', headerName: 'เจ้าหน้าที่', flex: 1.2, minWidth: 160,
      renderCell: (p) => {
        const row = p.row as StaffAuditLogRow;
        const display = row.target_name ?? row.target_full_name ?? '—';
        return <Typography variant="body2">{display}</Typography>;
      },
    },
    {
      field: 'full_name', headerName: 'โดย', flex: 1.2, minWidth: 140,
      renderCell: (p) => <Typography variant="body2">{p.value}</Typography>,
    },
    {
      field: 'created_at', headerName: 'เมื่อวันที่', flex: 1.4, minWidth: 200,
      renderCell: (p) => <DateTimeCell value={p.value} />,
    },
  ], []);

  return (
    <>
      {error && <Alert severity="error" sx={{ mb: 3 }}>เกิดข้อผิดพลาด: {error}</Alert>}

      <Paper elevation={1} sx={{ p: 3, borderRadius: 2 }}>
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems={{ xs: 'stretch', sm: 'center' }} flexWrap="wrap" sx={{ mb: 3 }}>
          <TextField label="ตั้งแต่วันที่" type="date" size="small" value={dateFrom}
            onChange={e => { setDateFrom(e.target.value); resetPage(); }}
            slotProps={{ inputLabel: { shrink: true } }} sx={{ minWidth: 160 }} />
          <TextField label="ถึงวันที่" type="date" size="small" value={dateTo}
            onChange={e => { setDateTo(e.target.value); resetPage(); }}
            slotProps={{ inputLabel: { shrink: true } }} sx={{ minWidth: 160 }} />
          <TextField label="ประเภท" select size="small" value={actionFilter}
            onChange={e => { setActionFilter(e.target.value); resetPage(); }} sx={{ minWidth: 220 }}
            slotProps={{ select: { displayEmpty: true }, inputLabel: { shrink: true } }}>
            <MenuItem value="">ทั้งหมด</MenuItem>
            {availableActions.map(v => (
              <MenuItem key={v} value={v}>{AUDIT_ACTION_LABEL[v]}</MenuItem>
            ))}
          </TextField>
          <TextField size="small" value={targetIdFilter}
            onChange={e => { setTargetIdFilter(e.target.value); resetPage(); }}
            sx={{ minWidth: 220 }}
            placeholder="ค้นหาชื่อ-นามสกุล / UUID" />
        </Stack>
        <Box sx={{ height: 500 }}>
            <DataGrid
              rows={rows} columns={columns} loading={loading}
              localeText={thGridLocale}
              paginationModel={{ page, pageSize }}
              onPaginationModelChange={({ page: p, pageSize: ps }) => { setPage(p); setPageSize(ps); }}
              pageSizeOptions={PAGE_SIZE_OPTIONS}
              columnVisibilityModel={isMobile ? { full_name: false, created_at: false } : undefined}
              onRowClick={({ row }) => setDetailRow(row as StaffAuditLogRow)}
              disableRowSelectionOnClick
              hideFooterSelectedRowCount
              sx={{
                border: 'none',
                '& .MuiDataGrid-columnHeaders': { bgcolor: 'action.hover' },
                '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
              }}
            />
          </Box>
      </Paper>

      <StaffAuditLogDetailDialog row={detailRow} onClose={() => setDetailRow(null)} />
    </>
  );
}

// ─── Tab 2: Request Status Log ────────────────────────────────────────────────

function RequestStatusLogTab() {
  const isMobile = useIsMobile();
  const { selectedServiceCenter } = useServiceCenterFilter();
  const [dateFrom, setDateFrom] = useState(getDefaultDateFrom);
  const [dateTo, setDateTo] = useState(() => toLocalDateString(new Date()));
  const [fromStatus, setFromStatus] = useState('');
  const [toStatus, setToStatus] = useState('');
  const [refNumFilter, setRefNumFilter] = useState('');
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(25);

  const resetPage = useCallback(() => setPage(0), []);

  const filters = useMemo<RequestStatusLogFilters>(() => ({
    performedBy:     null,
    fromStatus:      fromStatus || null,
    toStatus:        toStatus   || null,
    referenceNumber: refNumFilter.trim() || null,
    dateFrom:        dateFrom   || null,
    dateTo:          dateTo     || null,
    serviceCenter:   selectedServiceCenter,
  }), [fromStatus, toStatus, refNumFilter, dateFrom, dateTo, selectedServiceCenter]);

  const { rows, loading, error } = useRequestStatusLog(filters, page, pageSize);

  const columns = useMemo<GridColDef<RequestStatusLogRow>[]>(() => [
    {
      field: 'reference_number', headerName: 'รหัสอ้างอิง', width: 160, minWidth: 140,
      renderCell: (p) => (
        <Typography variant="body2">{p.value ?? '—'}</Typography>
      ),
    },
    {
      field: 'from_status', headerName: 'จากสถานะ', flex: 1, minWidth: 160,
      renderCell: (p) => <StatusChip status={p.value} />,
    },
    {
      field: 'to_status', headerName: 'เป็นสถานะ', flex: 1, minWidth: 160,
      renderCell: (p) => <StatusChip status={p.value} />,
    },
    {
      field: 'full_name', headerName: 'โดย', flex: 1.2, minWidth: 140,
      renderCell: (p) => <Typography variant="body2">{p.value ?? '—'}</Typography>,
    },
    {
      field: 'changed_at', headerName: 'เมื่อวันที่', flex: 1.3, minWidth: 170,
      renderCell: (p) => <DateTimeCell value={p.value} />,
    },
  ], []);

  return (
    <>
      {error && <Alert severity="error" sx={{ mb: 3 }}>เกิดข้อผิดพลาด: {error}</Alert>}

      <Paper elevation={1} sx={{ p: 3, borderRadius: 2 }}>
        <Stack spacing={2} sx={{ mb: 3 }}>
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems={{ xs: 'stretch', sm: 'center' }} flexWrap="wrap">
            <TextField label="ตั้งแต่วันที่" type="date" size="small" value={dateFrom}
              onChange={e => { setDateFrom(e.target.value); resetPage(); }}
              slotProps={{ inputLabel: { shrink: true } }} sx={{ minWidth: 160 }} />
            <TextField label="ถึงวันที่" type="date" size="small" value={dateTo}
              onChange={e => { setDateTo(e.target.value); resetPage(); }}
              slotProps={{ inputLabel: { shrink: true } }} sx={{ minWidth: 160 }} />
            <TextField label="จากสถานะ" select size="small" value={fromStatus}
              onChange={e => { setFromStatus(e.target.value); resetPage(); }} sx={{ minWidth: 190 }}
              slotProps={{ select: { displayEmpty: true }, inputLabel: { shrink: true } }}>
              {STATUS_OPTIONS.map(o => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
            </TextField>
            <TextField label="เป็นสถานะ" select size="small" value={toStatus}
              onChange={e => { setToStatus(e.target.value); resetPage(); }} sx={{ minWidth: 190 }}
              slotProps={{ select: { displayEmpty: true }, inputLabel: { shrink: true } }}>
              {STATUS_OPTIONS.map(o => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
            </TextField>
          </Stack>
          <TextField size="small" value={refNumFilter}
            onChange={e => { setRefNumFilter(e.target.value); resetPage(); }}
            sx={{ maxWidth: 320 }} placeholder="ค้นหารหัสอ้างอิง" />
        </Stack>
        <Box sx={{ height: 500 }}>
            <DataGrid
              rows={rows} columns={columns} loading={loading}
              localeText={thGridLocale}
              paginationModel={{ page, pageSize }}
              onPaginationModelChange={({ page: p, pageSize: ps }) => { setPage(p); setPageSize(ps); }}
              pageSizeOptions={PAGE_SIZE_OPTIONS}
              columnVisibilityModel={isMobile ? { from_status: false, full_name: false, changed_at: false } : undefined}
              disableRowSelectionOnClick
              sx={{
                border: 'none',
                '& .MuiDataGrid-columnHeaders': { bgcolor: 'action.hover' },
                '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
              }}
            />
          </Box>
      </Paper>
    </>
  );
}

// ─── Tab 3: Consultation Status Log ──────────────────────────────────────────

function ConsultationStatusChip({ status }: { status: string | null }) {
  const { mode } = useColorMode();
  if (!status) return <Typography variant="caption" color="text.disabled">—</Typography>;
  const label = CONSULTATION_STATUS_LABELS[status] ?? status;
  const d = mode === 'dark';
  switch (status) {
    case 'pending':            return <Chip label={label} size="small" sx={{ bgcolor: d ? alpha('#E65100', 0.15) : '#FFF3E0', color: d ? '#FFBE9E' : '#E65100', fontWeight: 600, fontSize: '0.72rem' }} />;
    case 'confirmed':          return <Chip label={label} size="small" sx={{ bgcolor: d ? alpha('#7B1FA2', 0.15) : '#F3E5F5', color: d ? '#CE93D8' : '#7B1FA2', fontWeight: 600, fontSize: '0.72rem' }} />;
    case 'completed':          return <Chip label={label} size="small" sx={{ bgcolor: d ? alpha('#2E7D32', 0.15) : '#E8F5E9', color: d ? '#81C784' : '#2E7D32', fontWeight: 600, fontSize: '0.72rem' }} />;
    case 'cancelled_by_user':
    case 'cancelled_by_staff': return <Chip label={label} size="small" sx={{ bgcolor: d ? alpha('#9E9E9E', 0.15) : '#F5F5F5', color: d ? '#BDBDBD' : '#616161', fontWeight: 600, fontSize: '0.72rem' }} />;
    default:                   return <Chip label={label} size="small" sx={{ bgcolor: d ? alpha('#9E9E9E', 0.15) : '#F5F5F5', color: d ? '#BDBDBD' : '#616161', fontWeight: 600, fontSize: '0.72rem' }} />;
  }
}

const CONSULTATION_STATUS_OPTIONS = [
  { value: '', label: 'ทั้งหมด' },
  ...Object.entries(CONSULTATION_STATUS_LABELS).map(([v, l]) => ({ value: v, label: l })),
];

function ConsultationStatusLogTab() {
  const isMobile = useIsMobile();
  const { selectedServiceCenter } = useServiceCenterFilter();
  const [dateFrom, setDateFrom] = useState(getDefaultDateFrom);
  const [dateTo, setDateTo] = useState(() => toLocalDateString(new Date()));
  const [fromStatus, setFromStatus] = useState('');
  const [toStatus, setToStatus] = useState('');
  const [refNumFilter, setRefNumFilter] = useState('');
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(25);

  const resetPage = useCallback(() => setPage(0), []);

  const filters = useMemo<ConsultationStatusLogFilters>(() => ({
    performedBy:     null,
    fromStatus:      fromStatus || null,
    toStatus:        toStatus   || null,
    referenceNumber: refNumFilter.trim() || null,
    dateFrom:        dateFrom   || null,
    dateTo:          dateTo     || null,
    serviceCenter:   selectedServiceCenter,
  }), [fromStatus, toStatus, refNumFilter, dateFrom, dateTo, selectedServiceCenter]);

  const { rows, loading, error } = useConsultationStatusLog(filters, page, pageSize);

  const columns = useMemo<GridColDef<ConsultationStatusLogRow>[]>(() => [
    {
      field: 'reference_number', headerName: 'รหัสอ้างอิง', width: 180, minWidth: 150,
      renderCell: (p) => <Typography variant="body2">{p.value ?? '—'}</Typography>,
    },
    {
      field: 'from_status', headerName: 'จากสถานะ', flex: 1, minWidth: 160,
      renderCell: (p) => <ConsultationStatusChip status={p.value} />,
    },
    {
      field: 'to_status', headerName: 'เป็นสถานะ', flex: 1, minWidth: 160,
      renderCell: (p) => <ConsultationStatusChip status={p.value} />,
    },
    {
      field: 'full_name', headerName: 'โดย', flex: 1.2, minWidth: 140,
      renderCell: (p) => <Typography variant="body2">{p.value ?? '—'}</Typography>,
    },
    {
      field: 'changed_at', headerName: 'เมื่อวันที่', flex: 1.3, minWidth: 170,
      renderCell: (p) => <DateTimeCell value={p.value} />,
    },
  ], []);

  return (
    <>
      {error && <Alert severity="error" sx={{ mb: 3 }}>เกิดข้อผิดพลาด: {error}</Alert>}

      <Paper elevation={1} sx={{ p: 3, borderRadius: 2 }}>
        <Stack spacing={2} sx={{ mb: 3 }}>
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems={{ xs: 'stretch', sm: 'center' }} flexWrap="wrap">
            <TextField label="ตั้งแต่วันที่" type="date" size="small" value={dateFrom}
              onChange={e => { setDateFrom(e.target.value); resetPage(); }}
              slotProps={{ inputLabel: { shrink: true } }} sx={{ minWidth: 160 }} />
            <TextField label="ถึงวันที่" type="date" size="small" value={dateTo}
              onChange={e => { setDateTo(e.target.value); resetPage(); }}
              slotProps={{ inputLabel: { shrink: true } }} sx={{ minWidth: 160 }} />
            <TextField label="จากสถานะ" select size="small" value={fromStatus}
              onChange={e => { setFromStatus(e.target.value); resetPage(); }} sx={{ minWidth: 190 }}
              slotProps={{ select: { displayEmpty: true }, inputLabel: { shrink: true } }}>
              {CONSULTATION_STATUS_OPTIONS.map(o => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
            </TextField>
            <TextField label="เป็นสถานะ" select size="small" value={toStatus}
              onChange={e => { setToStatus(e.target.value); resetPage(); }} sx={{ minWidth: 190 }}
              slotProps={{ select: { displayEmpty: true }, inputLabel: { shrink: true } }}>
              {CONSULTATION_STATUS_OPTIONS.map(o => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
            </TextField>
          </Stack>
          <TextField size="small" value={refNumFilter}
            onChange={e => { setRefNumFilter(e.target.value); resetPage(); }}
            sx={{ maxWidth: 320 }} placeholder="ค้นหารหัสอ้างอิง" />
        </Stack>
        <Box sx={{ height: 500 }}>
          <DataGrid
            rows={rows} columns={columns} loading={loading}
            localeText={thGridLocale}
            paginationModel={{ page, pageSize }}
            onPaginationModelChange={({ page: p, pageSize: ps }) => { setPage(p); setPageSize(ps); }}
            pageSizeOptions={PAGE_SIZE_OPTIONS}
            columnVisibilityModel={isMobile ? { from_status: false, full_name: false, changed_at: false } : undefined}
            disableRowSelectionOnClick
            sx={{
              border: 'none',
              '& .MuiDataGrid-columnHeaders': { bgcolor: 'action.hover' },
              '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
            }}
          />
        </Box>
      </Paper>
    </>
  );
}

// ─── Tab 4: Inventory Log ─────────────────────────────────────────────────────

function InventoryLogTab() {
  const isMobile = useIsMobile();
  const { selectedServiceCenter } = useServiceCenterFilter();
  const [dateFrom, setDateFrom] = useState(getDefaultDateFrom);
  const [dateTo, setDateTo] = useState(() => toLocalDateString(new Date()));
  const [actionFilter, setActionFilter] = useState('');
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(25);
  const [detailRow, setDetailRow] = useState<InventoryLogRow | null>(null);

  const resetPage = useCallback(() => setPage(0), []);

  const filters = useMemo<InventoryLogFilters>(() => ({
    action:        (actionFilter as AuditAction) || null,
    serviceCenter: selectedServiceCenter,
    dateFrom:      dateFrom  || null,
    dateTo:        dateTo    || null,
  }), [actionFilter, selectedServiceCenter, dateFrom, dateTo]);

  const { rows, loading, error } = useInventoryLog(filters, page, pageSize);

  const columns = useMemo<GridColDef<InventoryLogRow>[]>(() => [
    {
      field: 'action', headerName: 'ประเภท', width: 130, minWidth: 120,
      renderCell: (p) => <ActionChip action={p.value} />,
    },
    {
      field: 'service_center', headerName: 'สถานบริการ', flex: 1.2, minWidth: 150,
      renderCell: (p) => <Typography variant="body2">{p.value}</Typography>,
    },
    {
      field: 'condom_delta', headerName: 'ถุงยางอนามัย (ชิ้น)', flex: 0.9, minWidth: 140,
      align: 'center', headerAlign: 'center',
      renderCell: (p) => <InventoryQtyChip value={p.value} />,
    },
    {
      field: 'lubricant_delta', headerName: 'เจลหล่อลื่น (ชิ้น)', flex: 0.9, minWidth: 140,
      align: 'center', headerAlign: 'center',
      renderCell: (p) => <InventoryQtyChip value={p.value} />,
    },
    {
      field: 'full_name', headerName: 'โดย', flex: 1.3, minWidth: 160,
      renderCell: (p) => <Typography variant="body2">{p.value}</Typography>,
    },
    {
      field: 'created_at', headerName: 'เมื่อวันที่', flex: 1.3, minWidth: 170,
      renderCell: (p) => <DateTimeCell value={p.value} />,
    },
  ], []);

  return (
    <>
      {error && <Alert severity="error" sx={{ mb: 3 }}>เกิดข้อผิดพลาด: {error}</Alert>}

      <Paper elevation={1} sx={{ p: 3, borderRadius: 2 }}>
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems={{ xs: 'stretch', sm: 'center' }} flexWrap="wrap" sx={{ mb: 3 }}>
          <TextField label="ตั้งแต่วันที่" type="date" size="small" value={dateFrom}
            onChange={e => { setDateFrom(e.target.value); resetPage(); }}
            slotProps={{ inputLabel: { shrink: true } }} sx={{ minWidth: 160 }} />
          <TextField label="ถึงวันที่" type="date" size="small" value={dateTo}
            onChange={e => { setDateTo(e.target.value); resetPage(); }}
            slotProps={{ inputLabel: { shrink: true } }} sx={{ minWidth: 160 }} />
          <TextField label="ประเภท" select size="small" value={actionFilter}
            onChange={e => { setActionFilter(e.target.value); resetPage(); }} sx={{ minWidth: 180 }}
            slotProps={{ select: { displayEmpty: true }, inputLabel: { shrink: true } }}>
            <MenuItem value="">ทั้งหมด</MenuItem>
            {INVENTORY_AUDIT_ACTIONS.map(v => (
              <MenuItem key={v} value={v}>{AUDIT_ACTION_LABEL[v]}</MenuItem>
            ))}
          </TextField>
        </Stack>
        <Box sx={{ height: 500 }}>
            <DataGrid
              rows={rows} columns={columns} loading={loading}
              localeText={thGridLocale}
              paginationModel={{ page, pageSize }}
              onPaginationModelChange={({ page: p, pageSize: ps }) => { setPage(p); setPageSize(ps); }}
              pageSizeOptions={PAGE_SIZE_OPTIONS}
              columnVisibilityModel={isMobile ? { service_center: false, lubricant_delta: false, full_name: false, created_at: false } : undefined}
              onRowClick={({ row }) => setDetailRow(row as InventoryLogRow)}
              disableRowSelectionOnClick
              hideFooterSelectedRowCount
              sx={{
                border: 'none',
                '& .MuiDataGrid-columnHeaders': { bgcolor: 'action.hover' },
                '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
              }}
            />
          </Box>
      </Paper>

      <InventoryLogDetailDrawer row={detailRow} onClose={() => setDetailRow(null)} />
    </>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

// ─── Tab definitions ──────────────────────────────────────────────────────────

const ALL_TABS: { label: string; roles: StaffRole[]; Component: () => React.JSX.Element }[] = [
  { label: 'ประวัติการแก้ไขข้อมูลเจ้าหน้าที่', roles: ['admin', 'superadmin'], Component: AuditLogTab },
  { label: 'ประวัติสถานะคำขอ',                  roles: ['staff', 'admin', 'superadmin'], Component: RequestStatusLogTab },
  { label: 'ประวัติสถานะนัดรับคำปรึกษา',          roles: ['staff', 'admin', 'superadmin'], Component: ConsultationStatusLogTab },
  { label: 'ประวัติการแก้ไขสต็อก',              roles: ['admin', 'superadmin'], Component: InventoryLogTab },
];

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function AuditLogPage() {
  const { role, loading: roleLoading } = useRoleAccess();
  const [tab, setTab] = useState(0);

  if (roleLoading) return null;
  if (!role) {
    return (
      <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', gap: 2 }}>
        <LockOutlinedIcon sx={{ fontSize: 72, opacity: 0.3 }} />
        <Typography variant="h6" color="error">คุณไม่มีสิทธิ์เข้าถึงหน้านี้</Typography>
      </Box>
    );
  }

  const visibleTabs = ALL_TABS.filter(t => t.roles.includes(role));
  const safeTab = Math.min(tab, visibleTabs.length - 1);
  const ActiveComponent = visibleTabs[safeTab]?.Component ?? null;

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Typography variant="h5" fontWeight="bold" gutterBottom>บันทึกการตรวจสอบ</Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        {role === 'staff'
          ? 'ติดตามและตรวจสอบประวัติการดำเนินการในระบบ ครอบคลุมการเปลี่ยนแปลงสถานะคำขอ และการเปลี่ยนแปลงสถานะนัดรับคำปรึกษา'
          : 'ติดตามและตรวจสอบประวัติการดำเนินการในระบบ ครอบคลุมการแก้ไขข้อมูลเจ้าหน้าที่ การเปลี่ยนแปลงสถานะคำขอ การเปลี่ยนแปลงสถานะนัดรับคำปรึกษา และการจัดการสต็อก'
        }
      </Typography>

      <Tabs
        value={safeTab}
        onChange={(_, v) => setTab(v)}
        variant="scrollable"
        scrollButtons="auto"
        allowScrollButtonsMobile
        sx={{ mb: 3, borderBottom: 1, borderColor: 'divider' }}
      >
        {visibleTabs.map(t => <Tab key={t.label} label={t.label} />)}
      </Tabs>

      {ActiveComponent && <ActiveComponent />}
    </Box>
  );
}
