import { useState, useCallback, useEffect, useRef, useMemo } from 'react';
import {
  Box, Typography, Grid, Card, CardContent, LinearProgress,
  Alert, AlertTitle, Chip, Skeleton, Divider, Button, Paper,
  IconButton, Tooltip, Select, MenuItem, FormControl, InputLabel,
  Stack, Pagination, TextField,
} from '@mui/material';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import StorefrontIcon from '@mui/icons-material/Storefront';
import InventoryIcon from '@mui/icons-material/Inventory2';
import TuneIcon from '@mui/icons-material/Tune';
import AddBusinessIcon from '@mui/icons-material/AddBusiness';
import GridViewIcon from '@mui/icons-material/GridView';
import TableRowsIcon from '@mui/icons-material/TableRows';
import { DataGrid } from '@mui/x-data-grid';
import type { GridColDef } from '@mui/x-data-grid';
import { alpha } from '@mui/material/styles';
import { useInventoryForecast, type InventoryForecastRow } from '../../hooks/useInventoryForecast';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useColorMode } from '../../contexts/ThemeContext';
import RestockModal from './RestockModal';
import AdjustmentModal from './AdjustmentModal';
import ConsumptionTrendChart from './ConsumptionTrendChart';
import { createThGridLocale } from '../../constants/datagrid';

const LOW_STOCK_DAYS = 7;
const MAX_DISPLAY_QTY = 100;
const PAGE_SIZE_GRID = 8;

const thGridLocale = createThGridLocale('ไม่พบสถานบริการที่ตรงกับเงื่อนไข');

type StatusFilter = 'all' | 'sufficient' | 'restock';
type ViewMode = 'grid' | 'table';

// ─── Shared helpers ────────────────────────────────────────────────────────────

function rowIsZeroStock(r: InventoryForecastRow): boolean {
  return r.condom_qty <= 0 || r.lubricant_qty <= 0;
}

function rowIsLowStock(r: InventoryForecastRow): boolean {
  if (rowIsZeroStock(r)) return false;
  return (
    (r.condom_days_left !== null && r.condom_days_left < LOW_STOCK_DAYS) ||
    (r.lubricant_days_left !== null && r.lubricant_days_left < LOW_STOCK_DAYS)
  );
}

function daysLeftColor(days: number | null): 'error' | 'warning' | 'success' {
  if (days === null) return 'success';
  if (days < LOW_STOCK_DAYS) return 'error';
  if (days < 14) return 'warning';
  return 'success';
}

function daysLeftLabel(days: number | null): string {
  if (days === null) return 'ไม่มีข้อมูลการใช้';
  if (days <= 0) return 'หมดแล้ว';
  return `เหลือประมาณ ${days} วัน`;
}

function daysLeftTextColor(days: number | null, mode: 'light' | 'dark'): string {
  const c = daysLeftColor(days);
  if (c === 'success') return mode === 'dark' ? '#81C784' : '#2E7D32';
  return `${c}.main`;
}

// ─── Inventory Card ────────────────────────────────────────────────────────────

interface InventoryCardProps {
  row: InventoryForecastRow;
  canRestock: boolean;
  onRestock: (row: InventoryForecastRow) => void;
  onAdjust: (row: InventoryForecastRow) => void;
}

