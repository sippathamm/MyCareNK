import { Dialog, DialogTitle, DialogContent, DialogActions, Button, Box, Typography } from '@mui/material';
import NotificationsActiveIcon from '@mui/icons-material/NotificationsActive';

const DISMISSED_KEY = 'notif_permission_dismissed';

export function shouldShowPermissionDialog(): boolean {
  if ('Notification' in window && Notification.permission !== 'default') return false;
  return sessionStorage.getItem(DISMISSED_KEY) !== '1';
}

interface NotificationPermissionDialogProps {
  open: boolean;
  onClose: () => void;
}

export default function NotificationPermissionDialog({ open, onClose }: NotificationPermissionDialogProps) {
  const handleEnable = async () => {
    if ('Notification' in window) await Notification.requestPermission();
    onClose();
  };

  const handleDismiss = () => {
    sessionStorage.setItem(DISMISSED_KEY, '1');
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleDismiss} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ pb: 0 }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1.5, pt: 1 }}>
          <Box
            sx={{
              width: 64,
              height: 64,
              borderRadius: '50%',
              bgcolor: 'rgba(255,159,107,0.12)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <NotificationsActiveIcon sx={{ fontSize: 36, color: 'primary.main' }} />
          </Box>
          <Typography variant="h6" fontWeight="bold" textAlign="center">
            เปิดการแจ้งเตือนบนเบราว์เซอร์
          </Typography>
        </Box>
      </DialogTitle>

      <DialogContent>
        <Typography variant="body2" color="text.secondary" textAlign="center" sx={{ mt: 1 }}>
          รับการแจ้งเตือนเมื่อมีคำขอหรือนัดหมายใหม่
          <br />
          แม้ขณะที่แท็บนี้ไม่ได้เปิดอยู่
        </Typography>
      </DialogContent>

      <DialogActions sx={{ flexDirection: 'column', gap: 1, px: 3, pb: 3 }}>
        <Button
          fullWidth
          variant="contained"
          color="primary"
          onClick={handleEnable}
          sx={{ borderRadius: 2, textTransform: 'none', fontWeight: 600 }}
        >
          เปิดการแจ้งเตือน
        </Button>
        <Button
          fullWidth
          variant="text"
          color="inherit"
          onClick={handleDismiss}
          sx={{ borderRadius: 2, textTransform: 'none', color: 'text.secondary' }}
        >
          ไม่ใช่ตอนนี้
        </Button>
      </DialogActions>
    </Dialog>
  );
}
