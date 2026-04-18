import { useState, useEffect, useMemo } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions, Button,
  Typography, Box, Divider, Chip, CircularProgress, Stack,
  Tooltip, IconButton, Snackbar, Alert,
} from '@mui/material';
import VisibilityIcon from '@mui/icons-material/Visibility';
import WarningIcon from '@mui/icons-material/Warning';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import { useStaffWorkloadTrend } from '../../hooks/useStaffWorkloadTrend';
import { useStaffRequests, type StaffRequestRow } from '../../hooks/useStaffRequests';
import RequestDetailDialog, { type RequestData } from '../requests/RequestDetailDialog';
import StaffWeeklyTrendChart from './StaffWeeklyTrendChart';
import { formatLeadTime } from '../../utils/staffWorkloadUtils';
import { formatDate, getOverdueDays } from '../../utils/requestUtils';
import { supabase } from '../../lib/supabase';
import type { EnrichedRow } from '../../hooks/useStaffWorkload';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function isOverdue(r: { request_status: string; completed_at: string | null; selected_date: string | null }): boolean {
  if (r.request_status !== 'completed' || !r.completed_at || !r.selected_date) return false;
  return r.completed_at.slice(0, 10) > r.selected_date;
}

function toRequestData(r: StaffRequestRow): RequestData {
  return r as unknown as RequestData;
}

type ReqFilter = 'all' | 'completed' | 'cancelled' | 'overdue';

const FILTER_CONFIG: Record<ReqFilter, { label: string; color: string; bg: string; border: string }> = {
  all:       { label: 'ทั้งหมด',  color: 'white',   bg: '#FF9F6B', border: '#FF9F6B' },
  completed: { label: 'เสร็จสิ้น', color: '#2E7D32', bg: '#EBF7EC', border: '#2E7D32' },
  cancelled: { label: 'ยกเลิก',   color: '#616161', bg: '#E0E0E0', border: '#9E9E9E' },
  overdue:   { label: 'ล่าช้า',   color: '#E65100', bg: '#FFF8E1', border: '#E65100' },
};

const thGridLocale = {
  noRowsLabel:           'ไม่มีรายการคำขอ',
  noResultsOverlayLabel: 'ไม่พบข้อมูล',
  MuiTablePagination: {
    labelRowsPerPage: 'จำนวนต่อหน้า:',
    labelDisplayedRows: ({ from, to, count }: { from: number; to: number; count: number }) =>
      `${from} - ${to} จาก ${count !== -1 ? count : `มากกว่า ${to}`}`,
  },
};

// ─── Props ────────────────────────────────────────────────────────────────────

interface Props {
  open:          boolean;
  row:           EnrichedRow | null;
  dateFrom:      string;
  dateTo:        string;
  serviceCenter: string | null;
  onClose:       () => void;
}

// ─── Dialog ───────────────────────────────────────────────────────────────────

