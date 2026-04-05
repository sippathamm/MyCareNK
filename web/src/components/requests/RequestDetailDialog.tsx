import { useState } from 'react';
import { Dialog, DialogTitle, DialogContent, DialogActions, Button, Typography, Box, Divider, TextField, Chip } from '@mui/material';
import { QRCodeSVG } from 'qrcode.react';
import { formatDate, getOverdueDays } from '../../utils/requestUtils';

export interface RequestData {
  id: string;
  reference_number: string;
  selected_date: string;
  selected_time: string;
  selected_location: string;
  condom_quantities: Record<string, number>;
  lubricant_quantity: number;
  message?: string;
  cancel_reason?: string;
  created_at?: string;
  updated_at?: string;
  status: 'pending' | 'preparing' | 'ready' | 'completed' | 'cancelled';
}

interface RequestDetailDialogProps {
  open: boolean;
  request: RequestData | null;
  onClose: () => void;
  onStatusChange: (id: string, newStatus: string, reason?: string) => void;
}

export default function RequestDetailDialog({ open, request, onClose, onStatusChange }: RequestDetailDialogProps) {
  const [rejectReason, setRejectReason] = useState('');
  const [isRejecting, setIsRejecting] = useState(false);
  const [showQR, setShowQR] = useState(false);
  const [isConfirmingPrepare, setIsConfirmingPrepare] = useState(false);
  const [isConfirmingFinish, setIsConfirmingFinish] = useState(false);

  if (!request) return null;

  const handleConfirmPrepare = () => {
    onStatusChange(request.id, 'preparing');
    onCloseDialog();
  };

  const handleFinishPrepare = () => {
    onStatusChange(request.id, 'ready');
    setIsConfirmingFinish(false);
    setShowQR(true);
  };

  const handleCancelConfirm = () => {
    if (!rejectReason.trim()) return;
    onStatusChange(request.id, 'cancelled', rejectReason);
    onCloseDialog();
  };

  const onCloseDialog = () => {
    setIsRejecting(false);
    setRejectReason('');
    setIsConfirmingPrepare(false);
    setIsConfirmingFinish(false);
    setShowQR(false);
    onClose();
  };

  return (
    <Dialog open={open} onClose={onCloseDialog} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ fontWeight: 'bold' }}>
        รายละเอียดคำขอ: {request.reference_number}
      </DialogTitle>

      <DialogContent dividers>
        {isConfirmingPrepare ? (
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
            <Typography variant="h6" color="warning.main" fontWeight="bold">
              ยืนยันการเตรียมการเสร็จสิ้น
            </Typography>
            <Typography variant="body1" color="text.secondary">
              คุณต้องการเปลี่ยนสถานะคำขอนี้เป็น "รอรับ" ใช่หรือไม่?
            </Typography>
          </Box>
        ) : showQR ? (
          <Box display="flex" flexDirection="column" alignItems="center" py={4} gap={3}>
            <Typography variant="h6" color="primary" fontWeight="bold">
              เตรียมการเสร็จสิ้น
            </Typography>
            <QRCodeSVG value={request.reference_number} size={200} />
            <Typography variant="body2" color="text.secondary">
              รหัสอ้างอิง: {request.reference_number}
            </Typography>
            <Typography variant="body2" color="error">
              กรุณานำ QR Code นี้ติดไว้ที่กล่อง/ซองพัสดุ
            </Typography>
          </Box>
        ) : (
          <Box display="flex" flexDirection="column" gap={2}>
            <Box display="flex" justifyContent="space-between">
              <Typography variant="subtitle2" color="text.secondary">ส่งคำขอเมื่อ</Typography>
              <Typography variant="body1">{request.created_at || '-'}</Typography>
            </Box>
            <Box display="flex" justifyContent="space-between">
              <Typography variant="subtitle2" color="text.secondary">แก้ไขล่าสุดเมื่อ</Typography>
              <Typography variant="body1">{request.updated_at || '-'}</Typography>
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="subtitle2" color="text.secondary">วันเดือนปีรับ</Typography>
              {(() => {
                const days = getOverdueDays(request.selected_date, request.status);
                if (days > 0) {
                  return (
                    <Typography variant="body1" color="error.main">
                      {formatDate(request.selected_date)} (เลยกำหนด {days} วัน)
                    </Typography>
                  );
                }
                return <Typography variant="body1">{formatDate(request.selected_date)}</Typography>;
              })()}
            </Box>
            <Box display="flex" justifyContent="space-between">
              <Typography variant="subtitle2" color="text.secondary">เวลารับ</Typography>
              <Typography variant="body1">{request.selected_time} น.</Typography>
            </Box>
            <Box display="flex" justifyContent="space-between">
              <Typography variant="subtitle2" color="text.secondary">สถานที่รับ</Typography>
              <Typography variant="body1" fontWeight="medium">{request.selected_location}</Typography>
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="subtitle2" color="text.secondary">สถานะ</Typography>
              {(() => {
                switch (request.status) {
                  case 'pending': return <Chip label="รอดำเนินการ" color="warning" size="small" sx={{ fontWeight: 'bold' }} />;
                  case 'preparing': return <Chip label="กำลังเตรียม" color="info" size="small" sx={{ fontWeight: 'bold' }} />;
                  case 'ready': return <Chip label="รอรับ" color="secondary" size="small" sx={{ fontWeight: 'bold' }} />;
                  case 'completed': return <Chip label="เสร็จสิ้น" color="success" size="small" sx={{ fontWeight: 'bold' }} />;
                  case 'cancelled': return <Chip label="ยกเลิก" size="small" sx={{ bgcolor: '#E0E0E0', color: '#616161', fontWeight: 'bold' }} />;
                }
              })()}
            </Box>

            <Divider sx={{ my: 1 }} />

            <Typography variant="subtitle1" fontWeight="bold">รายการที่ต้องจัดเตรียม</Typography>
            <Box bgcolor="background.default" p={2} borderRadius={2}>
              <Typography variant="subtitle2" color="text.primary" sx={{ mb: 1 }}>ถุงยางอนามัย</Typography>
              {Object.entries(request.condom_quantities).map(([type, qty]) => (
                <Box key={type} display="flex" justifyContent="space-between" mb={1} pl={2}>
                  <Typography variant="body2">• ขนาด {type}</Typography>
                  <Typography variant="body2" fontWeight="bold">{qty} ชิ้น</Typography>
                </Box>
              ))}

              <Divider sx={{ my: 1.5, borderStyle: 'dashed' }} />

              <Typography variant="subtitle2" color="text.primary" sx={{ mb: 1 }}>เพิ่มเติม</Typography>
              <Box display="flex" justifyContent="space-between" pl={2}>
                <Typography variant="body2">• สารหล่อลื่น</Typography>
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

            {request.status === 'ready' && (
              <Box display="flex" flexDirection="column" alignItems="center" py={2} gap={3}>
                <Divider sx={{ width: '100%', mb: 1 }} />
                <QRCodeSVG value={request.reference_number} size={200} />
                <Typography variant="body2" color="error" textAlign="center" fontWeight="medium">
                  กรุณานำ QR Code นี้ติดไว้ที่กล่อง/ซองพัสดุ
                </Typography>
              </Box>
            )}

            {request.status === 'cancelled' && request.cancel_reason && (
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
            <Button onClick={() => setIsConfirmingPrepare(false)}>กลับ</Button>
            <Button onClick={handleConfirmPrepare} variant="contained" color="primary">ยืนยัน</Button>
          </>
        ) : isConfirmingFinish ? (
          <>
            <Button onClick={() => setIsConfirmingFinish(false)}>กลับ</Button>
            <Button onClick={handleFinishPrepare} variant="contained" color="primary">ยืนยัน</Button>
          </>
        ) : showQR ? (
          <Button onClick={onCloseDialog} variant="contained" color="primary">ปิด</Button>
        ) : isRejecting ? (
          <>
            <Button onClick={() => setIsRejecting(false)}>กลับ</Button>
            <Button
              onClick={handleCancelConfirm}
              color="error"
              variant="contained"
              disabled={!rejectReason.trim()}
            >
              ยืนยันการยกเลิก
            </Button>
          </>
        ) : (
          <>
            <Button onClick={onCloseDialog} color="inherit">ปิด</Button>
            {request.status === 'pending' && (
              <>
                <Button onClick={() => setIsRejecting(true)} color="error" variant="outlined">
                  ยกเลิกคำขอ
                </Button>
                <Button onClick={() => setIsConfirmingPrepare(true)} color="primary" variant="contained">
                  จัดเตรียมรายการ
                </Button>
              </>
            )}
            {request.status === 'preparing' && (
              <Button onClick={() => setIsConfirmingFinish(true)} color="primary" variant="contained">
                เตรียมการเสร็จสิ้น
              </Button>
            )}
          </>
        )}
      </DialogActions>
    </Dialog>
  );
}
