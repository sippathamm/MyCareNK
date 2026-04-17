import { useState } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, TextField, Typography, Box, CircularProgress,
  Alert, Divider,
} from '@mui/material';
import InventoryIcon from '@mui/icons-material/Inventory2';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import type { InventoryForecastRow } from '../../hooks/useInventoryForecast';

interface RestockModalProps {
  open: boolean;
  target: InventoryForecastRow | null;
  onClose: () => void;
  onSuccess: () => void;
}

export default function RestockModal({ open, target, onClose, onSuccess }: RestockModalProps) {
  const { session } = useAuth();
  const [condomAdd, setCondomAdd] = useState('');
  const [lubricantAdd, setLubricantAdd] = useState('');
  const [note, setNote] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleClose = () => {
    if (loading) return;
    setCondomAdd('');
    setLubricantAdd('');
    setNote('');
    setError(null);
    onClose();
  };

  const handleSubmit = async () => {
    if (!target || !session?.user) return;

    const condomDelta = parseInt(condomAdd, 10) || 0;
    const lubricantDelta = parseInt(lubricantAdd, 10) || 0;

    if (condomDelta <= 0 && lubricantDelta <= 0) {
      setError('กรุณากรอกจำนวนถุงยางอนามัย/เจลหล่อลื่นที่ต้องการเติมอย่างน้อย 1 รายการ');
      return;
    }

    setLoading(true);
    setError(null);

    const { error: insertError } = await supabase
      .from('inventory_transactions')
      .insert({
        service_center: target.service_center,
        transaction_type: 'restock',
        condom_delta: condomDelta,
        lubricant_delta: lubricantDelta,
        note: note.trim() || null,
        performed_by: session.user.id,
      });

    if (insertError) {
      setError(insertError.message);
      setLoading(false);
      return;
    }

    // อัปเดต service_center_inventory โดยตรง
    const { error: updateError } = await supabase
      .from('service_center_inventory')
      .update({
        condom_qty: target.condom_qty + condomDelta,
        lubricant_qty: target.lubricant_qty + lubricantDelta,
        last_restocked_at: new Date().toISOString(),
        updated_by: session.user.id,
      })
      .eq('service_center', target.service_center);

    if (updateError) {
      setError(updateError.message);
      setLoading(false);
      return;
    }

    setLoading(false);
    setCondomAdd('');
    setLubricantAdd('');
    setNote('');
    onSuccess();
  };

  if (!target) return null;

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ pb: 1 }}>
        <Typography variant="h6" fontWeight="bold" lineHeight={1.2}>
          เติมรายการ
        </Typography>
        <Typography variant="caption" color="text.secondary">
          {target.service_center}
        </Typography>
      </DialogTitle>

      <Divider />

      <DialogContent sx={{ pt: 2.5 }}>
        {/* Current stock info */}
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
            { label: 'ถุงยางอนามัย', qty: target.condom_qty },
            { label: 'เจลหล่อลื่น', qty: target.lubricant_qty },
          ].map(({ label, qty }) => (
            <Box key={label}>
              <Typography variant="caption" color="text.secondary" display="block">{label}</Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                <Typography variant="body2" fontWeight={600}>{qty.toLocaleString()}</Typography>
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
          label="จำนวนถุงยางอนามัยที่เติม (ชิ้น)"
          value={condomAdd}
          onChange={(e) => setCondomAdd(e.target.value.replace(/\D/g, ''))}
          fullWidth
          type="number"
          inputProps={{ min: 0 }}
          sx={{ mb: 2 }}
          disabled={loading}
        />

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
          label="หมายเหตุ (ไม่บังคับ)"
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
