import { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import {
  Box, Typography, Paper, Chip, IconButton,
  TextField, MenuItem, Stack, Snackbar, Alert,
} from '@mui/material';
import InboxIcon from '@mui/icons-material/Inbox';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import VisibilityIcon from '@mui/icons-material/Visibility';
import { useAppointments } from '../../hooks/useAppointments';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useServiceCenterFilter } from '../../contexts/ServiceCenterFilterContext';
import { supabase } from '../../lib/supabase';
import { createThGridLocale } from '../../constants/datagrid';
import AppointmentDetailDialog, { REASON_LABELS } from '../../components/appointments/AppointmentDetailDialog';
import type { AppointmentData } from '../../components/appointments/AppointmentDetailDialog';
import type { Enums } from '../../lib/database.types';

const thGridLocale = createThGridLocale('ไม่มีรายการนัดหมาย');

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString('th-TH', {
    day: 'numeric', month: 'short', year: 'numeric',
  });
}

function getStatusChip(status: Enums<'appointment_status'>) {
  switch (status) {
    case 'pending':           return <Chip label="รอยืนยัน"            size="small" sx={{ bgcolor: '#FFF3E0', color: '#E65100', fontWeight: 600 }} />;
    case 'confirmed':         return <Chip label="ยืนยันแล้ว"           size="small" sx={{ bgcolor: '#F3E5F5', color: '#7B1FA2', fontWeight: 600 }} />;
    case 'completed':         return <Chip label="เสร็จสิ้น"            size="small" sx={{ bgcolor: '#E8F5E9', color: '#2E7D32', fontWeight: 600 }} />;
    case 'cancelled_by_user': return <Chip label="ยกเลิกโดยผู้ใช้"      size="small" sx={{ bgcolor: '#F5F5F5', color: '#616161', fontWeight: 600 }} />;
    case 'cancelled_by_staff':return <Chip label="ยกเลิกโดยเจ้าหน้าที่" size="small" sx={{ bgcolor: '#F5F5F5', color: '#616161', fontWeight: 600 }} />;
    default:                  return <Chip label={status} size="small" />;
  }
}

