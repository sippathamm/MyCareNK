import { useEffect, useState } from 'react';
import {
  Box, Typography, Paper, Chip, Button, IconButton, Tooltip,
  Dialog, DialogTitle, DialogContent, DialogActions, Divider,
  TextField, MenuItem, CircularProgress, Alert,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import PersonAddIcon from '@mui/icons-material/PersonAdd';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useAuth } from '../../hooks/useAuth';
import { useStaffManagement, type StaffMember } from '../../hooks/useStaffManagement';
import { formatDateTime } from '../../utils/requestUtils';

// ─── Constants ───────────────────────────────────────────────────────────────

const ROLE_OPTIONS = [
  { value: 'staff', label: 'เจ้าหน้าที่' },
  { value: 'admin', label: 'ผู้ดูแล' },
  { value: 'superadmin', label: 'ผู้ดูแลสูงสุด' },
] as const;

const SERVICE_CENTER_OPTIONS = [
  'รพ.โพนพิสัย',
  'รพ.สต.วัดหลวง',
  'อบต.วัดหลวง',
  'สสจ.หนองคาย',
] as const;

const ROLE_COLOR: Record<string, 'error' | 'primary' | 'default'> = {
  superadmin: 'error',
  admin: 'primary',
  staff: 'default',
};

const ROLE_LABEL: Record<string, string> = {
  staff: 'เจ้าหน้าที่',
  admin: 'ผู้ดูแล',
  superadmin: 'ผู้ดูแลสูงสุด',
};

const ROLE_RANK: Record<string, number> = { staff: 0, admin: 1, superadmin: 2 };

const thGridLocale = {
  noRowsLabel: 'ไม่มีข้อมูลเจ้าหน้าที่',
  noResultsOverlayLabel: 'ไม่พบข้อมูล',
  MuiTablePagination: {
    labelRowsPerPage: 'จำนวนต่อหน้า:',
    labelDisplayedRows: ({ from, to, count }: { from: number; to: number; count: number }) =>
      `${from} - ${to} จาก ${count !== -1 ? count : `มากกว่า ${to}`}`,
  },
};

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

