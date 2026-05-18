import { useState, useEffect } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions, Button,
  Typography, Box, Grid, Card, CardContent, Chip,
  IconButton, Skeleton, Tooltip, Divider, Alert, CircularProgress,
} from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import AddIcon from '@mui/icons-material/Add';
import StorefrontIcon from '@mui/icons-material/Storefront';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import { useServiceCenters, type ServiceCenterRow } from '../../hooks/useServiceCenters';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { supabase } from '../../lib/supabase';
import ServiceCenterEditDialog from './ServiceCenterEditDialog';

// ─── Card ─────────────────────────────────────────────────────────────────────

interface CardProps {
  center: ServiceCenterRow;
  onEdit: () => void;
  isSuperadmin: boolean;
  toggling: boolean;
  onToggleActive: (newActive: boolean) => void;
}

function ServiceCenterCard({ center, onEdit, isSuperadmin, toggling, onToggleActive }: CardProps) {
  const firstTwoContacts = center.contacts.slice(0, 2);
  const hasLocation = center.latitude !== null && center.longitude !== null;

  return (
    <Card elevation={1} sx={{ borderRadius: 2, height: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* 16:9 image */}
      <Box sx={{ position: 'relative', paddingTop: '56.25%', bgcolor: 'grey.100', overflow: 'hidden', flexShrink: 0 }}>
        {center.image_url ? (
          <Box
            component="img"
            src={center.image_url}
            sx={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', objectFit: 'cover' }}
          />
        ) : (
          <Box sx={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <StorefrontIcon sx={{ fontSize: 48, color: 'grey.300' }} />
          </Box>
        )}
      </Box>

      <CardContent sx={{ p: 2, flex: 1, display: 'flex', flexDirection: 'column' }}>
        {/* Header: name + status chip + edit icon */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flex: 1, mr: 1, minWidth: 0 }}>
            <Typography variant="subtitle1" fontWeight="bold" noWrap>
              {center.name}
            </Typography>
            {isSuperadmin && (
              <Chip
                size="small"
                label={center.is_active ? 'ใช้งานอยู่' : 'ปิดใช้งาน'}
                sx={{
                  flexShrink: 0,
                  bgcolor: center.is_active ? '#E8F5E9' : '#F5F5F5',
                  color: center.is_active ? '#2E7D32' : '#9E9E9E',
                  fontSize: '0.7rem',
                }}
              />
            )}
          </Box>
          <Tooltip title="แก้ไข">
            <IconButton size="small" onClick={onEdit} sx={{ color: 'primary.main', flexShrink: 0 }}>
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>

        {/* Contacts */}
        {firstTwoContacts.length > 0 && (
          <Box sx={{ mb: 1.5 }}>
            {firstTwoContacts.map((c, i) => (
              <Typography key={i} variant="caption" color="text.secondary" display="block" noWrap>
                {c.label}: {c.value}
              </Typography>
            ))}
            {center.contacts.length > 2 && (
              <Typography variant="caption" color="text.disabled">
                +{center.contacts.length - 2} รายการ
              </Typography>
            )}
          </Box>
        )}

        <Box sx={{ mt: 'auto', display: 'flex', flexDirection: 'column', gap: 1 }}>
          {/* Location chip */}
          <Chip
            size="small"
            icon={<LocationOnIcon />}
            label={
              hasLocation
                ? `${center.latitude!.toFixed(4)}, ${center.longitude!.toFixed(4)}`
                : 'ยังไม่มีตำแหน่ง'
            }
            sx={{
              alignSelf: 'flex-start',
              bgcolor: hasLocation ? '#E8F5E9' : '#F5F5F5',
              color: hasLocation ? '#2E7D32' : '#9E9E9E',
              fontSize: '0.7rem',
              '& .MuiChip-icon': { color: hasLocation ? '#2E7D32' : '#9E9E9E', fontSize: 14 },
            }}
          />

          {/* Toggle button — superadmin only */}
          {isSuperadmin && (
            <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
              <Button
                variant="outlined"
                color={center.is_active ? 'error' : 'success'}
                disabled={toggling}
                onClick={() => onToggleActive(!center.is_active)}
                endIcon={toggling ? <CircularProgress size={14} color="inherit" /> : null}
              >
                {center.is_active ? 'ปิดใช้งาน' : 'เปิดใช้งาน'}
              </Button>
            </Box>
          )}
        </Box>
      </CardContent>
    </Card>
  );
}

// ─── Dialog ───────────────────────────────────────────────────────────────────

interface Props {
  open: boolean;
  onClose: () => void;
}

export default function ServiceCenterManagementDialog({ open, onClose }: Props) {
  const { centers, loading, error, refetch } = useServiceCenters(open);
  const { role } = useRoleAccess();
  const isSuperadmin = role === 'superadmin';
  const [editTarget, setEditTarget] = useState<ServiceCenterRow | null>(null);
  const [editOpen, setEditOpen] = useState(false);
  const [addOpen, setAddOpen] = useState(false);
  const [togglingCenter, setTogglingCenter] = useState<string | null>(null);

  useEffect(() => {
    if (!open) {
      setEditTarget(null);
      setEditOpen(false);
      setAddOpen(false);
    }
  }, [open]);

  const handleEdit = (center: ServiceCenterRow) => {
    setEditTarget(center);
    setEditOpen(true);
  };

  const handleDialogClose = () => {
    setEditOpen(false);
    setAddOpen(false);
    setEditTarget(null);
  };

  const handleDialogSuccess = () => {
    setEditOpen(false);
    setAddOpen(false);
    setEditTarget(null);
    refetch();
  };

  const handleToggleActive = async (center: ServiceCenterRow, newActive: boolean) => {
    setTogglingCenter(center.name);
    const { error: toggleError } = await supabase.rpc('toggle_service_center_active', {
      p_name: center.name,
      p_is_active: newActive,
    });
    setTogglingCenter(null);
    if (!toggleError) refetch();
  };

  return (
    <>
      <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
        <DialogTitle sx={{ pb: 1 }}>
          <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
            <Box>
              <Typography component="div" variant="h6" fontWeight="bold" lineHeight={1.2}>
                จัดการสถานบริการ
              </Typography>
              <Typography component="div" variant="caption" color="text.secondary">
                แก้ไขรูปภาพ ข้อมูลทั่วไป ช่องทางติดต่อ และตำแหน่งของแต่ละสถานบริการ
              </Typography>
            </Box>
            {isSuperadmin && (
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => setAddOpen(true)}
                sx={{ flexShrink: 0, ml: 2, mt: 0.5 }}
              >
                เพิ่มสถานบริการ
              </Button>
            )}
          </Box>
        </DialogTitle>

        <Divider />

        <DialogContent sx={{ pt: 2.5 }}>
          {error && (
            <Alert severity="error" sx={{ mb: 2.5, borderRadius: 1.5 }}>
              {error}
            </Alert>
          )}

          <Grid container spacing={2}>
            {loading
              ? Array.from({ length: 4 }).map((_, i) => (
                  <Grid key={i} size={{ xs: 12, sm: 6 }}>
                    <Skeleton variant="rounded" height={280} />
                  </Grid>
                ))
              : centers.map((center) => (
                  <Grid key={center.name} size={{ xs: 12, sm: 6 }}>
                    <ServiceCenterCard
                      center={center}
                      onEdit={() => handleEdit(center)}
                      isSuperadmin={isSuperadmin}
                      toggling={togglingCenter === center.name}
                      onToggleActive={(newActive) => handleToggleActive(center, newActive)}
                    />
                  </Grid>
                ))
            }
          </Grid>
        </DialogContent>

        <DialogActions sx={{ px: 3, pb: 2.5 }}>
          <Button onClick={onClose} color="inherit">ปิด</Button>
        </DialogActions>
      </Dialog>

      <ServiceCenterEditDialog
        open={editOpen || addOpen}
        center={addOpen ? null : editTarget}
        existingNames={centers.map(c => c.name)}
        isSuperadmin={isSuperadmin}
        onClose={handleDialogClose}
        onSuccess={handleDialogSuccess}
      />
    </>
  );
}
