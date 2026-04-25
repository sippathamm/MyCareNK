import { useState, useMemo, useCallback } from 'react';
import {
  Box, Typography, Card, CardContent, TextField, MenuItem, Stack,
  Alert, Chip, Tabs, Tab,
} from '@mui/material';
import ArrowForwardRoundedIcon from '@mui/icons-material/ArrowForwardRounded';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useAuditLog, type AuditLogRow, type AuditLogFilters } from '../../hooks/useAuditLog';
import { useRequestStatusLog, type RequestStatusLogRow, type RequestStatusLogFilters } from '../../hooks/useRequestStatusLog';
import AuditLogDetailDrawer from '../../components/audit/AuditLogDetailDrawer';
import {
  AUDIT_ACTION, AUDIT_ACTION_LABEL, AUDIT_ACTION_COLOR, AUDIT_ACTION_FALLBACK_COLOR,
} from '../../constants/auditLogActions';
import type { AuditAction } from '../../constants/auditLogActions';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function toLocalDateString(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function getDefaultDateFrom(): string {
  const d = new Date();
  d.setDate(d.getDate() - 30);
  return toLocalDateString(d);
}

function formatDateTime(iso: string): string {
  const d = new Date(iso);
  const datePart = d.toLocaleDateString('th-TH', { year: 'numeric', month: 'short', day: 'numeric' });
  const timePart = d.toLocaleTimeString('th-TH', { hour: '2-digit', minute: '2-digit', hour12: false });
  return `${datePart} เวลา ${timePart} น.`;
}

// ─── Constants ────────────────────────────────────────────────────────────────

const PAGE_SIZE_OPTIONS = [25, 50, 100];

const thGridLocale = {
  noRowsLabel: 'ไม่มีข้อมูลในช่วงที่เลือก',
  noResultsOverlayLabel: 'ไม่พบข้อมูล',
  MuiTablePagination: {
    labelRowsPerPage: 'จำนวนต่อหน้า:',
    labelDisplayedRows: ({ from, to, count }: { from: number; to: number; count: number }) =>
      `${from}–${to} จาก ${count !== -1 ? count : `มากกว่า ${to}`}`,
  },
};

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

const SERVICE_CENTER_OPTIONS = [
  'รพ.โพนพิสัย',
  'รพ.สต.วัดหลวง',
  'อบต.วัดหลวง',
  'สสจ.หนองคาย',
] as const;

const STATUS_LABELS: Record<string, string> = {
  pending:            'รอดำเนินการ',
  preparing:          'กำลังเตรียม',
  ready:              'รอรับ',
  completed:          'เสร็จสิ้น',
  cancelled_by_staff: 'ยกเลิกโดยเจ้าหน้าที่',
  cancelled_by_user:  'ยกเลิกโดยผู้ใช้',
};

const STATUS_COLORS: Record<string, { bg: string; color: string }> = {
  pending:            { bg: '#FFF0E6', color: '#E65100' },
  preparing:          { bg: '#EBF4FF', color: '#1565C0' },
  ready:              { bg: '#F5EAF9', color: '#7B1FA2' },
  completed:          { bg: '#EBF7EC', color: '#2E7D32' },
  cancelled_by_staff: { bg: '#F5F5F5', color: '#616161' },
  cancelled_by_user:  { bg: '#F5F5F5', color: '#616161' },
};

const STATUS_OPTIONS = [
  { value: '', label: 'ทั้งหมด' },
  ...Object.entries(STATUS_LABELS).map(([v, l]) => ({ value: v, label: l })),
];

// ─── Shared sub-components ────────────────────────────────────────────────────

function DateTimeCell({ value }: { value: string }) {
  return (
    <Typography variant="body2" sx={{ fontSize: '0.82rem' }}>
      {formatDateTime(value)}
    </Typography>
  );
}

function ActionChip({ action }: { action: string }) {
  const cfg = AUDIT_ACTION_COLOR[action as AuditAction] ?? AUDIT_ACTION_FALLBACK_COLOR;
  return (
    <Chip
      label={AUDIT_ACTION_LABEL[action as AuditAction] ?? action}
      size="small"
      sx={{ bgcolor: cfg.bg, color: cfg.color, fontWeight: 600, fontSize: '0.72rem' }}
    />
  );
}

function StatusChip({ status }: { status: string | null }) {
  if (!status) return <Typography variant="caption" color="text.disabled">—</Typography>;
  const cfg = STATUS_COLORS[status] ?? { bg: '#F5F5F5', color: '#616161' };
  return (
    <Chip
      label={STATUS_LABELS[status] ?? status}
      size="small"
      sx={{ bgcolor: cfg.bg, color: cfg.color, fontWeight: 600, fontSize: '0.72rem' }}
    />
  );
}

function InventoryQtyChip({ value }: { value: unknown }) {
  const num = typeof value === 'number' ? value : Number(value);
  if (num === 0 || isNaN(num)) return <Typography variant="body2" color="text.disabled">—</Typography>;
  const isPositive = num > 0;
  return (
    <Chip
      label={`${isPositive ? '+' : ''}${num.toLocaleString()}`}
      size="small"
      sx={{ bgcolor: isPositive ? '#EBF7EC' : '#FFF0F0', color: isPositive ? '#2E7D32' : '#C62828', fontWeight: 600, fontSize: '0.78rem' }}
    />
  );
}

// ─── Tab 1: Staff Audit Log ───────────────────────────────────────────────────

function AuditLogTab() {
  const [dateFrom, setDateFrom] = useState(getDefaultDateFrom);
  const [dateTo, setDateTo] = useState(() => toLocalDateString(new Date()));
  const [actionFilter, setActionFilter] = useState('');
  const [targetIdFilter, setTargetIdFilter] = useState('');
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(25);
  const [detailRow, setDetailRow] = useState<AuditLogRow | null>(null);

  const resetPage = useCallback(() => setPage(0), []);

  const filters = useMemo<AuditLogFilters>(() => ({
    performedBy:   null,
    action:        (actionFilter as AuditAction) || null,
    targetTable:   'staff_profiles',
    targetId:      targetIdFilter.trim() || null,
    serviceCenter: null,
    dateFrom:      dateFrom  || null,
    dateTo:        dateTo    || null,
  }), [actionFilter, targetIdFilter, dateFrom, dateTo]);

  const { rows, loading, error } = useAuditLog(filters, page, pageSize);

  const columns = useMemo<GridColDef<AuditLogRow>[]>(() => [
    {
      field: 'action', headerName: 'ประเภท', width: 180, minWidth: 160,
      renderCell: (p) => <ActionChip action={p.value} />,
    },
    {
      field: 'target_id', headerName: 'UUID เจ้าหน้าที่', width: 310,
      renderCell: (p) => (
        <Typography variant="body2" sx={{ fontFamily: 'monospace', fontSize: '0.8rem' }}>{p.value ?? '—'}</Typography>
      ),
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
      <Card sx={{ borderRadius: 2, mb: 3 }} elevation={1}>
        <CardContent>
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems={{ xs: 'stretch', sm: 'center' }} flexWrap="wrap">
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
              {STAFF_AUDIT_ACTIONS.map(v => (
                <MenuItem key={v} value={v}>{AUDIT_ACTION_LABEL[v]}</MenuItem>
              ))}
            </TextField>
            <TextField size="small" value={targetIdFilter}
              onChange={e => { setTargetIdFilter(e.target.value); resetPage(); }}
              sx={{ minWidth: 220 }}
              placeholder="ค้นหา UUID เจ้าหน้าที่" />
          </Stack>
        </CardContent>
      </Card>

      {error && <Alert severity="error" sx={{ mb: 3 }}>เกิดข้อผิดพลาด: {error}</Alert>}

      <Card sx={{ borderRadius: 2 }} elevation={1}>
        <CardContent sx={{ p: 0, '&:last-child': { pb: 0 } }}>
          <Box sx={{ height: 520 }}>
            <DataGrid
              rows={rows} columns={columns} loading={loading}
              localeText={thGridLocale}
              paginationModel={{ page, pageSize }}
              onPaginationModelChange={({ page: p, pageSize: ps }) => { setPage(p); setPageSize(ps); }}
              pageSizeOptions={PAGE_SIZE_OPTIONS}
              onRowClick={({ row }) => setDetailRow(row as AuditLogRow)}
              sx={{
                border: 'none', borderRadius: 2,
                '& .MuiDataGrid-columnHeaders': { bgcolor: 'grey.50' },
                '& .MuiDataGrid-row': { cursor: 'pointer' },
                '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
              }}
            />
          </Box>
        </CardContent>
      </Card>

      <AuditLogDetailDrawer row={detailRow} onClose={() => setDetailRow(null)} />
    </>
  );
}

// ─── Tab 2: Request Status Log ────────────────────────────────────────────────

function RequestStatusLogTab() {
  const [dateFrom, setDateFrom] = useState(getDefaultDateFrom);
  const [dateTo, setDateTo] = useState(() => toLocalDateString(new Date()));
  const [fromStatus, setFromStatus] = useState('');
  const [toStatus, setToStatus] = useState('');
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(25);

  const resetPage = useCallback(() => setPage(0), []);

  const filters = useMemo<RequestStatusLogFilters>(() => ({
    performedBy: null,
    fromStatus:  fromStatus || null,
    toStatus:    toStatus   || null,
    dateFrom:    dateFrom   || null,
    dateTo:      dateTo     || null,
  }), [fromStatus, toStatus, dateFrom, dateTo]);

  const { rows, loading, error } = useRequestStatusLog(filters, page, pageSize);

  const columns = useMemo<GridColDef<RequestStatusLogRow>[]>(() => [
    {
      field: 'changed_at', headerName: 'เมื่อวันที่', flex: 1.3, minWidth: 170,
      renderCell: (p) => <DateTimeCell value={p.value} />,
    },
    {
      field: 'full_name', headerName: 'โดย', flex: 1.2, minWidth: 140,
      renderCell: (p) => <Typography variant="body2">{p.value}</Typography>,
    },
    {
      field: 'from_status', headerName: 'จากสถานะ', flex: 1, minWidth: 160,
      renderCell: (p) => <StatusChip status={p.value} />,
    },
    {
      field: '__arrow', headerName: '', width: 32, sortable: false, filterable: false,
      disableColumnMenu: true, align: 'center', headerAlign: 'center',
      renderCell: () => <ArrowForwardRoundedIcon sx={{ fontSize: 16, color: 'text.disabled' }} />,
    },
    {
      field: 'to_status', headerName: 'เป็นสถานะ', flex: 1, minWidth: 160,
      renderCell: (p) => <StatusChip status={p.value} />,
    },
    {
      field: 'request_id', headerName: 'คำขอ', flex: 1, minWidth: 120,
      renderCell: (p) => (
        <Typography variant="body2" sx={{ fontFamily: 'monospace', fontSize: '0.75rem', color: 'text.secondary' }}>
          #{(p.value as string)?.slice(0, 8)}…
        </Typography>
      ),
    },
  ], []);

  return (
    <>
      <Card sx={{ borderRadius: 2, mb: 3 }} elevation={1}>
        <CardContent>
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
        </CardContent>
      </Card>

      {error && <Alert severity="error" sx={{ mb: 3 }}>เกิดข้อผิดพลาด: {error}</Alert>}

      <Card sx={{ borderRadius: 2 }} elevation={1}>
        <CardContent sx={{ p: 0, '&:last-child': { pb: 0 } }}>
          <Box sx={{ height: 520 }}>
            <DataGrid
              rows={rows} columns={columns} loading={loading}
              localeText={thGridLocale}
              paginationModel={{ page, pageSize }}
              onPaginationModelChange={({ page: p, pageSize: ps }) => { setPage(p); setPageSize(ps); }}
              pageSizeOptions={PAGE_SIZE_OPTIONS}
              sx={{
                border: 'none', borderRadius: 2,
                '& .MuiDataGrid-columnHeaders': { bgcolor: 'grey.50' },
                '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
              }}
            />
          </Box>
        </CardContent>
      </Card>
    </>
  );
}

// ─── Tab 3: Inventory Log ─────────────────────────────────────────────────────

function InventoryLogTab() {
  const [dateFrom, setDateFrom] = useState(getDefaultDateFrom);
  const [dateTo, setDateTo] = useState(() => toLocalDateString(new Date()));
  const [actionFilter, setActionFilter] = useState('');
  const [serviceCenterFilter, setServiceCenterFilter] = useState('');
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(25);
  const [detailRow, setDetailRow] = useState<AuditLogRow | null>(null);

  const resetPage = useCallback(() => setPage(0), []);

  const filters = useMemo<AuditLogFilters>(() => ({
    performedBy:   null,
    action:        (actionFilter as AuditAction) || null,
    targetTable:   'inventory_transactions',
    targetId:      null,
    serviceCenter: serviceCenterFilter || null,
    dateFrom:      dateFrom  || null,
    dateTo:        dateTo    || null,
  }), [actionFilter, serviceCenterFilter, dateFrom, dateTo]);

  const { rows, loading, error } = useAuditLog(filters, page, pageSize);

  const columns = useMemo<GridColDef<AuditLogRow>[]>(() => [
    {
      field: 'action', headerName: 'ประเภท', width: 130, minWidth: 120,
      renderCell: (p) => <ActionChip action={p.value} />,
    },
    {
      field: '__service_center', headerName: 'สถานบริการ', flex: 1.2, minWidth: 150,
      sortable: false,
      renderCell: (p) => (
        <Typography variant="body2">
          {String(p.row.new_value?.service_center ?? '—')}
        </Typography>
      ),
    },
    {
      field: '__condom_delta', headerName: 'ถุงยางอนามัย (ชิ้น)', flex: 0.9, minWidth: 140,
      sortable: false, align: 'center', headerAlign: 'center',
      renderCell: (p) => <InventoryQtyChip value={p.row.new_value?.condom_delta} />,
    },
    {
      field: '__lubricant_delta', headerName: 'เจลหล่อลื่น (ชิ้น)', flex: 0.9, minWidth: 140,
      sortable: false, align: 'center', headerAlign: 'center',
      renderCell: (p) => <InventoryQtyChip value={p.row.new_value?.lubricant_delta} />,
    },
    {
      field: 'full_name', headerName: 'โดย', flex: 1.1, minWidth: 130,
      renderCell: (p) => <Typography variant="body2">{p.value}</Typography>,
    },
    {
      field: 'created_at', headerName: 'เมื่อวันที่', flex: 1.3, minWidth: 170,
      renderCell: (p) => <DateTimeCell value={p.value} />,
    },
    {
      field: '__note', headerName: 'หมายเหตุ', flex: 1.2, minWidth: 140,
      sortable: false,
      renderCell: (p) => {
        const note = p.row.new_value?.note as string | null | undefined;
        return note
          ? <Typography variant="body2" sx={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: '100%' }}>{note}</Typography>
          : <Typography variant="body2" color="text.disabled">—</Typography>;
      },
    },
  ], []);

  return (
    <>
      <Card sx={{ borderRadius: 2, mb: 3 }} elevation={1}>
        <CardContent>
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems={{ xs: 'stretch', sm: 'center' }} flexWrap="wrap">
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
            <TextField label="สถานบริการ" select size="small" value={serviceCenterFilter}
              onChange={e => { setServiceCenterFilter(e.target.value); resetPage(); }} sx={{ minWidth: 180 }}
              slotProps={{ select: { displayEmpty: true }, inputLabel: { shrink: true } }}>
              <MenuItem value="">ทั้งหมด</MenuItem>
              {SERVICE_CENTER_OPTIONS.map(sc => (
                <MenuItem key={sc} value={sc}>{sc}</MenuItem>
              ))}
            </TextField>
          </Stack>
        </CardContent>
      </Card>

      {error && <Alert severity="error" sx={{ mb: 3 }}>เกิดข้อผิดพลาด: {error}</Alert>}

      <Card sx={{ borderRadius: 2 }} elevation={1}>
        <CardContent sx={{ p: 0, '&:last-child': { pb: 0 } }}>
          <Box sx={{ height: 520 }}>
            <DataGrid
              rows={rows} columns={columns} loading={loading}
              localeText={thGridLocale}
              paginationModel={{ page, pageSize }}
              onPaginationModelChange={({ page: p, pageSize: ps }) => { setPage(p); setPageSize(ps); }}
              pageSizeOptions={PAGE_SIZE_OPTIONS}
              onRowClick={({ row }) => setDetailRow(row as AuditLogRow)}
              sx={{
                border: 'none', borderRadius: 2,
                '& .MuiDataGrid-columnHeaders': { bgcolor: 'grey.50' },
                '& .MuiDataGrid-row': { cursor: 'pointer' },
                '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
              }}
            />
          </Box>
        </CardContent>
      </Card>

      <AuditLogDetailDrawer row={detailRow} onClose={() => setDetailRow(null)} />
    </>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function AuditLogPage() {
  const { role, loading: roleLoading } = useRoleAccess();
  const [tab, setTab] = useState(0);

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
    <Box sx={{ width: '100%', maxWidth: 1400, margin: '0 auto' }}>
      <Typography variant="h5" fontWeight="bold" gutterBottom>บันทึกการตรวจสอบ</Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        ติดตามและตรวจสอบประวัติการดำเนินการในระบบ ครอบคลุมการแก้ไขข้อมูลเจ้าหน้าที่ การเปลี่ยนแปลงสถานะคำขอ และการจัดการสต็อกวัสดุ
      </Typography>

      <Tabs
        value={tab}
        onChange={(_, v) => setTab(v)}
        sx={{ mb: 3, borderBottom: 1, borderColor: 'divider' }}
      >
        <Tab label="ประวัติการแก้ไขข้อมูลเจ้าหน้าที่" />
        <Tab label="ประวัติสถานะคำขอ" />
        <Tab label="ประวัติการแก้ไขสต็อก" />
      </Tabs>

      {tab === 0 && <AuditLogTab />}
      {tab === 1 && <RequestStatusLogTab />}
      {tab === 2 && <InventoryLogTab />}
    </Box>
  );
}
