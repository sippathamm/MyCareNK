import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box, Typography, Paper, Chip, Button, IconButton, Tooltip,
  Stack, TextField,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef, GridRenderCellParams } from '@mui/x-data-grid';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import ArticleIcon from '@mui/icons-material/Article';
import { useArticles, getArticleStatus, type Article, type ArticleStatus } from '../../hooks/useArticles';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { formatDateTime } from '../../utils/requestUtils';
import { createThGridLocale } from '../../constants/datagrid';

// ─── Constants ────────────────────────────────────────────────────────────────

const STATUS_FILTERS = [
  { value: 'all', label: 'ทั้งหมด' },
  { value: 'published', label: 'เผยแพร่แล้ว' },
  { value: 'scheduled', label: 'รอเผยแพร่' },
  { value: 'draft', label: 'ร่าง' },
] as const;

type FilterValue = typeof STATUS_FILTERS[number]['value'];

const STATUS_CHIP_PROPS: Record<ArticleStatus, { label: string; sx: object }> = {
  published: {
    label: 'เผยแพร่แล้ว',
    sx: { bgcolor: '#E8F5E9', color: '#2E7D32', fontWeight: 'bold' },
  },
  scheduled: {
    label: 'รอเผยแพร่',
    sx: { bgcolor: '#E3F2FD', color: '#1565C0', fontWeight: 'bold' },
  },
  draft: {
    label: 'ร่าง',
    sx: { bgcolor: '#F5F5F5', color: '#616161', fontWeight: 'bold' },
  },
};

const thGridLocale = createThGridLocale('ยังไม่มีบทความ');

// ─── Helpers ──────────────────────────────────────────────────────────────────

function StatusChip({ article }: { article: Article }) {
  const status = getArticleStatus(article);
  const { label, sx } = STATUS_CHIP_PROPS[status];
  return <Chip label={label} size="small" sx={sx} />;
}

