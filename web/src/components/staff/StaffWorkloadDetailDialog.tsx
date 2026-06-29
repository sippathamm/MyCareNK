import { useState, useEffect, useMemo } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions, Button,
  Typography, Box, Divider, Chip, Stack,
  Tooltip, IconButton, Snackbar, Alert,
} from '@mui/material';
import VisibilityIcon from '@mui/icons-material/Visibility';
import WarningIcon from '@mui/icons-material/Warning';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import { useStaffWorkloadTrend } from '../../hooks/useStaffWorkloadTrend';
import { useColorMode } from '../../contexts/ThemeContext';
import { getWorkloadChipSx } from '../../utils/statusColors';
import { useStaffRequests, type StaffRequestRow } from '../../hooks/useStaffRequests';
import RequestDetailDialog, { type RequestData } from '../requests/RequestDetailDialog';
import StaffWeeklyTrendChart from './StaffWeeklyTrendChart';
import { formatLeadTime } from '../../utils/staffWorkloadUtils';
import { formatDate, getOverdueDays } from '../../utils/requestUtils';
import { supabase } from '../../lib/supabase';
import type { EnrichedRow } from '../../hooks/useStaffWorkload';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function isOverdue(r: { is_delay: boolean }): boolean {
  return r.is_delay;
}

function toRequestData(r: StaffRequestRow): RequestData {
  return r as unknown as RequestData;
}

type ReqFilter = 'all' | 'completed' | 'cancelled' | 'overdue';

const FILTER_LABELS: Record<ReqFilter, string> = {
  all:       'ทั้งหมด',
  completed: 'เสร็จสิ้น',
  cancelled: 'ยกเลิก',
  overdue:   'ล่าช้า',
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
  const { mode } = useColorMode();
  const staffId = row?.staff_user_id ?? null;

  const [reqFilter, setReqFilter]             = useState<ReqFilter>('all');
  const [selectedReq, setSelectedReq]         = useState<RequestData | null>(null);
  const [reqDetailOpen, setReqDetailOpen]     = useState(false);
  const [statusUpdating, setStatusUpdating]   = useState(false);
  const [statusError, setStatusError]         = useState<string | null>(null);

  useEffect(() => {
    if (!open) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setReqFilter('all');
      setSelectedReq(null);
      setReqDetailOpen(false);
    }
  }, [open]);

  const { data: trendData, loading: trendLoading, error: trendError } = useStaffWorkloadTrend(
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

    setStatusUpdating(true);
    setStatusError(null);
    const { error } = await supabase.from('condom_requests').update(payload).eq('id', id);
    setStatusUpdating(false);

    if (error) { setStatusError(error.message); return false; }

    // Update local list + open dialog state
    setRequests(prev => prev.map(r =>
      r.id === id ? { ...r, request_status: newStatus, cancel_reason: reason ?? null } : r,
    ));
    if (selectedReq?.id === id) {
      setSelectedReq(prev => prev ? { ...prev,
        request_status: newStatus as RequestData['request_status'],
        cancel_reason: reason ?? null,
      } : null);
    }
    return true;
  };

  // Columns — mirrors RequestsPage, minus สถานะ, plus actions
  const columns = useMemo<GridColDef<StaffRequestRow>[]>(() => [
    {
      field: 'reference_number',
      headerName: 'รหัสอ้างอิง',
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
        return `ถุงยางอนามัย ${totalCondoms} ชิ้น / เจลหล่อลื่น ${row.lubricant_quantity ?? 0} ชิ้น`;
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
  ], []);

  return (
    <>
      {row && (
        <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
          <DialogTitle sx={{ pb: 1 }}>
            <Typography component="div" variant="h6" fontWeight="bold" lineHeight={1.2}>
              {row.first_name} {row.last_name}
            </Typography>
            <Typography component="div" variant="caption" color="text.secondary">
              {row.service_center}
            </Typography>
          </DialogTitle>

          <DialogContent dividers>
            {/* ── Summary ── */}
            <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap', mb: 3 }}>
              <Box>
                <Typography variant="caption" color="text.secondary">เสร็จสิ้น</Typography>
                <Box mt={0.5}>
                  <Chip label={row.completed_count} size="small" sx={{ ...getWorkloadChipSx('completed', row.completed_count, mode), fontWeight: 700 }} />
                </Box>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">ยกเลิก</Typography>
                <Box mt={0.5}>
                  <Chip label={row.cancelled_count} size="small" sx={{ ...getWorkloadChipSx('cancelled', row.cancelled_count, mode), fontWeight: 700 }} />
                </Box>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">ล่าช้า</Typography>
                <Box mt={0.5}>
                  <Chip label={row.overdue_count} size="small" sx={{ ...getWorkloadChipSx('overdue', row.overdue_count, mode), fontWeight: 700 }} />
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
            <StaffWeeklyTrendChart data={trendData} loading={trendLoading} error={trendError} />

            <Divider sx={{ my: 2 }} />

            {/* ── Request list ── */}
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1.5, flexWrap: 'wrap', gap: 1 }}>
              <Typography variant="subtitle1" fontWeight="bold">รายการคำขอ</Typography>
              <Stack direction="row" spacing={1} flexWrap="wrap">
                {(Object.entries(FILTER_LABELS) as [ReqFilter, string][]).map(([key, label]) => {
                  const active = reqFilter === key;
                  return (
                    <Chip
                      key={key}
                      label={label}
                      onClick={() => setReqFilter(key)}
                      sx={{
                        fontWeight: active ? 700 : 400,
                        bgcolor: active ? '#FF9F6B' : 'transparent',
                        color: active ? 'white' : 'text.secondary',
                        border: '1px solid',
                        borderColor: active ? '#FF9F6B' : 'divider',
                        cursor: 'pointer',
                        '&:hover': { bgcolor: active ? '#FF9F6B' : 'action.hover' },
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
                  '& .MuiDataGrid-columnHeaders': { bgcolor: 'action.hover' },
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