export default function AppointmentsPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const { appointments, setAppointments, loading } = useAppointments();
  const { role, loading: roleLoading } = useRoleAccess();
  const { selectedServiceCenter } = useServiceCenterFilter();

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedAppointment, setSelectedAppointment] = useState<AppointmentData | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [statusUpdating, setStatusUpdating] = useState(false);
  const [updateError, setUpdateError] = useState<string | null>(null);

  // Open detail dialog when navigated from a notification
  const openAppointmentId = (location.state as { openAppointmentId?: string } | null)?.openAppointmentId;
  useEffect(() => {
    if (loading || !openAppointmentId) return;
    const apt = appointments.find(a => a.id === openAppointmentId);
    if (apt) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setSelectedAppointment(apt);
      setDialogOpen(true);
      navigate(location.pathname, { replace: true, state: null });
    }
  }, [loading, openAppointmentId, appointments, navigate, location.pathname]);

  const handleOpenDialog = (apt: AppointmentData) => {
    setSelectedAppointment(apt);
    setDialogOpen(true);
  };

  const handleStatusChange = async (id: string, newStatus: string, reason?: string): Promise<boolean> => {
    const appointment_status = newStatus as AppointmentData['appointment_status'];

    const prevAppointments = appointments;
    const prevSelected = selectedAppointment;
    setAppointments(prev => prev.map(a => a.id === id ? { ...a, appointment_status, cancel_reason: reason ?? null } : a));
    if (selectedAppointment?.id === id) {
      setSelectedAppointment({ ...selectedAppointment, appointment_status, cancel_reason: reason ?? null });
    }

    setStatusUpdating(true);
    setUpdateError(null);

    const updatePayload: { appointment_status: AppointmentData['appointment_status']; cancel_reason?: string | null } = {
      appointment_status: newStatus as AppointmentData['appointment_status'],
    };
    if (reason !== undefined) {
      updatePayload.cancel_reason = reason;
    } else {
      updatePayload.cancel_reason = null;
    }

    const { error } = await supabase.from('doctor_appointments').update(updatePayload).eq('id', id);
    setStatusUpdating(false);

    if (error) {
      setAppointments(prevAppointments);
      setSelectedAppointment(prevSelected);
      setUpdateError(error.message);
      return false;
    }
    return true;
  };

  const filteredAppointments = appointments.filter(a => {
    const matchSearch = a.reference_number.toLowerCase().includes(search.toLowerCase());
    const matchStatus = statusFilter === 'all'
      || a.appointment_status === statusFilter
      || (statusFilter === 'cancelled' && (a.appointment_status === 'cancelled_by_user' || a.appointment_status === 'cancelled_by_staff'));
    const matchServiceCenter = selectedServiceCenter === null || a.selected_service_center === selectedServiceCenter;
    return matchSearch && matchStatus && matchServiceCenter;
  });

  const columns: GridColDef[] = [
    { field: 'reference_number', headerName: 'รหัสอ้างอิง', flex: 1, minWidth: 140 },
    {
      field: 'selected_date',
      headerName: 'วัน',
      flex: 1,
      minWidth: 140,
      renderCell: (params) => (
        <Box sx={{ display: 'flex', alignItems: 'center', height: '100%' }}>
          <Typography variant="body2">{formatDate((params.row as AppointmentData).selected_date)}</Typography>
        </Box>
      ),
    },
    {
      field: 'selected_time',
      headerName: 'เวลา',
      flex: 0.7,
      minWidth: 90,
      valueGetter: (_, row) => `${(row as AppointmentData).selected_time?.slice(0, 5) ?? '-'} น.`,
    },
    {
      field: 'reason',
      headerName: 'เรื่อง',
      flex: 2,
      minWidth: 160,
      valueGetter: (_, row) => REASON_LABELS[(row as AppointmentData).reason] ?? (row as AppointmentData).reason,
    },
    {
      field: 'appointment_status',
      headerName: 'สถานะ',
      flex: 1,
      minWidth: 140,
      renderCell: (params) => getStatusChip((params.row as AppointmentData).appointment_status),
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
        <IconButton
          size="small"
          onClick={() => handleOpenDialog(params.row as AppointmentData)}
          sx={{ color: 'primary.main' }}
          title="ดูรายละเอียด"
        >
          <VisibilityIcon fontSize="small" />
        </IconButton>
      ),
    },
  ];

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Typography variant="h5" fontWeight="bold" gutterBottom>
        รายการนัดหมาย
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        จัดการรายการนัดหมายรับคำปรึกษา
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
          <TextField
            select
            label="สถานะ"
            size="small"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            sx={{ minWidth: 200 }}
          >
            <MenuItem value="all">ทั้งหมด</MenuItem>
            <MenuItem value="pending">รอยืนยัน</MenuItem>
            <MenuItem value="confirmed">ยืนยันแล้ว</MenuItem>
            <MenuItem value="completed">เสร็จสิ้น</MenuItem>
            <MenuItem value="cancelled">ยกเลิก</MenuItem>
          </TextField>
        </Stack>

        {!loading && !roleLoading && role === 'staff' && appointments.length === 0 ? (
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
            <Typography variant="body1" fontWeight={500}>ไม่มีนัดหมายในสถานบริการของคุณ</Typography>
          </Box>
        ) : (
          <Box sx={{ height: 500, width: '100%' }}>
            <DataGrid
              rows={filteredAppointments}
              columns={columns}
              loading={loading || roleLoading}
              localeText={thGridLocale}
              initialState={{
                pagination: { paginationModel: { pageSize: 10, page: 0 } },
              }}
              pageSizeOptions={[10, 25, 50]}
              disableRowSelectionOnClick
              sx={{
                border: 'none',
                '& .MuiDataGrid-columnHeaders': { bgcolor: 'grey.50' },
                '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
              }}
            />
          </Box>
        )}
      </Paper>

      <AppointmentDetailDialog
        open={dialogOpen}
        appointment={selectedAppointment}
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
