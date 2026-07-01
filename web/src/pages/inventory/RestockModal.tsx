import { useState } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, TextField, Typography, Box, CircularProgress,
  Alert, Divider, Grid,
} from '@mui/material';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { useIsMobile } from '../../hooks/useIsMobile';
import type { InventoryForecastRow } from '../../hooks/useInventoryForecast';

const CONDOM_SIZES = ['49', '52', '54', '56'] as const;

interface RestockModalProps {
  open: boolean;
  target: InventoryForecastRow | null;
  onClose: () => void;
  onSuccess: () => void;
}

type SizeMap = Record<string, string>;

const emptySizes = (): SizeMap => ({ '49': '', '52': '', '54': '', '56': '' });

export default function RestockModal({ open, target, onClose, onSuccess }: RestockModalProps) {
  const { session } = useAuth();
  const isMobile = useIsMobile();
  const [condomSizes, setCondomSizes] = useState<SizeMap>(emptySizes);
  const [lubricantAdd, setLubricantAdd] = useState('');
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleClose = () => {
    if (loading) return;
    setCondomSizes(emptySizes());
    setLubricantAdd('');
    setReason('');
    setError(null);
    onClose();
  };

  const handleSubmit = async () => {
    if (!target || !session?.user) return;

    const condomQuantities: Record<string, number> = {};
    let hasCondom = false;
    for (const size of CONDOM_SIZES) {
      const v = parseInt(condomSizes[size], 10) || 0;
      condomQuantities[size] = v;
      if (v > 0) hasCondom = true;
    }
    const lubricantDelta = parseInt(lubricantAdd, 10) || 0;

    if (!hasCondom && lubricantDelta <= 0) {
      setError('กรุณากรอกจำนวนที่ต้องการเติมอย่างน้อย 1 รายการ');
      return;
    }

    setLoading(true);
    setError(null);

    const condomDelta = Object.values(condomQuantities).reduce((a, b) => a + b, 0);

    const { error: insertError } = await supabase
      .from('inventory_logs')
      .insert({
        service_center:   target.service_center,
        action:           'restock',
        condom_delta:     condomDelta,
        condom_quantities: condomQuantities,
        lubricant_delta:  lubricantDelta,
        reason:           reason.trim() || null,
        performed_by:     session.user.id,
      });

    if (insertError) {
      setError(insertError.message);
      setLoading(false);
      return;
    }

    setLoading(false);
    setCondomSizes(emptySizes());
    setLubricantAdd('');
    setReason('');
    onSuccess();
  };

  if (!target) return null;

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="xs" fullWidth fullScreen={isMobile}>
      <DialogTitle sx={{ pb: 1 }}>
        <Typography component="div" variant="h6" fontWeight="bold" lineHeight={1.2}>
          เติมสต็อก
        </Typography>
        <Typography component="div" variant="caption" color="text.secondary">
          {target.service_center}
        </Typography>
      </DialogTitle>

      <Divider />

      <DialogContent sx={{ pt: 2.5 }}>
        {/* Current stock info */}
        <Box sx={{ bgcolor: 'action.hover', borderRadius: 1.5, p: 1.5, mb: 2.5 }}>
          <Typography variant="caption" color="text.secondary" display="block" mb={0.75}>
            สต็อกปัจจุบัน
          </Typography>
          <Grid container spacing={1.5}>
            {CONDOM_SIZES.map((size) => (
              <Grid key={size} size={6}>
                <Typography variant="caption" color="text.secondary" display="block">
                  ถุงยางอนามัย {size}mm
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                  <Typography variant="body2" fontWeight={600}>
                    {(target.condom_quantities?.[size] ?? 0).toLocaleString()}
                  </Typography>
                  <Typography variant="caption" color="text.disabled">ชิ้น</Typography>
                </Box>
              </Grid>
            ))}
            <Grid size={6}>
              <Typography variant="caption" color="text.secondary" display="block">เจลหล่อลื่น</Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                <Typography variant="body2" fontWeight={600}>{target.lubricant_qty.toLocaleString()}</Typography>
                <Typography variant="caption" color="text.disabled">ชิ้น</Typography>
              </Box>
            </Grid>
          </Grid>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 2, borderRadius: 1.5 }}>
            {error}
          </Alert>
        )}

        <Typography variant="subtitle2" color="text.secondary" mb={1.5}>
          จำนวนถุงยางอนามัยที่เติม (ชิ้น)
        </Typography>
        <Grid container spacing={1.5} mb={2}>
          {CONDOM_SIZES.map((size) => (
            <Grid key={size} size={6}>
              <TextField
                label={`ขนาด ${size}mm`}
                value={condomSizes[size]}
                onChange={(e) =>
                  setCondomSizes((prev) => ({ ...prev, [size]: e.target.value.replace(/\D/g, '') }))
                }
                fullWidth
                type="number"
                inputProps={{ min: 0 }}
                size="small"
                disabled={loading}
              />
            </Grid>
          ))}
        </Grid>

        <TextField
          label="จำนวนเจลหล่อลื่นที่เติม (ชิ้น)"
          value={lubricantAdd}
          onChange={(e) => setLubricantAdd(e.target.value.replace(/\D/g, ''))}
          fullWidth
          type="number"
          inputProps={{ min: 0 }}
          sx={{ mb: 2 }}
          disabled={loading}
        />

        <TextField
          label="เหตุผล (ไม่บังคับ)"
          value={reason}
          onChange={(e) => setReason(e.target.value)}
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
