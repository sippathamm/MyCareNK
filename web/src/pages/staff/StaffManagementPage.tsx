import { useEffect, useState } from 'react';
import {
  Box, Typography, Paper, Chip, Stack, Button, IconButton, Tooltip,
  Dialog, DialogTitle, DialogContent, DialogActions, Divider,
  TextField, MenuItem, CircularProgress, Alert,
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
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useAuth } from '../../hooks/useAuth';
import { useStaffManagement, type StaffMember } from '../../hooks/useStaffManagement';
import { useServiceCenters } from '../../hooks/useServiceCenters';
import { formatDateTime } from '../../utils/requestUtils';
import { createThGridLocale } from '../../constants/datagrid';
import type { Enums } from '../../lib/database.types';
import ConfirmDialog from '../../components/shared/ConfirmDialog';

// ─── Constants ───────────────────────────────────────────────────────────────

const ROLE_OPTIONS = [
  { value: 'staff', label: 'เจ้าหน้าที่' },
  { value: 'admin', label: 'ผู้ดูแล' },
  { value: 'superadmin', label: 'ผู้ดูแลสูงสุด' },
] as const;

const ROLE_CHIP_SX: Record<string, { bgcolor: string; color: string }> = {
  superadmin: { bgcolor: '#FFEBEE', color: '#B71C1C' },
  admin:      { bgcolor: '#FFF3E0', color: '#E65100' },
  staff:      { bgcolor: '#F5F5F5', color: '#616161' },
};

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

// ─── Add Staff Dialog ─────────────────────────────────────────────────────────

interface AddStaffDialogProps {
  open: boolean;
  centerNames: string[];
  currentRole: string;
  onClose: () => void;
  onSuccess: () => void;
  onCreate: (payload: {
    email: string; password: string; first_name: string;
    last_name: string; service_center: string; role: Enums<'role'>;
  }) => Promise<string | null>;
}

function AddStaffDialog({ open, centerNames, currentRole, onClose, onSuccess, onCreate }: AddStaffDialogProps) {
  const [step, setStep] = useState<1 | 2>(1);
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [serviceCenter, setServiceCenter] = useState('');
  const [role, setRole] = useState<Enums<'role'>>('staff');
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
              {centerNames.map(sc => <MenuItem key={sc} value={sc}>{sc}</MenuItem>)}
            </TextField>
            <TextField
              select label="ระดับสิทธิ์" value={role}
              onChange={e => setRole(e.target.value as Enums<'role'>)} fullWidth required
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
                <Chip label={ROLE_LABEL[role]} size="small" sx={{ ...(ROLE_CHIP_SX[role] ?? ROLE_CHIP_SX.staff), fontWeight: 600 }} />
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
  onUpdate: (payload: { staff_user_id: string; first_name: string; last_name: string; service_center: string; role: Enums<'role'>; email?: string }) => Promise<string | null>;
  onDelete: (userId: string) => Promise<string | null>;
}

function EditStaffDialog({ open, staff, centerNames, currentUserId, currentRole, onClose, onUpdate, onDelete }: EditStaffDialogProps) {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [serviceCenter, setServiceCenter] = useState('');
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
      setServiceCenter(staff.service_center);
      setRole(staff.role);
      setError(null);
      setConfirmDeleteOpen(false);
      setConfirmDowngradeOpen(false);
    }
  }, [staff]);

  const handleClose = () => { setError(null); setConfirmDeleteOpen(false); setConfirmDowngradeOpen(false); onClose(); };

  const doSave = async () => {
    if (!staff) return;
    setSubmitting(true);
    setError(null);
    const emailChanged = email !== staff.email;
    const err = await onUpdate({ staff_user_id: staff.staff_user_id, first_name: firstName, last_name: lastName, service_center: serviceCenter, role, ...(emailChanged && { email }) });
    setSubmitting(false);
    if (err) { setError(err); return; }
    handleClose();
  };

  const handleSave = async () => {
    if (!staff) return;
    const isDowngrade = (ROLE_RANK[role] ?? 0) < (ROLE_RANK[staff.role] ?? 0);
    if (isDowngrade) { setConfirmDowngradeOpen(true); return; }
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

  const isRestricted = currentRole === 'admin' && staff?.role === 'superadmin';

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
          {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField label="ชื่อ" value={firstName} onChange={e => setFirstName(e.target.value)} fullWidth disabled={isRestricted} />
              <TextField label="นามสกุล" value={lastName} onChange={e => setLastName(e.target.value)} fullWidth disabled={isRestricted} />
            </Box>
            <TextField label="อีเมล" type="email" value={email} onChange={e => setEmail(e.target.value)} fullWidth disabled={isRestricted} />
            <TextField
              select label="สถานบริการ" value={serviceCenter}
              onChange={e => setServiceCenter(e.target.value)} fullWidth disabled={isRestricted}
            >
              {centerNames.map(sc => <MenuItem key={sc} value={sc}>{sc}</MenuItem>)}
            </TextField>
            <TextField
              select label="ระดับสิทธิ์" value={role}
              onChange={e => setRole(e.target.value as Enums<'role'>)} fullWidth disabled={isRestricted}
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
            disabled={deleting || isRestricted || (staff?.staff_user_id === currentUserId)}
            sx={{ mr: 'auto' }}
          >
            ลบ
          </Button>
          <Button onClick={handleClose} color="inherit">ยกเลิก</Button>
          <Button
            variant="contained"
            onClick={handleSave}
            disabled={submitting || isRestricted}
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
              <Chip label={ROLE_LABEL[staff?.role ?? '']} size="small" sx={{ fontWeight: 600, ...(ROLE_CHIP_SX[staff?.role ?? ''] ?? {}) }} />
              <Typography variant="body2" color="text.secondary">เป็น</Typography>
              <Chip label={ROLE_LABEL[role]} size="small" sx={{ fontWeight: 600, ...(ROLE_CHIP_SX[role] ?? {}) }} />
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
  const currentUserId = session?.user?.id ?? '';
  const { staff, loading, error, fetchStaff, createStaff, updateStaff, deleteStaff } = useStaffManagement();
  const { centers } = useServiceCenters();
  // Admin can only assign staff to their own SCs; superadmin can use all centers
  const centerNames = isSuperadmin
    ? centers.map(c => c.name)
    : centers.filter(c => serviceCenters.includes(c.name)).map(c => c.name);
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
          sx={{ ...(ROLE_CHIP_SX[params.value as string] ?? ROLE_CHIP_SX.staff), fontWeight: 600 }}
        />
      ),
    },
    { field: 'service_center', headerName: 'สถานบริการ', flex: 1.5, minWidth: 160 },
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
            rows={staff}
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
              '& .MuiDataGrid-columnHeaders': { bgcolor: 'grey.50' },
              '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
            }}
          />
        </Box>
      </Paper>

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
