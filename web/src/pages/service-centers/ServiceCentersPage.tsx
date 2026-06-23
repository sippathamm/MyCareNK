import { useState } from 'react';
import {
  Box, Typography, Grid, Card, CardContent, Chip,
  Button, Skeleton, Alert, IconButton, Tooltip,
} from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import AddIcon from '@mui/icons-material/Add';
import StorefrontIcon from '@mui/icons-material/Storefront';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import HomeIcon from '@mui/icons-material/Home';
import PeopleOutlineIcon from '@mui/icons-material/PeopleOutline';
import { useServiceCenters, type ServiceCenterRow } from '../../hooks/useServiceCenters';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import ServiceCenterEditDialog from '../../components/inventory/ServiceCenterEditDialog';

// ─── Card ─────────────────────────────────────────────────────────────────────

function ServiceCenterCard({ center, onEdit }: { center: ServiceCenterRow; onEdit: () => void }) {
  const firstTwoContacts = center.contacts.slice(0, 2);
  const hasLocation = center.latitude !== null && center.longitude !== null;

  return (
    <Card elevation={1} sx={{ borderRadius: 2, height: '100%', display: 'flex', flexDirection: 'column' }}>
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
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 1, minWidth: 0 }}>
          <Typography variant="subtitle1" fontWeight="bold" noWrap sx={{ flex: 1 }}>
            {center.name}
          </Typography>
          <Tooltip title="แก้ไข">
            <IconButton size="small" onClick={onEdit} sx={{ color: 'primary.main', flexShrink: 0 }}>
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>

        {center.operating_hours && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 0.5 }}>
            <AccessTimeIcon sx={{ fontSize: 13, color: 'text.disabled', flexShrink: 0 }} />
            <Typography variant="caption" color="text.secondary" noWrap>{center.operating_hours}</Typography>
          </Box>
        )}

        {center.address && (
          <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 0.5, mb: 1 }}>
            <HomeIcon sx={{ fontSize: 13, color: 'text.disabled', flexShrink: 0, mt: '1px' }} />
            <Typography variant="caption" color="text.secondary" sx={{ lineHeight: 1.4 }}>{center.address}</Typography>
          </Box>
        )}

        {firstTwoContacts.length > 0 && (
          <Box sx={{ mb: 1.5 }}>
            {firstTwoContacts.map((c, i) => (
              <Typography key={i} variant="caption" color="text.secondary" display="block" noWrap>
                {c.label}: {c.value}
              </Typography>
            ))}
            {center.contacts.length > 2 && (
              <Typography variant="caption" color="text.disabled">+{center.contacts.length - 2} รายการ</Typography>
            )}
          </Box>
        )}

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 1 }}>
          <PeopleOutlineIcon sx={{ fontSize: 13, color: 'text.disabled', flexShrink: 0 }} />
          <Typography variant="caption" color="text.secondary">
            เจ้าหน้าที่ {center.staff_count} · ผู้ดูแล {center.admin_count}
          </Typography>
        </Box>

        <Box sx={{ mt: 'auto' }}>
          <Chip
            size="small"
            icon={<LocationOnIcon />}
            label={hasLocation ? `${center.latitude!.toFixed(4)}, ${center.longitude!.toFixed(4)}` : 'ยังไม่มีตำแหน่ง'}
            sx={{
              bgcolor: hasLocation ? '#E8F5E9' : '#F5F5F5',
              color: hasLocation ? '#2E7D32' : '#9E9E9E',
              fontSize: '0.7rem',
              '& .MuiChip-icon': { color: hasLocation ? '#2E7D32' : '#9E9E9E', fontSize: 14 },
            }}
          />
        </Box>
      </CardContent>
    </Card>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function ServiceCentersPage() {
  const { centers, loading, error, refetch } = useServiceCenters(true);
  const { role } = useRoleAccess();
  const isSuperadmin = role === 'superadmin';
  const canManage = role === 'admin' || role === 'superadmin';

  const [editTarget, setEditTarget] = useState<ServiceCenterRow | null>(null);
  const [editOpen, setEditOpen] = useState(false);
  const [addOpen, setAddOpen] = useState(false);

  const handleEdit = (center: ServiceCenterRow) => { setEditTarget(center); setEditOpen(true); };
  const handleClose = () => { setEditOpen(false); setAddOpen(false); setEditTarget(null); };
  const handleSuccess = () => { setEditOpen(false); setAddOpen(false); setEditTarget(null); refetch(); };

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
        <Box>
          <Typography variant="h5" fontWeight="bold" gutterBottom>จัดการสถานบริการ</Typography>
          <Typography variant="body1" color="text.secondary">
            แก้ไขรูปภาพ ข้อมูลทั่วไป ช่องทางติดต่อ และตำแหน่งของแต่ละสถานบริการ
          </Typography>
        </Box>
        {canManage && (
          <Button variant="contained" startIcon={<AddIcon />} onClick={() => setAddOpen(true)}>
            เพิ่มสถานบริการ
          </Button>
        )}
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2.5, borderRadius: 1.5 }}>{error}</Alert>
      )}

      <Grid container spacing={2}>
        {loading
          ? Array.from({ length: 4 }).map((_, i) => (
              <Grid key={i} size={{ xs: 12, sm: 6, md: 4 }}>
                <Skeleton variant="rounded" height={280} />
              </Grid>
            ))
          : centers.map((center) => (
              <Grid key={center.name} size={{ xs: 12, sm: 6, md: 4 }}>
                <ServiceCenterCard center={center} onEdit={() => handleEdit(center)} />
              </Grid>
            ))
        }
      </Grid>

      <ServiceCenterEditDialog
        open={editOpen || addOpen}
        center={addOpen ? null : editTarget}
        existingNames={centers.map(c => c.name)}
        isSuperadmin={isSuperadmin}
        onClose={handleClose}
        onSuccess={handleSuccess}
      />
    </Box>
  );
}
