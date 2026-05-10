import { useState } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, Typography, Box, Divider, TextField, Chip, CircularProgress,
} from '@mui/material';
import type { Enums } from '../../lib/database.types';

export const REASON_LABELS: Record<string, string> = {
  pep:     'รับยา PEP',
  prep:    'รับยา PrEP',
  hiv:     'ตรวจเลือด HIV',
  consult: 'ปรึกษาทั่วไป',
};

export interface AppointmentData {
  id: string;
  reference_number: string;
  user_id: string;
  reason: string;
  selected_service_center: Enums<'service_center'>;
  selected_date: string;
  selected_time: string;
  note: string | null;
  appointment_status: Enums<'appointment_status'>;
  cancel_reason: string | null;
  handled_by: string | null;
  created_at: string;
  updated_at: string;
}

interface AppointmentDetailDialogProps {
  open: boolean;
  appointment: AppointmentData | null;
  onClose: () => void;
  onStatusChange: (id: string, newStatus: string, reason?: string) => Promise<boolean>;
  statusUpdating?: boolean;
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString('th-TH', {
    day: 'numeric', month: 'long', year: 'numeric',
  });
}

function formatDateTime(dateStr: string): string {
  const d = new Date(dateStr);
  return `${d.toLocaleDateString('th-TH', { day: 'numeric', month: 'short', year: 'numeric' })} ${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')} น.`;
}

function StatusChip({ status }: { status: Enums<'appointment_status'> }) {
  switch (status) {
    case 'pending':           return <Chip label="รอยืนยัน"            color="warning"     size="small" sx={{ fontWeight: 'bold' }} />;
    case 'confirmed':         return <Chip label="ยืนยันแล้ว"           color="secondary"   size="small" sx={{ fontWeight: 'bold' }} />;
    case 'completed':         return <Chip label="เสร็จสิ้น"            color="success"   size="small" sx={{ fontWeight: 'bold' }} />;
    case 'cancelled_by_user': return <Chip label="ยกเลิกโดยผู้ใช้"     size="small" sx={{ bgcolor: 'grey.200', color: 'text.secondary', fontWeight: 'bold' }} />;
    case 'cancelled_by_staff':return <Chip label="ยกเลิกโดยเจ้าหน้าที่" size="small" sx={{ bgcolor: 'grey.200', color: 'text.secondary', fontWeight: 'bold' }} />;
    default:                  return <Chip label={status} size="small" />;
  }
}

