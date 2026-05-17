import { useState, useEffect, useRef } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, TextField, Typography, Box, CircularProgress,
  Alert, Divider, IconButton, Tooltip,
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
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [staffBlockDialog, setStaffBlockDialog] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [addedName, setAddedName] = useState<string | null>(null);
  const imageInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!open) return;
    setError(null);
    setAddedName(null);
    setConfirmDelete(false);
    setStaffBlockDialog(false);
    if (center) {
      setName('');
      setDescription(center.description ?? '');
      setContacts(center.contacts.length > 0 ? [...center.contacts] : []);
      setLatitude(center.latitude !== null ? String(center.latitude) : '');
      setLongitude(center.longitude !== null ? String(center.longitude) : '');
      setImageUrl(center.image_url);
    } else {
      setName('');
      setDescription('');
      setContacts([]);
      setLatitude('');
      setLongitude('');
      setImageUrl(null);
    }
  }, [open, center]);

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

  const handleSaveAdd = async () => {
    const trimmedName = name.trim();
    if (!trimmedName) { setError('กรุณากรอกชื่อสถานบริการ'); return; }
    if (existingNames.includes(trimmedName)) { setError('ชื่อนี้มีอยู่แล้ว'); return; }

    setSaving(true);
    setError(null);

    const { error: addError } = await supabase.rpc('add_service_center', { p_name: trimmedName });
    if (addError) { setError(addError.message); setSaving(false); return; }

    const { error: initError } = await supabase.rpc('init_service_center_inventory', { p_name: trimmedName });
    setSaving(false);

    if (initError) {
      setError(`สถานบริการถูกเพิ่มแล้ว แต่เกิดข้อผิดพลาดในการสร้างสต็อก: ${initError.message}`);
      return;
    }

    setAddedName(trimmedName);
  };

  const handleSaveEdit = async () => {
    if (!center) return;
    const coords = validateLatLng();
    if (coords === null) return;

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
    });

    setSaving(false);
    if (saveError) { setError(saveError.message); return; }
    onSuccess();
  };

  const handleDelete = async () => {
    if (!center) return;
    if (!confirmDelete) { setConfirmDelete(true); return; }

    setDeleting(true);
    setError(null);
    const { error: deleteError } = await supabase.rpc('delete_service_center', { p_name: center.name });
    setDeleting(false);
    setConfirmDelete(false);

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

            {/* Description */}
            <TextField
              label="ข้อมูลทั่วไป"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              fullWidth
              multiline
              rows={3}
              sx={{ mb: 2.5 }}
              disabled={saving}
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

            {confirmDelete && (
              <Alert severity="warning" sx={{ mt: 2, borderRadius: 1.5 }}>
                คุณแน่ใจหรือไม่ว่าต้องการลบสถานบริการนี้? การดำเนินการนี้ไม่สามารถย้อนกลับได้ กดปุ่ม "ลบ" อีกครั้งเพื่อยืนยัน
              </Alert>
            )}

            {error && (
              <Alert severity="error" sx={{ mt: 2, borderRadius: 1.5 }}>
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
                  startIcon={deleting ? undefined : <DeleteIcon />}
                  endIcon={deleting ? <CircularProgress size={16} color="inherit" /> : undefined}
                  onClick={handleDelete}
                  disabled={!canDelete || saving || deleting}
                >
                  {confirmDelete ? 'ยืนยันลบ' : 'ลบ'}
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
            disabled={saving || uploading || deleting}
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
