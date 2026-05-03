import {
  Drawer, Box, Typography, Divider, IconButton, Chip, Stack,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import type { AuditLogRow } from '../../hooks/useAuditLog';
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

function sortedKeys(obj: Record<string, unknown>): string[] {
  return Object.keys(obj).sort();
}

// ─── JSON Diff View (fallback) ────────────────────────────────────────────────

interface DiffPanelProps {
  label: string;
  data: Record<string, unknown> | null;
  bg: string;
  headerColor: string;
}

function DiffPanel({ label, data, bg, headerColor }: DiffPanelProps) {
  return (
    <Box sx={{ flex: 1 }}>
      <Typography
        variant="caption"
        fontWeight="bold"
        sx={{ display: 'block', mb: 1, color: headerColor, textTransform: 'uppercase', letterSpacing: 0.5 }}
      >
        {label}
      </Typography>
      {data === null ? (
        <Box sx={{ p: 1.5, borderRadius: 1, bgcolor: '#F5F5F5' }}>
          <Typography variant="body2" color="text.disabled" sx={{ fontFamily: 'monospace' }}>null</Typography>
        </Box>
      ) : (
        <Box
          component="pre"
          sx={{
            m: 0, p: 1.5, borderRadius: 1, bgcolor: bg,
            fontSize: '0.78rem', fontFamily: 'monospace',
            overflowX: 'auto', whiteSpace: 'pre-wrap', wordBreak: 'break-all',
          }}
        >
          {JSON.stringify(
            Object.fromEntries(sortedKeys(data).map(k => [k, data[k]])),
            null, 2,
          )}
        </Box>
      )}
    </Box>
  );
}

// ─── Qty Chip (condom_delta / lubricant_delta) ────────────────────────────────

function QtyChip({ value }: { value: unknown }) {
  const num = typeof value === 'number' ? value : Number(value);
  if (num === 0 || isNaN(num)) return <Typography variant="body1" color="text.disabled">—</Typography>;
  const pos = num > 0;
  return (
    <Chip
      label={`${pos ? '+' : ''}${num.toLocaleString()}`}
      size="small"
      sx={{ bgcolor: pos ? '#EBF7EC' : '#FFF0F0', color: pos ? '#2E7D32' : '#C62828', fontWeight: 600, fontSize: '0.78rem' }}
    />
  );
}

const QTY_FIELDS = new Set(['condom_delta', 'lubricant_delta']);

// ─── Value Row (insert-only display) ─────────────────────────────────────────

function ValueRow({ fieldKey, value }: { fieldKey: string; value: unknown }) {
  const fmt = (v: unknown) => v === null || v === undefined ? '—' : String(v);
  return (
    <Box display="flex" justifyContent="space-between" alignItems="center">
      <Typography variant="subtitle2" color="text.secondary">{fieldKey}</Typography>
      {QTY_FIELDS.has(fieldKey)
        ? <QtyChip value={value} />
        : <Typography variant="body1">{fmt(value)}</Typography>
      }
    </Box>
  );
}

// ─── Diff Row (before / after) ────────────────────────────────────────────────

interface DiffRowProps {
  fieldKey: string;
  oldVal: unknown;
  newVal: unknown;
}

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

// ─── Field group definitions ──────────────────────────────────────────────────

const PROFILE_FIELD_SET   = new Set(['first_name', 'last_name', 'email', 'service_center']);
const PROFILE_FIELD_ORDER = ['first_name', 'last_name', 'email', 'service_center'];
const ROLE_FIELD_SET      = new Set(['role']);

// ─── Main Component ───────────────────────────────────────────────────────────

interface Props {
  row: AuditLogRow | null;
  onClose: () => void;
}

export default function AuditLogDetailDrawer({ row, onClose }: Props) {

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

  const hasOldAndNew  = row && (row.old_value !== null || row.new_value !== null);
  // Insert-only: new record with no prior state — show single-column value list
  const isInsertOnly  = row !== null && row.old_value === null && row.new_value !== null;
  // Actions that don't need a data/diff section
  const hideDataSection = row !== null && (row.action === 'staff_created' || row.action === 'staff_deleted');

  const orderedKeys = [...profileKeys, ...roleKeys, ...otherKeys];

  return (
    <Drawer
      anchor="right"
      open={row !== null}
      onClose={onClose}
      PaperProps={{ sx: { width: { xs: '100vw', sm: 640 }, p: 3 } }}
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
          {(() => {
            const isStaff = row.target_table === 'staff_profiles';
            return (
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
                {isStaff && (
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Typography variant="subtitle2" color="text.secondary">UUID เจ้าหน้าที่</Typography>
                    <Typography variant="body2">{row.target_id}</Typography>
                  </Box>
                )}
                <Box display="flex" justifyContent="space-between" alignItems="center">
                  <Typography variant="subtitle2" color="text.secondary">โดย</Typography>
                  <Typography variant="body1">{row.full_name}</Typography>
                </Box>
                <Box display="flex" justifyContent="space-between" alignItems="center">
                  <Typography variant="subtitle2" color="text.secondary">เมื่อวันที่</Typography>
                  <Typography variant="body1">{formatDateTime(row.created_at)}</Typography>
                </Box>
              </Box>
            );
          })()}

          <Divider sx={{ mb: 2 }} />

          {/* Data Section */}
          {!hideDataSection && (
            hasOldAndNew && allKeys.length > 0 ? (
              isInsertOnly ? (
                /* Single-column view for INSERT events (no prior state to diff) */
                <>
                  <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 2 }}>ข้อมูล</Typography>
                  <Box display="flex" flexDirection="column" gap={2}>
                    {orderedKeys.map(k => (
                      <ValueRow key={k} fieldKey={k} value={row.new_value?.[k]} />
                    ))}
                  </Box>
                </>
              ) : (
                /* Diff view for UPDATE / DELETE events */
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
            ) : (
              /* Raw JSON fallback (when keys can't be parsed into structured rows) */
              <>
                <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 2 }}>ข้อมูล</Typography>
                <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
                  <DiffPanel label="ก่อน (old_value)" data={row.old_value as Record<string, unknown> | null} bg="#FFF8F8" headerColor="#C62828" />
                  <DiffPanel label="หลัง (new_value)" data={row.new_value as Record<string, unknown> | null} bg="#F8FFF9" headerColor="#2E7D32" />
                </Stack>
              </>
            )
          )}
        </Box>
      )}
    </Drawer>
  );
}
