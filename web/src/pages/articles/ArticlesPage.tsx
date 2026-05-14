import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box, Typography, Paper, Chip, Button, IconButton, Tooltip,
  Dialog, DialogTitle, DialogContent, DialogContentText, DialogActions,
  Stack, Snackbar, Alert,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef, GridRenderCellParams } from '@mui/x-data-grid';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
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
  const { articles, staffMap, loading, deleteArticle } = useArticles();
  const { role } = useRoleAccess();
  const canManage = role === 'admin' || role === 'superadmin';

  const [filter, setFilter] = useState<FilterValue>('all');
  const [deleteTarget, setDeleteTarget] = useState<Article | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false, message: '', severity: 'success',
  });

  // ─── Filter ───────────────────────────────────────────────────────────────

  const filtered = useMemo(() => {
    if (filter === 'all') return articles;
    return articles.filter(a => getArticleStatus(a) === filter);
  }, [articles, filter]);

  const counts = useMemo(() => ({
    all: articles.length,
    published: articles.filter(a => getArticleStatus(a) === 'published').length,
    scheduled: articles.filter(a => getArticleStatus(a) === 'scheduled').length,
    draft: articles.filter(a => getArticleStatus(a) === 'draft').length,
  }), [articles]);

  // ─── Delete ───────────────────────────────────────────────────────────────

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    const err = await deleteArticle(deleteTarget.id);
    setDeleting(false);
    setDeleteTarget(null);
    setSnackbar({
      open: true,
      message: err ? `ลบไม่สำเร็จ: ${err}` : 'ลบบทความเรียบร้อยแล้ว',
      severity: err ? 'error' : 'success',
    });
  };

  // ─── Columns ──────────────────────────────────────────────────────────────

  const columns: GridColDef[] = [
    {
      field: 'cover_image_url',
      headerName: '',
      width: 100,
      sortable: false,
      renderCell: (params: GridRenderCellParams<Article>) =>
        <CoverThumbnail url={params.row.cover_image_url} />,
    },
    {
      field: 'title',
      headerName: 'เรื่อง',
      flex: 1,
      minWidth: 220,
      renderCell: (params: GridRenderCellParams<Article>) => (
        <Box sx={{ py: 1 }}>
          <Typography variant="body2" fontWeight="bold" noWrap sx={{ maxWidth: 320 }}>
            {params.row.title}
          </Typography>
          {params.row.excerpt && (
            <Typography variant="caption" color="text.secondary" noWrap sx={{ maxWidth: 320, display: 'block' }}>
              {params.row.excerpt}
            </Typography>
          )}
        </Box>
      ),
    },
    {
      field: 'created_by',
      headerName: 'โดย',
      width: 150,
      renderCell: (params: GridRenderCellParams<Article>) => (
        <Typography variant="body2" color="text.secondary">
          {params.row.created_by ? (staffMap[params.row.created_by] || '—') : '—'}
        </Typography>
      ),
    },
    {
      field: 'status',
      headerName: 'สถานะ',
      width: 140,
      sortable: false,
      renderCell: (params: GridRenderCellParams<Article>) =>
        <StatusChip article={params.row} />,
    },
    {
      field: 'publish_at',
      headerName: 'วันเผยแพร่',
      width: 180,
      renderCell: (params: GridRenderCellParams<Article>) => (
        <Typography variant="body2" color="text.secondary">
          {params.row.publish_at ? formatDateTime(params.row.publish_at) : '—'}
        </Typography>
      ),
    },
    {
      field: 'updated_at',
      headerName: 'แก้ไขล่าสุด',
      width: 180,
      renderCell: (params: GridRenderCellParams<Article>) => (
        <Typography variant="body2" color="text.secondary">
          {formatDateTime(params.row.updated_at ?? undefined)}
        </Typography>
      ),
    },
    {
      field: 'actions',
      headerName: '',
      width: 90,
      sortable: false,
      renderCell: (params: GridRenderCellParams<Article>) => canManage ? (
        <Stack direction="row" spacing={0.5} alignItems="center">
          <Tooltip title="แก้ไข">
            <IconButton
              size="small"
              onClick={() => navigate(`/articles/${params.row.id}/edit`)}
              sx={{ color: 'text.secondary' }}
            >
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Tooltip title="ลบ">
            <IconButton
              size="small"
              onClick={() => setDeleteTarget(params.row)}
              sx={{ color: 'error.main' }}
            >
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Stack>
      ) : null,
    },
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
        {/* Filter chips */}
        <Stack direction="row" spacing={1} sx={{ px: 2, pt: 2, pb: 1.5, borderBottom: '1px solid', borderColor: 'divider' }}>
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

        {/* DataGrid */}
        <Box sx={{ height: 500, width: '100%' }}>
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

      {/* Delete dialog */}
      <Dialog open={!!deleteTarget} onClose={() => !deleting && setDeleteTarget(null)} maxWidth="xs" fullWidth>
        <DialogTitle fontWeight="bold">ยืนยันการลบบทความ</DialogTitle>
        <DialogContent>
          <DialogContentText>
            คุณต้องการลบบทความ <strong>"{deleteTarget?.title}"</strong> ใช่หรือไม่?
            การกระทำนี้ไม่สามารถย้อนกลับได้
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setDeleteTarget(null)} disabled={deleting}>ยกเลิก</Button>
          <Button variant="contained" color="error" onClick={handleDeleteConfirm} disabled={deleting}>
            {deleting ? 'กำลังลบ...' : 'ลบบทความ'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar(s => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity={snackbar.severity} onClose={() => setSnackbar(s => ({ ...s, open: false }))}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
