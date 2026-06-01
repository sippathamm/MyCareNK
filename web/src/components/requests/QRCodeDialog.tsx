import { useEffect, useRef } from 'react';
import { Dialog, DialogTitle, DialogContent, DialogActions, Button, Typography, Box, CircularProgress } from '@mui/material';
import PrintIcon from '@mui/icons-material/Print';
import DownloadIcon from '@mui/icons-material/Download';
import { QRCodeSVG, QRCodeCanvas } from 'qrcode.react';
import { useSignPayload } from '../../hooks/useSignPayload';

interface QRCodeDialogProps {
  open: boolean;
  requestId: string;
  referenceNumber: string;
  onClose: () => void;
  /** When provided, status is changed to 'ready' only after signing succeeds */
  onFinishPrepare?: () => Promise<boolean>;
  /** Pre-signed payload (used when opening from a ready-status request) */
  initialPayload?: string;
}

export default function QRCodeDialog({
  open,
  requestId,
  referenceNumber,
  onClose,
  onFinishPrepare,
  initialPayload,
}: QRCodeDialogProps) {
  const { payload, loading, error, sign, reset } = useSignPayload();
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const handleSaveImage = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const url = canvas.toDataURL('image/png');
    const a = document.createElement('a');
    a.download = `${referenceNumber}.png`;
    a.href = url;
    a.click();
  };

  useEffect(() => {
    if (!open) return;

    if (initialPayload) return; // already have payload, no need to sign

    const run = async () => {
      const signed = await sign(requestId);
      if (!signed) return; // sign failed, stay open to show error

      if (onFinishPrepare) {
        const ok = await onFinishPrepare();
        if (!ok) {
          // status change failed — reset so user can retry
          reset();
        }
      }
    };

    run();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, requestId]);

  const displayPayload = initialPayload ?? payload;
  const isProcessing = loading;

  const handleClose = () => {
    reset();
    onClose();
  };

  return (
    <Dialog open={open} onClose={!isProcessing ? handleClose : undefined} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ fontWeight: 'bold' }}>QR Code สำหรับรับพัสดุ</DialogTitle>

      <DialogContent dividers>
        <Box display="flex" flexDirection="column" alignItems="center" py={2} gap={2}>
          {isProcessing && (
            <Box display="flex" flexDirection="column" alignItems="center" gap={2}>
              <CircularProgress size={48} />
              <Typography variant="body2" color="text.secondary">
                กำลังสร้าง QR Code...
              </Typography>
            </Box>
          )}

          {error && !isProcessing && (
            <Box display="flex" flexDirection="column" alignItems="center" gap={2}>
              <Typography variant="body2" color="error">{error}</Typography>
              <Button variant="outlined" color="error" onClick={() => sign(requestId)}>
                ลองใหม่
              </Button>
            </Box>
          )}

          {displayPayload && !isProcessing && (
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
              <Box sx={{ display: 'none' }}>
                <QRCodeCanvas ref={canvasRef} value={displayPayload} size={220} />
              </Box>
            </>
          )}
        </Box>
      </DialogContent>

      <DialogActions sx={{ p: 2 }}>
        <Button onClick={handleClose} color="inherit" disabled={isProcessing}>ปิด</Button>
        {displayPayload && !isProcessing && (
          <>
            <Button variant="outlined" startIcon={<DownloadIcon />} onClick={handleSaveImage}>
              บันทึกภาพ
            </Button>
            <Button variant="outlined" startIcon={<PrintIcon />} onClick={() => window.print()}>
              พิมพ์ QR Code
            </Button>
          </>
        )}
      </DialogActions>
    </Dialog>
  );
}
