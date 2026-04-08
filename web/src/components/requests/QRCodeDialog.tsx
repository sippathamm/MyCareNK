import { useEffect } from 'react';
import { Dialog, DialogTitle, DialogContent, DialogActions, Button, Typography, Box, CircularProgress } from '@mui/material';
import PrintIcon from '@mui/icons-material/Print';
import { QRCodeSVG } from 'qrcode.react';
import { useSignPayload } from '../../hooks/useSignPayload';

interface QRCodeDialogProps {
  open: boolean;
  requestId: string;
  referenceNumber: string;
  /** Pre-signed payload from finish-prepare flow; if omitted, dialog signs itself on open */
  initialPayload?: string;
  onClose: () => void;
}

export default function QRCodeDialog({ open, requestId, referenceNumber, initialPayload, onClose }: QRCodeDialogProps) {
  const { payload, loading, error, sign, reset } = useSignPayload();

  useEffect(() => {
    if (open && !initialPayload) {
      sign(requestId);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, requestId]);

  const displayPayload = initialPayload ?? payload;

  const handleClose = () => {
    reset();
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ fontWeight: 'bold' }}>QR Code สำหรับรับพัสดุ</DialogTitle>

      <DialogContent dividers>
        <Box display="flex" flexDirection="column" alignItems="center" py={2} gap={2}>
          {loading && (
            <Box display="flex" flexDirection="column" alignItems="center" gap={2}>
              <CircularProgress size={48} />
              <Typography variant="body2" color="text.secondary">
                กำลังสร้าง QR Code...
              </Typography>
            </Box>
          )}

          {error && !loading && (
            <Box display="flex" flexDirection="column" alignItems="center" gap={2}>
              <Typography variant="body2" color="error">{error}</Typography>
              <Button variant="outlined" color="error" onClick={() => sign(requestId)}>
                ลองใหม่
              </Button>
            </Box>
          )}

          {displayPayload && !loading && (
            <>
              <Box id="qr-print-area" display="flex" flexDirection="column" alignItems="center" gap={1}>
                <QRCodeSVG value={displayPayload} size={220} />
                <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                  รหัสอ้างอิง: {referenceNumber}
                </Typography>
              </Box>
              <Typography variant="body2" color="error" textAlign="center" fontWeight="medium">
                กรุณานำ QR Code นี้ติดไว้ที่กล่อง/ซองพัสดุ
              </Typography>
            </>
          )}
        </Box>
      </DialogContent>

      <DialogActions sx={{ p: 2 }}>
        <Button onClick={handleClose} color="inherit">ปิด</Button>
        {displayPayload && !loading && (
          <Button variant="outlined" startIcon={<PrintIcon />} onClick={() => window.print()}>
            พิมพ์ QR Code
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
}
