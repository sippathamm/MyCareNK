import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, Typography, Divider, CircularProgress,
} from '@mui/material';

interface ConfirmDialogProps {
  open: boolean;
  icon: React.ReactNode;
  title: string;
  body?: string;
  confirmLabel?: string;
  confirmColor?: 'primary' | 'error' | 'success' | 'info' | 'warning' | 'secondary';
  confirmDisabled?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
  loading?: boolean;
  children?: React.ReactNode;
  maxWidth?: 'xs' | 'sm';
}

export default function ConfirmDialog({
  open, icon, title, body, confirmLabel = 'ยืนยัน', confirmColor = 'primary',
  confirmDisabled, onConfirm, onCancel, loading, children, maxWidth = 'xs',
}: ConfirmDialogProps) {
  return (
    <Dialog open={open} onClose={loading ? undefined : onCancel} maxWidth={maxWidth} fullWidth>
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1.5, pb: 1 }}>
        {icon}
        <Typography component="div" variant="h6" fontWeight="bold">{title}</Typography>
      </DialogTitle>
      <Divider />
      <DialogContent sx={{ pt: 2.5 }}>
        {body && (
          <Typography variant="body2" color="text.secondary" sx={{ mb: children ? 2 : 0 }}>
            {body}
          </Typography>
        )}
        {children}
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2.5, gap: 1 }}>
        <Button onClick={onCancel} disabled={loading} color="inherit">กลับ</Button>
        <Button
          onClick={onConfirm}
          variant="contained"
          color={confirmColor}
          disabled={loading || confirmDisabled}
          endIcon={loading ? <CircularProgress size={16} color="inherit" /> : null}
        >
          {confirmLabel}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
