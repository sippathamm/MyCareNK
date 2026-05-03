import { useState } from 'react';
import { Dialog, DialogTitle, DialogContent, DialogActions, Button, Typography, Box, Divider, TextField, Chip, CircularProgress, Tooltip } from '@mui/material';
import QrCode2Icon from '@mui/icons-material/QrCode2';
import { formatDate, formatDateTime, getOverdueDays } from '../../utils/requestUtils';
import QRCodeDialog from './QRCodeDialog';
import type { Enums } from '../../lib/database.types';

export interface RequestData {
  id: string;
  reference_number: string;
  selected_date: string | null;
  selected_time: string | null;
  selected_service_center: Enums<'service_center'>;
  condom_quantities: Record<string, number>;
  lubricant_quantity: number;
  message: string | null;
  cancel_reason: string | null;
  handled_by: string | null;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
  request_status: Enums<'status'>;
}

interface RequestDetailDialogProps {
  open: boolean;
  request: RequestData | null;
  onClose: () => void;
  onStatusChange: (id: string, newStatus: string, reason?: string) => Promise<boolean>;
  statusUpdating?: boolean;
}

interface QRDialogState {
  open: boolean;
  requestId: string;
  referenceNumber: string;
  initialPayload?: string;
  onFinishPrepare?: () => Promise<boolean>;
}

