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

type ScheduleTab = 'condom' | 'appointment';
type Period = 'morning' | 'afternoon';

const DEFAULT_PICKUP_MORNING   = ['08:00'];
const DEFAULT_PICKUP_AFTERNOON: string[] = [];
const DEFAULT_APPT_MORNING     = ['08:00'];
const DEFAULT_APPT_AFTERNOON: string[]   = [];

const TIME_REGEX = /^\d{2}:\d{2}$/;

function hourOf(t: string): number {
  return parseInt(t.split(':')[0], 10);
}

function generateId(): string {
  return Array.from(crypto.getRandomValues(new Uint8Array(16)))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

function getFileExtension(filename: string) {
  return filename.split('.').pop() ?? 'jpg';
}

export default function ServiceCenterEditDialog({ open, center, existingNames, isSuperadmin, onClose, onSuccess }: Props) {
  const isAddMode = open && center === null;

  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [contacts, setContacts] = useState<ContactItem[]>([]);
  const [latitude, setLatitude] = useState('');
  const [longitude, setLongitude] = useState('');
  const [operatingHours, setOperatingHours] = useState('');
  const [address, setAddress] = useState('');
  const [imageUrl, setImageUrl] = useState<string | null>(null);

  const [scheduleTab, setScheduleTab] = useState<ScheduleTab>('condom');
  const [condomEnabled, setCondomEnabled] = useState(true);
  const [appointmentEnabled, setAppointmentEnabled] = useState(false);
  const [pickupMorning, setPickupMorning]     = useState<string[]>(DEFAULT_PICKUP_MORNING);
  const [pickupAfternoon, setPickupAfternoon] = useState<string[]>(DEFAULT_PICKUP_AFTERNOON);
  const [apptMorning, setApptMorning]         = useState<string[]>(DEFAULT_APPT_MORNING);
  const [apptAfternoon, setApptAfternoon]     = useState<string[]>(DEFAULT_APPT_AFTERNOON);

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
    setScheduleTab('condom');
    if (center) {
      setName('');
      setDescription(center.description ?? '');
      setAddress(center.address ?? '');
      setContacts(center.contacts.length > 0 ? [...center.contacts] : []);
      setLatitude(center.latitude !== null ? String(center.latitude) : '');
      setLongitude(center.longitude !== null ? String(center.longitude) : '');
      setOperatingHours(center.operating_hours ?? '');
      setImageUrl(center.image_url);
      setCondomEnabled(center.condom_service_enabled ?? true);
      setAppointmentEnabled(center.appointment_service_enabled ?? false);
      const pu = center.pickup_times ?? [];
      const pm = pu.filter(t => hourOf(t) < 12);
      const pa = pu.filter(t => hourOf(t) >= 12);
      setPickupMorning(pu.length === 0 ? DEFAULT_PICKUP_MORNING : pm);
      setPickupAfternoon(pu.length === 0 ? DEFAULT_PICKUP_AFTERNOON : pa);
      const au = center.appointment_times ?? [];
      const am = au.filter(t => hourOf(t) < 12);
      const aa = au.filter(t => hourOf(t) >= 12);
      setApptMorning(au.length === 0 ? DEFAULT_APPT_MORNING : am);
      setApptAfternoon(au.length === 0 ? DEFAULT_APPT_AFTERNOON : aa);
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
      setAppointmentEnabled(false);
      setPickupMorning(DEFAULT_PICKUP_MORNING);
      setPickupAfternoon(DEFAULT_PICKUP_AFTERNOON);
      setApptMorning(DEFAULT_APPT_MORNING);
      setApptAfternoon(DEFAULT_APPT_AFTERNOON);
    }
  }, [open, center]);

  useEffect(() => {
    if (error) {
      errorRef.current?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  }, [error]);

  const handleClose = () => {
    if (saving || uploading || deleting) return;
    if (addedName) { onSuccess(); return; }
    onClose();
  };

  const handleAddContact = () => setContacts(prev => [...prev, { label: '', value: '' }]);
  const handleContactChange = (i: number, field: 'label' | 'value', val: string) => {
    setContacts(prev => prev.map((c, idx) => idx === i ? { ...c, [field]: val } : c));
  };
  const handleRemoveContact = (i: number) => {
    setContacts(prev => prev.filter((_, idx) => idx !== i));
  };

  const handleAddTime = (type: ScheduleTab, period: Period) => {
    if (type === 'condom') {
      if (period === 'morning') setPickupMorning(prev => [...prev, '']);
      else setPickupAfternoon(prev => [...prev, '']);
    } else {
      if (period === 'morning') setApptMorning(prev => [...prev, '']);
      else setApptAfternoon(prev => [...prev, '']);
    }
  };
  const handleTimeChange = (type: ScheduleTab, period: Period, i: number, val: string) => {
    if (type === 'condom') {
      if (period === 'morning') setPickupMorning(prev => prev.map((t, idx) => idx === i ? val : t));
      else setPickupAfternoon(prev => prev.map((t, idx) => idx === i ? val : t));
    } else {
      if (period === 'morning') setApptMorning(prev => prev.map((t, idx) => idx === i ? val : t));
      else setApptAfternoon(prev => prev.map((t, idx) => idx === i ? val : t));
    }
  };
  const handleRemoveTime = (type: ScheduleTab, period: Period, i: number) => {
    if (type === 'condom') {
      if (period === 'morning') setPickupMorning(prev => prev.filter((_, idx) => idx !== i));
      else setPickupAfternoon(prev => prev.filter((_, idx) => idx !== i));
    } else {
      if (period === 'morning') setApptMorning(prev => prev.filter((_, idx) => idx !== i));
      else setApptAfternoon(prev => prev.filter((_, idx) => idx !== i));
    }
  };

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

  const validateSchedule = (): { cleanPickup: string[]; cleanAppt: string[] } | null => {
    if (!condomEnabled && !appointmentEnabled) {
      setError('ต้องเปิดใช้งานอย่างน้อย 1 บริการ (รับถุงยางอนามัย หรือ นัดพบแพทย์)');
      return null;
    }
    const dedup = (arr: string[]) => {
      const seen = new Set<string>();
      return arr.map(t => t.trim()).filter(t => { if (!t || seen.has(t)) return false; seen.add(t); return true; });
    };

    const cpm = dedup(pickupMorning);
    const cpa = dedup(pickupAfternoon);
    const cam = dedup(apptMorning);
    const caa = dedup(apptAfternoon);
    const cleanPickup = [...cpm, ...cpa].sort();
    const cleanAppt   = [...cam, ...caa].sort();

    if (condomEnabled) {
      if (cleanPickup.length === 0) {
        setScheduleTab('condom');
        setError('กรุณาเพิ่มเวลารับถุงยางอนามัยอย่างน้อย 1 ช่วงเวลา');
        return null;
      }
      for (const t of cpm) {
        if (!TIME_REGEX.test(t) || hourOf(t) >= 12) {
          setScheduleTab('condom');
          setError(`เวลาช่วงเช้า "${t}" ต้องอยู่ในรูปแบบ HH:MM และก่อน 12:00`);
          return null;
        }
      }
      for (const t of cpa) {
        if (!TIME_REGEX.test(t) || hourOf(t) < 12) {
          setScheduleTab('condom');
          setError(`เวลาช่วงบ่าย "${t}" ต้องอยู่ในรูปแบบ HH:MM และตั้งแต่ 12:00`);
          return null;
        }
      }
    }
    if (appointmentEnabled) {
      if (cleanAppt.length === 0) {
        setScheduleTab('appointment');
        setError('กรุณาเพิ่มเวลานัดพบแพทย์อย่างน้อย 1 ช่วงเวลา');
        return null;
      }
      for (const t of cam) {
        if (!TIME_REGEX.test(t) || hourOf(t) >= 12) {
          setScheduleTab('appointment');
          setError(`เวลาช่วงเช้า "${t}" ต้องอยู่ในรูปแบบ HH:MM และก่อน 12:00`);
          return null;
        }
      }
      for (const t of caa) {
        if (!TIME_REGEX.test(t) || hourOf(t) < 12) {
          setScheduleTab('appointment');
          setError(`เวลาช่วงบ่าย "${t}" ต้องอยู่ในรูปแบบ HH:MM และตั้งแต่ 12:00`);
          return null;
        }
      }
    }
    return { cleanPickup, cleanAppt };
  };

  const handleSaveAdd = async () => {
    const trimmedName = name.trim();
    if (!trimmedName) { setError('กรุณากรอกชื่อสถานบริการ'); return; }
    if (existingNames.includes(trimmedName)) { setError('ชื่อนี้มีอยู่แล้ว'); return; }
    const schedule = validateSchedule();
    if (schedule === null) return;
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
      p_condom_service_enabled: condomEnabled,
      p_appointment_service_enabled: appointmentEnabled,
      p_pickup_times: condomEnabled ? schedule.cleanPickup : [],
      p_appointment_times: appointmentEnabled ? schedule.cleanAppt : [],
    });

    setSaving(false);
    if (upsertError) {
      setError(`สถานบริการถูกเพิ่มแล้ว แต่เกิดข้อผิดพลาดในการบันทึกเวลา: ${upsertError.message}`);
      return;
    }

    setAddedName(trimmedName);
  };

  const handleSaveEdit = async () => {
    if (!center) return;
    const coords = validateLatLng();
    if (coords === null) return;
    const schedule = validateSchedule();
    if (schedule === null) return;

    const cleanedContacts = contacts.filter(c => c.label.trim() || c.value.trim());
    setSaving(true);
    setError(null);

    const { error: saveError } = await supabase.rpc('upsert_service_center', {
      p_name: center.name,
      p_image_url: imageUrl ?? undefined,
      p_description: description.trim() || undefined,
      p_contacts: cleanedContacts as unknown as never,
      p_latitude: coords.lat ?? undefined,
      p_longitude: coords.lng ?? undefined,
      p_operating_hours: operatingHours.trim().replace(/-/g, '–') || undefined,
      p_address: address.trim() || undefined,
      p_condom_service_enabled: condomEnabled,
      p_appointment_service_enabled: appointmentEnabled,
      p_pickup_times: condomEnabled ? schedule.cleanPickup : [],
      p_appointment_times: appointmentEnabled ? schedule.cleanAppt : [],
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
    onSuccess();
  };

  const lat = parseFloat(latitude.trim());
  const lng = parseFloat(longitude.trim());
  const canShowMap = latitude.trim() && longitude.trim() && !isNaN(lat) && !isNaN(lng);
  const canDelete = center !== null && !center.is_active;
  const currentEnabled = scheduleTab === 'condom' ? condomEnabled : appointmentEnabled;
  const isInvalidTime = (t: string): boolean => {
    if (!TIME_REGEX.test(t)) return false;
    const [h, m] = t.split(':').map(Number);
    return h > 23 || m > 59;
  };

  const isOutOfRange = (t: string, period: Period): boolean =>
    TIME_REGEX.test(t) && !isInvalidTime(t) && (period === 'morning' ? hourOf(t) >= 12 : hourOf(t) < 12);

  const hasRangeError =
    (condomEnabled && (
      pickupMorning.some(t => isInvalidTime(t) || isOutOfRange(t, 'morning')) ||
      pickupAfternoon.some(t => isInvalidTime(t) || isOutOfRange(t, 'afternoon'))
    )) ||
    (appointmentEnabled && (
      apptMorning.some(t => isInvalidTime(t) || isOutOfRange(t, 'morning')) ||
      apptAfternoon.some(t => isInvalidTime(t) || isOutOfRange(t, 'afternoon'))
    ));

  const renderTimePeriod = (type: ScheduleTab, period: Period, label: string, times: string[]) => (
    <Box sx={{ flex: 1 }}>
      <Typography variant="caption" color="text.secondary" fontWeight={600} sx={{ display: 'block', mb: 1 }}>
        {label}
      </Typography>
      {times.map((t, i) => (
        <Box key={i} sx={{ display: 'flex', gap: 0.5, mb: 0.75, alignItems: 'flex-start' }}>
          <TextField
            type="text"
            value={t}
            onChange={(e) => handleTimeChange(type, period, i, e.target.value)}
            size="small"
            disabled={saving}
            error={isInvalidTime(t) || isOutOfRange(t, period)}
            helperText={
              isInvalidTime(t) ? 'รูปแบบเวลาไม่ถูกต้อง' :
              isOutOfRange(t, period) ? (period === 'morning' ? 'ต้องก่อน 12:00' : 'ต้องตั้งแต่ 12:00') :
              undefined
            }
            placeholder="HH:MM"
            inputProps={{ maxLength: 5 }}
            sx={{ flex: 1 }}
          />
          <Tooltip title="ลบ">
            <IconButton size="small" onClick={() => handleRemoveTime(type, period, i)} disabled={saving} color="error">
              <DeleteOutlineIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      ))}
      <Button
        size="small"
        startIcon={<AddIcon />}
        onClick={() => handleAddTime(type, period)}
        disabled={saving}
        sx={{ color: 'text.secondary', fontSize: 12 }}
      >
        เพิ่มเวลา
      </Button>
    </Box>
  );

  const renderScheduleSection = () => {
    const morningTimes   = scheduleTab === 'condom' ? pickupMorning   : apptMorning;
    const afternoonTimes = scheduleTab === 'condom' ? pickupAfternoon : apptAfternoon;
    return (
      <>
        <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 1 }}>
          กำหนดเวลา
        </Typography>

        <Tabs
          value={scheduleTab}
          onChange={(_, v: ScheduleTab) => setScheduleTab(v)}
          sx={{ mb: 1.5, minHeight: 36 }}
          TabIndicatorProps={{ style: { backgroundColor: '#FF9F6B' } }}
        >
          <Tab
            label="รับถุงยางอนามัย"
            value="condom"
            sx={{ minHeight: 36, fontSize: 13, fontWeight: 600, color: scheduleTab === 'condom' ? '#FF9F6B' : 'text.secondary', '&.Mui-selected': { color: '#FF9F6B' } }}
          />
          <Tab
            label="นัดพบแพทย์"
            value="appointment"
            sx={{ minHeight: 36, fontSize: 13, fontWeight: 600, color: scheduleTab === 'appointment' ? '#FF9F6B' : 'text.secondary', '&.Mui-selected': { color: '#FF9F6B' } }}
          />
        </Tabs>

        <FormControlLabel
          control={
            <Switch
              checked={currentEnabled}
              onChange={(e) => {
                if (scheduleTab === 'condom') setCondomEnabled(e.target.checked);
                else setAppointmentEnabled(e.target.checked);
              }}
              disabled={saving}
              sx={{
                '& .MuiSwitch-switchBase.Mui-checked': { color: '#FF9F6B' },
                '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': { backgroundColor: '#FF9F6B' },
              }}
            />
          }
          label={
            <Typography variant="body2" color={currentEnabled ? 'text.primary' : 'text.secondary'}>
              เปิดใช้งาน
            </Typography>
          }
          sx={{ mb: currentEnabled ? 1.5 : 2 }}
        />

        {currentEnabled && (
          <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
            {renderTimePeriod(scheduleTab, 'morning', 'ช่วงเช้า', morningTimes)}
            {renderTimePeriod(scheduleTab, 'afternoon', 'ช่วงบ่าย', afternoonTimes)}
          </Box>
        )}

        <Divider sx={{ mb: 2 }} />
      </>
    );
  };

  return (
    <>
    <Dialog open={open && !addedName} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ pb: 1 }}>
        <Typography component="div" variant="h6" fontWeight="bold" lineHeight={1.2}>
          {isAddMode ? 'เพิ่มสถานบริการ' : 'แก้ไขสถานบริการ'}
        </Typography>
        {!isAddMode && center && (
          <Typography component="div" variant="caption" color="text.secondary">
            {center.name}
          </Typography>
        )}
      </DialogTitle>

      <Divider />

      <DialogContent sx={{ pt: 2.5 }}>
        <>
            {/* Image upload — 16:9 */}
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

            {/* Name */}
            <TextField
              label="ชื่อสถานบริการ"
              value={isAddMode ? name : center?.name ?? ''}
              onChange={isAddMode ? (e) => setName(e.target.value) : undefined}
              fullWidth
              required={isAddMode}
              disabled={!isAddMode || saving}
              sx={{ mb: 2 }}
            />

            {/* Scheduling — both modes */}
            {renderScheduleSection()}

            {/* Description */}
            <TextField
              label="ข้อมูลทั่วไป"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              fullWidth
              multiline
              rows={3}
              sx={{ mb: 2 }}
              disabled={saving}
            />

            {/* Operating hours */}
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

            {/* Address */}
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

            {/* Contacts */}
            <Typography variant="subtitle2" fontWeight="bold" sx={{ mb: 1.5 }}>
              ข้อมูลติดต่อ
            </Typography>

            {contacts.map((c, i) => (
              <Box key={i} sx={{ display: 'flex', gap: 1, mb: 1, alignItems: 'center' }}>
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

            {/* Location */}
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

            <Divider sx={{ mb: 2, mt: 1 }} />

            {error && (
              <Alert ref={errorRef} severity="error" sx={{ mt: 2, borderRadius: 1.5 }}>
                {error}
              </Alert>
            )}
          </>
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 2.5, gap: 1 }}>
        <>
          {/* Delete button — edit mode only, superadmin only, bottom-left */}
          {!isAddMode && isSuperadmin && (
            <Tooltip title={canDelete ? '' : 'ปิดใช้งานสถานบริการก่อนจึงจะสามารถลบได้'}>
              <span style={{ marginRight: 'auto' }}>
                <Button
                  variant="contained"
                  color="error"
                  startIcon={<DeleteIcon />}
                  onClick={() => setConfirmDeleteOpen(true)}
                  disabled={!canDelete || saving || deleting}
                >
                  ลบ
                </Button>
              </span>
            </Tooltip>
          )}

          <Button onClick={handleClose} disabled={saving || uploading || deleting} color="inherit">
            ยกเลิก
          </Button>
          <Button
            onClick={isAddMode ? handleSaveAdd : handleSaveEdit}
            variant="contained"
            disabled={saving || uploading || deleting || hasRangeError}
            startIcon={saving ? <CircularProgress size={16} color="inherit" /> : null}
          >
            {saving ? 'กำลังบันทึก...' : 'บันทึก'}
          </Button>
        </>
      </DialogActions>
    </Dialog>

    {/* Add success dialog */}
    <Dialog open={open && !!addedName} onClose={onSuccess} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1.5, pb: 1 }}>
        <CheckCircleOutlineIcon color="success" />
        <Typography component="div" variant="h6" fontWeight="bold">เพิ่มสถานบริการสำเร็จ</Typography>
      </DialogTitle>
      <Divider />
      <DialogContent sx={{ pt: 2.5 }}>
        <Typography variant="body2" color="text.secondary">
          เพิ่มสถานบริการ <strong>{addedName}</strong> เรียบร้อยแล้ว กรุณา refresh หน้า <strong>สต็อกและพยากรณ์</strong>
        </Typography>
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2.5 }}>
        <Button onClick={onSuccess} variant="contained">ปิด</Button>
      </DialogActions>
    </Dialog>

    {/* Confirm delete */}
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

    {/* Staff-still-assigned warning dialog */}
    <Dialog open={staffBlockDialog} onClose={() => setStaffBlockDialog(false)} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1.5, pb: 1 }}>
        <PeopleOutlineIcon color="warning" />
        <Typography component="div" variant="h6" fontWeight="bold">ยังมีเจ้าหน้าที่อยู่</Typography>
      </DialogTitle>
      <Divider />
      <DialogContent sx={{ pt: 2.5 }}>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
          ไม่สามารถลบสถานบริการ <strong>{center?.name}</strong> ได้ เนื่องจากยังมีบัญชีเจ้าหน้าที่ที่ผูกกับสถานบริการนี้อยู่
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
