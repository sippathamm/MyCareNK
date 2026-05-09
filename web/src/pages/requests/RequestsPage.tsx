import { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Box, Typography, Paper, Chip, IconButton, TextField, MenuItem, Stack, Tooltip, Snackbar, Alert } from '@mui/material';
import WarningIcon from '@mui/icons-material/Warning';
import InboxIcon from '@mui/icons-material/Inbox';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import RequestDetailDialog from '../../components/requests/RequestDetailDialog';
import type { RequestData } from '../../components/requests/RequestDetailDialog';
import VisibilityIcon from '@mui/icons-material/Visibility';
import { formatDate, getOverdueDays } from '../../utils/requestUtils';
import { useRequests } from '../../hooks/useRequests';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { supabase } from '../../lib/supabase';
import { createThGridLocale } from '../../constants/datagrid';

const SERVICE_CENTERS = ['รพ.โพนพิสัย', 'รพ.สต.วัดหลวง', 'อบต.วัดหลวง', 'สสจ.หนองคาย'] as const;

const thGridLocale = createThGridLocale('ไม่มีรายการคำขอ');

export default function RequestsPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const { requests, setRequests, loading } = useRequests();
  const { role, loading: roleLoading } = useRoleAccess();
  const isAdminOrSuperadmin = role === 'admin' || role === 'superadmin';
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [serviceCenterFilter, setServiceCenterFilter] = useState('all');
  const [selectedRequest, setSelectedRequest] = useState<RequestData | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [statusUpdating, setStatusUpdating] = useState(false);
  const [updateError, setUpdateError] = useState<string | null>(null);

  // Open detail dialog when navigated here from a notification
  const openRequestId = (location.state as { openRequestId?: string } | null)?.openRequestId;
  useEffect(() => {
    if (loading || !openRequestId) return;
    const req = requests.find(r => r.id === openRequestId);
    if (req) {
      setSelectedRequest(req);
      setDialogOpen(true);
      navigate(location.pathname, { replace: true, state: null });
    }
  }, [loading, openRequestId, requests, navigate, location.pathname]);

  const getStatusChip = (status: string) => {
    switch (status) {
      case 'pending': return <Chip label="รอดำเนินการ" color="warning" size="small" sx={{ fontWeight: 'bold' }} />;
      case 'preparing': return <Chip label="กำลังเตรียม" color="info" size="small" sx={{ fontWeight: 'bold' }} />;
      case 'ready': return <Chip label="รอรับ" color="secondary" size="small" sx={{ fontWeight: 'bold' }} />;
      case 'completed': return <Chip label="เสร็จสิ้น" color="success" size="small" sx={{ fontWeight: 'bold' }} />;
      case 'cancelled_by_user': return <Chip label="ยกเลิกโดยผู้ใช้" size="small" sx={{ bgcolor: 'grey.200', color: 'text.secondary', fontWeight: 'bold' }} />;
      case 'cancelled_by_staff': return <Chip label="ยกเลิกโดยเจ้าหน้าที่" size="small" sx={{ bgcolor: 'grey.200', color: 'text.secondary', fontWeight: 'bold' }} />;
      default: return <Chip label={status} size="small" />;
    }
  };

  const handleOpenDialog = (req: RequestData) => {
    setSelectedRequest(req);
    setDialogOpen(true);
  };

  const handleStatusChange = async (id: string, newStatus: string, reason?: string): Promise<boolean> => {
    const request_status = newStatus as RequestData['request_status'];

    // Optimistic update
    const prevRequests = requests;
    const prevSelected = selectedRequest;
    setRequests(prev => prev.map(r => r.id === id ? { ...r, request_status, cancel_reason: reason ?? null } : r));
    if (selectedRequest?.id === id) {
      setSelectedRequest({ ...selectedRequest, request_status, cancel_reason: reason ?? null });
    }

    setStatusUpdating(true);
    setUpdateError(null);

    const updatePayload: { request_status: RequestData['request_status']; cancel_reason?: string | null } = { request_status: newStatus as RequestData['request_status'] };
    if (reason !== undefined) {
      updatePayload.cancel_reason = reason;
    } else {
      updatePayload.cancel_reason = null;
    }

    const { error } = await supabase.from('condom_requests').update(updatePayload).eq('id', id);
    setStatusUpdating(false);

    if (error) {
      setRequests(prevRequests);
      setSelectedRequest(prevSelected);
      setUpdateError(error.message);
      return false;
    }
    return true;
  };

  const filteredRequests = requests.filter(r => {
    const matchSearch = r.reference_number.toLowerCase().includes(search.toLowerCase());
    const matchStatus = statusFilter === 'all'
      || r.request_status === statusFilter
      || (statusFilter === 'cancelled' && (r.request_status === 'cancelled_by_user' || r.request_status === 'cancelled_by_staff'));
    const matchServiceCenter = !isAdminOrSuperadmin || serviceCenterFilter === 'all'
      || r.selected_service_center === serviceCenterFilter;
    return matchSearch && matchStatus && matchServiceCenter;
  });

  const columns: GridColDef[] = [
    { field: 'reference_number', headerName: 'รหัสอ้างอิง', flex: 1, minWidth: 120 },
    {
      field: 'selected_date',
      headerName: 'วันเดือนปีรับ',
      flex: 1,
      minWidth: 150,
      renderCell: (params) => {
        const row = params.row as RequestData;
        const days = getOverdueDays(row.selected_date ?? '', row.request_status);
        const dateFormatted = formatDate(row.selected_date ?? '');
        if (days > 0) {
          return (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, height: '100%', width: '100%' }}>
              <Typography variant="body2">{dateFormatted}</Typography>
              <Tooltip title={`เลยกำหนด ${days} วัน`}>
                <WarningIcon color="error" fontSize="small" sx={{ mt: '-2px' }} />
              </Tooltip>
            </Box>
          );
        }
        return (
          <Box sx={{ display: 'flex', alignItems: 'center', height: '100%', width: '100%' }}>
            <Typography variant="body2">{dateFormatted}</Typography>
          </Box>
        );
      }
    },
    {
      field: 'selected_time',
      headerName: 'เวลารับ',
      flex: 0.8,
      minWidth: 100,
      valueGetter: (_, row) => `${(row as RequestData).selected_time ?? '-'} น.`
    },
    {
      field: 'items',
      headerName: 'รายการ',
      flex: 2,
      minWidth: 200,
      valueGetter: (_, row) => {
        const r = row as RequestData;
        const totalCondoms = Object.values(r.condom_quantities as Record<string, number>).reduce((a, b) => a + b, 0);
        return `ถุงยางอนามัย ${totalCondoms} ชิ้น / เจลหล่อลื่น ${r.lubricant_quantity} ชิ้น`;
      }
    },
    {
      field: 'request_status',
      headerName: 'สถานะ',
      flex: 1,
      minWidth: 120,
      renderCell: (params) => getStatusChip(params.value)
    },
    {
      field: 'actions',
      headerName: '',
      flex: 0.4,
      minWidth: 60,
      align: 'center',
      headerAlign: 'center',
      sortable: false,
      filterable: false,
      disableColumnMenu: true,
      renderCell: (params) => (
        <Tooltip title="ดูรายละเอียด">
          <IconButton
            size="small"
            onClick={() => handleOpenDialog(params.row as RequestData)}
            sx={{ color: 'primary.main' }}
          >
            <VisibilityIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      )
    }
  ];

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Typography variant="h5" fontWeight="bold" gutterBottom>
        รายการคำขอ
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        จัดการรายการคำขอ
      </Typography>

      <Paper elevation={1} sx={{ p: 3, mb: 4, borderRadius: 2 }}>
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ mb: 3 }}>
          <TextField
            label="ค้นหารหัสอ้างอิง"
            variant="outlined"
            size="small"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            sx={{ flexGrow: 1 }}
          />
          {isAdminOrSuperadmin && (
            <TextField
              select
              label="สถานบริการ"
              size="small"
              value={serviceCenterFilter}
              onChange={(e) => setServiceCenterFilter(e.target.value)}
              sx={{ minWidth: 200 }}
            >
              <MenuItem value="all">ทั้งหมด</MenuItem>
              {SERVICE_CENTERS.map(sc => (
                <MenuItem key={sc} value={sc}>{sc}</MenuItem>
              ))}
            </TextField>
          )}
          <TextField
            select
            label="สถานะ"
            size="small"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            sx={{ minWidth: 200 }}
          >
            <MenuItem value="all">ทั้งหมด</MenuItem>
            <MenuItem value="pending">รอดำเนินการ</MenuItem>
            <MenuItem value="preparing">กำลังเตรียม</MenuItem>
            <MenuItem value="ready">รอรับ</MenuItem>
            <MenuItem value="completed">เสร็จสิ้น</MenuItem>
            <MenuItem value="cancelled">ยกเลิก</MenuItem>
          </TextField>
        </Stack>

        {!loading && !roleLoading && role === 'staff' && requests.length === 0 ? (
          <Box
            sx={{
              height: 500,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 1.5,
              color: 'text.disabled',
            }}
          >
            <InboxIcon sx={{ fontSize: 48 }} />
            <Typography variant="body1" fontWeight={500}>ไม่มีคำขอในสถานบริการของคุณ</Typography>
          </Box>
        ) : (
          <Box sx={{ height: 500, width: '100%' }}>
            <DataGrid
              rows={filteredRequests}
              columns={columns}
              loading={loading || roleLoading}
              localeText={thGridLocale}
              initialState={{
                pagination: {
                  paginationModel: { pageSize: 10, page: 0 },
                },
              }}
              pageSizeOptions={[10, 25, 50]}
              disableRowSelectionOnClick
            />
          </Box>
        )}
      </Paper>

      <RequestDetailDialog
        open={dialogOpen}
        request={selectedRequest}
        onClose={() => setDialogOpen(false)}
        onStatusChange={handleStatusChange}
        statusUpdating={statusUpdating}
      />

      <Snackbar
        open={!!updateError}
        autoHideDuration={5000}
        onClose={() => setUpdateError(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="error" onClose={() => setUpdateError(null)} variant="filled">
          เกิดข้อผิดพลาด: {updateError}
        </Alert>
      </Snackbar>
    </Box>
  );
}
