import {
  Drawer, Box, Typography, Divider, IconButton, Chip,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import type { StaffAuditLogRow } from '../../hooks/useStaffAuditLog';
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

// ─── Diff Row (before / after) ────────────────────────────────────────────────

interface DiffRowProps { fieldKey: string; oldVal: unknown; newVal: unknown }

function DiffRow({ fieldKey, oldVal, newVal }: DiffRowProps) {
  const fmt = (v: unknown) => v === null || v === undefined ? '—' : String(v);
  return (
    <Box display="flex" justifyContent="space-between" alignItems="center">
      <Typography variant="subtitle2" color="text.secondary">{fieldKey}</Typography>
      <Box display="flex" alignItems="center" gap={1}>
        <Typography variant="body1" sx={{ color: '#C62828' }}>{fmt(oldVal)}</Typography>
        <Typography variant="body2" color="text.disabled">→</Typography>
        <Typography variant="body1" sx={{ color: '#2E7D32' }}>{fmt(newVal)}</Typography>
      </Box>
    </Box>
  );
}

// ─── Value Row (insert-only display) ─────────────────────────────────────────

function ValueRow({ fieldKey, value }: { fieldKey: string; value: unknown }) {
  const fmt = (v: unknown) => v === null || v === undefined ? '—' : String(v);
  return (
    <Box display="flex" justifyContent="space-between" alignItems="center">
      <Typography variant="subtitle2" color="text.secondary">{fieldKey}</Typography>
      <Typography variant="body1">{fmt(value)}</Typography>
    </Box>
  );
}

// ─── Field group definitions ──────────────────────────────────────────────────

const PROFILE_FIELD_SET   = new Set(['first_name', 'last_name', 'email', 'service_center']);
const PROFILE_FIELD_ORDER = ['first_name', 'last_name', 'email', 'service_center'];
const ROLE_FIELD_SET      = new Set(['role']);

// ─── Main Component ───────────────────────────────────────────────────────────

interface Props {
  row: StaffAuditLogRow | null;
  onClose: () => void;
}

export default function StaffAuditLogDetailDrawer({ row, onClose }: Props) {
  const actionCfg = row
    ? (AUDIT_ACTION_COLOR[row.action as AuditAction] ?? AUDIT_ACTION_FALLBACK_COLOR)
    : null;
  const actionLabel = row
    ? (AUDIT_ACTION_LABEL[row.action as AuditAction] ?? row.action)
    : '';

  // Compute unified key set
  const allKeys: string[] = [];
  if (row) {
    const keySet = new Set([
      ...Object.keys(row.old_value ?? {}),
      ...Object.keys(row.new_value ?? {}),
    ]);
    allKeys.push(...Array.from(keySet).sort());
  }

  // Group keys — only include keys actually present in the data
  const profileKeys = PROFILE_FIELD_ORDER.filter(k => allKeys.includes(k));
  const roleKeys    = allKeys.filter(k => ROLE_FIELD_SET.has(k));
  const otherKeys   = allKeys.filter(k => !PROFILE_FIELD_SET.has(k) && !ROLE_FIELD_SET.has(k));
  const hasGroups   = profileKeys.length > 0 || roleKeys.length > 0;

  const hasOldAndNew   = row && (row.old_value !== null || row.new_value !== null);
  const isInsertOnly   = row !== null && row.old_value === null && row.new_value !== null;
  const hideDataSection = row !== null && (row.action === 'staff_created' || row.action === 'staff_deleted');

  const orderedKeys = [...profileKeys, ...roleKeys, ...otherKeys];

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

          {/* Meta */}
          <Box display="flex" flexDirection="column" gap={2} sx={{ mb: 3 }}>
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
              <Typography variant="subtitle2" color="text.secondary">UUID เจ้าหน้าที่</Typography>
              <Typography variant="body2">{row.target_id}</Typography>
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="subtitle2" color="text.secondary">โดย</Typography>
              <Typography variant="body1">{row.full_name}</Typography>
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="subtitle2" color="text.secondary">เมื่อวันที่</Typography>
              <Typography variant="body1">{formatDateTime(row.created_at)}</Typography>
            </Box>
          </Box>

          <Divider sx={{ mb: 2 }} />

          {/* Data Section */}
          {!hideDataSection && (
            hasOldAndNew && allKeys.length > 0 ? (
              isInsertOnly ? (
                <>
                  <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 2 }}>ข้อมูล</Typography>
                  <Box display="flex" flexDirection="column" gap={2}>
                    {orderedKeys.map(k => (
                      <ValueRow key={k} fieldKey={k} value={row.new_value?.[k]} />
                    ))}
                  </Box>
                </>
              ) : (
                <>
                  <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 2 }}>การเปลี่ยนแปลง</Typography>
                  <Box display="flex" flexDirection="column" gap={2}>
                    {(hasGroups ? orderedKeys : allKeys).map(k => {
                      const oldVal = row.old_value?.[k] ?? null;
                      const newVal = row.new_value?.[k] ?? null;
                      return <DiffRow key={k} fieldKey={k} oldVal={oldVal} newVal={newVal} />;
                    })}
                  </Box>
                </>
              )
            ) : null
          )}
        </Box>
      )}
    </Drawer>
  );
}
