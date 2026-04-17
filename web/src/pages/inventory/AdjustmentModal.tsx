import { useState } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, TextField, Typography, Box, CircularProgress,
  Alert, Divider, MenuItem,
} from '@mui/material';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import type { InventoryForecastRow } from '../../hooks/useInventoryForecast';

const ADJUSTMENT_REASONS = [
  'สต็อกเสียหาย',
  'สต็อกสูญหาย',
  'นับสต็อกใหม่',
  'โอนย้ายระหว่างสถานบริการ',
  'อื่นๆ',
] as const;

interface AdjustmentModalProps {
  open: boolean;
  target: InventoryForecastRow | null;
  onClose: () => void;
  onSuccess: () => void;
}

export default function AdjustmentModal({ open, target, onClose, onSuccess }: AdjustmentModalProps) {
  const { session } = useAuth();
  const [condomDelta, setCondomDelta] = useState('');
  const [lubricantDelta, setLubricantDelta] = useState('');
  const [reason, setReason] = useState('');
  const [note, setNote] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleClose = () => {
    if (loading) return;
    setCondomDelta('');
    setLubricantDelta('');
    setReason('');
    setNote('');
    setError(null);
    onClose();
  };

  const handleSubmit = async () => {
    if (!target || !session?.user) return;

    const condom = parseInt(condomDelta, 10);
    const lubricant = parseInt(lubricantDelta, 10);

    if ((isNaN(condom) || condom === 0) && (isNaN(lubricant) || lubricant === 0)) {
      setError('กรุณากรอกจำนวนที่ต้องการปรับแก้อย่างน้อย 1 รายการ (ค่าบวก = เพิ่ม, ค่าลบ = ลด)');
      return;
    }
    if (!reason) {
      setError('กรุณาเลือกเหตุผลการปรับแก้');
      return;
    }
    if (reason === 'อื่นๆ' && !note.trim()) {
      setError('กรุณาระบุหมายเหตุเมื่อเลือกเหตุผล "อื่นๆ"');
      return;
    }

    setLoading(true);
    setError(null);

    const noteText = [reason, note.trim()].filter(Boolean).join(' — ');

    // Insert adjustment transaction — trigger apply_inventory_adjustment จะอัปเดต service_center_inventory อัตโนมัติ
    const { error: insertError } = await supabase
      .from('inventory_transactions')
      .insert({
        service_center: target.service_center,
        transaction_type: 'adjustment',
        condom_delta: isNaN(condom) ? 0 : condom,
        lubricant_delta: isNaN(lubricant) ? 0 : lubricant,
        note: noteText,
        performed_by: session.user.id,
      });

    if (insertError) {
      setError(insertError.message);
      setLoading(false);
      return;
    }

    setLoading(false);
    setCondomDelta('');
    setLubricantDelta('');
    setReason('');
    setNote('');
    onSuccess();
  };

  if (!target) return null;

  const condomPreview = parseInt(condomDelta, 10);
  const lubricantPreview = parseInt(lubricantDelta, 10);
  const condomAfter = isNaN(condomPreview) ? target.condom_qty : Math.max(0, target.condom_qty + condomPreview);
  const lubricantAfter = isNaN(lubricantPreview) ? target.lubricant_qty : Math.max(0, target.lubricant_qty + lubricantPreview);

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ pb: 1 }}>
        <Typography variant="h6" fontWeight="bold" lineHeight={1.2}>
          ปรับแก้สต็อก
        </Typography>
        <Typography variant="caption" color="text.secondary">
          {target.service_center}
        </Typography>
      </DialogTitle>

      <Divider />

      <DialogContent sx={{ pt: 2.5 }}>
        {/* Current → After preview */}
        <Box
          sx={{
            bgcolor: 'grey.50',
            borderRadius: 1.5,
            p: 1.5,
            mb: 2.5,
            display: 'grid',
            gridTemplateColumns: '1fr 1fr',
            gap: 1.5,
          }}
        >
          {[
            { label: 'ถุงยางอนามัย', current: target.condom_qty, after: condomAfter },
            { label: 'เจลหล่อลื่น', current: target.lubricant_qty, after: lubricantAfter },
          ].map(({ label, current, after }) => (
            <Box key={label}>
              <Typography variant="caption" color="text.secondary" display="block">{label}</Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, flexWrap: 'wrap' }}>
                <Typography variant="body2" fontWeight={600}>{current.toLocaleString()}</Typography>
                {after !== current && (
                  <>
                    <Typography variant="caption" color="text.disabled">→</Typography>
                    <Typography
                      variant="body2"
                      fontWeight={600}
                      color={after > current ? 'success.main' : 'error.main'}
                    >
                      {after.toLocaleString()}
                    </Typography>
                  </>
                )}
                <Typography variant="caption" color="text.disabled">ชิ้น</Typography>
              </Box>
            </Box>
          ))}
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 2, borderRadius: 1.5 }}>
            {error}
          </Alert>
        )}

        <TextField
          label="ปรับจำนวนถุงยางอนามัย (ชิ้น)"
          helperText="ค่าบวก = เพิ่ม  |  ค่าลบ = ลด  เช่น +20 หรือ -5"
          value={condomDelta}
          onChange={(e) => setCondomDelta(e.target.value.replace(/[^0-9-]/g, ''))}
          fullWidth
          type="number"
          sx={{ mb: 2 }}
          disabled={loading}
        />

        <TextField
          label="ปรับจำนวนเจลหล่อลื่น (ชิ้น)"
          helperText="ค่าบวก = เพิ่ม  |  ค่าลบ = ลด  เช่น +20 หรือ -5"
          value={lubricantDelta}
          onChange={(e) => setLubricantDelta(e.target.value.replace(/[^0-9-]/g, ''))}
          fullWidth
          type="number"
          sx={{ mb: 2 }}
          disabled={loading}
        />

        <TextField
          select
          label="เหตุผล *"
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          fullWidth
          sx={{ mb: 2 }}
          disabled={loading}
        >
          {ADJUSTMENT_REASONS.map((r) => (
            <MenuItem key={r} value={r}>{r}</MenuItem>
          ))}
        </TextField>

        <TextField
          label={reason === 'อื่นๆ' ? 'หมายเหตุ *' : 'หมายเหตุ (ไม่บังคับ)'}
          value={note}
          onChange={(e) => setNote(e.target.value)}
          fullWidth
          multiline
          rows={2}
          disabled={loading}
        />
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 2.5, gap: 1 }}>
        <Button onClick={handleClose} disabled={loading} color="inherit">
          ยกเลิก
        </Button>
        <Button
          onClick={handleSubmit}
          variant="contained"
          disabled={loading}
          startIcon={loading ? <CircularProgress size={16} color="inherit" /> : null}
        >
          {loading ? 'กำลังบันทึก...' : 'บันทึก'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
