import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Box, Typography, Button, TextField, Alert, CircularProgress, Avatar, IconButton } from '@mui/material';
import LockResetIcon from '@mui/icons-material/LockReset';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import AuthPageWrapper from '../../components/shared/AuthPageWrapper';
import { MESSAGES } from '../../constants/messages';

interface ForgotPasswordPageProps {
  loading: boolean;
  errorMsg: string;
  onSubmit: (email: string) => Promise<boolean>;
}

const ForgotPasswordPage = ({ loading, errorMsg, onSubmit }: ForgotPasswordPageProps) => {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [resetSuccess, setResetSuccess] = useState(false);

  const handleSubmit = async (e: React.SubmitEvent<HTMLFormElement>) => {
    e.preventDefault();
    const success = await onSubmit(email);
    if (success) setResetSuccess(true);
  };

  return (
    <AuthPageWrapper>
      <Box sx={{ width: '100%', display: 'flex', justifyContent: 'flex-start', mb: 1 }}>
        <IconButton onClick={() => navigate('/login')} disabled={loading} sx={{ ml: -2 }}>
          <ArrowBackIcon />
        </IconButton>
      </Box>

      <Avatar sx={{ m: 1, mb: 3, bgcolor: 'info.main', width: 56, height: 56 }}>
        <LockResetIcon fontSize="large" />
      </Avatar>
      <Typography component="h2" variant="h5" sx={{ mb: 3, fontWeight: 'bold', textAlign: 'center' }}>
        เปลี่ยนรหัสผ่าน
      </Typography>

      {errorMsg && (
        <Alert severity="error" sx={{ width: '100%', mb: 2 }}>
          {errorMsg}
        </Alert>
      )}

      {resetSuccess ? (
        <Box sx={{ width: '100%', textAlign: 'left' }}>
          <Alert severity="success" sx={{ mb: 3 }}>
            {MESSAGES.success.resetEmailSent}
          </Alert>
          <Button
            fullWidth
            variant="outlined"
            onClick={() => navigate('/login')}
            sx={{ py: 1.5 }}
          >
            กลับไปหน้าเข้าสู่ระบบ
          </Button>
        </Box>
      ) : (
        <Box component="form" onSubmit={handleSubmit} sx={{ width: '100%' }}>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2, textAlign: 'center' }}>
            กรุณากรอกอีเมลที่ใช้ลงทะเบียน เพื่อรับลิงก์ตั้งรหัสผ่านใหม่
          </Typography>
          <TextField
            margin="normal"
            required
            fullWidth
            id="reset-email"
            label="อีเมล"
            name="email"
            autoComplete="email"
            autoFocus
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            disabled={loading}
          />
          <Button
            type="submit"
            fullWidth
            variant="contained"
            color="primary"
            disabled={loading}
            sx={{ mt: 3, mb: 2, py: 1.5 }}
          >
            {loading ? <CircularProgress size={24} color="inherit" /> : 'ส่งลิงก์เปลี่ยนรหัสผ่าน'}
          </Button>
        </Box>
      )}
    </AuthPageWrapper>
  );
};

export default ForgotPasswordPage;
