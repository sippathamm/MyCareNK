import { useState, useCallback } from 'react';
import {
  Box, Typography, Grid, Card, CardContent, LinearProgress,
  Alert, AlertTitle, Chip, Skeleton, Divider, Button, Paper,
} from '@mui/material';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import StorefrontIcon from '@mui/icons-material/Storefront';
import InventoryIcon from '@mui/icons-material/Inventory2';
import TuneIcon from '@mui/icons-material/Tune';
import AddBusinessIcon from '@mui/icons-material/AddBusiness';
import { useInventoryForecast, type InventoryForecastRow } from '../../hooks/useInventoryForecast';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import RestockModal from './RestockModal';
import AdjustmentModal from './AdjustmentModal';
import ConsumptionTrendChart from './ConsumptionTrendChart';
import ServiceCenterManagementDialog from '../../components/inventory/ServiceCenterManagementDialog';

const LOW_STOCK_DAYS = 7;

// ความจุสูงสุดที่ใช้แสดง progress bar (ตั้งไว้ที่ 500 ชิ้น)
const MAX_DISPLAY_QTY = 500;

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

interface InventoryCardProps {
  row: InventoryForecastRow;
  canRestock: boolean;
  onRestock: (row: InventoryForecastRow) => void;
  onAdjust: (row: InventoryForecastRow) => void;
}

