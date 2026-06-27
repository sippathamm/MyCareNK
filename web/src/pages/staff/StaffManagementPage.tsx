import { useEffect, useMemo, useState } from 'react';
import {
  Box, Typography, Paper, Chip, Stack, Button, IconButton, Tooltip,
  Dialog, DialogTitle, DialogContent, DialogActions, Divider,
  TextField, MenuItem, CircularProgress, Alert, Collapse,
  Select, Checkbox, ListItemText, OutlinedInput, InputLabel, FormControl,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import PersonAddIcon from '@mui/icons-material/PersonAdd';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import WarningAmberRoundedIcon from '@mui/icons-material/WarningAmberRounded';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { alpha } from '@mui/material/styles';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useAuth } from '../../hooks/useAuth';
import { useColorMode } from '../../contexts/ThemeContext';
import { useStaffManagement, type StaffMember } from '../../hooks/useStaffManagement';
import { useServiceCenters } from '../../hooks/useServiceCenters';
import { useServiceCenterFilter } from '../../contexts/ServiceCenterFilterContext';
import { formatDateTime } from '../../utils/requestUtils';
import { createThGridLocale } from '../../constants/datagrid';
import type { Enums } from '../../lib/database.types';
import ConfirmDialog from '../../components/shared/ConfirmDialog';
import { useNotificationSettings, type NotificationSetting } from '../../hooks/useNotificationSettings';
import { STATUS_CONFIG, APPOINTMENT_STATUS_CONFIG, STOCK_OPERATION_CONFIG, SERVICE_CENTER_MANAGEMENT_CONFIG } from '../../contexts/NotificationContext';

// ─── Constants ───────────────────────────────────────────────────────────────

const ROLE_OPTIONS = [
  { value: 'staff', label: 'เจ้าหน้าที่' },
  { value: 'admin', label: 'ผู้ดูแล' },
  { value: 'superadmin', label: 'ผู้ดูแลสูงสุด' },
] as const;

function getRoleChipSx(role: string, mode: 'light' | 'dark'): { bgcolor: string; color: string } {
  if (mode === 'dark') {
    const dark: Record<string, { bgcolor: string; color: string }> = {
      superadmin: { bgcolor: alpha('#EF5350', 0.15), color: '#EF9A9A' },
      admin:      { bgcolor: alpha('#FF9F6B', 0.15), color: '#FFBE9E' },
      staff:      { bgcolor: alpha('#9E9E9E', 0.15), color: '#BDBDBD' },
    };
    return dark[role] ?? dark.staff;
  }
  const light: Record<string, { bgcolor: string; color: string }> = {
    superadmin: { bgcolor: '#FFEBEE', color: '#B71C1C' },
    admin:      { bgcolor: '#FFF3E0', color: '#E65100' },
    staff:      { bgcolor: '#F5F5F5', color: '#616161' },
  };
  return light[role] ?? light.staff;
}

const ROLE_LABEL: Record<string, string> = {
  staff: 'เจ้าหน้าที่',
  admin: 'ผู้ดูแล',
  superadmin: 'ผู้ดูแลสูงสุด',
};

const ROLE_RANK: Record<string, number> = { staff: 0, admin: 1, superadmin: 2 };

const thGridLocale = createThGridLocale('ไม่มีข้อมูลเจ้าหน้าที่');

// ─── Helpers ─────────────────────────────────────────────────────────────────

function generatePassword(): string {
  const lower = 'abcdefghijklmnopqrstuvwxyz';
  const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const digits = '0123456789';
  const special = '!@#$%^&*()_+-=[]{}|;:,.<>?';
  const all = lower + upper + digits + special;
  const required = [
    lower[Math.floor(Math.random() * lower.length)],
    upper[Math.floor(Math.random() * upper.length)],
    digits[Math.floor(Math.random() * digits.length)],
    special[Math.floor(Math.random() * special.length)],
  ];
  const rest = Array.from({ length: 12 }, () => all[Math.floor(Math.random() * all.length)]);
  return [...required, ...rest].sort(() => Math.random() - 0.5).join('');
}

// ─── Notification Settings Labels ────────────────────────────────────────────