function formatRelative(dateStr: string | null): string {
  if (!dateStr) return 'ยังไม่เคยเข้าสู่ระบบ';
  const diffMs = Date.now() - new Date(dateStr).getTime();
  const secs = Math.floor(diffMs / 1000);
  if (secs < 60) return `${secs} วินาทีที่แล้ว`;
  const mins = Math.floor(secs / 60);
  if (mins < 60) return `${mins} นาทีที่แล้ว`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs} ชั่วโมงที่แล้ว`;
  return `${Math.floor(hrs / 24)} วันที่แล้ว`;
}

function formatLastSignIn(dateStr: string | null): string {
  if (!dateStr) return 'ยังไม่เคยเข้าสู่ระบบ';
  return `${formatDateTime(dateStr)} (${formatRelative(dateStr)})`;
}

// ─── Add Staff Dialog ─────────────────────────────────────────────────────────

interface AddStaffDialogProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  onCreate: (payload: {
    email: string; password: string; first_name: string;
    last_name: string; service_center: string; role: string;
  }) => Promise<string | null>;
}

function AddStaffDialog({ open, onClose, onSuccess, onCreate }: AddStaffDialogProps) {
  const [step, setStep] = useState<1 | 2>(1);
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [serviceCenter, setServiceCenter] = useState('');
  const [role, setRole] = useState('staff');
  const [password, setPassword] = useState('');
  const [copied, setCopied] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleClose = () => {
    setStep(1); setFirstName(''); setLastName(''); setEmail('');
    setServiceCenter(''); setRole('staff'); setPassword(''); setCopied(false); setError(null);
    onClose();
  };

  const handleNext = () => {
    if (!firstName || !lastName || !email || !serviceCenter || !role) {
      setError('กรุณากรอกข้อมูลให้ครบถ้วน');
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
    const err = await onCreate({ email, password, first_name: firstName, last_name: lastName, service_center: serviceCenter, role });
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
            <TextField
              select label="สถานบริการ" value={serviceCenter}
              onChange={e => setServiceCenter(e.target.value)} fullWidth required
            >
              {SERVICE_CENTER_OPTIONS.map(sc => <MenuItem key={sc} value={sc}>{sc}</MenuItem>)}
            </TextField>
            <TextField
              select label="ระดับสิทธิ์" value={role}
              onChange={e => setRole(e.target.value)} fullWidth required
            >
              {ROLE_OPTIONS.map(r => <MenuItem key={r.value} value={r.value}>{r.label}</MenuItem>)}
            </TextField>
          </Box>
        ) : (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <Alert severity="info">
              รหัสผ่านนี้จะแสดงเพียงครั้งเดียว กรุณาคัดลอกและแจ้งให้เจ้าหน้าที่ทราบ
            </Alert>
            {error && <Alert severity="error">{error}</Alert>}
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, bgcolor: 'grey.100', borderRadius: 2, px: 2, py: 1.5 }}>
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
              <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                <Typography variant="subtitle2" color="text.secondary">สถานบริการ</Typography>
                <Typography variant="body1">{serviceCenter}</Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="subtitle2" color="text.secondary">ระดับสิทธิ์</Typography>
                <Chip label={ROLE_LABEL[role]} color={ROLE_COLOR[role] ?? 'default'} size="small" />
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
  currentUserId: string;
  onClose: () => void;
  onUpdate: (payload: { user_id: string; first_name: string; last_name: string; service_center: string; role: string; email?: string }) => Promise<string | null>;
  onDelete: (userId: string) => Promise<string | null>;
}

function EditStaffDialog({ open, staff, currentUserId, onClose, onUpdate, onDelete }: EditStaffDialogProps) {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [serviceCenter, setServiceCenter] = useState('');
  const [role, setRole] = useState('staff');
  const [submitting, setSubmitting] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [confirmDowngrade, setConfirmDowngrade] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (staff) {
      setFirstName(staff.first_name);
      setLastName(staff.last_name);
      setEmail(staff.email);
      setServiceCenter(staff.service_center);
      setRole(staff.role);
      setError(null);
      setConfirmDelete(false);
      setConfirmDowngrade(false);
    }
  }, [staff]);

  const handleClose = () => { setError(null); setConfirmDelete(false); setConfirmDowngrade(false); onClose(); };

  const handleSave = async () => {
    if (!staff) return;
    const isDowngrade = (ROLE_RANK[role] ?? 0) < (ROLE_RANK[staff.role] ?? 0);
    if (isDowngrade && !confirmDowngrade) {
      setConfirmDowngrade(true);
      return;
    }
    setSubmitting(true);
    setError(null);
    const emailChanged = email !== staff.email;
    const err = await onUpdate({ user_id: staff.user_id, first_name: firstName, last_name: lastName, service_center: serviceCenter, role, ...(emailChanged && { email }) });
    setSubmitting(false);
    if (err) { setError(err); return; }
    handleClose();
  };

  const handleDelete = async () => {
    if (!staff) return;
    if (!confirmDelete) { setConfirmDelete(true); return; }
    setDeleting(true);
    const err = await onDelete(staff.user_id);
    setDeleting(false);
    if (err) { setError(err); return; }
    handleClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} fullWidth maxWidth="sm">
      <DialogTitle fontWeight="bold">แก้ไขข้อมูลเจ้าหน้าที่</DialogTitle>
      <DialogContent dividers>
        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
          <Box sx={{ display: 'flex', gap: 2 }}>
            <TextField label="ชื่อ" value={firstName} onChange={e => setFirstName(e.target.value)} fullWidth />
            <TextField label="นามสกุล" value={lastName} onChange={e => setLastName(e.target.value)} fullWidth />
          </Box>
          <TextField label="อีเมล" type="email" value={email} onChange={e => setEmail(e.target.value)} fullWidth />
          <TextField
            select label="สถานบริการ" value={serviceCenter}
            onChange={e => setServiceCenter(e.target.value)} fullWidth
          >
            {SERVICE_CENTER_OPTIONS.map(sc => <MenuItem key={sc} value={sc}>{sc}</MenuItem>)}
          </TextField>
          <TextField
            select label="ระดับสิทธิ์" value={role}
            onChange={e => { setRole(e.target.value); setConfirmDowngrade(false); }} fullWidth
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
          {confirmDowngrade && (
            <Alert severity="warning">
              คุณกำลังลดระดับสิทธิ์จาก <strong>{ROLE_LABEL[staff?.role ?? '']}</strong> เป็น <strong>{ROLE_LABEL[role]}</strong> กดปุ่ม "บันทึก" อีกครั้งเพื่อยืนยัน
            </Alert>
          )}
          {confirmDelete && (
            <Alert severity="warning">
              คุณแน่ใจหรือไม่ว่าต้องการลบบัญชีนี้? การดำเนินการนี้ไม่สามารถย้อนกลับได้ กดปุ่ม "ลบ" อีกครั้งเพื่อยืนยัน
            </Alert>
          )}
        </Box>
      </DialogContent>
      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button
          color="error"
          startIcon={deleting ? undefined : <DeleteIcon />}
          endIcon={deleting ? <CircularProgress size={16} color="inherit" /> : undefined}
          onClick={handleDelete}
          disabled={deleting || (staff?.user_id === currentUserId)}
          sx={{ mr: 'auto' }}
        >
          {confirmDelete ? 'ยืนยันลบ' : 'ลบ'}
        </Button>
        <Button onClick={handleClose} color="inherit">ยกเลิก</Button>
        <Button
          variant="contained"
          onClick={handleSave}
          disabled={submitting}
          endIcon={submitting ? <CircularProgress size={16} color="inherit" /> : undefined}
        >
          บันทึก
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function StaffManagementPage() {
  const { role, loading: roleLoading } = useRoleAccess();
  const { session } = useAuth();
  const currentUserId = session?.user?.id ?? '';
  const { staff, loading, error, fetchStaff, createStaff, updateStaff, deleteStaff } = useStaffManagement();
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
          color={ROLE_COLOR[params.value as string] ?? 'default'}
          size="small"
        />
      ),
    },
    { field: 'service_center', headerName: 'สถานบริการ', flex: 1.5, minWidth: 160 },
    {
      field: 'last_sign_in_at',
      headerName: 'เข้าสู่ระบบล่าสุดเมื่อ',
      flex: 2,
      minWidth: 220,
      renderCell: (params) => (
        <Box sx={{ display: 'flex', alignItems: 'center', height: '100%', width: '100%' }}>
          <Typography variant="body2">
            {formatLastSignIn(params.value as string | null)}
          </Typography>
        </Box>
      ),
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
            เพิ่ม ลบ หรือแก้ไขสิทธิ์การใช้งานของเจ้าหน้าที่ในระบบ
          </Typography>
        </Box>
        <Button variant="contained" startIcon={<PersonAddIcon />} onClick={() => setAddOpen(true)}>
          เพิ่มเจ้าหน้าที่
        </Button>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>}

      <Paper sx={{ p: 3, borderRadius: 3, boxShadow: 2 }}>
        <Box sx={{ height: 500, width: '100%' }}>
          <DataGrid
            rows={staff}
            getRowId={(row) => row.user_id}
            columns={columns}
            loading={loading}
            localeText={thGridLocale}
            initialState={{ pagination: { paginationModel: { pageSize: 10, page: 0 } } }}
            pageSizeOptions={[10]}
            disableRowSelectionOnClick
            getRowHeight={() => 56}
          />
        </Box>
      </Paper>

      <AddStaffDialog
        open={addOpen}
        onClose={() => setAddOpen(false)}
        onSuccess={fetchStaff}
        onCreate={createStaff}
      />

      <EditStaffDialog
        open={!!editTarget}
        staff={editTarget}
        currentUserId={currentUserId}
        onClose={() => setEditTarget(null)}
        onUpdate={updateStaff}
        onDelete={deleteStaff}
      />
    </Box>
  );
}
