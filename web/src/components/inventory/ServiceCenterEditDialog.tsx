import { useState, useEffect, useRef } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, TextField, Typography, Box, CircularProgress,
  Alert, Divider, IconButton, Tooltip, Switch, FormControlLabel,
  Tabs, Tab,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import DeleteIcon from '@mui/icons-material/Delete';
import PhotoCameraIcon from '@mui/icons-material/PhotoCamera';
import MapIcon from '@mui/icons-material/Map';
import StorefrontIcon from '@mui/icons-material/Storefront';
import PeopleOutlineIcon from '@mui/icons-material/PeopleOutline';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import { supabase } from '../../lib/supabase';
import type { ServiceCenterRow } from '../../hooks/useServiceCenters';
import { useIsMobile } from '../../hooks/useIsMobile';
import ConfirmDialog from '../shared/ConfirmDialog';

interface Props {
  open: boolean;
  center: ServiceCenterRow | null;
  existingNames: string[];
  isSuperadmin: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

interface ContactItem {
  label: string;
  value: string;
}

type ScheduleGroup = 'condom' | 'consultation';
type SchedulePeriod = 'morning' | 'afternoon';

const SCHEDULE_TABS = ['แจกถุงยางอนามัย/เจลหล่อลื่น', 'ให้คำปรึกษา'];

function generateId(): string {
  return Array.from(crypto.getRandomValues(new Uint8Array(16)))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

function getFileExtension(filename: string) {
  return filename.split('.').pop() ?? 'jpg';
}

export default function ServiceCenterEditDialog({ open, center, existingNames, isSuperadmin, onClose, onSuccess }: Props) {
  const isMobile = useIsMobile();
  const isAddMode = open && center === null;

  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [contacts, setContacts] = useState<ContactItem[]>([]);
  const [latitude, setLatitude] = useState('');
  const [longitude, setLongitude] = useState('');
  const [operatingHours, setOperatingHours] = useState('');
  const [address, setAddress] = useState('');
  const [imageUrl, setImageUrl] = useState<string | null>(null);

  const [scheduleTab, setScheduleTab] = useState(0);
  const [condomEnabled, setCondomEnabled] = useState(true);
  const [consultationEnabled, setConsultationEnabled] = useState(false);
  const [pickupMorning, setPickupMorning] = useState<string[]>(['08:00']);
  const [pickupAfternoon, setPickupAfternoon] = useState<string[]>([]);
  const [apptMorning, setApptMorning] = useState<string[]>(['08:00']);
  const [apptAfternoon, setApptAfternoon] = useState<string[]>([]);

  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [confirmDeleteOpen, setConfirmDeleteOpen] = useState(false);
  const [staffBlockDialog, setStaffBlockDialog] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [addedName, setAddedName] = useState<string | null>(null);
  const imageInputRef = useRef<HTMLInputElement>(null);
  const errorRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    setError(null);
    setAddedName(null);
    setConfirmDeleteOpen(false);
    setStaffBlockDialog(false);
    setScheduleTab(0);

    if (center) {
      setName(center.name);
      setDescription(center.description ?? '');
      setAddress(center.address ?? '');
      setContacts(center.contacts.length > 0 ? [...center.contacts] : []);
      setLatitude(center.latitude !== null ? String(center.latitude) : '');
      setLongitude(center.longitude !== null ? String(center.longitude) : '');
      setOperatingHours(center.operating_hours ?? '');
      setImageUrl(center.image_url);
      setCondomEnabled(center.condom_service_enabled);
      setConsultationEnabled(center.consultation_service_enabled);
      setPickupMorning(center.pickup_times.filter(t => t < '12:00').sort());
      setPickupAfternoon(center.pickup_times.filter(t => t >= '12:00').sort());
      setApptMorning(center.consultation_times.filter(t => t < '12:00').sort());
      setApptAfternoon(center.consultation_times.filter(t => t >= '12:00').sort());
    } else {
      setName('');
      setDescription('');
      setAddress('');
      setContacts([]);
      setLatitude('');
      setLongitude('');
      setOperatingHours('');
      setImageUrl(null);
      setCondomEnabled(true);
      setConsultationEnabled(false);
      setPickupMorning(['08:00']);
      setPickupAfternoon([]);
      setApptMorning(['08:00']);
      setApptAfternoon([]);
    }
  }, [open, center]);