const NOTIF_GROUPS: Array<{
  source_type: string;
  label: string;
  rows: Array<{ event_type: string; label: string }>;
}> = [
  {
    source_type: 'condom_request',
    label: 'คำขอถุงยางอนามัย',
    rows: (Object.entries(STATUS_CONFIG) as [string, { label: string }][]).map(([k, v]) => ({ event_type: k, label: v.label })),
  },
  {
    source_type: 'doctor_appointment',
    label: 'นัดรับคำปรึกษา',
    rows: (Object.entries(APPOINTMENT_STATUS_CONFIG) as [string, { label: string }][]).map(([k, v]) => ({ event_type: k, label: v.label })),
  },
  {
    source_type: 'stock_operation',
    label: 'การจัดการสต็อก',
    rows: (Object.entries(STOCK_OPERATION_CONFIG) as [string, { label: string }][]).map(([k, v]) => ({ event_type: k, label: v.label })),
  },
  {
    source_type: 'service_center_management',
    label: SERVICE_CENTER_MANAGEMENT_CONFIG.label,
    rows: [
      { event_type: 'add',    label: 'เพิ่มสถานบริการ' },
      { event_type: 'remove', label: 'ลบสถานบริการ' },
    ],
  },
  {
    source_type: 'staff_management',
    label: 'การจัดการเจ้าหน้าที่',
    rows: [
      { event_type: 'add',          label: 'เพิ่มเจ้าหน้าที่' },
      { event_type: 'remove',       label: 'ลบเจ้าหน้าที่' },
      { event_type: 'edit_profile', label: 'แก้ไขโปรไฟล์' },
      { event_type: 'edit_email',   label: 'แก้ไขอีเมล' },
      { event_type: 'edit_role',    label: 'แก้ไขระดับสิทธิ์' },
    ],
  },
];

// ─── Notification Settings Section ───────────────────────────────────────────

