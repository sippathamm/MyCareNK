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

// ─── Field display name map ───────────────────────────────────────────────────

const FIELD_LABEL: Record<string, string> = {
  first_name:      'ชื่อ',
  last_name:       'นามสกุล',
  email:           'อีเมล',
  service_centers: 'สถานบริการ',
  service_center:  'สถานบริการ',
  role:            'ระดับสิทธิ์',
};

const ROLE_LABEL: Record<string, string> = {
  staff:      'เจ้าหน้าที่',
  admin:      'ผู้ดูแล',
  superadmin: 'ผู้ดูแลสูงสุด',
};

const formatFieldValue = (key: string, value: unknown): string => {
  if (value === null || value === undefined) return '—';
  if (Array.isArray(value)) return value.length === 0 ? '—' : value.join(', ');
  if (key === 'role') return ROLE_LABEL[String(value)] ?? String(value);
  const str = String(value);
  return str === '' ? '—' : str;
};

const fieldLabel = (key: string) => FIELD_LABEL[key] ?? key;

// ─── Field group definitions ──────────────────────────────────────────────────

const PROFILE_FIELD_SET   = new Set(['first_name', 'last_name', 'email', 'service_centers', 'service_center']);
const PROFILE_FIELD_ORDER = ['first_name', 'last_name', 'email', 'service_centers', 'service_center'];
const ROLE_FIELD_SET      = new Set(['role']);

// ─── Data rows ────────────────────────────────────────────────────────────────

function MetaRow({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <Box display="flex" justifyContent="space-between" alignItems="center">
      <Typography variant="subtitle2" color="text.secondary">{label}</Typography>
      {children}
    </Box>
  );
}

// Single-column value row (staff_created = normal, staff_deleted = red)
function ValueRow({ rawKey, fieldKey, value, color }: { rawKey: string; fieldKey: string; value: unknown; color?: string }) {
  return (
    <Box display="flex" justifyContent="space-between" alignItems="center">
      <Typography variant="body2" color="text.secondary">{fieldKey}</Typography>
      <Typography variant="body2" fontWeight="medium" sx={{ color: color ?? 'text.primary' }}>
        {formatFieldValue(rawKey, value)}
      </Typography>
    </Box>
  );
}

// Diff row (before → after)
function DiffRow({ rawKey, fieldKey, oldVal, newVal }: { rawKey: string; fieldKey: string; oldVal: unknown; newVal: unknown }) {
  return (
    <Box display="flex" justifyContent="space-between" alignItems="center">
      <Typography variant="body2" color="text.secondary">{fieldKey}</Typography>
      <Box display="flex" alignItems="center" gap={1}>
        <Typography variant="body2" fontWeight="medium" sx={{ color: '#C62828' }}>{formatFieldValue(rawKey, oldVal)}</Typography>
        <Typography variant="body2" color="text.disabled">→</Typography>
        <Typography variant="body2" fontWeight="medium" sx={{ color: '#2E7D32' }}>{formatFieldValue(rawKey, newVal)}</Typography>
      </Box>
    </Box>
  );
}

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

  // Determine data source and display mode
  const isCreated = row?.action === 'staff_created';
  const isDeleted = row?.action === 'staff_deleted';
  // Both created and deleted use single-column display (not diff)
  const isSingleColumn = isCreated || isDeleted;

  // Pick the relevant JSON blob
  const dataSource = isDeleted
    ? (row?.old_value ?? null)
    : (row?.new_value ?? (row?.old_value ?? null));

  // Build ordered keys for single-column display
  const singleKeys: string[] = (() => {
    if (!row || !isSingleColumn || !dataSource) return [];
    const keys = Object.keys(dataSource);
    const profile = PROFILE_FIELD_ORDER.filter(k => keys.includes(k));
    const role    = keys.filter(k => ROLE_FIELD_SET.has(k));
    const other   = keys.filter(k => !PROFILE_FIELD_SET.has(k) && !ROLE_FIELD_SET.has(k));
    return [...profile, ...role, ...other];
  })();

  // Build ordered keys for diff display
  const diffAllKeys: string[] = (() => {
    if (!row || isSingleColumn) return [];
    const keySet = new Set([
      ...Object.keys(row.old_value ?? {}),
      ...Object.keys(row.new_value ?? {}),
    ]);
    return Array.from(keySet).sort();
  })();

  const diffProfileKeys = PROFILE_FIELD_ORDER.filter(k => diffAllKeys.includes(k));
  const diffRoleKeys    = diffAllKeys.filter(k => ROLE_FIELD_SET.has(k));
  const diffOtherKeys   = diffAllKeys.filter(k => !PROFILE_FIELD_SET.has(k) && !ROLE_FIELD_SET.has(k));
  const hasDiffGroups   = diffProfileKeys.length > 0 || diffRoleKeys.length > 0;
  const orderedDiffKeys = [...diffProfileKeys, ...diffRoleKeys, ...diffOtherKeys];

  const hasData = isSingleColumn ? singleKeys.length > 0 : diffAllKeys.length > 0;
  const dataTitle = isSingleColumn ? 'ข้อมูล' : 'การเปลี่ยนแปลง';
  const valueColor = isDeleted ? '#C62828' : isCreated ? '#2E7D32' : undefined;

  return (
    <Dialog open={row !== null} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ pb: 1 }}>
        <Typography component="div" variant="h6" fontWeight="bold" lineHeight={1.2}>รายละเอียด</Typography>
      </DialogTitle>

      <DialogContent dividers>
        {row && (
          <Box display="flex" flexDirection="column" gap={2}>
            {/* Meta */}
            <MetaRow label="ประเภท">
              {actionCfg && (
                <Chip
                  label={actionLabel}
                  size="small"
                  sx={{ bgcolor: actionCfg.bg, color: actionCfg.color, fontWeight: 600, fontSize: '0.72rem' }}
                />
              )}
            </MetaRow>
            <MetaRow label="ชื่อ-นามสกุล">
              <Typography variant="body1">{row.target_name ?? row.target_full_name ?? '—'}</Typography>
            </MetaRow>
            <MetaRow label="UUID เจ้าหน้าที่">
              <Typography variant="body1" sx={{ wordBreak: 'break-all', textAlign: 'right', maxWidth: '65%' }}>
                {row.target_staff_user_id ?? '—'}
              </Typography>
            </MetaRow>
            <MetaRow label="โดย">
              <Typography variant="body1">{row.full_name}</Typography>
            </MetaRow>
            <MetaRow label="เมื่อวันที่">
              <Typography variant="body1">{formatDateTime(row.created_at)}</Typography>
            </MetaRow>

            {/* Data section */}
            {hasData && (
              <>
                <Divider sx={{ my: 1 }} />
                <Typography variant="subtitle1" fontWeight="bold">{dataTitle}</Typography>
                <Box display="flex" flexDirection="column" gap={2}>
                  {isSingleColumn
                    ? singleKeys.map(k => (
                        <ValueRow key={k} rawKey={k} fieldKey={fieldLabel(k)} value={dataSource?.[k]} color={valueColor} />
                      ))
                    : (hasDiffGroups ? orderedDiffKeys : diffAllKeys).map(k => (
                        <DiffRow key={k} rawKey={k} fieldKey={fieldLabel(k)}
                          oldVal={row.old_value?.[k] ?? null}
                          newVal={row.new_value?.[k] ?? null}
                        />
                      ))
                  }
                </Box>
              </>
            )}
          </Box>
        )}
      </DialogContent>

      <DialogActions sx={{ p: 2 }}>
        <Button onClick={onClose} color="inherit">ปิด</Button>
      </DialogActions>
    </Dialog>
  );
}