  useEffect(() => {
    if (error) errorRef.current?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }, [error]);

  const getScheduleTimes = (group: ScheduleGroup, period: SchedulePeriod) => {
    if (group === 'condom') return period === 'morning' ? pickupMorning : pickupAfternoon;
    return period === 'morning' ? apptMorning : apptAfternoon;
  };

  const setScheduleTimes = (group: ScheduleGroup, period: SchedulePeriod, times: string[]) => {
    if (group === 'condom') {
      if (period === 'morning') setPickupMorning(times);
      else setPickupAfternoon(times);
    } else {
      if (period === 'morning') setApptMorning(times);
      else setApptAfternoon(times);
    }
  };



  const handleAddTime = (group: ScheduleGroup, period: SchedulePeriod) => {
    const candidates = period === 'morning'
      ? ['08:00', '09:00', '10:00', '11:00']
      : ['13:00', '14:00', '15:00', '16:00'];
    const current = getScheduleTimes(group, period);
    const next = candidates.find(c => !current.includes(c)) ?? (period === 'morning' ? '08:00' : '13:00');
    setScheduleTimes(group, period, [...current, next]);
  };

  const handleTimeChange = (group: ScheduleGroup, period: SchedulePeriod, oldTime: string, newTime: string) => {
    setScheduleTimes(group, period, getScheduleTimes(group, period).map(t => t === oldTime ? newTime : t));
  };

  const handleRemoveTime = (group: ScheduleGroup, period: SchedulePeriod, time: string) => {
    setScheduleTimes(group, period, getScheduleTimes(group, period).filter(t => t !== time));
  };

  const handleClose = () => {
    if (saving || uploading || deleting) return;
    if (addedName) { onSuccess(); return; }
    onClose();
  };

  const handleAddContact = () => setContacts(prev => [...prev, { label: '', value: '' }]);
  const handleContactChange = (i: number, field: 'label' | 'value', val: string) => {
    setContacts(prev => prev.map((c, idx) => idx === i ? { ...c, [field]: val } : c));
  };
  const handleRemoveContact = (i: number) => setContacts(prev => prev.filter((_, idx) => idx !== i));