function NotificationSettingsSection() {
  const { settings, loading, save } = useNotificationSettings();
  const [draft, setDraft] = useState<NotificationSetting[]>([]);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [sectionOpen, setSectionOpen] = useState(false);
  const [openGroups, setOpenGroups] = useState<Set<string>>(
    () => new Set(NOTIF_GROUPS.map(g => g.source_type))
  );

  useEffect(() => { setDraft(settings); }, [settings]);

  const isDirty = useMemo(() => {
    if (draft.length !== settings.length) return false;
    return draft.some(d => {
      const orig = settings.find(s => s.source_type === d.source_type && s.event_type === d.event_type);
      return orig && (d.notify_staff !== orig.notify_staff || d.notify_admin !== orig.notify_admin || d.notify_superadmin !== orig.notify_superadmin);
    });
  }, [draft, settings]);

  const toggle = (source_type: string, event_type: string, field: 'notify_staff' | 'notify_admin' | 'notify_superadmin') => {
    setDraft(prev => prev.map(s =>
      s.source_type === source_type && s.event_type === event_type
        ? { ...s, [field]: !s[field] }
        : s
    ));
  };

  const toggleGroup = (sourceType: string) => {
    setOpenGroups(prev => {
      const next = new Set(prev);
      if (next.has(sourceType)) next.delete(sourceType); else next.add(sourceType);
      return next;
    });
  };

  const handleSave = async () => {
    setSaving(true);
    setSaveError(null);
    const err = await save(draft);
    setSaving(false);
    if (err) setSaveError(err);
  };

  return (
    <Box sx={{ mt: 4 }}>
      <Box
        onClick={() => setSectionOpen(o => !o)}
        sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', cursor: 'pointer', userSelect: 'none', mb: sectionOpen ? 0.5 : 0 }}
      >
        <Typography variant="h6" fontWeight="bold">ตั้งค่าการแจ้งเตือน</Typography>
        <ExpandMoreIcon sx={{ color: 'text.secondary', transition: 'transform 0.2s', transform: sectionOpen ? 'rotate(180deg)' : 'none' }} />
      </Box>

      <Collapse in={sectionOpen}>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
          กำหนดว่าแต่ละระดับสิทธิ์จะได้รับการแจ้งเตือนสำหรับกิจกรรมใดบ้าง
        </Typography>

        {saveError && <Alert severity="error" sx={{ mb: 2 }}>{saveError}</Alert>}

        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
            <CircularProgress size={28} />
          </Box>
        ) : (
          <>
            {NOTIF_GROUPS.map(group => {
              const isGroupOpen = openGroups.has(group.source_type);
              return (
                <Paper key={group.source_type} elevation={1} sx={{ borderRadius: 2, mb: 2, overflow: 'hidden' }}>
                  <Box
                    onClick={() => toggleGroup(group.source_type)}
                    sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', px: 3, py: 2, cursor: 'pointer', userSelect: 'none' }}
                  >
                    <Typography variant="subtitle1" fontWeight="bold">{group.label}</Typography>
                    <ExpandMoreIcon sx={{ color: 'text.secondary', fontSize: 20, transition: 'transform 0.2s', transform: isGroupOpen ? 'rotate(180deg)' : 'none' }} />
                  </Box>
                  <Collapse in={isGroupOpen}>
                    <Box sx={{ px: 3, pb: 2, overflowX: 'auto' }}>
                      <Box component="table" sx={{ width: '100%', borderCollapse: 'collapse' }}>
                        <Box component="thead">
                          <Box component="tr">
                            {(['การดำเนินการ', 'เจ้าหน้าที่', 'ผู้ดูแล', 'ผู้ดูแลสูงสุด'] as const).map((h, i) => (
                              <Box
                                component="th"
                                key={h}
                                sx={{
                                  textAlign: i === 0 ? 'left' : 'center',
                                  pb: 1.5,
                                  pr: 2,
                                  fontSize: 12,
                                  color: 'text.secondary',
                                  fontWeight: 'medium',
                                  whiteSpace: 'nowrap',
                                  ...(i > 0 && { width: 100 }),
                                }}
                              >
                                {h}
                              </Box>
                            ))}
                          </Box>
                        </Box>
                        <Box component="tbody">
                          {group.rows.map(row => {
                            const s = draft.find(d => d.source_type === group.source_type && d.event_type === row.event_type);
                            return (
                              <Box
                                component="tr"
                                key={row.event_type}
                                sx={{ borderTop: '1px solid', borderColor: 'divider' }}
                              >
                                <Box component="td" sx={{ py: 1.5, pr: 2 }}>
                                  <Typography variant="body2">{row.label}</Typography>
                                </Box>
                                {(['notify_staff', 'notify_admin', 'notify_superadmin'] as const).map(field => (
                                  <Box component="td" key={field} sx={{ py: 1.5, textAlign: 'center', width: 100 }}>
                                    <Checkbox
                                      checked={s?.[field] ?? false}
                                      onChange={() => toggle(group.source_type, row.event_type, field)}
                                      size="small"
                                    />
                                  </Box>
                                ))}
                              </Box>
                            );
                          })}
                        </Box>
                      </Box>
                    </Box>
                  </Collapse>
                </Paper>
              );
            })}

            <Box sx={{ display: 'flex', justifyContent: 'flex-end', mt: 1 }}>
              <Button
                variant="contained"
                disabled={!isDirty || saving}
                onClick={handleSave}
                endIcon={saving ? <CircularProgress size={16} color="inherit" /> : undefined}
              >
                บันทึก
              </Button>
            </Box>
          </>
        )}
      </Collapse>
    </Box>
  );
}

// ─── Add Staff Dialog ─────────────────────────────────────────────────────────

interface AddStaffDialogProps {
  open: boolean;
  centerNames: string[];
  currentRole: string;
  onClose: () => void;
  onSuccess: () => void;
  onCreate: (payload: {
    email: string; password: string; first_name: string;
    last_name: string; service_centers: string[]; role: Enums<'role'>;
  }) => Promise<string | null>;
}

