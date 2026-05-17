import { useState, useEffect } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions, Button,
  Typography, Box, Grid, Card, CardContent, Chip,
  IconButton, Skeleton, Tooltip, Divider, Alert,
} from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import StorefrontIcon from '@mui/icons-material/Storefront';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import { useServiceCenters, type ServiceCenterRow } from '../../hooks/useServiceCenters';
import ServiceCenterEditDialog from './ServiceCenterEditDialog';

// ─── Card ─────────────────────────────────────────────────────────────────────

function ServiceCenterCard({ center, onEdit }: { center: ServiceCenterRow; onEdit: () => void }) {
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
            sx={{
              position: 'absolute', top: 0, left: 0,
              width: '100%', height: '100%', objectFit: 'cover',
            }}
          />
        ) : (
          <Box
            sx={{
              position: 'absolute', top: 0, left: 0,
              width: '100%', height: '100%',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}
          >
            <StorefrontIcon sx={{ fontSize: 48, color: 'grey.300' }} />
          </Box>
        )}
      </Box>

      <CardContent sx={{ p: 2, flex: 1, display: 'flex', flexDirection: 'column' }}>
        {/* Header row */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1 }}>
          <Typography variant="subtitle1" fontWeight="bold" sx={{ flex: 1, mr: 1 }}>
            {center.name}
          </Typography>
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

        <Box sx={{ mt: 'auto' }}>
          <Chip
            size="small"
            icon={<LocationOnIcon />}
            label={hasLocation ? 'มีตำแหน่ง' : 'ยังไม่มีตำแหน่ง'}
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

// ─── Dialog ───────────────────────────────────────────────────────────────────

interface Props {
  open: boolean;
  onClose: () => void;
}

export default function ServiceCenterManagementDialog({ open, onClose }: Props) {
  const { centers, loading, error, refetch } = useServiceCenters(open);
  const [editTarget, setEditTarget] = useState<ServiceCenterRow | null>(null);
  const [editOpen, setEditOpen] = useState(false);

  useEffect(() => {
    if (!open) {
      setEditTarget(null);
      setEditOpen(false);
    }
  }, [open]);

  const handleEdit = (center: ServiceCenterRow) => {
    setEditTarget(center);
    setEditOpen(true);
  };

  const handleEditClose = () => {
    setEditOpen(false);
    setEditTarget(null);
  };

  const handleEditSuccess = () => {
    setEditOpen(false);
    setEditTarget(null);
    refetch();
  };

  return (
    <>
      <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
        <DialogTitle sx={{ pb: 1 }}>
          <Typography component="div" variant="h6" fontWeight="bold" lineHeight={1.2}>
            จัดการสถานบริการ
          </Typography>
          <Typography component="div" variant="caption" color="text.secondary">
            แก้ไขรูปภาพ ข้อมูลทั่วไป ช่องทางติดต่อ และตำแหน่งของแต่ละสถานบริการ
          </Typography>
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
                    <Skeleton variant="rounded" height={240} />
                  </Grid>
                ))
              : centers.map((center) => (
                  <Grid key={center.name} size={{ xs: 12, sm: 6 }}>
                    <ServiceCenterCard center={center} onEdit={() => handleEdit(center)} />
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
        open={editOpen}
        center={editTarget}
        onClose={handleEditClose}
        onSuccess={handleEditSuccess}
      />
    </>
  );
}