function InventoryCard({ row, canRestock, onRestock, onAdjust }: InventoryCardProps) {
  const condomPct = Math.min((row.condom_qty / MAX_DISPLAY_QTY) * 100, 100);
  const lubPct = Math.min((row.lubricant_qty / MAX_DISPLAY_QTY) * 100, 100);
  const condomColor = daysLeftColor(row.condom_days_left);
  const lubColor = daysLeftColor(row.lubricant_days_left);
  const isZeroStock = row.condom_qty <= 0 || row.lubricant_qty <= 0;
  const isLowStock =
    !isZeroStock && (
      (row.condom_days_left !== null && row.condom_days_left < LOW_STOCK_DAYS) ||
      (row.lubricant_days_left !== null && row.lubricant_days_left < LOW_STOCK_DAYS)
    );

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
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, minWidth: 0, flex: 1, mr: 1 }}>
            <StorefrontIcon sx={{ color: 'info.main', fontSize: 20, flexShrink: 0 }} />
            <Typography variant="h6" fontWeight="bold" noWrap>
              {row.service_center}
            </Typography>
            <Chip
              size="small"
              label={row.is_active ? 'ใช้งานอยู่' : 'ปิดใช้งาน'}
              sx={{
                flexShrink: 0,
                bgcolor: row.is_active ? '#E8F5E9' : '#F5F5F5',
                color: row.is_active ? '#2E7D32' : '#9E9E9E',
                fontSize: '0.65rem',
                height: 20,
              }}
            />
          </Box>
          {isZeroStock && (
            <Chip
              label="ยังไม่ได้เติมสต็อก"
              size="small"
              icon={<WarningAmberIcon />}
              sx={{ bgcolor: '#FFF7E6', color: '#FF9F6B', fontWeight: 600, fontSize: '0.7rem' }}
            />
          )}
          {!isZeroStock && isLowStock && (
            <Chip
              label="สต็อกต่ำ"
              size="small"
              icon={<WarningAmberIcon />}
              sx={{ bgcolor: '#FFF0F0', color: '#EF7070', fontWeight: 600, fontSize: '0.7rem' }}
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
            sx={{ height: 8, borderRadius: 4, mb: 0.5, bgcolor: 'grey.100' }}
          />
          <Typography
            variant="caption"
            color={row.condom_days_left === null ? 'text.secondary' : `${condomColor}.main`}
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
            sx={{ height: 8, borderRadius: 4, mb: 0.5, bgcolor: 'grey.100' }}
          />
          <Typography
            variant="caption"
            color={row.lubricant_days_left === null ? 'text.secondary' : `${lubColor}.main`}
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

export default function InventoryPage() {
  const { forecast, trend, loading, error, refetch } = useInventoryForecast();
  const { role, profile, loading: roleLoading } = useRoleAccess();
  const [restockTarget, setRestockTarget] = useState<InventoryForecastRow | null>(null);
  const [adjustmentTarget, setAdjustmentTarget] = useState<InventoryForecastRow | null>(null);
  const [manageOpen, setManageOpen] = useState(false);

  const handleRestockSuccess = useCallback(() => {
    setRestockTarget(null);
    refetch();
  }, [refetch]);

  const handleAdjustmentSuccess = useCallback(() => {
    setAdjustmentTarget(null);
    refetch();
  }, [refetch]);

  if (roleLoading) return null;

  const isAdminOrSuperadmin = role === 'admin' || role === 'superadmin';
  const canRestock = isAdminOrSuperadmin;

  // staff เห็นเฉพาะสถานบริการตัวเอง
  const visibleForecast = role === 'staff' && profile?.service_center
    ? forecast.filter((r) => r.service_center === profile.service_center)
    : forecast;

  const visibleTrend = role === 'staff' && profile?.service_center
    ? trend.filter((t) => t.service_center === profile.service_center)
    : trend;

  const zeroStockItems = visibleForecast.filter(
    (r) => r.condom_qty <= 0 || r.lubricant_qty <= 0,
  );

  const lowStockItems = visibleForecast.filter(
    (r) =>
      r.condom_qty > 0 && r.lubricant_qty > 0 &&
      (
        (r.condom_days_left !== null && r.condom_days_left < LOW_STOCK_DAYS) ||
        (r.lubricant_days_left !== null && r.lubricant_days_left < LOW_STOCK_DAYS)
      ),
  );

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
        <Box>
          <Typography variant="h5" fontWeight="bold" gutterBottom>สต็อกและพยากรณ์</Typography>
          <Typography variant="body1" color="text.secondary">
            สต็อกปัจจุบันและการพยากรณ์จากอัตราการใช้
          </Typography>
        </Box>
        {isAdminOrSuperadmin && (
          <Button
            variant="contained"
            startIcon={<StorefrontIcon />}
            onClick={() => setManageOpen(true)}
          >
            จัดการสถานบริการ
          </Button>
        )}
      </Box>

      {/* Zero-stock warning banner */}
      {!loading && zeroStockItems.length > 0 && (
        <Alert
          severity="warning"
          icon={<WarningAmberIcon />}
          sx={{ mb: 3, borderRadius: 2 }}
        >
          <AlertTitle sx={{ fontWeight: 700 }}>
            แจ้งเตือน: สถานบริการยังไม่ได้เติมสต็อกเริ่มต้น ({zeroStockItems.length} สถานบริการ)
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
            แจ้งเตือน: ถุงยางอนามัย/เจลหล่อลื่นใกล้หมด ({lowStockItems.length} สถานบริการ)
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

      {/* Empty state — no service centers */}
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
            {isAdminOrSuperadmin
              ? 'กดปุ่ม "จัดการสถานบริการ" ด้านบนเพื่อเพิ่มสถานบริการใหม่'
              : 'ติดต่อผู้ดูแลระบบเพื่อเพิ่มสถานบริการ'}
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
          <Grid container spacing={2} mb={4}>
            {loading
              ? Array.from({ length: 4 }).map((_, i) => (
                  <Grid key={i} size={{ xs: 12, sm: 6, lg: 3 }}>
                    <Skeleton variant="rounded" height={220} />
                  </Grid>
                ))
              : visibleForecast.map((row) => (
                  <Grid key={row.service_center} size={{ xs: 12, sm: 6, lg: 3 }}>
                    <InventoryCard
                      row={row}
                      canRestock={canRestock}
                      onRestock={setRestockTarget}
                      onAdjust={setAdjustmentTarget}
                    />
                  </Grid>
                ))}
          </Grid>

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

      {/* Service center management dialog */}
      <ServiceCenterManagementDialog
        open={manageOpen}
        onClose={() => setManageOpen(false)}
      />
    </Box>
  );
}