export default function RequestDetailDialog({ open, request, onClose, onStatusChange, statusUpdating = false }: RequestDetailDialogProps) {
  const [rejectReason, setRejectReason] = useState('');
  const [isRejecting, setIsRejecting] = useState(false);
  const [isConfirmingPrepare, setIsConfirmingPrepare] = useState(false);
  const [isConfirmingFinish, setIsConfirmingFinish] = useState(false);
  const [isConfirmingComplete, setIsConfirmingComplete] = useState(false);
  const [qrDialog, setQrDialog] = useState<QRDialogState>({ open: false, requestId: '', referenceNumber: '' });

  const handleConfirmPrepare = async () => {
    if (!request) return;
    const ok = await onStatusChange(request.id, 'preparing');
    if (ok) onCloseDialog();
  };

  const handleFinishPrepare = () => {
    if (!request) return;
    // Capture request data before closing (request prop may be stale after onClose)
    const qrData = {
      open: true,
      requestId: request.id,
      referenceNumber: request.reference_number,
      onFinishPrepare: () => onStatusChange(request.id, 'ready'),
    };
    onCloseDialogInternal();
    setQrDialog(qrData);
  };

  const handleCancelConfirm = async () => {
    if (!request || !rejectReason.trim()) return;
    const ok = await onStatusChange(request.id, 'cancelled_by_staff', rejectReason);
    if (ok) onCloseDialog();
  };

  const handleConfirmComplete = async () => {
    if (!request) return;
    const ok = await onStatusChange(request.id, 'completed');
    if (ok) onCloseDialog();
  };

  const onCloseDialogInternal = () => {
    setIsRejecting(false);
    setRejectReason('');
    setIsConfirmingPrepare(false);
    setIsConfirmingFinish(false);
    setIsConfirmingComplete(false);
    onClose();
  };

  const onCloseDialog = () => {
    onCloseDialogInternal();
  };

  const openQRDialog = () => {
    if (!request) return;
    setQrDialog({ open: true, requestId: request.id, referenceNumber: request.reference_number });
  };

  return (
    <>
      {request && (
        <Dialog open={open} onClose={onCloseDialog} maxWidth="sm" fullWidth>
          <DialogTitle sx={{ pb: 1 }}>
            <Typography variant="h6" fontWeight="bold" lineHeight={1.2}>
              รายละเอียดคำขอ
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {request.reference_number}
            </Typography>
          </DialogTitle>

          <DialogContent dividers>
            {isConfirmingComplete ? (
              <Box display="flex" flexDirection="column" alignItems="center" py={4} gap={3}>
                <Typography variant="h6" color="success.main" fontWeight="bold">
                  ยืนยันการเสร็จสิ้น
                </Typography>
                <Typography variant="body1" color="text.secondary">
                  คุณต้องการเปลี่ยนสถานะคำขอนี้เป็น "เสร็จสิ้น" ใช่หรือไม่?
                </Typography>
              </Box>
            ) : isConfirmingPrepare ? (
              <Box display="flex" flexDirection="column" alignItems="center" py={4} gap={3}>
                <Typography variant="h6" color="warning.main" fontWeight="bold">
                  ยืนยันการเริ่มจัดเตรียม
                </Typography>
                <Typography variant="body1" color="text.secondary">
                  คุณต้องการเปลี่ยนสถานะคำขอนี้เป็น "กำลังเตรียม" ใช่หรือไม่?
                </Typography>
              </Box>
            ) : isConfirmingFinish ? (
              <Box display="flex" flexDirection="column" alignItems="center" py={4} gap={3}>
                <Typography variant="h6" color="info.main" fontWeight="bold">
                  ยืนยันการเตรียมการเสร็จสิ้น
                </Typography>
                <Typography variant="body1" color="text.secondary">
                  คุณต้องการเปลี่ยนสถานะคำขอนี้เป็น "รอรับ" ใช่หรือไม่?
                </Typography>
              </Box>
            ) : (
              <Box display="flex" flexDirection="column" gap={2}>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">ส่งคำขอเมื่อ</Typography>
                  <Typography variant="body1">{formatDateTime(request.created_at)}</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">เปลี่ยนแปลงล่าสุดเมื่อ</Typography>
                  <Typography variant="body1">{formatDateTime(request.updated_at)}</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between" alignItems="center">
                  <Typography variant="subtitle2" color="text.secondary">วันเดือนปีรับ</Typography>
                  {(() => {
                    const days = getOverdueDays(request.selected_date ?? '', request.request_status);
                    if (days > 0) {
                      return (
                        <Typography variant="body1" color="error.main">
                          {formatDate(request.selected_date ?? '')} (เลยกำหนด {days} วัน)
                        </Typography>
                      );
                    }
                    return <Typography variant="body1">{formatDate(request.selected_date ?? '')}</Typography>;
                  })()}
                </Box>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">เวลารับ</Typography>
                  <Typography variant="body1">{request.selected_time ?? '-'} น.</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">สถานที่รับ</Typography>
                  <Typography variant="body1" fontWeight="medium">{request.selected_service_center}</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between" alignItems="center">
                  <Typography variant="subtitle2" color="text.secondary">สถานะ</Typography>
                  {(() => {
                    switch (request.request_status) {
                      case 'pending': return <Chip label="รอดำเนินการ" color="warning" size="small" sx={{ fontWeight: 'bold' }} />;
                      case 'preparing': return <Chip label="กำลังเตรียม" color="info" size="small" sx={{ fontWeight: 'bold' }} />;
                      case 'ready': return <Chip label="รอรับ" color="secondary" size="small" sx={{ fontWeight: 'bold' }} />;
                      case 'completed': return <Chip label="เสร็จสิ้น" color="success" size="small" sx={{ fontWeight: 'bold' }} />;
                      case 'cancelled_by_user': return <Chip label="ยกเลิกโดยผู้ใช้" size="small" sx={{ bgcolor: '#E0E0E0', color: '#616161', fontWeight: 'bold' }} />;
                      case 'cancelled_by_staff': return <Chip label="ยกเลิกโดยเจ้าหน้าที่" size="small" sx={{ bgcolor: '#E0E0E0', color: '#616161', fontWeight: 'bold' }} />;
                    }
                  })()}
                </Box>

                <Divider sx={{ my: 1 }} />

                <Typography variant="subtitle1" fontWeight="bold">รายการที่ต้องจัดเตรียม</Typography>
                <Box bgcolor="background.default" p={2} borderRadius={2}>
                  <Typography variant="subtitle2" color="text.primary" sx={{ mb: 1 }}>ถุงยางอนามัย</Typography>
                  {Object.entries(request.condom_quantities).map(([type, qty]) => (
                    <Box key={type} display="flex" justifyContent="space-between" mb={1} pl={2}>
                      <Typography variant="body2">• ขนาด {type} มม.</Typography>
                      <Typography variant="body2" fontWeight="bold" color={qty > 0 ? 'text.primary' : 'text.secondary'}>
                        {qty > 0 ? `${qty} ชิ้น` : 'ไม่ต้องการ'}
                      </Typography>
                    </Box>
                  ))}

                  <Divider sx={{ my: 1.5, borderStyle: 'dashed' }} />

                  <Typography variant="subtitle2" color="text.primary" sx={{ mb: 1 }}>เพิ่มเติม</Typography>
                  <Box display="flex" justifyContent="space-between" pl={2}>
                    <Typography variant="body2">• เจลหล่อลื่น</Typography>
                    <Typography variant="body2" fontWeight="bold" color={request.lubricant_quantity > 0 ? 'text.primary' : 'text.secondary'}>
                      {request.lubricant_quantity > 0 ? `${request.lubricant_quantity} ซอง` : 'ไม่ต้องการ'}
                    </Typography>
                  </Box>
                </Box>

                {request.message && (
                  <Box mt={2}>
                    <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>ข้อความเพิ่มเติม</Typography>
                    <Typography variant="body2" sx={{ fontStyle: 'italic', bgcolor: 'rgba(0,0,0,0.03)', p: 1.5, borderRadius: 1 }}>
                      {request.message}
                    </Typography>
                  </Box>
                )}

                {(request.request_status === 'cancelled_by_user' || request.request_status === 'cancelled_by_staff') && request.cancel_reason && (
                  <Box mt={2}>
                    <Typography variant="subtitle2" color="error.main" sx={{ mb: 1 }}>เหตุผลที่ยกเลิก</Typography>
                    <Typography variant="body2" sx={{ fontStyle: 'italic', bgcolor: 'rgba(211,47,47,0.06)', p: 1.5, borderRadius: 1, color: 'error.main' }}>
                      {request.cancel_reason}
                    </Typography>
                  </Box>
                )}

                {isRejecting && (
                  <Box mt={2}>
                    <TextField
                      fullWidth
                      label="ระบุเหตุผลที่ยกเลิก"
                      multiline
                      rows={3}
                      value={rejectReason}
                      onChange={(e) => setRejectReason(e.target.value)}
                      error={rejectReason.trim() === ''}
                      helperText={rejectReason.trim() === '' ? 'จำเป็นต้องระบุเหตุผล' : ''}
                      color="error"
                      autoFocus
                    />
                  </Box>
                )}
              </Box>
            )}
          </DialogContent>

          <DialogActions sx={{ p: 2 }}>
            {isConfirmingPrepare ? (
              <>
                <Button onClick={() => setIsConfirmingPrepare(false)} disabled={statusUpdating} color="inherit">กลับ</Button>
                <Button
                  onClick={handleConfirmPrepare}
                  variant="contained"
                  color="primary"
                  disabled={statusUpdating}
                  endIcon={statusUpdating ? <CircularProgress size={16} color="inherit" /> : null}
                >
                  ยืนยัน
                </Button>
              </>
            ) : isConfirmingFinish ? (
              <>
                <Button onClick={() => setIsConfirmingFinish(false)} disabled={statusUpdating} color="inherit">กลับ</Button>
                <Button
                  onClick={handleFinishPrepare}
                  variant="contained"
                  color="info"
                  disabled={statusUpdating}
                  endIcon={statusUpdating ? <CircularProgress size={16} color="inherit" /> : null}
                >
                  ยืนยัน
                </Button>
              </>
            ) : isConfirmingComplete ? (
              <>
                <Button onClick={() => setIsConfirmingComplete(false)} disabled={statusUpdating} color="inherit">กลับ</Button>
                <Button
                  onClick={handleConfirmComplete}
                  variant="contained"
                  color="success"
                  disabled={statusUpdating}
                  endIcon={statusUpdating ? <CircularProgress size={16} color="inherit" /> : null}
                >
                  ยืนยัน
                </Button>
              </>
            ) : isRejecting ? (
              <>
                <Button onClick={() => setIsRejecting(false)} disabled={statusUpdating} color="inherit">กลับ</Button>
                <Button
                  onClick={handleCancelConfirm}
                  color="error"
                  variant="contained"
                  disabled={!rejectReason.trim() || statusUpdating}
                  endIcon={statusUpdating ? <CircularProgress size={16} color="inherit" /> : null}
                >
                  ยืนยันการยกเลิก
                </Button>
              </>
            ) : (
              <>
                <Button onClick={onCloseDialog} color="inherit">ปิด</Button>
                {request.request_status === 'ready' && (
                  <Button
                    variant="outlined"
                    startIcon={<QrCode2Icon />}
                    onClick={openQRDialog}
                  >
                    ดู QR Code
                  </Button>
                )}
                {request.request_status === 'ready' && (() => {
                  const daysPast = (() => {
                    if (!request.selected_date) return 0;
                    const selected = new Date(request.selected_date);
                    selected.setHours(0, 0, 0, 0);
                    const today = new Date();
                    today.setHours(0, 0, 0, 0);
                    return Math.floor((today.getTime() - selected.getTime()) / 86400000);
                  })();
                  return (
                    <Tooltip title={daysPast <= 7 ? 'กดปุ่มนี้ได้เมื่อเลยกำหนดมากกว่า 7 วัน' : ''}>
                      <span>
                        <Button
                          onClick={() => setIsConfirmingComplete(true)}
                          color="success"
                          variant="contained"
                          disabled={daysPast <= 7}
                        >
                          เสร็จสิ้น
                        </Button>
                      </span>
                    </Tooltip>
                  );
                })()}
                {request.request_status === 'pending' && (
                  <>
                    <Button onClick={() => setIsRejecting(true)} color="error" variant="outlined">
                      ยกเลิกคำขอ
                    </Button>
                    <Button onClick={() => setIsConfirmingPrepare(true)} color="primary" variant="contained">
                      จัดเตรียมรายการ
                    </Button>
                  </>
                )}
                {request.request_status === 'preparing' && (
                  <Button onClick={() => setIsConfirmingFinish(true)} color="info" variant="contained">
                    เตรียมการเสร็จสิ้น
                  </Button>
                )}
              </>
            )}
          </DialogActions>
        </Dialog>
      )}

      <QRCodeDialog
        open={qrDialog.open}
        requestId={qrDialog.requestId}
        referenceNumber={qrDialog.referenceNumber}
        initialPayload={qrDialog.initialPayload}
        onFinishPrepare={qrDialog.onFinishPrepare}
        onClose={() => setQrDialog(s => ({ ...s, open: false, initialPayload: undefined, onFinishPrepare: undefined }))}
      />
    </>
  );
}