function InventoryCard({ row, canRestock, onRestock, onAdjust }: InventoryCardProps) {
  const { mode } = useColorMode();
  const condomPct = Math.min((row.condom_qty / MAX_DISPLAY_QTY) * 100, 100);
  const lubPct = Math.min((row.lubricant_qty / MAX_DISPLAY_QTY) * 100, 100);
  const condomColor = daysLeftColor(row.condom_days_left);
  const lubColor = daysLeftColor(row.lubricant_days_left);
  const isZeroStock = rowIsZeroStock(row);
  const isLowStock = rowIsLowStock(row);

  const borderColor = isZeroStock ? '#FF9F6B' : isLowStock ? '#EF7070' : 'transparent';

  return (
    <Card
      elevation={1}
      sx={{
        borderRadius: 2,
        border: `1.5px solid ${borderColor}`,
        transition: 'border-color 0.2s',
      }}
    >
      <CardContent sx={{ p: 2.5 }}>
        {/* Header */}
        <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', mb: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, minWidth: 0, flex: 1, mr: 1 }}>
            <StorefrontIcon sx={{ color: 'info.main', fontSize: 20, flexShrink: 0 }} />
            <Typography variant="h6" fontWeight="bold" noWrap>
              {row.service_center}
            </Typography>
          </Box>
          {isZeroStock && (
            <Chip
              label="ยังไม่ได้เติมสต็อก"
              size="small"
              icon={<WarningAmberIcon />}
              sx={mode === 'dark'
                ? { bgcolor: alpha('#FF9F6B', 0.15), color: '#FFBE9E', fontWeight: 600, fontSize: '0.7rem' }
                : { bgcolor: '#FFF7E6', color: '#FF9F6B', fontWeight: 600, fontSize: '0.7rem' }}
            />
          )}
          {!isZeroStock && isLowStock && (
            <Chip
              label="สต็อกต่ำ"
              size="small"
              icon={<WarningAmberIcon />}
              sx={mode === 'dark'
                ? { bgcolor: alpha('#EF7070', 0.15), color: '#FC9E9E', fontWeight: 600, fontSize: '0.7rem' }
                : { bgcolor: '#FFF0F0', color: '#EF7070', fontWeight: 600, fontSize: '0.7rem' }}
            />
          )}
        </Box>

        <Divider sx={{ mb: 2 }} />

        {/* Condom */}
        <Box sx={{ mb: 2 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
            <Typography variant="body2" color="text.secondary">ถุงยางอนามัย</Typography>
            <Typography variant="body2" fontWeight={600}>{row.condom_qty.toLocaleString()} ชิ้น</Typography>
          </Box>
          <LinearProgress
            variant="determinate"
            value={condomPct}
            color={condomColor}
            sx={{ height: 8, borderRadius: 4, mb: 0.5, bgcolor: 'action.hover' }}
          />
          <Typography
            variant="caption"
            color={row.condom_days_left === null ? 'text.secondary' : daysLeftTextColor(row.condom_days_left, mode)}
          >
            {daysLeftLabel(row.condom_days_left)}
            {row.condom_daily_burn > 0 && ` (เฉลี่ย ${row.condom_daily_burn.toFixed(1)} ชิ้น/วัน)`}
          </Typography>
        </Box>

        {/* Lubricant */}
        <Box sx={{ mb: 2.5 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
            <Typography variant="body2" color="text.secondary">เจลหล่อลื่น</Typography>
            <Typography variant="body2" fontWeight={600}>{row.lubricant_qty.toLocaleString()} ชิ้น</Typography>
          </Box>
          <LinearProgress
            variant="determinate"
            value={lubPct}
            color={lubColor}
            sx={{ height: 8, borderRadius: 4, mb: 0.5, bgcolor: 'action.hover' }}
          />
          <Typography
            variant="caption"
            color={row.lubricant_days_left === null ? 'text.secondary' : daysLeftTextColor(row.lubricant_days_left, mode)}
          >
            {daysLeftLabel(row.lubricant_days_left)}
            {row.lubricant_daily_burn > 0 && ` (เฉลี่ย ${row.lubricant_daily_burn.toFixed(1)} ชิ้น/วัน)`}
          </Typography>
        </Box>

        {/* Action buttons */}
        {canRestock && (
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Button
              variant="contained"
              color="primary"
              startIcon={<InventoryIcon />}
              onClick={() => onRestock(row)}
              fullWidth
            >
              เติมสต็อก
            </Button>
            <Button
              variant="outlined"
              color="primary"
              startIcon={<TuneIcon />}
              onClick={() => onAdjust(row)}
              fullWidth
            >
              ปรับสต็อก
            </Button>
          </Box>
        )}
      </CardContent>
    </Card>
  );
}

// ─── Page ──────────────────────────────────────────────────────────────────────

export default function InventoryPage() {
  const { forecast, trend, loading, error, refetch } = useInventoryForecast();
  const { role, loading: roleLoading, isSuperadmin, serviceCenters } = useRoleAccess();
  const { mode } = useColorMode();
  const [restockTarget, setRestockTarget] = useState<InventoryForecastRow | null>(null);
  const [adjustmentTarget, setAdjustmentTarget] = useState<InventoryForecastRow | null>(null);

  // Admin/superadmin filter + view state
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [page, setPage] = useState(1);
  const [viewMode, setViewMode] = useState<ViewMode>('grid');
  const isFirstPageRender = useRef(true);

  const handleRestockSuccess = useCallback(() => {
    setRestockTarget(null);
    refetch();
  }, [refetch]);

  const handleAdjustmentSuccess = useCallback(() => {
    setAdjustmentTarget(null);
    refetch();
  }, [refetch]);

  const isAdminOrSuperadmin = role === 'admin' || role === 'superadmin';
  const canRestock = isAdminOrSuperadmin;

  // staff/admin: filter to own SCs; superadmin: sees all
  const visibleForecast = isSuperadmin
    ? forecast
    : serviceCenters.length > 0
      ? forecast.filter((r) => serviceCenters.includes(r.service_center))
      : forecast;

  const visibleTrend = isSuperadmin
    ? trend
    : serviceCenters.length > 0
      ? trend.filter((t) => serviceCenters.includes(t.service_center))
      : trend;

  // Banners use visibleForecast (unchanged)
  const zeroStockItems = visibleForecast.filter(rowIsZeroStock);
  const lowStockItems = visibleForecast.filter(rowIsLowStock);

  // Admin/superadmin filtered list
  const filteredForecast = visibleForecast
    .filter((r) => r.service_center.toLowerCase().includes(search.toLowerCase()))
    .filter((r) => {
      if (statusFilter === 'sufficient') return !rowIsZeroStock(r) && !rowIsLowStock(r);
      if (statusFilter === 'restock') return rowIsZeroStock(r) || rowIsLowStock(r);
      return true;
    });

  const totalPages = Math.ceil(filteredForecast.length / PAGE_SIZE_GRID);
  const paginatedForecast = filteredForecast.slice((page - 1) * PAGE_SIZE_GRID, page * PAGE_SIZE_GRID);

  // Clamp page when filter shrinks result set
  useEffect(() => {
    if (!loading && page > 1 && page > Math.max(1, totalPages)) {
      setPage(Math.max(1, totalPages));
    }
  }, [loading, page, totalPages]);

  // Smooth scroll to top on page change (not on first render)
  useEffect(() => {
    if (isFirstPageRender.current) { isFirstPageRender.current = false; return; }
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }, [page]);

  const columns = useMemo<GridColDef<InventoryForecastRow>[]>(() => {
    const cols: GridColDef<InventoryForecastRow>[] = [
      {
        field: 'service_center',
        headerName: 'สถานบริการ',
        flex: 1.5,
      },
      {
        field: '_status',
        headerName: 'สถานะ',
        flex: 1,
        sortable: false,
        renderCell: ({ row }) => {
          if (rowIsZeroStock(row)) {
            return (
              <Chip
                label="ยังไม่ได้เติมสต็อก"
                size="small"
                sx={mode === 'dark'
                  ? { bgcolor: alpha('#FF9F6B', 0.15), color: '#FFBE9E', fontWeight: 600, fontSize: '0.7rem' }
                  : { bgcolor: '#FFF7E6', color: '#FF9F6B', fontWeight: 600, fontSize: '0.7rem' }}
              />
            );
          }
          if (rowIsLowStock(row)) {
            return (
              <Chip
                label="สต็อกต่ำ"
                size="small"
                sx={mode === 'dark'
                  ? { bgcolor: alpha('#EF7070', 0.15), color: '#FC9E9E', fontWeight: 600, fontSize: '0.7rem' }
                  : { bgcolor: '#FFF0F0', color: '#EF7070', fontWeight: 600, fontSize: '0.7rem' }}
              />
            );
          }
          return (
            <Chip
              label="เพียงพอ"
              size="small"
              sx={mode === 'dark'
                ? { bgcolor: alpha('#66BB6A', 0.15), color: '#81C784', fontWeight: 600, fontSize: '0.7rem' }
                : { bgcolor: '#E8F5E9', color: '#2E7D32', fontWeight: 600, fontSize: '0.7rem' }}
            />
          );
        },
      },
      {
        field: 'condom_qty',
        headerName: 'ถุงยางอนามัย',
        flex: 1,
        renderCell: ({ row }) => (
          <Box sx={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 0.2 }}>
            <Typography variant="body2">{row.condom_qty.toLocaleString()} ชิ้น</Typography>
            <Typography
              variant="caption"
              color={row.condom_days_left === null ? 'text.secondary' : daysLeftTextColor(row.condom_days_left, mode)}
            >
              {daysLeftLabel(row.condom_days_left)}
            </Typography>
          </Box>
        ),
      },
      {
        field: 'lubricant_qty',
        headerName: 'เจลหล่อลื่น',
        flex: 1,
        renderCell: ({ row }) => (
          <Box sx={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 0.2 }}>
            <Typography variant="body2">{row.lubricant_qty.toLocaleString()} ชิ้น</Typography>
            <Typography
              variant="caption"
              color={row.lubricant_days_left === null ? 'text.secondary' : daysLeftTextColor(row.lubricant_days_left, mode)}
            >
              {daysLeftLabel(row.lubricant_days_left)}
            </Typography>
          </Box>
        ),
      },
    ];

    if (canRestock) {
      cols.push({
        field: '_actions',
        headerName: '',
        width: 96,
        sortable: false,
        renderCell: ({ row }) => (
          <Box sx={{ display: 'flex', gap: 0.5 }}>
            <Tooltip title="เติมสต็อก">
              <IconButton size="small" color="primary" onClick={() => setRestockTarget(row)}>
                <InventoryIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            <Tooltip title="ปรับสต็อก">
              <IconButton size="small" color="primary" onClick={() => setAdjustmentTarget(row)}>
                <TuneIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </Box>
        ),
      });
    }

    return cols;
  }, [canRestock, mode]);

  if (roleLoading) return null;

  const handleSearchChange = (value: string) => { setSearch(value); setPage(1); };
  const handleStatusFilterChange = (value: StatusFilter) => { setStatusFilter(value); setPage(1); };

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={isAdminOrSuperadmin ? 3 : 4}>
        <Box>
          <Typography variant="h5" fontWeight="bold" gutterBottom>สต็อกและพยากรณ์</Typography>
          <Typography variant="body1" color="text.secondary">
            สต็อกปัจจุบันและการพยากรณ์จากอัตราการใช้
          </Typography>
        </Box>
        {isAdminOrSuperadmin && (
          <Box sx={{ display: 'flex', gap: 0.5 }}>
            <Tooltip title="มุมมองการ์ด">
              <IconButton
                onClick={() => setViewMode('grid')}
                color={viewMode === 'grid' ? 'primary' : 'default'}
              >
                <GridViewIcon />
              </IconButton>
            </Tooltip>
            <Tooltip title="มุมมองรายการ">
              <IconButton
                onClick={() => setViewMode('table')}
                color={viewMode === 'table' ? 'primary' : 'default'}
              >
                <TableRowsIcon />
              </IconButton>
            </Tooltip>
          </Box>
        )}
      </Box>

      {/* Filter card — admin/superadmin only, hidden when no service centers */}
      {isAdminOrSuperadmin && (loading || visibleForecast.length > 0) && (
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
            <FormControl size="small" sx={{ minWidth: 160 }}>
              <InputLabel>สถานะ</InputLabel>
              <Select
                label="สถานะ"
                value={statusFilter}
                onChange={(e) => handleStatusFilterChange(e.target.value as StatusFilter)}
              >
                <MenuItem value="all">ทั้งหมด</MenuItem>
                <MenuItem value="sufficient">เพียงพอ</MenuItem>
                <MenuItem value="restock">ต้องเติม</MenuItem>
              </Select>
            </FormControl>
          </Stack>
        </Paper>
      )}

      {/* Zero-stock warning banner */}
      {!loading && zeroStockItems.length > 0 && (
        <Alert
          severity="warning"
          icon={<WarningAmberIcon />}
          sx={{ mb: 3, borderRadius: 2 }}
        >
          <AlertTitle sx={{ fontWeight: 700 }}>
            สถานบริการยังไม่ได้เติมสต็อกเริ่มต้น ({zeroStockItems.length} สถานบริการ)
          </AlertTitle>
          {zeroStockItems.map((r) => {
            const parts: string[] = [];
            if (r.condom_qty <= 0) parts.push('ถุงยางอนามัย');
            if (r.lubricant_qty <= 0) parts.push('เจลหล่อลื่น');
            return (
              <Typography key={r.service_center} variant="body2">
                <strong>{r.service_center}</strong>: {parts.join(', ')} มีสต็อกเป็นศูนย์ — คำขอที่เสร็จสิ้นจะถูกระงับจนกว่าจะเติมสต็อก
              </Typography>
            );
          })}
        </Alert>
      )}

      {/* Low-stock warning banner */}
      {!loading && lowStockItems.length > 0 && (
        <Alert
          severity="error"
          icon={<WarningAmberIcon />}
          sx={{ mb: 3, borderRadius: 2 }}
        >
          <AlertTitle sx={{ fontWeight: 700 }}>
            ถุงยางอนามัย/เจลหล่อลื่นใกล้หมด ({lowStockItems.length} สถานบริการ)
          </AlertTitle>
          {lowStockItems.map((r) => {
            const parts: string[] = [];
            if (r.condom_days_left !== null && r.condom_days_left < LOW_STOCK_DAYS)
              parts.push(`ถุงยางอนามัย ${r.condom_days_left} วัน`);
            if (r.lubricant_days_left !== null && r.lubricant_days_left < LOW_STOCK_DAYS)
              parts.push(`เจลหล่อลื่น ${r.lubricant_days_left} วัน`);
            return (
              <Typography key={r.service_center} variant="body2">
                <strong>{r.service_center}</strong>: {parts.join(', ')}
              </Typography>
            );
          })}
        </Alert>
      )}

      {/* Error */}
      {error && (
        <Alert severity="error" sx={{ mb: 3, borderRadius: 2 }}>
          {error}
        </Alert>
      )}

      {/* Empty state — no service centers at all */}
      {!loading && !error && visibleForecast.length === 0 && (
        <Paper
          elevation={0}
          sx={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 2,
            py: 8,
            px: 4,
            borderRadius: 3,
            border: '1.5px dashed',
            borderColor: 'divider',
            textAlign: 'center',
          }}
        >
          <AddBusinessIcon sx={{ fontSize: 48, color: 'text.disabled' }} />
          <Typography variant="h5" fontWeight="bold" color="text.primary">
            ยังไม่มีสถานบริการ
          </Typography>
          <Typography variant="body2" color="text.secondary">
            ติดต่อผู้ดูแลระบบเพื่อเพิ่มสถานบริการ
          </Typography>
        </Paper>
      )}

      {role === 'staff' ? (
        /* ── Staff layout: card + trend chart side by side ── */
        <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 2, mb: 4 }}>
          <Box sx={{ flexShrink: 0, width: { xs: '100%', md: 280 } }}>
            {loading ? (
              <Skeleton variant="rounded" height={220} />
            ) : (
              visibleForecast.map((row) => (
                <InventoryCard
                  key={row.service_center}
                  row={row}
                  canRestock={false}
                  onRestock={setRestockTarget}
                  onAdjust={setAdjustmentTarget}
                />
              ))
            )}
          </Box>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <ConsumptionTrendChart trend={visibleTrend} loading={loading} />
          </Box>
        </Box>
      ) : (
        /* ── Admin / Superadmin layout ── */
        <>
          {viewMode === 'grid' ? (
            <>
              <Grid container spacing={2} mb={2}>
                {loading
                  ? Array.from({ length: 4 }).map((_, i) => (
                      <Grid key={i} size={{ xs: 12, sm: 6, lg: 3 }}>
                        <Skeleton variant="rounded" height={220} />
                      </Grid>
                    ))
                  : paginatedForecast.map((row) => (
                      <Grid key={row.service_center} size={{ xs: 12, sm: 6, lg: 3 }}>
                        <InventoryCard
                          row={row}
                          canRestock={canRestock}
                          onRestock={setRestockTarget}
                          onAdjust={setAdjustmentTarget}
                        />
                      </Grid>
                    ))}
                {!loading && filteredForecast.length === 0 && visibleForecast.length > 0 && (
                  <Grid size={{ xs: 12 }}>
                    <Typography color="text.secondary" textAlign="center" sx={{ py: 6 }}>
                      ไม่พบสถานบริการที่ตรงกับเงื่อนไข
                    </Typography>
                  </Grid>
                )}
              </Grid>

              {!loading && totalPages > 1 && (
                <Box sx={{ display: 'flex', justifyContent: 'center', mb: 4 }}>
                  <Pagination
                    count={totalPages}
                    page={page}
                    onChange={(_, v) => setPage(v)}
                    color="primary"
                    shape="rounded"
                  />
                </Box>
              )}
            </>
          ) : (
            <Paper elevation={1} sx={{ borderRadius: 2, mb: 4, overflow: 'hidden' }}>
              <Box sx={{ height: 500, width: '100%' }}>
                <DataGrid
                  rows={filteredForecast}
                  columns={columns}
                  getRowId={(row) => row.service_center}
                  rowHeight={64}
                  loading={loading}
                  localeText={thGridLocale}
                  initialState={{
                    pagination: {
                      paginationModel: { pageSize: 10, page: 0 },
                    },
                  }}
                  pageSizeOptions={[10, 25, 50]}
                  disableRowSelectionOnClick
                  sx={{
                    border: 'none',
                    '& .MuiDataGrid-columnHeaders': { bgcolor: 'action.hover' },
                    '& .MuiDataGrid-cell': { display: 'flex', alignItems: 'center' },
                  }}
                />
              </Box>
            </Paper>
          )}

          <ConsumptionTrendChart trend={visibleTrend} loading={loading} />
        </>
      )}

      {/* Restock modal */}
      <RestockModal
        open={restockTarget !== null}
        target={restockTarget}
        onClose={() => setRestockTarget(null)}
        onSuccess={handleRestockSuccess}
      />

      {/* Adjustment modal */}
      <AdjustmentModal
        open={adjustmentTarget !== null}
        target={adjustmentTarget}
        onClose={() => setAdjustmentTarget(null)}
        onSuccess={handleAdjustmentSuccess}
      />
    </Box>
  );
}
