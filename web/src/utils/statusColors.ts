import { alpha } from '@mui/material/styles';

type ColorMode = 'light' | 'dark';

// ─── Request Status ───────────────────────────────────────────────────────────

const REQUEST_STATUS: Record<string, { lightBg: string; lightColor: string; darkBase: string; darkText: string }> = {
  pending:            { lightBg: '#FFF3E0', lightColor: '#E65100', darkBase: '#E65100', darkText: '#FF8A50' },
  preparing:          { lightBg: '#E3F2FD', lightColor: '#1565C0', darkBase: '#64B5F6', darkText: '#64B5F6' },
  ready:              { lightBg: '#F3E5F5', lightColor: '#7B1FA2', darkBase: '#BA68C8', darkText: '#CE93D8' },
  completed:          { lightBg: '#E8F5E9', lightColor: '#2E7D32', darkBase: '#81C784', darkText: '#81C784' },
  cancelled_by_user:  { lightBg: '#F5F5F5', lightColor: '#616161', darkBase: '#9E9E9E', darkText: '#BDBDBD' },
  cancelled_by_staff: { lightBg: '#F5F5F5', lightColor: '#616161', darkBase: '#9E9E9E', darkText: '#BDBDBD' },
};

export function getRequestStatusSx(status: string, mode: ColorMode): object {
  const cfg = REQUEST_STATUS[status];
  if (!cfg) return { fontWeight: 600 };
  if (mode === 'light') return { bgcolor: cfg.lightBg, color: cfg.lightColor, fontWeight: 600 };
  return { bgcolor: alpha(cfg.darkBase, 0.2), color: cfg.darkText, fontWeight: 600 };
}

// ─── Consultation Status ──────────────────────────────────────────────────────

const CONSULTATION_STATUS: Record<string, { lightBg: string; lightColor: string; darkBase: string; darkText: string }> = {
  pending:            { lightBg: '#FFF3E0', lightColor: '#E65100', darkBase: '#E65100', darkText: '#FF8A50' },
  confirmed:          { lightBg: '#F3E5F5', lightColor: '#7B1FA2', darkBase: '#BA68C8', darkText: '#CE93D8' },
  completed:          { lightBg: '#E8F5E9', lightColor: '#2E7D32', darkBase: '#81C784', darkText: '#81C784' },
  cancelled_by_user:  { lightBg: '#F5F5F5', lightColor: '#616161', darkBase: '#9E9E9E', darkText: '#BDBDBD' },
  cancelled_by_staff: { lightBg: '#F5F5F5', lightColor: '#616161', darkBase: '#9E9E9E', darkText: '#BDBDBD' },
};

export function getConsultationStatusSx(status: string, mode: ColorMode): object {
  const cfg = CONSULTATION_STATUS[status];
  if (!cfg) return { fontWeight: 600 };
  if (mode === 'light') return { bgcolor: cfg.lightBg, color: cfg.lightColor, fontWeight: 600 };
  return { bgcolor: alpha(cfg.darkBase, 0.2), color: cfg.darkText, fontWeight: 600 };
}

// ─── Workload Count Chip ──────────────────────────────────────────────────────

type WorkloadType = 'completed' | 'cancelled' | 'overdue';

const WORKLOAD_CONFIG: Record<WorkloadType, { lightBg: string; lightColor: string; darkBase: string; darkText: string }> = {
  completed: { lightBg: '#EBF7EC', lightColor: '#2E7D32', darkBase: '#81C784', darkText: '#81C784' },
  cancelled: { lightBg: '#FFF0F0', lightColor: '#C62828', darkBase: '#EF9A9A', darkText: '#EF9A9A' },
  overdue:   { lightBg: '#FFF8E1', lightColor: '#E65100', darkBase: '#E65100', darkText: '#FF8A50' },
};

export function getWorkloadChipSx(type: WorkloadType, value: number, mode: ColorMode): object {
  const cfg = WORKLOAD_CONFIG[type];
  if (value === 0) {
    return mode === 'light'
      ? { bgcolor: '#F5F5F5', color: '#9E9E9E', fontWeight: 600 }
      : { bgcolor: alpha('#9E9E9E', 0.2), color: '#9E9E9E', fontWeight: 600 };
  }
  if (mode === 'light') return { bgcolor: cfg.lightBg, color: cfg.lightColor, fontWeight: 600 };
  return { bgcolor: alpha(cfg.darkBase, 0.2), color: cfg.darkText, fontWeight: 600 };
}

// ─── Qty Delta Chip (InventoryLogDetailDrawer) ────────────────────────────────

export function getDeltaChipSx(value: number, mode: ColorMode): object {
  const pos = value > 0;
  if (mode === 'light') {
    return { bgcolor: pos ? '#EBF7EC' : '#FFF0F0', color: pos ? '#2E7D32' : '#C62828', fontWeight: 600, fontSize: '0.78rem' };
  }
  return { bgcolor: alpha(pos ? '#81C784' : '#EF9A9A', 0.2), color: pos ? '#81C784' : '#EF9A9A', fontWeight: 600, fontSize: '0.78rem' };
}

// ─── Article Status ───────────────────────────────────────────────────────────

const ARTICLE_STATUS: Record<string, { lightBg: string; lightColor: string; darkBase: string; darkText: string }> = {
  published: { lightBg: '#E8F5E9', lightColor: '#2E7D32', darkBase: '#81C784', darkText: '#81C784' },
  draft:     { lightBg: '#F5F5F5', lightColor: '#616161', darkBase: '#9E9E9E', darkText: '#BDBDBD' },
  hidden:    { lightBg: '#ECEFF1', lightColor: '#546E7A', darkBase: '#78909C', darkText: '#90A4AE' },
};

export const ARTICLE_STATUS_LABELS: Record<string, string> = {
  published: 'เผยแพร่แล้ว',
  draft:     'ร่าง',
  hidden:    'ซ่อน',
};

export function getArticleStatusSx(status: string, mode: ColorMode): object {
  const cfg = ARTICLE_STATUS[status];
  if (!cfg) return { fontWeight: 'bold' };
  if (mode === 'light') return { bgcolor: cfg.lightBg, color: cfg.lightColor, fontWeight: 'bold' };
  return { bgcolor: alpha(cfg.darkBase, 0.2), color: cfg.darkText, fontWeight: 'bold' };
}