export default function StaffWorkloadDetailDialog({
  open, row, dateFrom, dateTo, serviceCenter, onClose,
}: Props) {
  const staffId = row?.staff_user_id ?? null;

  const [reqFilter, setReqFilter]             = useState<ReqFilter>('all');
  const [selectedReq, setSelectedReq]         = useState<RequestData | null>(null);
  const [reqDetailOpen, setReqDetailOpen]     = useState(false);
  const [statusUpdating, setStatusUpdating]   = useState(false);
  const [statusError, setStatusError]         = useState<string | null>(null);

  useEffect(() => { if (!open) { setReqFilter('all'); setSelectedReq(null); setReqDetailOpen(false); } }, [open]);

  const { data: trendData, loading: trendLoading } = useStaffWorkloadTrend(
    dateFrom, dateTo, serviceCenter, open ? staffId : null,
  );

  const { data: requests, setData: setRequests, loading: reqLoading, refetch } = useStaffRequests(
    open ? staffId : null, dateFrom, dateTo,
  );

  const filteredRequests = useMemo(() => {
    switch (reqFilter) {
      case 'completed': return requests.filter(r => r.request_status === 'completed');
      case 'cancelled': return requests.filter(r => r.request_status.startsWith('cancelled'));
      case 'overdue':   return requests.filter(isOverdue);
      default:          return requests;
    }
  }, [requests, reqFilter]);

  const handleOpenReqDetail = (r: StaffRequestRow) => {
    setSelectedReq(toRequestData(r));
    setReqDetailOpen(true);
  };

  const handleStatusChange = async (id: string, newStatus: string, reason?: string): Promise<boolean> => {
    const payload: Record<string, unknown> = { request_status: newStatus, cancel_reason: reason ?? null };
    if (newStatus === 'completed') payload.completed_at = new Date().toISOString();

    setStatusUpdating(true);
    setStatusError(null);
    const { error } = await supabase.from('condom_requests').update(payload).eq('id', id);
    setStatusUpdating(false);

    if (error) { setStatusError(error.message); return false; }

    // Update local list + open dialog state
    setRequests(prev => prev.map(r =>
      r.id === id ? { ...r, request_status: newStatus, cancel_reason: reason ?? null,
        completed_at: newStatus === 'completed' ? payload.completed_at as string : r.completed_at } : r,
    ));
    if (selectedReq?.id === id) {
      setSelectedReq(prev => prev ? { ...prev,
        request_status: newStatus as RequestData['request_status'],
        cancel_reason: reason ?? null,
        completed_at: newStatus === 'completed' ? payload.completed_at as string : prev.completed_at,
      } : null);
    }
    return true;
  };

  // Columns — mirrors RequestsPage, minus สถานะ, plus actions
  const columns = useMemo<GridColDef<StaffRequestRow>[]>(() => [
    {
      field: 'reference_number',
      headerName: 'หมายเลขอ้างอิง',
      flex: 1, minWidth: 120,
    },
    {
      field: 'selected_date',
      headerName: 'วันเดือนปีรับ',
      flex: 1, minWidth: 150,
      renderCell: (params) => {
        const r = params.row as StaffRequestRow;
        const days = getOverdueDays(r.selected_date ?? '', r.request_status);
        const dateFormatted = formatDate(r.selected_date ?? '');
        return (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, height: '100%', width: '100%' }}>
            <Typography variant="body2">{dateFormatted}</Typography>
            {days > 0 && (
              <Tooltip title={`เลยกำหนด ${days} วัน`}>
                <WarningIcon color="error" fontSize="small" sx={{ mt: '-2px' }} />
              </Tooltip>
            )}
          </Box>
        );
      },
    },
    {
      field: 'selected_time',
      headerName: 'เวลารับ',
      flex: 0.8, minWidth: 100,
      valueGetter: (_, r) => `${(r as StaffRequestRow).selected_time ?? '-'} น.`,
    },
    {
      field: 'items',
      headerName: 'รายการ',
      flex: 2, minWidth: 200,
      valueGetter: (_, r) => {
        const row = r as StaffRequestRow;
        const totalCondoms = Object.values(row.condom_quantities ?? {}).reduce((a: number, b: number) => a + b, 0);
        return `ถุงยางอนามัย ${totalCondoms} ชิ้น / สารหล่อลื่น ${row.lubricant_quantity ?? 0} ชิ้น`;
      },
    },
    {
      field: 'actions',
      headerName: '',
      flex: 0.4, minWidth: 60,
      align: 'center', headerAlign: 'center',
      sortable: false, filterable: false, disableColumnMenu: true,
      renderCell: (params) => (
        <Tooltip title="ดูรายละเอียด">
          <IconButton
            size="small"
            onClick={(e) => { e.stopPropagation(); handleOpenReqDetail(params.row as StaffRequestRow); }}
            onMouseDown={(e) => e.stopPropagation()}
            sx={{ color: 'primary.main' }}
          >
            <VisibilityIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      ),
    },
  // eslint-disable-next-line react-hooks/exhaustive-deps
  ], []);

  return (
    <>
      {row && (
        <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
          <DialogTitle sx={{ pb: 1 }}>
            <Typography variant="h6" fontWeight="bold" lineHeight={1.2}>
              {row.first_name} {row.last_name}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {row.service_center}
            </Typography>
          </DialogTitle>

          <DialogContent dividers>
            {/* ── Summary ── */}
            <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap', mb: 3 }}>
              <Box>
                <Typography variant="caption" color="text.secondary">เสร็จสิ้น</Typography>
                <Box mt={0.5}>
                  <Chip label={row.completed_count} size="small" sx={{
                    bgcolor: row.completed_count > 0 ? '#EBF7EC' : '#F5F5F5',
                    color:   row.completed_count > 0 ? '#2E7D32' : '#9E9E9E',
                    fontWeight: 700,
                  }} />
                </Box>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">ยกเลิก</Typography>
                <Box mt={0.5}>
                  <Chip label={row.cancelled_count} size="small" sx={{
                    bgcolor: row.cancelled_count > 0 ? '#FFF0F0' : '#F5F5F5',
                    color:   row.cancelled_count > 0 ? '#C62828' : '#9E9E9E',
                    fontWeight: 700,
                  }} />
                </Box>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">ล่าช้า</Typography>
                <Box mt={0.5}>
                  <Chip label={row.overdue_count} size="small" sx={{
                    bgcolor: row.overdue_count > 0 ? '#FFF8E1' : '#F5F5F5',
                    color:   row.overdue_count > 0 ? '#E65100' : '#9E9E9E',
                    fontWeight: 700,
                  }} />
                </Box>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">เวลาเฉลี่ย</Typography>
                <Box mt={0.5}>
                  <Typography variant="body2" fontWeight={600}
                    color={row.avg_lead_time_minutes == null ? 'text.disabled' : 'text.primary'}>
                    {formatLeadTime(row.avg_lead_time_minutes)}
                  </Typography>
                </Box>
              </Box>
            </Box>

            <Divider sx={{ my: 2 }} />

            {/* ── Trend chart ── */}
            <Typography variant="subtitle1" fontWeight="bold" sx={{ mb: 1 }}>
              จำนวนคำขอที่สำเร็จรายสัปดาห์
            </Typography>
            <StaffWeeklyTrendChart data={trendData} loading={trendLoading} />

            <Divider sx={{ my: 2 }} />

            {/* ── Request list ── */}
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1.5, flexWrap: 'wrap', gap: 1 }}>
              <Typography variant="subtitle1" fontWeight="bold">รายการคำขอ</Typography>
              <Stack direction="row" spacing={0.75}>
                {(Object.entries(FILTER_CONFIG) as [ReqFilter, typeof FILTER_CONFIG[ReqFilter]][]).map(([key, cfg]) => {
                  const active = reqFilter === key;
                  return (
                    <Chip
                      key={key}
                      label={cfg.label}
                      size="small"
                      onClick={() => setReqFilter(key)}
                      sx={{
                        fontWeight: active ? 700 : 400,
                        bgcolor: active ? cfg.bg : 'transparent',
                        color: active ? cfg.color : 'text.secondary',
                        border: '1px solid',
                        borderColor: active ? cfg.border : 'divider',
                        cursor: 'pointer',
                        '&:hover': { bgcolor: active ? cfg.bg : 'action.hover' },
                      }}
                    />
                  );
                })}
              </Stack>
            </Box>

            <Box sx={{ height: 340 }}>
              <DataGrid
                rows={filteredRequests}
                columns={columns}
                getRowId={(r) => r.id}
                loading={reqLoading}
                localeText={thGridLocale}
                initialState={{ pagination: { paginationModel: { pageSize: 10, page: 0 } } }}
                pageSizeOptions={[10, 25]}
                disableRowSelectionOnClick
                sx={{
                  border: 'none',
                  borderRadius: 2,
                  '& .MuiDataGrid-columnHeaders': { bgcolor: 'grey.50' },
                }}
              />
            </Box>
          </DialogContent>

          <DialogActions sx={{ p: 2 }}>
            <Button onClick={onClose} color="inherit">ปิด</Button>
          </DialogActions>
        </Dialog>
      )}

      {/* Nested request detail dialog */}
      <RequestDetailDialog
        open={reqDetailOpen}
        request={selectedReq}
        onClose={() => { setReqDetailOpen(false); refetch(); }}
        onStatusChange={handleStatusChange}
        statusUpdating={statusUpdating}
      />

      <Snackbar
        open={!!statusError}
        autoHideDuration={5000}
        onClose={() => setStatusError(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="error" onClose={() => setStatusError(null)} variant="filled">
          เกิดข้อผิดพลาด: {statusError}
        </Alert>
      </Snackbar>
    </>
  );
}
