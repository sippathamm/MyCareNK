import { useMemo, useEffect } from 'react';
import { Box, Typography, Paper, Chip, Tooltip } from '@mui/material';
import InventoryIcon from '@mui/icons-material/Inventory2';
import TuneIcon from '@mui/icons-material/Tune';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import { useRestockHistory } from '../../hooks/useRestockHistory';

const thGridLocale = {
  noRowsLabel: 'ไม่มีประวัติการเติมรายการ',
  noResultsOverlayLabel: 'ไม่พบข้อมูล',
  MuiTablePagination: {
    labelRowsPerPage: 'จำนวนต่อหน้า:',
    labelDisplayedRows: ({ from, to, count }: { from: number; to: number; count: number }) =>
      `${from} - ${to} จาก ${count !== -1 ? count : `มากกว่า ${to}`}`,
  },
};

const THAI_MONTHS = ['ม.ค.','ก.พ.','มี.ค.','เม.ย.','พ.ค.','มิ.ย.','ก.ค.','ส.ค.','ก.ย.','ต.ค.','พ.ย.','ธ.ค.'];

function formatDateTime(iso: string): string {
  const d = new Date(iso);
  const day = d.getDate();
  const month = THAI_MONTHS[d.getMonth()];
  const year = d.getFullYear() + 543;
  const h = String(d.getHours()).padStart(2, '0');
  const min = String(d.getMinutes()).padStart(2, '0');
  return `${day} ${month} ${year} เวลา ${h}:${min} น.`;
}

function QtyChip({ value }: { value: number }) {
  if (value === 0) return <Typography variant="body2" color="text.disabled">—</Typography>;
  const isPositive = value > 0;
  return (
    <Chip
      label={`${isPositive ? '+' : ''}${value.toLocaleString()}`}
      size="small"
      sx={{
        bgcolor: isPositive ? '#EBF7EC' : '#FFF0F0',
        color: isPositive ? '#2E7D32' : '#C62828',
        fontWeight: 600,
        fontSize: '0.78rem',
      }}
    />
  );
}

function TypeChip({ type }: { type: 'restock' | 'adjustment' }) {
  return type === 'restock' ? (
    <Chip
      icon={<InventoryIcon sx={{ fontSize: '0.85rem !important' }} />}
      label="เติมรายการ"
      size="small"
      sx={{ bgcolor: '#EBF4FF', color: '#1565C0', fontWeight: 600, fontSize: '0.75rem' }}
    />
  ) : (
    <Chip
      icon={<TuneIcon sx={{ fontSize: '0.85rem !important' }} />}
      label="ปรับแก้สต็อก"
      size="small"
      sx={{ bgcolor: '#FFF0F0', color: '#C62828', fontWeight: 600, fontSize: '0.75rem' }}
    />
  );
}

interface RestockHistoryTableProps {
  refetchTrigger?: number;
}

export default function RestockHistoryTable({ refetchTrigger }: RestockHistoryTableProps) {
  const { rows, loading, refetch } = useRestockHistory();

  useEffect(() => {
    if (refetchTrigger) refetch();
  }, [refetchTrigger, refetch]);

  const stableRows = useMemo(() => rows, [rows]);

  const columns: GridColDef[] = [
    {
      field: 'transaction_type',
      headerName: 'ประเภท',
      flex: 1.2,
      renderCell: (params) => <TypeChip type={params.value as 'restock' | 'adjustment'} />,
    },
    {
      field: 'service_center',
      headerName: 'สถานบริการ',
      flex: 1.5,
    },
    {
      field: 'condom_delta',
      headerName: 'ถุงยางอนามัย (ชิ้น)',
      flex: 1.4,
      align: 'center',
      headerAlign: 'center',
      renderCell: (params) => <QtyChip value={params.value as number} />,
    },
    {
      field: 'lubricant_delta',
      headerName: 'เจลหล่อลื่น (ชิ้น)',
      flex: 1.3,
      align: 'center',
      headerAlign: 'center',
      renderCell: (params) => <QtyChip value={params.value as number} />,
    },
    {
      field: 'created_at',
      headerName: 'เมื่อวันที่',
      flex: 1.3,
      valueGetter: (value: string) => value,
      renderCell: (params) => (
        <Typography variant="body2">{formatDateTime(params.value as string)}</Typography>
      ),
    },
    {
      field: 'performer_name',
      headerName: 'โดย',
      flex: 1,
    },
    {
      field: 'note',
      headerName: 'หมายเหตุ',
      flex: 1.4,
      renderCell: (params) =>
        params.value ? (
          <Tooltip title={params.value as string} placement="top">
            <Typography
              variant="body2"
              sx={{
                overflow: 'hidden',
                textOverflow: 'ellipsis',
                whiteSpace: 'nowrap',
                maxWidth: '100%',
              }}
            >
              {params.value as string}
            </Typography>
          </Tooltip>
        ) : (
          <Typography variant="body2" color="text.disabled">—</Typography>
        ),
    },
  ];

  return (
    <Paper sx={{ p: 3, borderRadius: 3, boxShadow: 2 }}>
      <Box sx={{ mb: 2 }}>
        <Typography variant="h6" fontWeight="bold">
          ประวัติการแก้ไขสต็อก
        </Typography>
      </Box>

      <Box sx={{ height: 400, width: '100%' }}>
        <DataGrid
          rows={stableRows}
          columns={columns}
          loading={loading}
          localeText={thGridLocale}
          initialState={{
            pagination: { paginationModel: { pageSize: 10, page: 0 } },
          }}
          pageSizeOptions={[10, 25, 50]}
          disableRowSelectionOnClick
          sx={{
            border: 'none',
            '& .MuiDataGrid-columnHeaders': { bgcolor: 'grey.50' },
            '& .MuiDataGrid-row:hover': { bgcolor: 'rgba(255,159,107,0.05)' },
            '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
          }}
        />
      </Box>
    </Paper>
  );
}
