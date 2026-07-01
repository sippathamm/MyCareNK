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
import { useConsultations } from '../../hooks/useConsultations';
import { useIsMobile } from '../../hooks/useIsMobile';
import MobileListCard from '../../components/shared/MobileListCard';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useServiceCenterFilter } from '../../contexts/ServiceCenterFilterContext';
import { supabase } from '../../lib/supabase';
import { createThGridLocale } from '../../constants/datagrid';
import ConsultationDetailDialog, { REASON_LABELS } from '../../components/consultations/ConsultationDetailDialog';
import { useColorMode } from '../../contexts/ThemeContext';
import { getConsultationStatusSx } from '../../utils/statusColors';
import type { ConsultationData } from '../../components/consultations/ConsultationDetailDialog';


const thGridLocale = createThGridLocale('ไม่มีรายการนัดรับคำปรึกษา');

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString('th-TH', {
    day: 'numeric', month: 'short', year: 'numeric',
  });
}

const CONSULTATION_STATUS_LABELS: Record<string, string> = {
  pending:            'รอยืนยัน',
  confirmed:          'ยืนยันแล้ว',
  completed:          'เสร็จสิ้น',
  cancelled_by_user:  'ยกเลิกโดยผู้ใช้',
  cancelled_by_staff: 'ยกเลิกโดยเจ้าหน้าที่',
};

export default function ConsultationsPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const { consultations, setConsultations, loading } = useConsultations();
  const isMobile = useIsMobile();
  const { role, loading: roleLoading } = useRoleAccess();
  const { selectedServiceCenter } = useServiceCenterFilter();
  const { mode } = useColorMode();

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedConsultation, setSelectedConsultation] = useState<ConsultationData | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [statusUpdating, setStatusUpdating] = useState(false);
  const [updateError, setUpdateError] = useState<string | null>(null);

  // Open detail dialog when navigated from a notification
  const openConsultationId = (location.state as { openConsultationId?: string } | null)?.openConsultationId;
  useEffect(() => {
    if (loading || !openConsultationId) return;
    const apt = consultations.find(a => a.id === openConsultationId);
    if (apt) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setSelectedConsultation(apt);
      setDialogOpen(true);
      navigate(location.pathname, { replace: true, state: null });
    }
  }, [loading, openConsultationId, consultations, navigate, location.pathname]);

  const handleOpenDialog = (apt: ConsultationData) => {
    setSelectedConsultation(apt);
    setDialogOpen(true);
  };

  const handleStatusChange = async (id: string, newStatus: string, reason?: string): Promise<boolean> => {
    const consultation_status = newStatus as ConsultationData['consultation_status'];

    const prevConsultations = consultations;
    const prevSelected = selectedConsultation;
    setConsultations(prev => prev.map(a => a.id === id ? { ...a, consultation_status, cancel_reason: reason ?? null } : a));
    if (selectedConsultation?.id === id) {
      setSelectedConsultation({ ...selectedConsultation, consultation_status, cancel_reason: reason ?? null });
    }

    setStatusUpdating(true);
    setUpdateError(null);

    const updatePayload: { consultation_status: ConsultationData['consultation_status']; cancel_reason?: string | null } = {
      consultation_status: newStatus as ConsultationData['consultation_status'],
    };
    if (reason !== undefined) {
      updatePayload.cancel_reason = reason;
    } else {
      updatePayload.cancel_reason = null;
    }

    const { error } = await supabase.from('consultations').update(updatePayload).eq('id', id);
    setStatusUpdating(false);

    if (error) {
      setConsultations(prevConsultations);
      setSelectedConsultation(prevSelected);
      setUpdateError(error.message);
      return false;
    }
    return true;
  };

  const filteredConsultations = consultations.filter(a => {
    const matchSearch = a.reference_number.toLowerCase().includes(search.toLowerCase());
    const matchStatus = statusFilter === 'all'
      || a.consultation_status === statusFilter
      || (statusFilter === 'cancelled' && (a.consultation_status === 'cancelled_by_user' || a.consultation_status === 'cancelled_by_staff'));
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
          <Typography variant="body2">{formatDate((params.row as ConsultationData).selected_date)}</Typography>
        </Box>
      ),
    },
    {
      field: 'selected_time',
      headerName: 'เวลา',
      flex: 0.7,
      minWidth: 90,
      valueGetter: (_, row) => `${(row as ConsultationData).selected_time?.slice(0, 5) ?? '-'} น.`,
    },
    {
      field: 'reason',
      headerName: 'เรื่อง',
      flex: 2,
      minWidth: 160,
      valueGetter: (_, row) => REASON_LABELS[(row as ConsultationData).reason] ?? (row as ConsultationData).reason,
    },
    {
      field: 'consultation_status',
      headerName: 'สถานะ',
      flex: 1,
      minWidth: 140,
      renderCell: (params) => {
        const s = (params.row as ConsultationData).consultation_status;
        return <Chip label={CONSULTATION_STATUS_LABELS[s] ?? s} size="small" sx={getConsultationStatusSx(s, mode)} />;
      },
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
          onClick={() => handleOpenDialog(params.row as ConsultationData)}
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
        รายการนัดรับคำปรึกษา
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        จัดการรายการนัดรับคำปรึกษา
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

        {!loading && !roleLoading && role === 'staff' && consultations.length === 0 ? (
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
            <Typography variant="body1" fontWeight={500}>ไม่มีรายการนัดรับคำปรึกษาในสถานบริการของคุณ</Typography>
          </Box>
        ) : isMobile ? (
          filteredConsultations.length === 0 ? (
            <Box sx={{ py: 6, textAlign: 'center', color: 'text.disabled' }}>
              <InboxIcon sx={{ fontSize: 40, mb: 1 }} />
              <Typography variant="body2">ไม่มีรายการนัดรับคำปรึกษา</Typography>
            </Box>
          ) : (
            <Stack spacing={1.5}>
              {filteredConsultations.map((a) => (
                <MobileListCard
                  key={a.id}
                  title={REASON_LABELS[a.reason] ?? a.reason}
                  statusChip={
                    <Chip
                      label={CONSULTATION_STATUS_LABELS[a.consultation_status] ?? a.consultation_status}
                      size="small"
                      sx={getConsultationStatusSx(a.consultation_status, mode)}
                    />
                  }
                  onClick={() => handleOpenDialog(a)}
                  meta={
                    <>
                      <Typography variant="body2" color="text.secondary">
                        {a.reference_number}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {formatDate(a.selected_date)} · {a.selected_time?.slice(0, 5) ?? '-'} น.
                      </Typography>
                    </>
                  }
                />
              ))}
            </Stack>
          )
        ) : (
          <Box sx={{ height: 500, width: '100%' }}>
            <DataGrid
              rows={filteredConsultations}
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
                '& .MuiDataGrid-columnHeaders': { bgcolor: 'action.hover' },
                '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
              }}
            />
          </Box>
        )}
      </Paper>

      <ConsultationDetailDialog
        open={dialogOpen}
        consultation={selectedConsultation}
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