  const handleImageFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    e.target.value = '';
    setUploading(true);
    setError(null);
    try {
      const ext = getFileExtension(file.name);
      const path = `${generateId()}.${ext}`;
      const { error: uploadError } = await supabase.storage
        .from('service-center-assets')
        .upload(path, file, { cacheControl: '3600', upsert: false });
      if (uploadError) { setError(`อัปโหลดรูปไม่สำเร็จ: ${uploadError.message}`); return; }
      const { data: { publicUrl } } = supabase.storage.from('service-center-assets').getPublicUrl(path);
      setImageUrl(publicUrl);
    } catch (e) {
      setError(`อัปโหลดรูปไม่สำเร็จ: ${e instanceof Error ? e.message : 'ข้อผิดพลาดที่ไม่ทราบสาเหตุ'}`);
    } finally {
      setUploading(false);
    }
  };

  const validateLatLng = (): { lat: number | null; lng: number | null } | null => {
    const latStr = latitude.trim();
    const lngStr = longitude.trim();
    const lat = latStr ? parseFloat(latStr) : null;
    const lng = lngStr ? parseFloat(lngStr) : null;
    if (latStr && (lat === null || isNaN(lat))) { setError('ละติจูดต้องเป็นตัวเลข'); return null; }
    if (lngStr && (lng === null || isNaN(lng))) { setError('ลองจิจูดต้องเป็นตัวเลข'); return null; }
    if ((latStr && !lngStr) || (!latStr && lngStr)) {
      setError('กรุณากรอกทั้งละติจูดและลองจิจูด หรือเว้นว่างทั้งคู่');
      return null;
    }
    return { lat, lng };
  };

  const validateSchedule = (): boolean => {
    if (condomEnabled && pickupMorning.length === 0 && pickupAfternoon.length === 0) {
      setError('กรุณาเพิ่มอย่างน้อย 1 ช่วงเวลาสำหรับบริการแจกถุงยางอนามัย/เจลหล่อลื่น');
      return false;
    }
    if (consultationEnabled && apptMorning.length === 0 && apptAfternoon.length === 0) {
      setError('กรุณาเพิ่มอย่างน้อย 1 ช่วงเวลาสำหรับบริการให้คำปรึกษา');
      return false;
    }
    return true;
  };

  const buildSchedulePayload = () => ({
    p_condom_service_enabled: condomEnabled,
    p_consultation_service_enabled: consultationEnabled,
    p_pickup_times: [...pickupMorning, ...pickupAfternoon].sort(),
    p_consultation_times: [...apptMorning, ...apptAfternoon].sort(),
  });

  const handleSaveAdd = async () => {
    const trimmedName = name.trim();
    if (!trimmedName) { setError('กรุณากรอกชื่อสถานบริการ'); return; }
    if (existingNames.includes(trimmedName)) { setError('ชื่อนี้มีอยู่แล้ว'); return; }
    if (!validateSchedule()) return;
    const coords = validateLatLng();
    if (coords === null) return;
    const cleanedContacts = contacts.filter(c => c.label.trim() || c.value.trim());

    setSaving(true);
    setError(null);

    const { error: addError } = await supabase.rpc('add_service_center', { p_name: trimmedName });
    if (addError) { setError(addError.message); setSaving(false); return; }

    const { error: initError } = await supabase.rpc('init_service_center_inventory', { p_name: trimmedName });
    if (initError) {
      setSaving(false);
      setError(`สถานบริการถูกเพิ่มแล้ว แต่เกิดข้อผิดพลาดในการสร้างสต็อก: ${initError.message}`);
      return;
    }

    const { error: upsertError } = await supabase.rpc('upsert_service_center', {
      p_name: trimmedName,
      p_image_url: imageUrl ?? undefined,
      p_description: description.trim() || undefined,
      p_contacts: cleanedContacts as unknown as never,
      p_latitude: coords.lat ?? undefined,
      p_longitude: coords.lng ?? undefined,
      p_operating_hours: operatingHours.trim().replace(/-/g, '–') || undefined,
      p_address: address.trim() || undefined,
      ...buildSchedulePayload(),
    });

    setSaving(false);
    if (upsertError) {
      setError(`สถานบริการถูกเพิ่มแล้ว แต่เกิดข้อผิดพลาดในการบันทึก: ${upsertError.message}`);
      return;
    }
    setAddedName(trimmedName);
  };

  const handleSaveEdit = async () => {
    if (!center) return;
    const trimmedName = name.trim();
    if (!trimmedName) { setError('กรุณากรอกชื่อสถานบริการ'); return; }
    const otherNames = existingNames.filter(n => n !== center.name);
    if (otherNames.includes(trimmedName)) { setError('ชื่อนี้มีอยู่แล้ว'); return; }
    if (!validateSchedule()) return;
    const coords = validateLatLng();
    if (coords === null) return;
    const cleanedContacts = contacts.filter(c => c.label.trim() || c.value.trim());

    setSaving(true);
    setError(null);

    if (trimmedName !== center.name) {
      const { error: renameError } = await supabase.rpc('rename_service_center', {
        p_old: center.name,
        p_new: trimmedName,
      });
      if (renameError) { setError(renameError.message); setSaving(false); return; }
    }

    const { error: saveError } = await supabase.rpc('upsert_service_center', {
      p_name: trimmedName,
      p_image_url: imageUrl ?? undefined,
      p_description: description.trim() || undefined,
      p_contacts: cleanedContacts as unknown as never,
      p_latitude: coords.lat ?? undefined,
      p_longitude: coords.lng ?? undefined,
      p_operating_hours: operatingHours.trim().replace(/-/g, '–') || undefined,
      p_address: address.trim() || undefined,
      ...buildSchedulePayload(),
    });

    setSaving(false);
    if (saveError) { setError(saveError.message); return; }
    onSuccess();
  };

  const handleDeleteConfirm = async () => {
    if (!center) return;
    setDeleting(true);
    setError(null);
    const { error: deleteError } = await supabase.rpc('delete_service_center', { p_name: center.name });
    setDeleting(false);
    setConfirmDeleteOpen(false);
    if (deleteError) {
      if (deleteError.message.includes('ยังมีเจ้าหน้าที่')) {
        setStaffBlockDialog(true);
      } else {
        setError(deleteError.message);
      }
      return;
    }
    window.location.reload();
  };

  const lat = parseFloat(latitude.trim());
  const lng = parseFloat(longitude.trim());
  const canShowMap = latitude.trim() && longitude.trim() && !isNaN(lat) && !isNaN(lng);
  const hasAssignedStaff = center !== null && (center.staff_count + center.admin_count) > 0;

  const switchSx = {
    '& .MuiSwitch-switchBase.Mui-checked': { color: '#F97316' },
    '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': { backgroundColor: '#F97316' },
  };

  const renderTimePeriod = (group: ScheduleGroup, period: SchedulePeriod, label: string) => {
    const times = getScheduleTimes(group, period);
    return (
      <Box sx={{ flex: 1, minWidth: 0 }}>
        <Typography variant="caption" fontWeight="bold" color="text.secondary" display="block" sx={{ mb: 0.5 }}>
          {label}
        </Typography>
        {times.map(t => (
          <Box key={t} sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 0.5 }}>
            <TextField
              type="time"
              value={t}
              onChange={(e) => handleTimeChange(group, period, t, e.target.value)}
              size="small"
              inputProps={{ step: 300 }}
              sx={{ flex: 1 }}
              disabled={saving}
            />
            <IconButton size="small" onClick={() => handleRemoveTime(group, period, t)} color="error" disabled={saving}>
              <DeleteOutlineIcon fontSize="small" />
            </IconButton>
          </Box>
        ))}
        <Button
          size="small"
          startIcon={<AddIcon />}
          onClick={() => handleAddTime(group, period)}
          disabled={saving}
          sx={{ color: 'text.secondary', fontSize: '0.75rem' }}
        >
          เพิ่มเวลา
        </Button>
      </Box>
    );
  };

  const renderSchedulePanel = (group: ScheduleGroup) => {
    const enabled = group === 'condom' ? condomEnabled : consultationEnabled;
    const setEnabled = group === 'condom' ? setCondomEnabled : setConsultationEnabled;
    return (
      <Box sx={{ pt: 1.5 }}>
        <FormControlLabel
          control={
            <Switch checked={enabled} onChange={(e) => setEnabled(e.target.checked)} disabled={saving} sx={switchSx} />
          }
          label="เปิดใช้งาน"
          sx={{ mb: 1 }}
        />
        <Box sx={{ display: 'flex', gap: 2 }}>
          {renderTimePeriod(group, 'morning', 'ช่วงเช้า')}
          {renderTimePeriod(group, 'afternoon', 'ช่วงบ่าย')}
        </Box>
      </Box>
    );
  };

  return (
    <>
      <Dialog open={open && !addedName} onClose={handleClose} maxWidth="sm" fullWidth fullScreen={isMobile}>
        <DialogTitle sx={{ pb: 1 }}>
          <Typography component="div" variant="h6" fontWeight="bold" lineHeight={1.2}>
            {isAddMode ? 'เพิ่มสถานบริการ' : 'แก้ไขสถานบริการ'}
          </Typography>
        </DialogTitle>

        <Divider />

        <DialogContent sx={{ pt: 2.5 }}>
          <Box
            sx={{
              position: 'relative', paddingTop: '56.25%', bgcolor: 'grey.100',
              borderRadius: 2, overflow: 'hidden', mb: 2.5,
              cursor: uploading ? 'not-allowed' : 'pointer',
            }}
            onClick={uploading ? undefined : () => imageInputRef.current?.click()}
          >
            {imageUrl ? (
              <Box
                component="img"
                src={imageUrl}
                sx={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', objectFit: 'cover' }}
              />
            ) : (
              <Box
                sx={{
                  position: 'absolute', top: 0, left: 0, width: '100%', height: '100%',
                  display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 1,
                }}
              >
                <StorefrontIcon sx={{ fontSize: 40, color: 'grey.400' }} />
                <Typography variant="caption" color="text.secondary">คลิกเพื่ออัปโหลดรูปภาพ</Typography>
              </Box>
            )}
            <Box sx={{ position: 'absolute', bottom: 8, right: 8 }}>
              <Button
                size="small"
                variant="contained"
                startIcon={uploading ? <CircularProgress size={14} color="inherit" /> : <PhotoCameraIcon />}
                onClick={(e) => { e.stopPropagation(); imageInputRef.current?.click(); }}
                disabled={uploading}
                sx={{ bgcolor: 'rgba(0,0,0,0.55)', '&:hover': { bgcolor: 'rgba(0,0,0,0.75)' } }}
              >
                {uploading ? 'กำลังอัปโหลด...' : 'เปลี่ยนรูป'}
              </Button>
            </Box>
          </Box>
          <input
            ref={imageInputRef}
            type="file"
            accept="image/jpeg,image/png,image/webp,image/gif"
            style={{ display: 'none' }}
            onChange={handleImageFileChange}
          />
          <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: -1.5, mb: 2.5 }}>
            รองรับไฟล์ JPG, PNG, WEBP, GIF ขนาดไม่เกิน 5 MB
          </Typography>

          <TextField
            label="ชื่อสถานบริการ"
            value={name}
            onChange={(e) => setName(e.target.value)}
            fullWidth
            required
            disabled={saving}
            sx={{ mb: 2 }}
          />

          <TextField
            label="ข้อมูลทั่วไป"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            fullWidth
            multiline
            rows={3}
            disabled={saving}
            sx={{ mb: 2 }}
          />

          <Divider sx={{ mb: 2 }} />
          <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 1 }}>
            กำหนดเวลา
          </Typography>
          <Tabs
            value={scheduleTab}
            onChange={(_, v) => setScheduleTab(v)}
            sx={{ mb: 0, borderBottom: 1, borderColor: 'divider' }}
          >
            {SCHEDULE_TABS.map(label => <Tab key={label} label={label} />)}
          </Tabs>
          {scheduleTab === 0 && renderSchedulePanel('condom')}
          {scheduleTab === 1 && renderSchedulePanel('consultation')}

          <Divider sx={{ mb: 2, mt: 2.5 }} />

          <TextField
            label="เวลาทำการ"
            value={operatingHours}
            onChange={(e) => setOperatingHours(e.target.value)}
            fullWidth
            size="small"
            placeholder="เช่น จ–ศ 08:00–16:00"
            disabled={saving}
            sx={{ mb: 2 }}
          />

          <TextField
            label="ที่อยู่"
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            fullWidth
            multiline
            rows={2}
            placeholder="เช่น 123 ถ.มิตรภาพ ต.หนองกาย อ.เมือง จ.หนองคาย 43000"
            disabled={saving}
            sx={{ mb: 2.5 }}
          />

          <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 1.5 }}>
            ข้อมูลติดต่อ
          </Typography>
          {contacts.map((c, i) => (
            <Box key={i} sx={{ display: 'flex', gap: 1, mb: 2, alignItems: 'center' }}>
              <TextField
                label="ป้ายกำกับ"
                value={c.label}
                onChange={(e) => handleContactChange(i, 'label', e.target.value)}
                size="small"
                sx={{ flex: 1 }}
                placeholder="เช่น โทรศัพท์"
                disabled={saving}
              />
              <TextField
                label="ช่องทางติดต่อ"
                value={c.value}
                onChange={(e) => handleContactChange(i, 'value', e.target.value)}
                size="small"
                sx={{ flex: 2 }}
                placeholder="เช่น 042-471-xxx"
                disabled={saving}
              />
              <Tooltip title="ลบ">
                <IconButton size="small" onClick={() => handleRemoveContact(i)} disabled={saving} color="error">
                  <DeleteOutlineIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            </Box>
          ))}
          <Button
            size="small"
            startIcon={<AddIcon />}
            onClick={handleAddContact}
            disabled={saving}
            sx={{ mb: 2.5, color: 'text.secondary' }}
          >
            เพิ่มช่องทางติดต่อ
          </Button>

          <Divider sx={{ mb: 2 }} />

          <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 1.5 }}>
            ตำแหน่ง
          </Typography>
          <Box sx={{ display: 'flex', gap: 1.5, mb: 1.5 }}>
            <TextField
              label="ละติจูด"
              value={latitude}
              onChange={(e) => setLatitude(e.target.value)}
              fullWidth
              size="small"
              placeholder="เช่น 17.6830000"
              disabled={saving}
              inputProps={{ inputMode: 'decimal' }}
            />
            <TextField
              label="ลองจิจูด"
              value={longitude}
              onChange={(e) => setLongitude(e.target.value)}
              fullWidth
              size="small"
              placeholder="เช่น 102.4160000"
              disabled={saving}
              inputProps={{ inputMode: 'decimal' }}
            />
          </Box>
          {canShowMap && (
            <Button
              variant="outlined"
              startIcon={<MapIcon />}
              component="a"
              href={`https://www.google.com/maps?q=${lat},${lng}`}
              target="_blank"
              rel="noopener noreferrer"
              sx={{ mb: 1 }}
            >
              ดูบน Google Maps
            </Button>
          )}

          {error && (
            <Alert ref={errorRef} severity="error" sx={{ mt: 2, borderRadius: 1.5 }}>{error}</Alert>
          )}
        </DialogContent>

        <DialogActions sx={{ px: 3, pb: 2.5, gap: 1 }}>
          {!isAddMode && isSuperadmin && (
            <span style={{ marginRight: 'auto' }}>
              <Button
                variant="contained"
                color="error"
                startIcon={<DeleteIcon />}
                onClick={() => hasAssignedStaff ? setStaffBlockDialog(true) : setConfirmDeleteOpen(true)}
                disabled={saving || deleting}
              >
                ลบ
              </Button>
            </span>
          )}
          <Button onClick={handleClose} disabled={saving || uploading || deleting} color="inherit">
            ยกเลิก
          </Button>
          <Button
            onClick={isAddMode ? handleSaveAdd : handleSaveEdit}
            variant="contained"
            disabled={saving || uploading || deleting}
            startIcon={saving ? <CircularProgress size={16} color="inherit" /> : null}
          >
            {saving ? 'กำลังบันทึก...' : 'บันทึก'}
          </Button>
        </DialogActions>
      </Dialog>

      <Dialog open={open && !!addedName} onClose={onSuccess} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1.5, pb: 1 }}>
          <CheckCircleOutlineIcon color="success" />
          <Typography component="div" variant="h6" fontWeight="bold">เพิ่มสถานบริการสำเร็จ</Typography>
        </DialogTitle>
        <Divider />
        <DialogContent sx={{ pt: 2.5 }}>
          <Typography variant="body2" color="text.secondary">
            เพิ่มสถานบริการ <strong>{addedName}</strong> เรียบร้อยแล้ว
          </Typography>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2.5 }}>
          <Button onClick={onSuccess} variant="contained">ปิด</Button>
        </DialogActions>
      </Dialog>

      <ConfirmDialog
        open={confirmDeleteOpen}
        icon={<DeleteOutlineIcon color="error" />}
        title="ยืนยันการลบสถานบริการ"
        body="คุณแน่ใจหรือไม่ว่าต้องการลบสถานบริการนี้? การดำเนินการนี้ไม่สามารถย้อนกลับได้"
        confirmLabel="ลบ"
        confirmColor="error"
        loading={deleting}
        onConfirm={handleDeleteConfirm}
        onCancel={() => setConfirmDeleteOpen(false)}
      />

      <Dialog open={staffBlockDialog} onClose={() => setStaffBlockDialog(false)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1.5, pb: 1 }}>
          <PeopleOutlineIcon color="warning" />
          <Typography component="div" variant="h6" fontWeight="bold">ยังมีเจ้าหน้าที่อยู่</Typography>
        </DialogTitle>
        <Divider />
        <DialogContent sx={{ pt: 2.5 }}>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
            ไม่สามารถลบสถานบริการ <strong>{center?.name}</strong> ได้ เนื่องจากยังมี
            {center && center.staff_count > 0 && <> เจ้าหน้าที่ <strong>{center.staff_count} คน</strong></>}
            {center && center.staff_count > 0 && center.admin_count > 0 && ' และ'}
            {center && center.admin_count > 0 && <> ผู้ดูแล <strong>{center.admin_count} คน</strong></>}
            {' '}ผูกกับสถานบริการนี้อยู่
          </Typography>
          <Typography variant="body2" color="text.secondary">
            กรุณาไปที่หน้า <strong>จัดการเจ้าหน้าที่</strong> และย้ายหรือลบเจ้าหน้าที่ทุกคนออกจากสถานบริการนี้ก่อน จึงจะสามารถลบได้
          </Typography>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2.5 }}>
          <Button onClick={() => setStaffBlockDialog(false)} variant="contained">รับทราบ</Button>
        </DialogActions>
      </Dialog>
    </>
  );
}
