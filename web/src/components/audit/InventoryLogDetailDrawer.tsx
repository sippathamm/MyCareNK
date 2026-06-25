import {
  Drawer, Box, Typography, Divider, IconButton, Chip,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import { useColorMode } from '../../contexts/ThemeContext';
import { getDeltaChipSx } from '../../utils/statusColors';
import type { InventoryLogRow } from '../../hooks/useInventoryLog';
import {
  AUDIT_ACTION_COLOR, AUDIT_ACTION_FALLBACK_COLOR, AUDIT_ACTION_LABEL,
} from '../../constants/auditLogActions';
import type { AuditAction } from '../../constants/auditLogActions';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function formatDateTime(iso: string): string {
  const d = new Date(iso);
  const datePart = d.toLocaleDateString('th-TH', { year: 'numeric', month: 'short', day: 'numeric' });
  const timePart = d.toLocaleTimeString('th-TH', { hour: '2-digit', minute: '2-digit', hour12: false });
  return `${datePart} เวลา ${timePart} น.`;
}

// ─── Qty Chip ─────────────────────────────────────────────────────────────────

function QtyChip({ value }: { value: number }) {
  const { mode } = useColorMode();
  if (value === 0) return <Typography variant="body1" color="text.disabled">—</Typography>;
  const pos = value > 0;
  return (
    <Chip
      label={`${pos ? '+' : ''}${value.toLocaleString()}`}
      size="small"
      sx={getDeltaChipSx(value, mode)}
    />
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────

interface Props {
  row: InventoryLogRow | null;
  onClose: () => void;
}

export default function InventoryLogDetailDrawer({ row, onClose }: Props) {
  const actionCfg = row
    ? (AUDIT_ACTION_COLOR[row.action as AuditAction] ?? AUDIT_ACTION_FALLBACK_COLOR)
    : null;
  const actionLabel = row
    ? (AUDIT_ACTION_LABEL[row.action as AuditAction] ?? row.action)
    : '';

  return (
    <Drawer
      anchor="right"
      open={row !== null}
      onClose={onClose}
      PaperProps={{ sx: { width: { xs: '100vw', sm: 480 }, p: 3 } }}
    >
      {row && (
        <Box>
          {/* Header */}
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
            <Typography variant="h6" fontWeight="bold">รายละเอียด</Typography>
            <IconButton onClick={onClose} size="small"><CloseIcon /></IconButton>
          </Box>
          <Divider sx={{ mb: 2 }} />

          {/* Fields */}
          <Box display="flex" flexDirection="column" gap={2}>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="subtitle2" color="text.secondary">ประเภท</Typography>
              {actionCfg && (
                <Chip
                  label={actionLabel}
                  size="small"
                  sx={{ bgcolor: actionCfg.bg, color: actionCfg.color, fontWeight: 600, fontSize: '0.72rem' }}
                />
              )}
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="subtitle2" color="text.secondary">สถานบริการ</Typography>
              <Typography variant="body1">{row.service_center}</Typography>
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="subtitle2" color="text.secondary">ถุงยางอนามัย (ชิ้น)</Typography>
              <QtyChip value={row.condom_delta} />
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="subtitle2" color="text.secondary">เจลหล่อลื่น (ชิ้น)</Typography>
              <QtyChip value={row.lubricant_delta} />
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="subtitle2" color="text.secondary">โดย</Typography>
              <Typography variant="body1">{row.full_name}</Typography>
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="subtitle2" color="text.secondary">เมื่อวันที่</Typography>
              <Typography variant="body1">{formatDateTime(row.created_at)}</Typography>
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="flex-start">
              <Typography variant="subtitle2" color="text.secondary">เหตุผล</Typography>
              {row.reason
                ? <Typography variant="body1" sx={{ maxWidth: '60%', textAlign: 'right' }}>{row.reason}</Typography>
                : <Typography variant="body1" color="text.disabled">—</Typography>
              }
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="flex-start">
              <Typography variant="subtitle2" color="text.secondary">หมายเหตุ</Typography>
              {row.note
                ? <Typography variant="body1" sx={{ maxWidth: '60%', textAlign: 'right' }}>{row.note}</Typography>
                : <Typography variant="body1" color="text.disabled">—</Typography>
              }
            </Box>
          </Box>
        </Box>
      )}
    </Drawer>
  );
}
