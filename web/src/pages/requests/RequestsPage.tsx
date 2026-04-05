import { useState } from 'react';
import { Box, Typography, Paper, Chip, Button, TextField, MenuItem, Stack, Tooltip } from '@mui/material';
import WarningIcon from '@mui/icons-material/Warning';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import RequestDetailDialog from '../../components/requests/RequestDetailDialog';
import type { RequestData } from '../../components/requests/RequestDetailDialog';
import VisibilityIcon from '@mui/icons-material/Visibility';
import { formatDate, getOverdueDays } from '../../utils/requestUtils';

// Mock Data
const mockRequests: RequestData[] = [
  {
    id: 'req-1',
    reference_number: 'AB12CD34',
    selected_date: '2026-04-02',
    selected_time: '10:00',
    selected_location: 'ศูนย์บริการ A',
    condom_quantities: { '52': 4, '56': 2 },
    lubricant_quantity: 4,
    status: 'pending',
    message: 'รบกวนขอกล่องเปล่าไม่ระบุชื่อ',
    created_at: '10 เม.ย. 2569 เวลา 08:30 น.',
  },
  {
    id: 'req-2',
    reference_number: 'E5F6G7H8',
    selected_date: '2026-04-10',
    selected_time: '13:30',
    selected_location: 'ศูนย์บริการ A',
    condom_quantities: { '49': 10 },
    lubricant_quantity: 2,
    status: 'preparing',
    created_at: '09 เม.ย. 2569 เวลา 16:20 น.',
  },
  {
    id: 'req-3',
    reference_number: 'XY98UV76',
    selected_date: '2026-04-09',
    selected_time: '09:00',
    selected_location: 'ศูนย์บริการ A',
    condom_quantities: { '56': 6 },
    lubricant_quantity: 3,
    status: 'completed',
    created_at: '08 เม.ย. 2569 เวลา 11:15 น.',
  },
  {
    id: 'req-4',
    reference_number: 'ZX12CV34',
    selected_date: '2026-04-08',
    selected_time: '14:00',
    selected_location: 'ศูนย์บริการ A',
    condom_quantities: { '52': 5 },
    lubricant_quantity: 5,
    status: 'cancelled',
    created_at: '07 เม.ย. 2569 เวลา 09:45 น.',
  },
];

const thGridLocale = {
  noRowsLabel: 'ไม่มีข้อมูลคำขอ',
  noResultsOverlayLabel: 'ไม่พบข้อมูล',
  footerRowSelected: (count: number) => `เลือกแล้ว ${count} แถว`,
  MuiTablePagination: {
    labelRowsPerPage: 'จำนวนต่อหน้า:',
    labelDisplayedRows: ({ from, to, count }: { from: number; to: number; count: number }) =>
      `${from} - ${to} จาก ${count !== -1 ? count : `มากกว่า ${to}`}`,
  },
};

export default function RequestsPage() {
  const [requests, setRequests] = useState<RequestData[]>(mockRequests);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedRequest, setSelectedRequest] = useState<RequestData | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);

  const getStatusChip = (status: string) => {
    switch (status) {
      case 'pending': return <Chip label="รอดำเนินการ" color="warning" size="small" sx={{ fontWeight: 'bold' }} />;
      case 'preparing': return <Chip label="กำลังเตรียม" color="info" size="small" sx={{ fontWeight: 'bold' }} />;
      case 'ready': return <Chip label="รอรับ" color="secondary" size="small" sx={{ fontWeight: 'bold' }} />;
      case 'completed': return <Chip label="เสร็จสิ้น" color="success" size="small" sx={{ fontWeight: 'bold' }} />;
      case 'cancelled': return <Chip label="ยกเลิก" size="small" sx={{ bgcolor: '#E0E0E0', color: '#616161', fontWeight: 'bold' }} />;
      default: return <Chip label={status} size="small" />;
    }
  };

  const handleOpenDialog = (req: RequestData) => {
    setSelectedRequest(req);
    setDialogOpen(true);
  };

  const handleStatusChange = (id: string, newStatus: string, reason?: string) => {
    const status = newStatus as RequestData['status'];
    setRequests(prev => prev.map(r => r.id === id ? { ...r, status, cancel_reason: reason } : r));
    if (selectedRequest?.id === id) {
      setSelectedRequest({ ...selectedRequest, status, cancel_reason: reason });
    }
  };

  const filteredRequests = requests.filter(r => {
    const matchSearch = r.reference_number.toLowerCase().includes(search.toLowerCase());
    const matchStatus = statusFilter === 'all' || r.status === statusFilter;
    return matchSearch && matchStatus;
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
        const days = getOverdueDays(row.selected_date, row.status);
        const dateFormatted = formatDate(row.selected_date);
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
      valueGetter: (_, row) => `${(row as RequestData).selected_time} น.`
    },
    {
      field: 'items',
      headerName: 'รายการ',
      flex: 2,
      minWidth: 200,
      valueGetter: (_, row) => {
        const r = row as RequestData;
        const totalCondoms = Object.values(r.condom_quantities).reduce((a, b) => a + b, 0);
        return `ถุงยางอนามัย ${totalCondoms} ชิ้น / สารหล่อลื่น ${r.lubricant_quantity} ชิ้น`;
      }
    },
    {
      field: 'status',
      headerName: 'สถานะ',
      flex: 1,
      minWidth: 120,
      renderCell: (params) => getStatusChip(params.value)
    },
    {
      field: 'actions',
      headerName: '',
      flex: 1,
      minWidth: 120,
      align: 'center',
      headerAlign: 'center',
      sortable: false,
      filterable: false,
      disableColumnMenu: true,
      renderCell: (params) => (
        <Button
          variant="contained"
          color="primary"
          size="small"
          startIcon={<VisibilityIcon />}
          onClick={() => handleOpenDialog(params.row as RequestData)}
        >
          ดูรายละเอียด
        </Button>
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

      <Paper sx={{ p: 3, mb: 4, borderRadius: 3, boxShadow: 2 }}>
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
            label="คัดกรองตามสถานะ"
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

        <Box sx={{ height: 500, width: '100%' }}>
          <DataGrid
            rows={filteredRequests}
            columns={columns}
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
      </Paper>

      <RequestDetailDialog
        open={dialogOpen}
        request={selectedRequest}
        onClose={() => setDialogOpen(false)}
        onStatusChange={handleStatusChange}
      />
    </Box>
  );
}
