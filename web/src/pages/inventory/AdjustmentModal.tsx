import { useState } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, TextField, Typography, Box, CircularProgress,
  Alert, Divider, MenuItem, Collapse, Grid,
} from '@mui/material';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { useIsMobile } from '../../hooks/useIsMobile';
import type { InventoryForecastRow } from '../../hooks/useInventoryForecast';

const CONDOM_SIZES = ['49', '52', '54', '56'] as const;

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

type SizeDeltaMap = Record<string, string>;

const emptyDeltas = (): SizeDeltaMap => ({ '49': '', '52': '', '54': '', '56': '' });

export default function AdjustmentModal({ open, target, onClose, onSuccess }: AdjustmentModalProps) {
  const { session } = useAuth();
  const isMobile = useIsMobile();
  const [condomDeltas, setCondomDeltas] = useState<SizeDeltaMap>(emptyDeltas);
  const [lubricantDelta, setLubricantDelta] = useState('');
  const [reason, setReason] = useState('');
  const [note, setNote] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleClose = () => {
    if (loading) return;
    setCondomDeltas(emptyDeltas());
    setLubricantDelta('');
    setReason('');
    setNote('');
    setError(null);
    onClose();
  };

  const handleSubmit = async () => {
    if (!target || !session?.user) return;

    const condomQuantities: Record<string, number> = {};
    let hasCondom = false;
    for (const size of CONDOM_SIZES) {
      const v = parseInt(condomDeltas[size], 10);
      condomQuantities[size] = isNaN(v) ? 0 : v;
      if (!isNaN(v) && v !== 0) hasCondom = true;
    }
    const lubricant = parseInt(lubricantDelta, 10);

    if (!hasCondom && (isNaN(lubricant) || lubricant === 0)) {
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

    const condomDelta = Object.values(condomQuantities).reduce((a, b) => a + b, 0);

    const { error: insertError } = await supabase
      .from('inventory_logs')
      .insert({
        service_center:   target.service_center,
        action:           'adjustment',
        condom_delta:     condomDelta,
        condom_quantities: condomQuantities,
        lubricant_delta:  isNaN(lubricant) ? 0 : lubricant,
        reason,
        note:             note.trim() || null,
        performed_by:     session.user.id,
      });

    if (insertError) {
      setError(insertError.message);
      setLoading(false);
      return;
    }

    setLoading(false);
    setCondomDeltas(emptyDeltas());
    setLubricantDelta('');
    setReason('');
    setNote('');
    onSuccess();
  };

  if (!target) return null;

  // Compute after-adjustment per-size preview
  const sizeAfter: Record<string, number> = {};
  const clampedSizes: string[] = [];
  for (const size of CONDOM_SIZES) {
    const delta = parseInt(condomDeltas[size], 10);
    const current = target.condom_quantities?.[size] ?? 0;
    const raw = isNaN(delta) ? current : current + delta;
    sizeAfter[size] = Math.max(0, raw);
    if (!isNaN(delta) && delta !== 0 && raw < 0) clampedSizes.push(`ขนาด ${size} มม.`);
  }
  const lubricantParsed = parseInt(lubricantDelta, 10);
  const lubricantRaw = isNaN(lubricantParsed) ? target.lubricant_qty : target.lubricant_qty + lubricantParsed;
  const lubricantAfter = Math.max(0, lubricantRaw);
  if (!isNaN(lubricantParsed) && lubricantParsed !== 0 && lubricantRaw < 0) clampedSizes.push('เจลหล่อลื่น');

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="xs" fullWidth fullScreen={isMobile}>
      <DialogTitle sx={{ pb: 1 }}>
        <Typography component="div" variant="h6" fontWeight="bold" lineHeight={1.2}>
          ปรับสต็อก
        </Typography>
        <Typography component="div" variant="caption" color="text.secondary">
          {target.service_center}
        </Typography>
      </DialogTitle>

      <Divider />

      <DialogContent sx={{ pt: 2.5 }}>
        {/* Current → After preview */}
        <Typography variant="subtitle2" color="text.secondary" mb={1}>
          สต็อกก่อน → หลัง
        </Typography>
        <Box sx={{ bgcolor: 'action.hover', borderRadius: 1.5, p: 1.5, mb: 2.5 }}>
          <Typography variant="caption" color="text.secondary" fontWeight={700} display="block" mb={1}>
            ถุงยางอนามัย
          </Typography>
          <Grid container spacing={1.5}>
            {CONDOM_SIZES.map((size) => {
              const current = target.condom_quantities?.[size] ?? 0;
              const after = sizeAfter[size];
              return (
                <Grid key={size} size={6}>
                  <Typography variant="caption" color="text.secondary" display="block">
                    ขนาด {size} มม.
                  </Typography>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, flexWrap: 'wrap' }}>
                    <Typography variant="body2" fontWeight={600}>{current.toLocaleString()}</Typography>
                    {after !== current && (
                      <>
                        <Typography variant="caption" color="text.disabled">→</Typography>
                        <Typography variant="body2" fontWeight={600} color={after > current ? 'success.main' : 'error.main'}>
                          {after.toLocaleString()}
                        </Typography>
                      </>
                    )}
                    <Typography variant="caption" color="text.disabled">ชิ้น</Typography>
                  </Box>
                </Grid>
              );
            })}
          </Grid>
          <Divider sx={{ my: 1.5 }} />
          <Typography variant="caption" color="text.secondary" fontWeight={700} display="block" mb={1}>
            เจลหล่อลื่น
          </Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, flexWrap: 'wrap' }}>
            <Typography variant="body2" fontWeight={600}>{target.lubricant_qty.toLocaleString()}</Typography>
            {lubricantAfter !== target.lubricant_qty && (
              <>
                <Typography variant="caption" color="text.disabled">→</Typography>
                <Typography variant="body2" fontWeight={600} color={lubricantAfter > target.lubricant_qty ? 'success.main' : 'error.main'}>
                  {lubricantAfter.toLocaleString()}
                </Typography>
              </>
            )}
            <Typography variant="caption" color="text.disabled">ชิ้น</Typography>
          </Box>
        </Box>

        <Collapse in={clampedSizes.length > 0}>
          <Alert
            severity="warning"
            icon={<WarningAmberIcon fontSize="small" />}
            sx={{ mb: 2, borderRadius: 1.5, py: 0.5 }}
          >
            <Typography variant="caption">
              {clampedSizes.join(', ')} จะถูกปรับเป็น 0 เนื่องจากสต็อกไม่เพียงพอ
            </Typography>
          </Alert>
        </Collapse>

        {error && (
          <Alert severity="error" sx={{ mb: 2, borderRadius: 1.5 }}>
            {error}
          </Alert>
        )}

        <Typography variant="subtitle2" color="text.secondary" mb={1.5}>
          ปรับจำนวนถุงยางอนามัย (ชิ้น)
        </Typography>
        <Grid container spacing={1.5} mb={2}>
          {CONDOM_SIZES.map((size) => (
            <Grid key={size} size={6}>
              <TextField
                label={`ขนาด ${size} มม.`}
                helperText="+ เพิ่ม / − ลด"
                value={condomDeltas[size]}
                onChange={(e) =>
                  setCondomDeltas((prev) => ({ ...prev, [size]: e.target.value.replace(/[^0-9-]/g, '') }))
                }
                fullWidth
                type="number"
                size="small"
                disabled={loading}
              />
            </Grid>
          ))}
        </Grid>

        <TextField
          label="ปรับจำนวนเจลหล่อลื่น (ชิ้น)"
          helperText="+ เพิ่ม / - ลด"
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
