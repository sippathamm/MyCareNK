import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Box, Typography, Button, TextField, Alert, CircularProgress, Avatar, Link } from '@mui/material';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import AuthPageWrapper from '../../components/shared/AuthPageWrapper';
import PasswordField from '../../components/shared/PasswordField';
import packageInfo from '../../../package.json';

interface LoginPageProps {
  loading: boolean;
  errorMsg: string;
  onLogin: (email: string, password: string) => Promise<boolean>;
}

const LoginPage = ({ loading, errorMsg, onLogin }: LoginPageProps) => {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) return;
    const success = await onLogin(email, password);
    if (success) navigate('/dashboard', { replace: true });
  };

  return (
    <AuthPageWrapper>
      <Avatar sx={{ m: 1, mb: 3, bgcolor: 'primary.main', width: 56, height: 56 }}>
        <LockOutlinedIcon fontSize="large" />
      </Avatar>
      <Typography component="h2" variant="h5" sx={{ mb: 3, fontWeight: 'bold' }}>
        เข้าสู่ระบบ
      </Typography>

      {errorMsg && (
        <Alert severity="error" sx={{ width: '100%', mb: 2 }}>
          {errorMsg}
        </Alert>
      )}

      <Box component="form" onSubmit={handleSubmit} sx={{ width: '100%' }}>
        <TextField
          margin="normal"
          required
          fullWidth
          id="email"
          label="อีเมล"
          name="email"
          autoComplete="email"
          autoFocus
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          disabled={loading}
        />
        <PasswordField
          id="password"
          name="password"
          label="รหัสผ่าน"
          value={password}
          onChange={setPassword}
          disabled={loading}
        />
        <Button
          type="submit"
          fullWidth
          variant="contained"
          disabled={loading}
          sx={{ mt: 3, mb: 2, py: 1.5, borderRadius: 2, fontWeight: 'bold' }}
        >
          {loading ? <CircularProgress size={24} color="inherit" /> : 'เข้าสู่ระบบ'}
        </Button>
        <Box sx={{ display: 'flex', justifyContent: 'center' }}>
          <Link
            component="button"
            type="button"
            variant="body2"
            color="primary"
            onClick={() => navigate('/forgot-password')}
            sx={{ textDecoration: 'none', '&:hover': { textDecoration: 'underline' } }}
          >
            ลืมรหัสผ่าน?
          </Link>
        </Box>
      </Box>

      <Box sx={{ mt: 4, opacity: 0.7 }}>
        <Typography variant="caption" color="text.secondary">
          v{packageInfo.version}
        </Typography>
      </Box>
    </AuthPageWrapper>
  );
};

export default LoginPage;