export default function AppointmentDetailDialog({
  open, appointment, onClose, onStatusChange, statusUpdating = false,
}: AppointmentDetailDialogProps) {
  const [cancelReason, setCancelReason] = useState('');
  const [isCancelling, setIsCancelling] = useState(false);
  const [isConfirming, setIsConfirming] = useState(false);
  const [isCompleting, setIsCompleting] = useState(false);

  const resetState = () => {
    setIsCancelling(false);
    setCancelReason('');
    setIsConfirming(false);
    setIsCompleting(false);
  };

  const handleClose = () => { resetState(); onClose(); };

  const handleConfirm = async () => {
    if (!appointment) return;
    const ok = await onStatusChange(appointment.id, 'confirmed');
    if (ok) handleClose();
  };

  const handleComplete = async () => {
    if (!appointment) return;
    const ok = await onStatusChange(appointment.id, 'completed');
    if (ok) handleClose();
  };

  const handleCancelConfirm = async () => {
    if (!appointment || !cancelReason.trim()) return;
    const ok = await onStatusChange(appointment.id, 'cancelled_by_staff', cancelReason);
    if (ok) handleClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      {appointment && (
        <>
          <DialogTitle sx={{ pb: 1 }}>
            <Typography variant="h6" fontWeight="bold" lineHeight={1.2}>
              รายละเอียดการนัดหมาย
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {appointment.reference_number}
            </Typography>
          </DialogTitle>

          <DialogContent dividers>
            {isConfirming ? (
              <Box display="flex" flexDirection="column" alignItems="center" py={4} gap={3}>
                <Typography variant="h6" color="primary.main" fontWeight="bold">ยืนยันนัดหมาย</Typography>
                <Typography variant="body1" color="text.secondary">
                  คุณต้องการยืนยันนัดหมายนี้ใช่หรือไม่?
                </Typography>
              </Box>
            ) : isCompleting ? (
              <Box display="flex" flexDirection="column" alignItems="center" py={4} gap={3}>
                <Typography variant="h6" color="success.main" fontWeight="bold">ยืนยันการเสร็จสิ้น</Typography>
                <Typography variant="body1" color="text.secondary">
                  คุณต้องการเปลี่ยนสถานะนัดหมายนี้เป็น "เสร็จสิ้น" ใช่หรือไม่?
                </Typography>
              </Box>
            ) : (
              <Box display="flex" flexDirection="column" gap={2}>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">ส่งคำขอเมื่อ</Typography>
                  <Typography variant="body1">{formatDateTime(appointment.created_at)}</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">เปลี่ยนแปลงล่าสุดเมื่อ</Typography>
                  <Typography variant="body1">{formatDateTime(appointment.updated_at)}</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">วันนัดหมาย</Typography>
                  <Typography variant="body1">{formatDate(appointment.selected_date)}</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">เวลานัดหมาย</Typography>
                  <Typography variant="body1">{appointment.selected_time?.slice(0, 5)} น.</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">สถานที่</Typography>
                  <Typography variant="body1" fontWeight="medium">{appointment.selected_service_center}</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between" alignItems="center">
                  <Typography variant="subtitle2" color="text.secondary">สถานะ</Typography>
                  <StatusChip status={appointment.appointment_status} />
                </Box>

                <Divider sx={{ my: 1 }} />

                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">เรื่องที่ต้องการพบแพทย์</Typography>
                  <Typography variant="body1">{REASON_LABELS[appointment.reason] ?? appointment.reason}</Typography>
                </Box>

                {appointment.note && (
                  <Box>
                    <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>หมายเหตุเพิ่มเติม</Typography>
                    <Typography variant="body2" sx={{ fontStyle: 'italic', bgcolor: 'rgba(0,0,0,0.03)', p: 1.5, borderRadius: 1 }}>
                      {appointment.note}
                    </Typography>
                  </Box>
                )}

                {(appointment.appointment_status === 'cancelled_by_user' || appointment.appointment_status === 'cancelled_by_staff') && appointment.cancel_reason && (
                  <Box>
                    <Typography variant="subtitle2" color="error.main" sx={{ mb: 1 }}>เหตุผลที่ยกเลิก</Typography>
                    <Typography variant="body2" sx={{ fontStyle: 'italic', bgcolor: 'rgba(211,47,47,0.06)', p: 1.5, borderRadius: 1, color: 'error.main' }}>
                      {appointment.cancel_reason}
                    </Typography>
                  </Box>
                )}

                {isCancelling && (
                  <Box>
                    <TextField
                      fullWidth
                      label="ระบุเหตุผลที่ยกเลิก"
                      multiline
                      rows={3}
                      value={cancelReason}
                      onChange={(e) => setCancelReason(e.target.value)}
                      error={cancelReason.trim() === ''}
                      helperText={cancelReason.trim() === '' ? 'จำเป็นต้องระบุเหตุผล' : ''}
                      color="error"
                      autoFocus
                    />
                  </Box>
                )}
              </Box>
            )}
          </DialogContent>

          <DialogActions sx={{ p: 2 }}>
            {isConfirming ? (
              <>
                <Button onClick={() => setIsConfirming(false)} disabled={statusUpdating} color="inherit">กลับ</Button>
                <Button
                  onClick={handleConfirm}
                  variant="contained"
                  color="primary"
                  disabled={statusUpdating}
                  endIcon={statusUpdating ? <CircularProgress size={16} color="inherit" /> : null}
                >
                  ยืนยัน
                </Button>
              </>
            ) : isCompleting ? (
              <>
                <Button onClick={() => setIsCompleting(false)} disabled={statusUpdating} color="inherit">กลับ</Button>
                <Button
                  onClick={handleComplete}
                  variant="contained"
                  color="success"
                  disabled={statusUpdating}
                  endIcon={statusUpdating ? <CircularProgress size={16} color="inherit" /> : null}
                >
                  ยืนยัน
                </Button>
              </>
            ) : isCancelling ? (
              <>
                <Button onClick={() => setIsCancelling(false)} disabled={statusUpdating} color="inherit">กลับ</Button>
                <Button
                  onClick={handleCancelConfirm}
                  color="error"
                  variant="contained"
                  disabled={!cancelReason.trim() || statusUpdating}
                  endIcon={statusUpdating ? <CircularProgress size={16} color="inherit" /> : null}
                >
                  ยืนยันการยกเลิก
                </Button>
              </>
            ) : (
              <>
                <Button onClick={handleClose} color="inherit">ปิด</Button>
                {appointment.appointment_status === 'pending' && (
                  <Button onClick={() => setIsCancelling(true)} color="error" variant="outlined">
                    ยกเลิกนัดหมาย
                  </Button>
                )}
                {appointment.appointment_status === 'pending' && (
                  <Button onClick={() => setIsConfirming(true)} color="primary" variant="contained">
                    ยืนยันนัดหมาย
                  </Button>
                )}
                {appointment.appointment_status === 'confirmed' && (
                  <Button onClick={() => setIsCompleting(true)} color="success" variant="contained">
                    เสร็จสิ้น
                  </Button>
                )}
              </>
            )}
          </DialogActions>
        </>
      )}
    </Dialog>
  );
}
