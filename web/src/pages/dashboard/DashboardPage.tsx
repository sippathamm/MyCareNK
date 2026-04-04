import { useNavigate } from 'react-router-dom';
import { Box, Typography, Button, Avatar, CircularProgress } from '@mui/material';
import type { Session } from '@supabase/supabase-js';

interface DashboardPageProps {
  session: Session;
  loading: boolean;
  onLogout: () => Promise<void>;
}

const DashboardPage = ({ session, loading, onLogout }: DashboardPageProps) => {
  const navigate = useNavigate();
  const displayName = session.user.email?.split('@')[0] || 'ผู้ใช้งาน';

  const handleLogout = async () => {
    await onLogout();
    navigate('/login', { replace: true });
  };

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      {/* Sidebar — placeholder for future navigation */}
      <Box
        sx={{
          width: 240,
          bgcolor: 'primary.main',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          py: 4,
          px: 2,
          gap: 2,
        }}
      >
        <Typography variant="h6" fontWeight="bold" color="white" sx={{ mb: 2 }}>
          MyCareNK
        </Typography>
        {/* Future nav items go here */}
      </Box>

      {/* Main content area */}
      <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', p: 4 }}>
        <Avatar sx={{ width: 64, height: 64, bgcolor: 'primary.main', mb: 2, fontSize: 28 }}>
          {displayName[0].toUpperCase()}
        </Avatar>
        <Typography variant="h5" fontWeight="bold" color="primary" gutterBottom>
          ยินดีต้อนรับ, {displayName}!
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 4 }}>
          คุณได้เข้าสู่ระบบส่วนของเจ้าหน้าที่แล้ว
        </Typography>
        <Button
          variant="outlined"
          color="primary"
          onClick={handleLogout}
          disabled={loading}
          sx={{ borderRadius: 2 }}
        >
          {loading ? <CircularProgress size={20} /> : 'ออกจากระบบ'}
        </Button>
      </Box>
    </Box>
  );
};

export default DashboardPage;
