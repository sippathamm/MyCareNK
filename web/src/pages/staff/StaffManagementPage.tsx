import { Box, Typography, Paper, Chip, Button } from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import PersonAddIcon from '@mui/icons-material/PersonAdd';
import { useRoleAccess } from '../../hooks/useRoleAccess';

const mockStaff = [
  { id: '1', first_name: 'สมปอง', last_name: 'ทองดี', role: 'admin', service_center: 'ศูนย์บริการ A' },
  { id: '2', first_name: 'สมหญิง', last_name: 'รักเรียน', role: 'staff', service_center: 'ศูนย์บริการ A' },
  { id: '3', first_name: 'สุดใจ', last_name: 'มานะ', role: 'staff', service_center: 'ศูนย์บริการ B' },
];

export default function StaffManagementPage() {
  const { role } = useRoleAccess();

  // Redirect or show error if not admin/superadmin (Though routing handles this ideally)
  if (role !== 'admin' && role !== 'superadmin') {
    return <Box p={4}><Typography color="error">คุณไม่มีสิทธิ์เข้าถึงหน้านี้</Typography></Box>;
  }

  const columns: GridColDef[] = [
    { field: 'first_name', headerName: 'ชื่อ', width: 150 },
    { field: 'last_name', headerName: 'นามสกุล', width: 150 },
    { 
      field: 'role', 
      headerName: 'ระดับสิทธิ์ (Role)', 
      width: 150,
      renderCell: (params) => {
        const color = params.value === 'superadmin' ? 'error' : params.value === 'admin' ? 'primary' : 'default';
        return <Chip label={params.value} color={color as any} size="small" />;
      }
    },
    { field: 'service_center', headerName: 'สถานที่ประจำการ', width: 200 },
  ];

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
        <Box>
          <Typography variant="h5" fontWeight="bold" gutterBottom>
            จัดการเจ้าหน้าที่
          </Typography>
          <Typography variant="body1" color="text.secondary">
            เพิ่ม ลบ หรือแก้ไขสิทธิ์การใช้งานของเจ้าหน้าที่ในระบบ
          </Typography>
        </Box>
        <Button variant="contained" startIcon={<PersonAddIcon />}>
          เพิ่มเจ้าหน้าที่
        </Button>
      </Box>

      <Paper sx={{ p: 3, borderRadius: 3, boxShadow: 2 }}>
        <Box sx={{ height: 400, width: '100%' }}>
          <DataGrid
            rows={mockStaff}
            columns={columns}
            initialState={{
              pagination: {
                paginationModel: { pageSize: 10, page: 0 },
              },
            }}
            pageSizeOptions={[10]}
            disableRowSelectionOnClick
          />
        </Box>
      </Paper>
    </Box>
  );
}