function CoverThumbnail({ url }: { url: string | null }) {
  if (!url) {
    return (
      <Box
        sx={{
          width: 80, height: 45, borderRadius: 1,
          background: 'linear-gradient(135deg, #FEF1D2 0%, #FBCFB8 100%)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}
      >
        <ArticleIcon sx={{ fontSize: 18, color: '#FF9F6B' }} />
      </Box>
    );
  }
  return (
    <Box
      component="img"
      src={url}
      sx={{ width: 80, height: 45, borderRadius: 1, objectFit: 'cover', display: 'block' }}
    />
  );
}

// ─── Component ────────────────────────────────────────────────────────────────

export default function ArticlesPage() {
  const navigate = useNavigate();
  const { articles, staffMap, loading } = useArticles();
  const { role } = useRoleAccess();
  const canManage = role === 'admin' || role === 'superadmin';

  const [filter, setFilter] = useState<FilterValue>('all');
  const [titleSearch, setTitleSearch] = useState('');

  // ─── Filter ───────────────────────────────────────────────────────────────

  const filtered = useMemo(() => {
    let result = articles;
    if (filter !== 'all') result = result.filter(a => getArticleStatus(a) === filter);
    if (titleSearch.trim()) {
      const q = titleSearch.trim().toLowerCase();
      result = result.filter(a => a.title.toLowerCase().includes(q));
    }
    return result;
  }, [articles, filter, titleSearch]);

  const counts = useMemo(() => ({
    all: articles.length,
    published: articles.filter(a => getArticleStatus(a) === 'published').length,
    scheduled: articles.filter(a => getArticleStatus(a) === 'scheduled').length,
    draft: articles.filter(a => getArticleStatus(a) === 'draft').length,
  }), [articles]);

  // ─── Columns ──────────────────────────────────────────────────────────────

  const columns: GridColDef[] = [
    {
      field: 'cover_image_url',
      headerName: 'รูปหน้าปก',
      width: 110,
      sortable: false,
      renderCell: (params: GridRenderCellParams<Article>) => (
        <Box sx={{ display: 'flex', alignItems: 'center', height: '100%' }}>
          <CoverThumbnail url={params.row.cover_image_url} />
        </Box>
      ),
    },
    {
      field: 'title',
      headerName: 'เรื่อง',
      flex: 1,
      minWidth: 220,
      renderCell: (params: GridRenderCellParams<Article>) => {
        const isPublished = getArticleStatus(params.row) === 'published';
        const hasDraft = params.row.has_draft && isPublished;
        const hidden = !params.row.is_visible;
        return (
          <Box sx={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', height: '100%', py: 1 }}>
            <Typography variant="body2" fontWeight="bold" noWrap sx={{ maxWidth: 320 }}>
              {params.row.title}
            </Typography>
            {hasDraft && (
              <Typography variant="caption" sx={{ color: '#E65100', fontWeight: 600, display: 'block' }}>
                มีการแก้ไขที่ยังไม่ได้เผยแพร่
              </Typography>
            )}
            {hidden && (
              <Typography variant="caption" sx={{ color: 'text.disabled', display: 'block' }}>
                ซ่อนอยู่ (ผู้ใช้ไม่เห็น)
              </Typography>
            )}
          </Box>
        );
      },
    },
    {
      field: 'created_by',
      headerName: 'โดย',
      flex: 0.7,
      minWidth: 130,
      renderCell: (params: GridRenderCellParams<Article>) => (
        <Box sx={{ display: 'flex', alignItems: 'center', height: '100%' }}>
          <Typography variant="body2">
            {params.row.created_by ? (staffMap[params.row.created_by] || '—') : '—'}
          </Typography>
        </Box>
      ),
    },
    {
      field: 'status',
      headerName: 'สถานะ',
      width: 140,
      sortable: false,
      renderCell: (params: GridRenderCellParams<Article>) => (
        <Box sx={{ display: 'flex', alignItems: 'center', height: '100%' }}>
          <StatusChip article={params.row} />
        </Box>
      ),
    },
    {
      field: 'publish_at',
      headerName: 'เผยแพร่ล่าสุด',
      flex: 0.8,
      minWidth: 160,
      renderCell: (params: GridRenderCellParams<Article>) => (
        <Box sx={{ display: 'flex', alignItems: 'center', height: '100%' }}>
          <Typography variant="body2">
            {getArticleStatus(params.row) === 'published' && params.row.publish_at
              ? formatDateTime(params.row.publish_at)
              : '—'}
          </Typography>
        </Box>
      ),
    },
    {
      field: 'updated_at',
      headerName: 'แก้ไขล่าสุด',
      flex: 0.8,
      minWidth: 160,
      renderCell: (params: GridRenderCellParams<Article>) => (
        <Box sx={{ display: 'flex', alignItems: 'center', height: '100%' }}>
          <Typography variant="body2">
            {formatDateTime(params.row.updated_at ?? undefined)}
          </Typography>
        </Box>
      ),
    },
    ...(canManage ? [{
      field: 'actions',
      headerName: '',
      width: 60,
      sortable: false,
      align: 'center' as const,
      headerAlign: 'center' as const,
      renderCell: (params: GridRenderCellParams<Article>) => (
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' }}>
          <Tooltip title="แก้ไข">
            <IconButton
              size="small"
              onClick={() => navigate(`/articles/${params.row.id}/edit`)}
              sx={{ color: '#FF9F6B' }}
            >
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      ),
    }] : []),
  ];

  // ─── Render ───────────────────────────────────────────────────────────────

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
        <Box>
          <Typography variant="h5" fontWeight="bold" gutterBottom>บทความ</Typography>
          <Typography variant="body1" color="text.secondary">จัดการบทความสาระน่ารู้</Typography>
        </Box>
        {canManage && (
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => navigate('/articles/new')}
          >
            สร้างบทความ
          </Button>
        )}
      </Box>

      <Paper elevation={1} sx={{ p: 3, borderRadius: 2 }}>
        {/* Search + status filters */}
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems={{ sm: 'center' }} sx={{ mb: 2 }}>
          <TextField
            label="ค้นหาเรื่อง"
            variant="outlined"
            size="small"
            value={titleSearch}
            onChange={e => setTitleSearch(e.target.value)}
            sx={{ flexGrow: 1, maxWidth: 360 }}
          />
          <Stack direction="row" spacing={1} flexWrap="wrap">
            {STATUS_FILTERS.map(f => {
              const active = filter === f.value;
              return (
                <Chip
                  key={f.value}
                  label={`${f.label} (${counts[f.value]})`}
                  onClick={() => setFilter(f.value)}
                  sx={{
                    fontWeight: active ? 700 : 400,
                    bgcolor: active ? '#FF9F6B' : 'transparent',
                    color: active ? 'white' : 'text.secondary',
                    border: '1px solid',
                    borderColor: active ? '#FF9F6B' : 'divider',
                    cursor: 'pointer',
                    '&:hover': { bgcolor: active ? '#FF9F6B' : 'action.hover' },
                  }}
                />
              );
            })}
          </Stack>
        </Stack>

        {/* DataGrid */}
        <Box sx={{ height: 600, width: '100%' }}>
          <DataGrid
            rows={filtered}
            columns={columns}
            loading={loading}
            rowHeight={64}
            pageSizeOptions={[10, 25, 50]}
            initialState={{ pagination: { paginationModel: { pageSize: 10 } } }}
            disableRowSelectionOnClick
            localeText={thGridLocale}
          />
        </Box>
      </Paper>
    </Box>
  );
}
