import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, Box, Typography, Divider, Chip,
} from '@mui/material';
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

interface DiffRowProps { rawKey: string; fieldKey: string; oldVal: unknown; newVal: unknown }

function DiffRow({ rawKey, fieldKey, oldVal, newVal }: DiffRowProps) {
  return (
    <Box display="flex" justifyContent="space-between" alignItems="center">
      <Typography variant="subtitle2" color="text.secondary">{fieldKey}</Typography>
      <Box display="flex" alignItems="center" gap={1}>
        <Typography variant="body1" sx={{ color: '#C62828' }}>{formatFieldValue(rawKey, oldVal)}</Typography>
        <Typography variant="body2" color="text.disabled">→</Typography>
        <Typography variant="body1" sx={{ color: '#2E7D32' }}>{formatFieldValue(rawKey, newVal)}</Typography>
      </Box>
    </Box>
  );
}

// ─── Value Row (insert-only display) ─────────────────────────────────────────

function ValueRow({ rawKey, fieldKey, value }: { rawKey: string; fieldKey: string; value: unknown }) {
  return (
    <Box display="flex" justifyContent="space-between" alignItems="center">
      <Typography variant="subtitle2" color="text.secondary">{fieldKey}</Typography>
      <Typography variant="body1">{formatFieldValue(rawKey, value)}</Typography>
    </Box>
  );
}

// ─── Field display name map ───────────────────────────────────────────────────

const FIELD_LABEL: Record<string, string> = {
  first_name:     'ชื่อ',
  last_name:      'นามสกุล',
  email:          'อีเมล',
  service_center: 'สถานบริการ',
  role:           'ระดับสิทธิ์',
};

const ROLE_LABEL: Record<string, string> = {
  staff:      'เจ้าหน้าที่',
  admin:      'ผู้ดูแล',
  superadmin: 'ผู้ดูแลสูงสุด',
};

const formatFieldValue = (key: string, value: unknown): string => {
  if (value === null || value === undefined) return '—';
  if (key === 'role') return ROLE_LABEL[String(value)] ?? String(value);
  return String(value);
};

const fieldLabel = (key: string) => FIELD_LABEL[key] ?? key;

// ─── Field group definitions ──────────────────────────────────────────────────

const PROFILE_FIELD_SET   = new Set(['first_name', 'last_name', 'email', 'service_center']);
const PROFILE_FIELD_ORDER = ['first_name', 'last_name', 'email', 'service_center'];
const ROLE_FIELD_SET      = new Set(['role']);

// ─── Main Component ───────────────────────────────────────────────────────────

interface Props {
  row: StaffAuditLogRow | null;
  onClose: () => void;
}

export default function StaffAuditLogDetailDialog({ row, onClose }: Props) {
  const actionCfg = row
    ? (AUDIT_ACTION_COLOR[row.action as AuditAction] ?? AUDIT_ACTION_FALLBACK_COLOR)
    : null;
  const actionLabel = row
    ? (AUDIT_ACTION_LABEL[row.action as AuditAction] ?? row.action)
    : '';

  const allKeys: string[] = [];
  if (row) {
    const keySet = new Set([
      ...Object.keys(row.old_value ?? {}),
      ...Object.keys(row.new_value ?? {}),
    ]);
    allKeys.push(...Array.from(keySet).sort());
  }

  const profileKeys = PROFILE_FIELD_ORDER.filter(k => allKeys.includes(k));
  const roleKeys    = allKeys.filter(k => ROLE_FIELD_SET.has(k));
  const otherKeys   = allKeys.filter(k => !PROFILE_FIELD_SET.has(k) && !ROLE_FIELD_SET.has(k));
  const hasGroups   = profileKeys.length > 0 || roleKeys.length > 0;

  const hasOldAndNew = row && (row.old_value !== null || row.new_value !== null);
  const isInsertOnly = row !== null && row.old_value === null && row.new_value !== null;

  const orderedKeys = [...profileKeys, ...roleKeys, ...otherKeys];

  return (
    <Dialog open={row !== null} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ pb: 1 }}>
        <Typography component="div" variant="h6" fontWeight="bold">รายละเอียด</Typography>
      </DialogTitle>
      <Divider />

      <DialogContent sx={{ pt: 2.5 }}>
        {row && (
          <Box display="flex" flexDirection="column" gap={2}>
            {/* Meta */}
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
              <Typography variant="subtitle2" color="text.secondary">ชื่อ-นามสกุล</Typography>
              <Typography variant="body1">{row.target_name ?? row.target_full_name ?? '—'}</Typography>
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="flex-start">
              <Typography variant="subtitle2" color="text.secondary" sx={{ flexShrink: 0 }}>UUID เจ้าหน้าที่</Typography>
              <Typography variant="body2" sx={{ fontFamily: 'monospace', wordBreak: 'break-all', textAlign: 'right', maxWidth: '65%' }}>
                {row.target_staff_user_id ?? '—'}
              </Typography>
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="subtitle2" color="text.secondary">โดย</Typography>
              <Typography variant="body1">{row.full_name}</Typography>
            </Box>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="subtitle2" color="text.secondary">เมื่อวันที่</Typography>
              <Typography variant="body1">{formatDateTime(row.created_at)}</Typography>
            </Box>

            {/* Data Section */}
            {hasOldAndNew && allKeys.length > 0 && (
              <>
                <Divider />
                {isInsertOnly ? (
                  <>
                    <Typography variant="subtitle2" fontWeight="bold">ข้อมูล</Typography>
                    <Box display="flex" flexDirection="column" gap={2}>
                      {orderedKeys.map(k => (
                        <ValueRow key={k} rawKey={k} fieldKey={fieldLabel(k)} value={row.new_value?.[k]} />
                      ))}
                    </Box>
                  </>
                ) : (
                  <>
                    <Typography variant="subtitle2" fontWeight="bold">การเปลี่ยนแปลง</Typography>
                    <Box display="flex" flexDirection="column" gap={2}>
                      {(hasGroups ? orderedKeys : allKeys).map(k => {
                        const oldVal = row.old_value?.[k] ?? null;
                        const newVal = row.new_value?.[k] ?? null;
                        return <DiffRow key={k} rawKey={k} fieldKey={fieldLabel(k)} oldVal={oldVal} newVal={newVal} />;
                      })}
                    </Box>
                  </>
                )}
              </>
            )}
          </Box>
        )}
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 2.5 }}>
        <Button onClick={onClose} variant="outlined">ปิด</Button>
      </DialogActions>
    </Dialog>
  );
}
