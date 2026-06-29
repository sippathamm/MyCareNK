import { useState, useEffect, useRef } from 'react';
import {
  Box, Typography, Grid, Card, CardContent, Chip,
  Button, Skeleton, Alert, IconButton, Tooltip, Pagination,
  TextField, CircularProgress, Paper, Stack,
  Select, MenuItem, FormControl, InputLabel,
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
import { alpha } from '@mui/material/styles';
import { useColorMode } from '../../contexts/ThemeContext';

const PAGE_SIZE = 6;

type ServiceFilter = 'all' | 'condom' | 'consultation';
type SortBy = 'newest' | 'oldest' | 'name_asc' | 'name_desc';

// ─── Card ─────────────────────────────────────────────────────────────────────

function ServiceCenterCard({ center, onEdit }: { center: ServiceCenterRow; onEdit: () => void }) {
  const { mode } = useColorMode();
  const firstTwoContacts = center.contacts.slice(0, 2);
  const hasLocation = center.latitude !== null && center.longitude !== null;

  const chipSx = (active: boolean) => ({
    height: 20,
    fontSize: '0.65rem',
    bgcolor: active
      ? mode === 'dark' ? alpha('#EA580C', 0.15) : '#FFF7ED'
      : mode === 'dark' ? alpha('#9E9E9E', 0.12) : '#F5F5F5',
    color: active ? '#EA580C' : '#9E9E9E',
    border: `1px solid ${active
      ? mode === 'dark' ? alpha('#EA580C', 0.4) : '#FDBA74'
      : mode === 'dark' ? alpha('#9E9E9E', 0.3) : '#E0E0E0'}`,
  });

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
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 0.75, minWidth: 0 }}>
          <Typography variant="subtitle1" fontWeight="bold" noWrap sx={{ flex: 1 }}>
            {center.name}
          </Typography>
          <Tooltip title="แก้ไข">
            <IconButton size="small" onClick={onEdit} sx={{ color: 'primary.main', flexShrink: 0 }}>
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>

        <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap', mb: 1 }}>
          <Chip size="small" label="แจกถุงยางอนามัย/เจลหล่อลื่น" sx={chipSx(center.condom_service_enabled)} />
          <Chip size="small" label="ให้คำปรึกษา" sx={chipSx(center.consultation_service_enabled)} />
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
              bgcolor: hasLocation
                ? mode === 'dark' ? alpha('#81C784', 0.2) : '#E8F5E9'
                : mode === 'dark' ? alpha('#9E9E9E', 0.12) : '#F5F5F5',
              color: hasLocation ? (mode === 'dark' ? '#81C784' : '#2E7D32') : '#9E9E9E',
              fontSize: '0.7rem',
              '& .MuiChip-icon': { color: hasLocation ? (mode === 'dark' ? '#81C784' : '#2E7D32') : '#9E9E9E', fontSize: 14 },
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
  const { role, loading: roleLoading } = useRoleAccess();
  const isSuperadmin = role === 'superadmin';

  const [editTarget, setEditTarget] = useState<ServiceCenterRow | null>(null);
  const [editOpen, setEditOpen] = useState(false);
  const [addOpen, setAddOpen] = useState(false);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [serviceFilter, setServiceFilter] = useState<ServiceFilter>('all');
  const [sortBy, setSortBy] = useState<SortBy>('newest');
  const isFirstPageRender = useRef(true);

  const filtered = centers
    .filter(c => {
      if (serviceFilter === 'condom') return c.condom_service_enabled;
      if (serviceFilter === 'consultation') return c.consultation_service_enabled;
      return true;
    })
    .filter(c => c.name.toLowerCase().includes(search.toLowerCase()))
    .sort((a, b) => {
      if (sortBy === 'newest') return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
      if (sortBy === 'oldest') return new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
      if (sortBy === 'name_asc') return a.name.localeCompare(b.name, 'th');
      return b.name.localeCompare(a.name, 'th');
    });

  const totalPages = Math.ceil(filtered.length / PAGE_SIZE);
  const paginatedCenters = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  useEffect(() => {
    if (!loading && page > 1 && page > Math.max(1, totalPages)) {
      setPage(Math.max(1, totalPages));
    }
  }, [loading, page, totalPages]);

  // Smooth scroll after React renders the new page content
  useEffect(() => {
    if (isFirstPageRender.current) { isFirstPageRender.current = false; return; }
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }, [page]);

  if (roleLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 10 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (!isSuperadmin) {
    return (
      <Box sx={{ textAlign: 'center', py: 10 }}>
        <Typography variant="h6" color="text.secondary">ไม่มีสิทธิ์เข้าถึงหน้านี้</Typography>
      </Box>
    );
  }

  const handleEdit = (center: ServiceCenterRow) => { setEditTarget(center); setEditOpen(true); };
  const handleClose = () => { setEditOpen(false); setAddOpen(false); setEditTarget(null); };
  const handleSuccess = () => { setEditOpen(false); setAddOpen(false); setEditTarget(null); refetch(); };

  const handleSearchChange = (value: string) => { setSearch(value); setPage(1); };
  const handleServiceFilterChange = (value: ServiceFilter) => { setServiceFilter(value); setPage(1); };
  const handleSortChange = (value: SortBy) => { setSortBy(value); setPage(1); };

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box>
          <Typography variant="h5" fontWeight="bold" gutterBottom>จัดการสถานบริการ</Typography>
          <Typography variant="body1" color="text.secondary">
            แก้ไขรูปภาพ ข้อมูลทั่วไป ช่องทางติดต่อ และตำแหน่งของแต่ละสถานบริการ
          </Typography>
        </Box>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setAddOpen(true)}>
          เพิ่มสถานบริการ
        </Button>
      </Box>

      <Paper elevation={1} sx={{ p: 2, mb: 3, borderRadius: 2 }}>
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems="center">
          <TextField
            label="ค้นหาสถานบริการ"
            variant="outlined"
            size="small"
            value={search}
            onChange={(e) => handleSearchChange(e.target.value)}
            sx={{ flexGrow: 1 }}
          />
          <FormControl size="small" sx={{ minWidth: 200 }}>
            <InputLabel>บริการ</InputLabel>
            <Select
              label="บริการ"
              value={serviceFilter}
              onChange={(e) => handleServiceFilterChange(e.target.value as ServiceFilter)}
            >
              <MenuItem value="all">ทั้งหมด</MenuItem>
              <MenuItem value="condom">แจกถุงอนามัย/เจลหล่อลื่น</MenuItem>
              <MenuItem value="consultation">ให้คำปรึกษา</MenuItem>
            </Select>
          </FormControl>
          <FormControl size="small" sx={{ minWidth: 160 }}>
            <InputLabel>เรียงตาม</InputLabel>
            <Select
              label="เรียงตาม"
              value={sortBy}
              onChange={(e) => handleSortChange(e.target.value as SortBy)}
            >
              <MenuItem value="newest">ใหม่สุด</MenuItem>
              <MenuItem value="oldest">เก่าสุด</MenuItem>
              <MenuItem value="name_asc">ชื่อ ก→ฮ</MenuItem>
              <MenuItem value="name_desc">ชื่อ ฮ→ก</MenuItem>
            </Select>
          </FormControl>
        </Stack>
      </Paper>

      {error && (
        <Alert severity="error" sx={{ mb: 2.5, borderRadius: 1.5 }}>{error}</Alert>
      )}

      <Grid container spacing={2}>
        {loading
          ? Array.from({ length: PAGE_SIZE }).map((_, i) => (
              <Grid key={i} size={{ xs: 12, sm: 6, md: 4 }}>
                <Skeleton variant="rounded" height={280} />
              </Grid>
            ))
          : paginatedCenters.map((center) => (
              <Grid key={center.name} size={{ xs: 12, sm: 6, md: 4 }}>
                <ServiceCenterCard center={center} onEdit={() => handleEdit(center)} />
              </Grid>
            ))
        }
        {!loading && paginatedCenters.length === 0 && (
          <Grid size={{ xs: 12 }}>
            <Typography color="text.secondary" textAlign="center" sx={{ py: 6 }}>
              {search || serviceFilter !== 'all' ? 'ไม่พบสถานบริการที่ตรงกับเงื่อนไข' : 'ยังไม่มีสถานบริการ'}
            </Typography>
          </Grid>
        )}
      </Grid>

      {!loading && totalPages > 1 && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}>
          <Pagination
            count={totalPages}
            page={page}
            onChange={(_, v) => setPage(v)}
            color="primary"
            shape="rounded"
          />
        </Box>
      )}

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
