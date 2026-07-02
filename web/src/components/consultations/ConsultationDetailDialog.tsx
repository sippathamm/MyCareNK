import { useState } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, Typography, Box, Divider, TextField, Chip, Stack,
} from '@mui/material';
import { useColorMode } from '../../contexts/ThemeContext';
import { useIsMobile } from '../../hooks/useIsMobile';
import { getConsultationStatusSx } from '../../utils/statusColors';
import EventAvailableOutlinedIcon from '@mui/icons-material/EventAvailableOutlined';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import CancelOutlinedIcon from '@mui/icons-material/CancelOutlined';
import ConfirmDialog from '../shared/ConfirmDialog';
import type { Enums } from '../../lib/database.types';

// eslint-disable-next-line react-refresh/only-export-components
export const REASON_LABELS: Record<string, string> = {
  pep:     'รับยา PEP',
  prep:    'รับยา PrEP',
  hiv:     'ตรวจเลือด HIV',
  consult: 'ปรึกษาทั่วไป',
};

export interface ConsultationData {
  id: string;
  reference_number: string;
  user_id: string | null;
  reason: string;
  selected_service_center: string;
  selected_date: string;
  selected_time: string;
  note: string | null;
  consultation_status: Enums<'consultation_status'>;
  cancel_reason: string | null;
  handled_by: string | null;
  handled_by_name: string | null;
  created_at: string;
  updated_at: string;
  phone_number: string | null;
  nickname: string | null;
}

interface ConsultationDetailDialogProps {
  open: boolean;
  consultation: ConsultationData | null;
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

const CONSULTATION_STATUS_LABELS: Record<string, string> = {
  pending:            'รอยืนยัน',
  confirmed:          'ยืนยันแล้ว',
  completed:          'เสร็จสิ้น',
  cancelled_by_user:  'ยกเลิกโดยผู้ใช้',
  cancelled_by_staff: 'ยกเลิกโดยเจ้าหน้าที่',
};

export default function ConsultationDetailDialog({
  open, consultation, onClose, onStatusChange, statusUpdating = false,
}: ConsultationDetailDialogProps) {
  const { mode } = useColorMode();
  const isMobile = useIsMobile();
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
    if (!consultation) return;
    const ok = await onStatusChange(consultation.id, 'confirmed');
    if (ok) handleClose();
  };

  const handleComplete = async () => {
    if (!consultation) return;
    const ok = await onStatusChange(consultation.id, 'completed');
    if (ok) handleClose();
  };

  const handleCancelConfirm = async () => {
    if (!consultation || !cancelReason.trim()) return;
    const ok = await onStatusChange(consultation.id, 'cancelled_by_staff', cancelReason);
    if (ok) handleClose();
  };