function AddStaffDialog({ open, centerNames, currentRole, onClose, onSuccess, onCreate }: AddStaffDialogProps) {
  const { mode } = useColorMode();
  const [step, setStep] = useState<1 | 2>(1);
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [serviceCenters, setServiceCenters] = useState<string[]>([]);
  const [role, setRole] = useState<Enums<'role'>>('staff');
  const [password, setPassword] = useState('');
  const [copied, setCopied] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const scRequired = role === 'staff' || role === 'admin';

  const handleClose = () => {
    setStep(1); setFirstName(''); setLastName(''); setEmail('');
    setServiceCenters([]); setRole('staff'); setPassword(''); setCopied(false); setError(null);
    onClose();
  };

  const handleNext = () => {
    if (!firstName || !lastName || !email || !role) {
      setError('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }
    if (scRequired && serviceCenters.length === 0) {
      setError('กรุณาเลือกสถานบริการ');
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setError('รูปแบบอีเมลไม่ถูกต้อง');
      return;
    }
    setError(null);
    setPassword(generatePassword());
    setStep(2);
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(password);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  const handleCreate = async () => {
    setSubmitting(true);
    setError(null);
    const err = await onCreate({ email, password, first_name: firstName, last_name: lastName, service_centers: serviceCenters, role });
    setSubmitting(false);
    if (err) { setError(err); return; }
    handleClose();
    onSuccess();
  };

  return (
    <Dialog open={open} onClose={handleClose} fullWidth maxWidth="sm">
      <DialogTitle fontWeight="bold">เพิ่มเจ้าหน้าที่</DialogTitle>
      <DialogContent dividers>
        {step === 1 ? (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            {error && <Alert severity="error">{error}</Alert>}
            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField label="ชื่อ" value={firstName} onChange={e => setFirstName(e.target.value)} fullWidth required />
              <TextField label="นามสกุล" value={lastName} onChange={e => setLastName(e.target.value)} fullWidth required />
            </Box>
            <TextField label="อีเมล" type="email" value={email} onChange={e => setEmail(e.target.value)} fullWidth required />
            {role === 'staff' ? (
              <TextField
                select label="สถานบริการ" required fullWidth
                value={serviceCenters[0] ?? ''}
                onChange={e => setServiceCenters(e.target.value ? [e.target.value] : [])}
              >
                {centerNames.map(sc => <MenuItem key={sc} value={sc}>{sc}</MenuItem>)}
              </TextField>
            ) : (
              <FormControl fullWidth required={role === 'admin'}>
                <InputLabel>สถานบริการ{role === 'superadmin' ? ' (ไม่บังคับ)' : ''}</InputLabel>
                <Select
                  multiple
                  value={serviceCenters}
                  onChange={e => setServiceCenters(typeof e.target.value === 'string' ? e.target.value.split(',') : e.target.value as string[])}
                  input={<OutlinedInput label={`สถานบริการ${role === 'superadmin' ? ' (ไม่บังคับ)' : ''}`} />}
                  renderValue={(selected) => (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {(selected as string[]).map(v => <Chip key={v} label={v} size="small" />)}
                    </Box>
                  )}
                >
                  {centerNames.map(sc => (
                    <MenuItem key={sc} value={sc}>
                      <Checkbox checked={serviceCenters.includes(sc)} size="small" />
                      <ListItemText primary={sc} />
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            )}
            <TextField
              select label="ระดับสิทธิ์" value={role}
              onChange={e => { setRole(e.target.value as Enums<'role'>); setServiceCenters([]); }} fullWidth required
            >
              {ROLE_OPTIONS.filter(r => currentRole !== 'admin' || r.value !== 'superadmin').map(r => <MenuItem key={r.value} value={r.value}>{r.label}</MenuItem>)}
            </TextField>
          </Box>
        ) : (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <Alert severity="info">
              รหัสผ่านนี้จะแสดงเพียงครั้งเดียว กรุณาคัดลอกและแจ้งให้เจ้าหน้าที่ทราบ
            </Alert>
            {error && <Alert severity="error">{error}</Alert>}
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, bgcolor: 'action.hover', borderRadius: 2, px: 2, py: 1.5 }}>
              <Typography fontFamily="monospace" fontWeight="bold" sx={{ flex: 1, wordBreak: 'break-all' }}>
                {password}
              </Typography>
              <Tooltip title={copied ? 'คัดลอกแล้ว!' : 'คัดลอก'} placement="top">
                <IconButton size="small" onClick={handleCopy} color={copied ? 'success' : 'default'}>
                  <ContentCopyIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            </Box>
            <Divider />
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                <Typography variant="subtitle2" color="text.secondary">ชื่อ</Typography>
                <Typography variant="body1">{firstName} {lastName}</Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                <Typography variant="subtitle2" color="text.secondary">อีเมล</Typography>
                <Typography variant="body1">{email}</Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <Typography variant="subtitle2" color="text.secondary">สถานบริการ</Typography>
                <Typography variant="body1" textAlign="right">
                  {serviceCenters.length > 0 ? serviceCenters.join(', ') : '—'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="subtitle2" color="text.secondary">ระดับสิทธิ์</Typography>
                <Chip label={ROLE_LABEL[role]} size="small" sx={{ ...getRoleChipSx(role, mode), fontWeight: 600 }} />
              </Box>
            </Box>
          </Box>
        )}
      </DialogContent>
      <DialogActions sx={{ px: 3, py: 2, gap: 1 }}>
        <Button onClick={handleClose} color="inherit">ยกเลิก</Button>
        {step === 1 ? (
          <Button variant="contained" onClick={handleNext}>ถัดไป</Button>
        ) : (
          <>
            <Button onClick={() => setStep(1)} color="inherit">ย้อนกลับ</Button>
            <Button
              variant="contained"
              onClick={handleCreate}
              disabled={submitting}
              endIcon={submitting ? <CircularProgress size={16} color="inherit" /> : undefined}
            >
              สร้างบัญชี
            </Button>
          </>
        )}
      </DialogActions>
    </Dialog>
  );
}

// ─── Edit Staff Dialog ────────────────────────────────────────────────────────

interface EditStaffDialogProps {
  open: boolean;
  staff: StaffMember | null;
  centerNames: string[];
  currentUserId: string;
  currentRole: string;
  onClose: () => void;
  onUpdate: (payload: { staff_user_id: string; first_name: string; last_name: string; service_centers?: string[]; role?: Enums<'role'>; email?: string }) => Promise<string | null>;
  onDelete: (userId: string) => Promise<string | null>;
}

function EditStaffDialog({ open, staff, centerNames, currentUserId, currentRole, onClose, onUpdate, onDelete }: EditStaffDialogProps) {
  const { mode } = useColorMode();
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [serviceCenters, setServiceCenters] = useState<string[]>([]);
  const [role, setRole] = useState<Enums<'role'>>('staff');
  const [submitting, setSubmitting] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [confirmDeleteOpen, setConfirmDeleteOpen] = useState(false);
  const [confirmDowngradeOpen, setConfirmDowngradeOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (staff) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setFirstName(staff.first_name);
      setLastName(staff.last_name);
      setEmail(staff.email);
      setServiceCenters(staff.service_centers);
      setRole(staff.role);
      setError(null);
      setConfirmDeleteOpen(false);
      setConfirmDowngradeOpen(false);
    }
  }, [staff]);

  const handleClose = () => { setError(null); setConfirmDeleteOpen(false); setConfirmDowngradeOpen(false); onClose(); };

  const isCallerAdmin = currentRole === 'admin';
  // Admin cannot touch superadmin accounts at all
  const isRestricted = isCallerAdmin && staff?.role === 'superadmin';
  // Admin cannot change role or SC of anyone
  const isRoleScLocked = isCallerAdmin;
  // Admin cannot change name/email of other admins or self (can only edit staff)
  const isNameEmailLocked = isCallerAdmin && staff?.role !== 'staff';
  // Nothing is editable — disable save
  const nothingEditable = isRestricted || (isRoleScLocked && isNameEmailLocked);

  const doSave = async () => {
    if (!staff) return;
    setSubmitting(true);
    setError(null);
    const emailChanged = email !== staff.email;
    const err = await onUpdate({
      staff_user_id: staff.staff_user_id,
      first_name: firstName,
      last_name: lastName,
      ...(emailChanged && { email }),
      ...(!isRoleScLocked && { service_centers: serviceCenters, role }),
    });
    setSubmitting(false);
    if (err) { setError(err); return; }
    handleClose();
  };

  const handleSave = async () => {
    if (!staff) return;
    if (!isRestricted && !isNameEmailLocked) {
      if (!firstName.trim() || !lastName.trim() || !email.trim()) {
        setError('กรุณากรอกข้อมูลให้ครบถ้วน');
        return;
      }
    }
    if (!isRoleScLocked) {
      if ((role === 'staff' || role === 'admin') && serviceCenters.length === 0) {
        setError('กรุณาเลือกสถานบริการ');
        return;
      }
      const isDowngrade = (ROLE_RANK[role] ?? 0) < (ROLE_RANK[staff.role] ?? 0);
      if (isDowngrade) { setConfirmDowngradeOpen(true); return; }
    }
    await doSave();
  };

  const handleDowngradeConfirm = async () => {
    setConfirmDowngradeOpen(false);
    await doSave();
  };

  const handleDeleteConfirm = async () => {
    if (!staff) return;
    setConfirmDeleteOpen(false);
    setDeleting(true);
    const err = await onDelete(staff.staff_user_id);
    setDeleting(false);
    if (err) { setError(err); return; }
    handleClose();
  };

  return (
    <>
      <Dialog open={open} onClose={handleClose} fullWidth maxWidth="sm">
        <DialogTitle fontWeight="bold">แก้ไขข้อมูล</DialogTitle>
        <DialogContent dividers>
          {isRestricted && (
            <Alert severity="warning" sx={{ mb: 2 }}>
              ผู้ดูแลไม่สามารถแก้ไขหรือลบบัญชีผู้ดูแลสูงสุดได้
            </Alert>
          )}
          {!isRestricted && isNameEmailLocked && (
            <Alert severity="info" sx={{ mb: 2 }}>
              ไม่สามารถแก้ไขข้อมูลได้ โปรดติดต่อผู้ดูแลสูงสุด
            </Alert>
          )}
          {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField label="ชื่อ" value={firstName} onChange={e => setFirstName(e.target.value)} fullWidth required disabled={isRestricted || isNameEmailLocked} />
              <TextField label="นามสกุล" value={lastName} onChange={e => setLastName(e.target.value)} fullWidth required disabled={isRestricted || isNameEmailLocked} />
            </Box>
            <TextField label="อีเมล" type="email" value={email} onChange={e => setEmail(e.target.value)} fullWidth required disabled={isRestricted || isNameEmailLocked} />
            {role === 'staff' ? (
              <TextField
                select label="สถานบริการ" required fullWidth disabled={isRestricted || isRoleScLocked}
                value={serviceCenters[0] ?? ''}
                onChange={e => setServiceCenters(e.target.value ? [e.target.value] : [])}
              >
                {centerNames.map(sc => <MenuItem key={sc} value={sc}>{sc}</MenuItem>)}
              </TextField>
            ) : (
              <FormControl fullWidth required={role === 'admin'} disabled={isRestricted || isRoleScLocked}>
                <InputLabel>สถานบริการ{role === 'superadmin' ? ' (ไม่บังคับ)' : ''}</InputLabel>
                <Select
                  multiple
                  value={serviceCenters}
                  onChange={e => setServiceCenters(typeof e.target.value === 'string' ? e.target.value.split(',') : e.target.value as string[])}
                  input={<OutlinedInput label={`สถานบริการ${role === 'superadmin' ? ' (ไม่บังคับ)' : ''}`} />}
                  renderValue={(selected) => (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {(selected as string[]).length === 0
                        ? <Typography variant="body2" color="text.disabled">ไม่ระบุ</Typography>
                        : (selected as string[]).map(v => <Chip key={v} label={v} size="small" />)}
                    </Box>
                  )}
                >
                  {centerNames.map(sc => (
                    <MenuItem key={sc} value={sc}>
                      <Checkbox checked={serviceCenters.includes(sc)} size="small" />
                      <ListItemText primary={sc} />
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            )}
            <TextField
              select label="ระดับสิทธิ์" value={role}
              onChange={e => { setRole(e.target.value as Enums<'role'>); setServiceCenters([]); }} fullWidth required disabled={isRestricted || isRoleScLocked}
            >
              {ROLE_OPTIONS.map(r => <MenuItem key={r.value} value={r.value}>{r.label}</MenuItem>)}
            </TextField>
            <Divider sx={{ my: 1 }} />
            {staff && (
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="subtitle2" color="text.secondary">เพิ่มเมื่อ</Typography>
                  <Typography variant="body1">{formatDateTime(staff.created_at)}</Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="subtitle2" color="text.secondary">แก้ไขเมื่อ</Typography>
                  <Typography variant="body1">{formatDateTime(staff.updated_at ?? undefined)}</Typography>
                </Box>
              </Box>
            )}
          </Box>
        </DialogContent>
        <DialogActions sx={{ px: 3, py: 2 }}>
          <Button
            variant="contained"
            color="error"
            startIcon={deleting ? undefined : <DeleteIcon />}
            endIcon={deleting ? <CircularProgress size={16} color="inherit" /> : undefined}
            onClick={() => setConfirmDeleteOpen(true)}
            disabled={deleting || staff?.role === 'superadmin' || (isCallerAdmin && staff?.role === 'admin') || (staff?.staff_user_id === currentUserId)}
            sx={{ mr: 'auto' }}
          >
            ลบ
          </Button>
          <Button onClick={handleClose} color="inherit">ยกเลิก</Button>
          <Button
            variant="contained"
            onClick={handleSave}
            disabled={submitting || nothingEditable}
            endIcon={submitting ? <CircularProgress size={16} color="inherit" /> : undefined}
          >
            บันทึก
          </Button>
        </DialogActions>
      </Dialog>

      {/* Confirm: Delete staff */}
      <ConfirmDialog
        open={confirmDeleteOpen}
        icon={<DeleteOutlineIcon color="error" />}
        title="ยืนยันการลบบัญชี"
        body="คุณแน่ใจหรือไม่ว่าต้องการลบบัญชีนี้? การดำเนินการนี้ไม่สามารถย้อนกลับได้"
        confirmLabel="ลบ"
        confirmColor="error"
        loading={deleting}
        onConfirm={handleDeleteConfirm}
        onCancel={() => setConfirmDeleteOpen(false)}
      />

      {/* Confirm: Role downgrade */}
      <ConfirmDialog
        open={confirmDowngradeOpen}
        icon={<WarningAmberRoundedIcon color="warning" />}
        title="ยืนยันการลดระดับสิทธิ์"
        body={
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
            <Stack direction="row" alignItems="center" gap={0.75} flexWrap="wrap">
              <Typography variant="body2" color="text.secondary">คุณกำลังลดระดับสิทธิ์จาก</Typography>
              <Chip label={ROLE_LABEL[staff?.role ?? '']} size="small" sx={{ fontWeight: 600, ...getRoleChipSx(staff?.role ?? '', mode) }} />
              <Typography variant="body2" color="text.secondary">เป็น</Typography>
              <Chip label={ROLE_LABEL[role]} size="small" sx={{ fontWeight: 600, ...getRoleChipSx(role, mode) }} />
            </Stack>
            <Typography variant="body2" color="text.secondary">การดำเนินการนี้อาจส่งผลต่อการเข้าถึงระบบของเจ้าหน้าที่</Typography>
          </Box>
        }
        confirmLabel="ยืนยัน"
        confirmColor="warning"
        loading={submitting}
        onConfirm={handleDowngradeConfirm}
        onCancel={() => setConfirmDowngradeOpen(false)}
      />
    </>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function StaffManagementPage() {
  const { role, loading: roleLoading, isSuperadmin, serviceCenters } = useRoleAccess();
  const { session } = useAuth();
  const { mode } = useColorMode();
  const currentUserId = session?.user?.id ?? '';
  const { staff, loading, error, fetchStaff, createStaff, updateStaff, deleteStaff } = useStaffManagement();
  const { centers } = useServiceCenters();
  const { selectedServiceCenter } = useServiceCenterFilter();
  // Admin can only assign staff to their own SCs; superadmin can use all centers
  const centerNames = isSuperadmin
    ? centers.map(c => c.name)
    : centers.filter(c => serviceCenters.includes(c.name)).map(c => c.name);
  const filteredStaff = selectedServiceCenter === null
    ? staff
    : staff.filter(s => s.service_centers.includes(selectedServiceCenter));
  const [addOpen, setAddOpen] = useState(false);
  const [editTarget, setEditTarget] = useState<StaffMember | null>(null);

  useEffect(() => { fetchStaff(); }, [fetchStaff]);

  if (roleLoading) return null;
  if (role !== 'admin' && role !== 'superadmin') {
    return (
      <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', gap: 2, color: 'text.secondary' }}>
        <LockOutlinedIcon sx={{ fontSize: 72, opacity: 0.3 }} />
        <Typography variant="h6" color="error">คุณไม่มีสิทธิ์เข้าถึงหน้านี้</Typography>
      </Box>
    );
  }

  const columns: GridColDef[] = [
    {
      field: 'staff_user_id', headerName: 'UUID', flex: 1.8, minWidth: 280,
      renderCell: (params) => (
        <Tooltip title={params.value as string} placement="top">
          <Typography variant="body2" noWrap sx={{ overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: '100%' }}>
            {params.value}
          </Typography>
        </Tooltip>
      ),
    },
    { field: 'first_name', headerName: 'ชื่อ', flex: 1, minWidth: 100 },
    { field: 'last_name', headerName: 'นามสกุล', flex: 1, minWidth: 100 },
    {
      field: 'role',
      headerName: 'ระดับสิทธิ์',
      flex: 1,
      minWidth: 120,
      renderCell: (params) => (
        <Chip
          label={ROLE_LABEL[params.value as string] ?? params.value}
          size="small"
          sx={{ ...getRoleChipSx(params.value as string, mode), fontWeight: 600 }}
        />
      ),
    },
    {
      field: 'service_center',
      headerName: 'สถานบริการ',
      flex: 1.5,
      minWidth: 160,
      renderCell: (params) => {
        const scs: string[] = (params.row as StaffMember).service_centers ?? [];
        return (
          <Typography variant="body2" noWrap>
            {scs.length > 0 ? scs.join(', ') : (params.value as string) || '—'}
          </Typography>
        );
      },
    },
    {
      field: 'actions',
      headerName: '',
      flex: 0.6,
      minWidth: 80,
      sortable: false,
      filterable: false,
      disableColumnMenu: true,
      align: 'center',
      headerAlign: 'center',
      renderCell: (params) => (
        <Tooltip title="แก้ไขข้อมูล">
          <IconButton
            size="small"
            color="primary"
            onClick={() => setEditTarget(params.row as StaffMember)}
          >
            <EditIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      ),
    },
  ];

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
        <Box>
          <Typography variant="h5" fontWeight="bold" gutterBottom>
            จัดการเจ้าหน้าที่
          </Typography>
          <Typography variant="body1" color="text.secondary">
            จัดการบัญชีเจ้าหน้าที่ เพิ่ม แก้ไขข้อมูลและระดับสิทธิ์ หรือลบบัญชีออกจากระบบ
          </Typography>
        </Box>
        <Button variant="contained" startIcon={<PersonAddIcon />} onClick={() => setAddOpen(true)}>
          เพิ่มเจ้าหน้าที่
        </Button>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>}

      <Paper elevation={1} sx={{ p: 3, borderRadius: 2 }}>
        <Box sx={{ height: 500, width: '100%' }}>
          <DataGrid
            rows={filteredStaff}
            getRowId={(row) => row.staff_user_id}
            columns={columns}
            loading={loading}
            localeText={thGridLocale}
            initialState={{ pagination: { paginationModel: { pageSize: 10, page: 0 } } }}
            pageSizeOptions={[10]}
            disableRowSelectionOnClick
            getRowHeight={() => 56}
            sx={{
              border: 'none',
              '& .MuiDataGrid-columnHeaders': { bgcolor: 'action.hover' },
              '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
            }}
          />
        </Box>
      </Paper>

      {isSuperadmin && <NotificationSettingsSection />}

      <AddStaffDialog
        open={addOpen}
        centerNames={centerNames}
        currentRole={role ?? ''}
        onClose={() => setAddOpen(false)}
        onSuccess={fetchStaff}
        onCreate={createStaff}
      />

      <EditStaffDialog
        open={!!editTarget}
        staff={editTarget}
        centerNames={centerNames}
        currentUserId={currentUserId}
        currentRole={role ?? ''}
        onClose={() => setEditTarget(null)}
        onUpdate={updateStaff}
        onDelete={deleteStaff}
      />
    </Box>
  );
}
