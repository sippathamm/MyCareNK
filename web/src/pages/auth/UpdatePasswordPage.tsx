import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Box, Typography, Button, Alert, CircularProgress, Avatar, Dialog, DialogContent, DialogActions } from '@mui/material';
import LockResetIcon from '@mui/icons-material/LockReset';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import AuthPageWrapper from '../../components/shared/AuthPageWrapper';
import PasswordField from '../../components/shared/PasswordField';
import { MESSAGES } from '../../constants/messages';
import { supabase } from '../../lib/supabase';

interface UpdatePasswordPageProps {
  loading: boolean;
  errorMsg: string;
  onSubmit: (newPassword: string, confirmPassword: string) => Promise<boolean>;
}

const UpdatePasswordPage = ({ loading, errorMsg, onSubmit }: UpdatePasswordPageProps) => {
  const navigate = useNavigate();
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [successDialogOpen, setSuccessDialogOpen] = useState(false);

  const handleSubmit = async (e: React.SubmitEvent<HTMLFormElement>) => {
    e.preventDefault();
    const success = await onSubmit(newPassword, confirmPassword);
    if (success) setSuccessDialogOpen(true);
  };

  const handleSuccessDialogClose = async () => {
    setSuccessDialogOpen(false);
    await supabase.auth.signOut();
    navigate('/login', { replace: true });
  };

  return (
    <AuthPageWrapper>
      <Avatar sx={{ m: 1, mb: 3, bgcolor: 'success.main', width: 56, height: 56 }}>
        <LockResetIcon fontSize="large" />
      </Avatar>
      <Typography component="h2" variant="h5" sx={{ mb: 3, fontWeight: 'bold', textAlign: 'center' }}>
        ตั้งรหัสผ่านใหม่
      </Typography>

      {errorMsg && (
        <Alert severity="error" sx={{ width: '100%', mb: 2 }}>
          {errorMsg}
        </Alert>
      )}

      <Box component="form" onSubmit={handleSubmit} sx={{ width: '100%' }}>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2, textAlign: 'center' }}>
          กรุณาตั้งรหัสผ่านใหม่
        </Typography>
        <PasswordField
          id="new-password"
          name="newPassword"
          label="รหัสผ่านใหม่"
          value={newPassword}
          onChange={setNewPassword}
          disabled={loading}
          autoFocus
        />
        <PasswordField
          id="confirm-password"
          name="confirmPassword"
          label="ยืนยันรหัสผ่านใหม่"
          value={confirmPassword}
          onChange={setConfirmPassword}
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
          {loading ? <CircularProgress size={24} color="inherit" /> : 'บันทึกรหัสผ่านใหม่'}
        </Button>
      </Box>

      <Dialog
        open={successDialogOpen}
        onClose={handleSuccessDialogClose}
        slotProps={{ paper: { sx: { p: 1, minWidth: 300 } } }}
      >
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', py: 2 }}>
            <CheckCircleIcon sx={{ fontSize: 64, color: 'success.main', mb: 2 }} />
            <Typography variant="h6" fontWeight="bold" gutterBottom>
              {MESSAGES.success.passwordChanged}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              กรุณาเข้าสู่ระบบด้วยรหัสผ่านใหม่
            </Typography>
          </Box>
        </DialogContent>
        <DialogActions sx={{ justifyContent: 'center', pb: 2 }}>
          <Button
            variant="contained"
            color="primary"
            onClick={handleSuccessDialogClose}
            sx={{ px: 4 }}
          >
            ตกลง
          </Button>
        </DialogActions>
      </Dialog>
    </AuthPageWrapper>
  );
};

export default UpdatePasswordPage;
