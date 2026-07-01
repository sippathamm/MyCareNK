import { useEffect, useState } from 'react';
import { Box, Typography, Paper, Chip, Alert } from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import { alpha } from '@mui/material/styles';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useIsMobile } from '../../hooks/useIsMobile';
import { useColorMode } from '../../contexts/ThemeContext';
import { useServiceCenterFilter } from '../../contexts/ServiceCenterFilterContext';
import { createThGridLocale } from '../../constants/datagrid';
import { supabase } from '../../lib/supabase';
import type { Enums } from '../../lib/database.types';

// ─── Constants ───────────────────────────────────────────────────────────────

function getRoleChipSx(role: string, mode: 'light' | 'dark'): { bgcolor: string; color: string } {
  if (mode === 'dark') {
    const dark: Record<string, { bgcolor: string; color: string }> = {
      superadmin: { bgcolor: alpha('#EF5350', 0.15), color: '#EF9A9A' },
      admin:      { bgcolor: alpha('#FF9F6B', 0.15), color: '#FFBE9E' },
      staff:      { bgcolor: alpha('#9E9E9E', 0.15), color: '#BDBDBD' },
    };
    return dark[role] ?? dark.staff;
  }
  const light: Record<string, { bgcolor: string; color: string }> = {
    superadmin: { bgcolor: '#FFEBEE', color: '#B71C1C' },
    admin:      { bgcolor: '#FFF3E0', color: '#E65100' },
    staff:      { bgcolor: '#F5F5F5', color: '#616161' },
  };
  return light[role] ?? light.staff;
}

const ROLE_LABEL: Record<string, string> = {
  staff: 'เจ้าหน้าที่',
  admin: 'ผู้ดูแล',
  superadmin: 'ผู้ดูแลสูงสุด',
};

const thGridLocale = createThGridLocale('ไม่มีข้อมูลเจ้าหน้าที่');

// ─── Types ────────────────────────────────────────────────────────────────────

interface StaffDirectoryMember {
  id: string;
  first_name: string | null;
  last_name: string | null;
  role: Enums<'role'>;
  service_centers: string[] | null;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function StaffDirectoryPage() {
  const isMobile = useIsMobile();
  const { role, serviceCenters, loading: roleLoading } = useRoleAccess();
  const { mode } = useColorMode();
  const { selectedServiceCenter } = useServiceCenterFilter();
  const [staff, setStaff] = useState<StaffDirectoryMember[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (roleLoading) return;

    const fetchStaff = async () => {
      setLoading(true);
      setError(null);

      let query = supabase
        .from('staff_profiles')
        .select('id, first_name, last_name, role, service_centers')
        .order('first_name');

      if (role === 'staff') {
        if (serviceCenters[0]) {
          query = query.contains('service_centers', [serviceCenters[0]]);
        }
      } else if (selectedServiceCenter) {
        query = query.contains('service_centers', [selectedServiceCenter]);
      }

      const { data, error: err } = await query;
      if (err) {
        setError('เกิดข้อผิดพลาดในการโหลดข้อมูล');
      } else {
        setStaff(data ?? []);
      }
      setLoading(false);
    };

    fetchStaff();
  }, [role, serviceCenters, selectedServiceCenter, roleLoading]);

  const columns: GridColDef[] = [
    { field: 'first_name', headerName: 'ชื่อ', flex: 1, minWidth: 120 },
    { field: 'last_name', headerName: 'นามสกุล', flex: 1, minWidth: 120 },
    {
      field: 'role',
      headerName: 'ระดับสิทธิ์',
      width: 160,
      renderCell: ({ value }) => {
        const sx = getRoleChipSx(value as string, mode);
        return (
          <Chip
            label={ROLE_LABEL[value as string] ?? value}
            size="small"
            sx={{ bgcolor: sx.bgcolor, color: sx.color, fontWeight: 600 }}
          />
        );
      },
    },
    {
      field: 'service_centers',
      headerName: 'สถานบริการ',
      flex: 1.5,
      minWidth: 160,
      renderCell: ({ value }) => (value as string[] | null)?.join(', ') ?? '-',
    },
  ];

  return (
    <Box>
      <Box mb={4}>
        <Typography variant="h5" fontWeight="bold" gutterBottom>เจ้าหน้าที่</Typography>
        <Typography variant="body1" color="text.secondary">
          รายชื่อเจ้าหน้าที่ในสถานบริการของคุณ
        </Typography>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Paper elevation={1} sx={{ p: 3, borderRadius: 2 }}>
        <Box sx={{ height: 500, width: '100%' }}>
          <DataGrid
            rows={staff}
            columns={columns}
            loading={loading}
            columnVisibilityModel={isMobile ? { last_name: false, service_centers: false } : {}}
            initialState={{ pagination: { paginationModel: { pageSize: 10 } } }}
            pageSizeOptions={[10]}
            localeText={thGridLocale}
            disableRowSelectionOnClick
            getRowHeight={() => 56}
            sx={{
              border: 'none',
              '& .MuiDataGrid-columnHeaders': { bgcolor: 'action.hover' },
              '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
            }}
          />
        </Box>
      </Paper>
    </Box>
  );
}