  return (
    <>
      <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth fullScreen={isMobile}>
        {consultation && (
          <>
            <DialogTitle sx={{ pb: 1 }}>
              <Typography component="div" variant="h6" fontWeight="bold" lineHeight={1.2}>
                รายละเอียดการนัดรับคำปรึกษา
              </Typography>
              <Typography component="div" variant="caption" color="text.secondary">
                {consultation.reference_number}
              </Typography>
            </DialogTitle>

            <DialogContent dividers>
              <Box display="flex" flexDirection="column" gap={2}>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">ส่งคำขอเมื่อ</Typography>
                  <Typography variant="body1">{formatDateTime(consultation.created_at)}</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">เปลี่ยนแปลงล่าสุดเมื่อ</Typography>
                  <Typography variant="body1">{formatDateTime(consultation.updated_at)}</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">วันนัดรับคำปรึกษา</Typography>
                  <Typography variant="body1">{formatDate(consultation.selected_date)}</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">เวลานัดรับคำปรึกษา</Typography>
                  <Typography variant="body1">{consultation.selected_time?.slice(0, 5)} น.</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">สถานที่</Typography>
                  <Typography variant="body1" fontWeight="medium">{consultation.selected_service_center}</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between" alignItems="center">
                  <Typography variant="subtitle2" color="text.secondary">สถานะ</Typography>
                  <Chip
                    label={CONSULTATION_STATUS_LABELS[consultation.consultation_status] ?? consultation.consultation_status}
                    size="small"
                    sx={getConsultationStatusSx(consultation.consultation_status, mode)}
                  />
                </Box>
                {consultation.handled_by_name && (
                  <Box display="flex" justifyContent="space-between">
                    <Typography variant="subtitle2" color="text.secondary">ดำเนินการโดย</Typography>
                    <Typography variant="body1">{consultation.handled_by_name}</Typography>
                  </Box>
                )}

                <Divider sx={{ my: 1 }} />

                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">เรื่องที่ต้องการรับคำปรึกษา</Typography>
                  <Typography variant="body1">{REASON_LABELS[consultation.reason] ?? consultation.reason}</Typography>
                </Box>

                <Divider sx={{ my: 1 }} />

                <Typography variant="subtitle1" fontWeight="bold">ข้อมูลติดต่อ</Typography>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">ชื่อที่ใช้เรียก</Typography>
                  <Typography variant="body1">{consultation.nickname ?? '-'}</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between">
                  <Typography variant="subtitle2" color="text.secondary">หมายเลขโทรศัพท์</Typography>
                  <Typography variant="body1">{consultation.phone_number ?? '-'}</Typography>
                </Box>

                {consultation.note && (
                  <Box>
                    <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>หมายเหตุเพิ่มเติม</Typography>
                    <Typography variant="body2" sx={{ fontStyle: 'italic', bgcolor: 'rgba(0,0,0,0.03)', p: 1.5, borderRadius: 1 }}>
                      {consultation.note}
                    </Typography>
                  </Box>
                )}

                {(consultation.consultation_status === 'cancelled_by_user' || consultation.consultation_status === 'cancelled_by_staff') && consultation.cancel_reason && (
                  <Box>
                    <Typography variant="subtitle2" color="error.main" sx={{ mb: 1 }}>เหตุผลที่ยกเลิก</Typography>
                    <Typography variant="body2" sx={{ fontStyle: 'italic', bgcolor: 'rgba(211,47,47,0.06)', p: 1.5, borderRadius: 1, color: 'error.main' }}>
                      {consultation.cancel_reason}
                    </Typography>
                  </Box>
                )}
              </Box>
            </DialogContent>

            <DialogActions sx={{ p: 2 }}>
              <Button onClick={handleClose} color="inherit">ปิด</Button>
              {consultation.consultation_status === 'pending' && (
                <Button onClick={() => setIsCancelling(true)} color="error" variant="outlined">
                  ยกเลิกการนัดรับคำปรึกษา
                </Button>
              )}
              {consultation.consultation_status === 'pending' && (
                <Button onClick={() => setIsConfirming(true)} color="primary" variant="contained">
                  ยืนยันการนัดรับคำปรึกษา
                </Button>
              )}
              {consultation.consultation_status === 'confirmed' && (
                <Button onClick={() => setIsCompleting(true)} color="success" variant="contained">
                  เสร็จสิ้น
                </Button>
              )}
            </DialogActions>
          </>
        )}
      </Dialog>

      {/* Confirm: Confirm Consultation */}
      <ConfirmDialog
        open={isConfirming}
        icon={<EventAvailableOutlinedIcon color="primary" />}
        title="ยืนยันการนัดรับคำปรึกษา"
        body={
          <Stack direction="row" alignItems="center" gap={0.75} flexWrap="wrap">
            <Typography variant="body2" color="text.secondary">คุณต้องการเปลี่ยนสถานะการนัดรับคำปรึกษานี้เป็น</Typography>
            <Chip label="ยืนยันแล้ว" size="small" sx={getConsultationStatusSx('confirmed', mode)} />
            <Typography variant="body2" color="text.secondary">ใช่หรือไม่?</Typography>
          </Stack>
        }
        confirmLabel="ยืนยัน"
        confirmColor="primary"
        loading={statusUpdating}
        onConfirm={handleConfirm}
        onCancel={() => setIsConfirming(false)}
      />

      {/* Confirm: Complete */}
      <ConfirmDialog
        open={isCompleting}
        icon={<CheckCircleOutlineIcon color="success" />}
        title="ยืนยันการเสร็จสิ้น"
        body={
          <Stack direction="row" alignItems="center" gap={0.75} flexWrap="wrap">
            <Typography variant="body2" color="text.secondary">คุณต้องการเปลี่ยนสถานะการนัดรับคำปรึกษานี้เป็น</Typography>
            <Chip label="เสร็จสิ้น" size="small" sx={getConsultationStatusSx('completed', mode)} />
            <Typography variant="body2" color="text.secondary">ใช่หรือไม่?</Typography>
          </Stack>
        }
        confirmLabel="ยืนยัน"
        confirmColor="success"
        loading={statusUpdating}
        onConfirm={handleComplete}
        onCancel={() => setIsCompleting(false)}
      />

      {/* Confirm: Cancel Consultation */}
      <ConfirmDialog
        open={isCancelling}
        icon={<CancelOutlinedIcon color="error" />}
        title="ยกเลิกการนัดรับคำปรึกษา"
        body="กรุณาระบุเหตุผลที่ยกเลิก"
        confirmLabel="ยืนยันการยกเลิก"
        confirmColor="error"
        confirmDisabled={!cancelReason.trim()}
        loading={statusUpdating}
        onConfirm={handleCancelConfirm}
        onCancel={() => { setIsCancelling(false); setCancelReason(''); }}
        maxWidth="sm"
      >
        <TextField
          fullWidth
          label="เหตุผลที่ยกเลิก"
          multiline
          rows={3}
          value={cancelReason}
          onChange={(e) => setCancelReason(e.target.value)}
          error={cancelReason.trim() === ''}
          helperText={cancelReason.trim() === '' ? 'จำเป็นต้องระบุเหตุผล' : ''}
          color="error"
          autoFocus
        />
      </ConfirmDialog>
    </>
  );
}
