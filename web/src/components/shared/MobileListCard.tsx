import type { ReactNode } from 'react';
import { Box, Paper, Typography } from '@mui/material';

interface MobileListCardProps {
  /** Primary line (e.g. reference number). */
  title: ReactNode;
  /** Status chip shown top-right. */
  statusChip: ReactNode;
  /** Secondary rows (date/time, item summary, etc.). */
  meta?: ReactNode;
  /** Tapping anywhere on the card opens the detail dialog. */
  onClick: () => void;
}

/**
 * Compact tappable card used to render list rows on mobile in place of a
 * DataGrid. Shared by RequestsPage and ConsultationsPage.
 */
export default function MobileListCard({ title, statusChip, meta, onClick }: MobileListCardProps) {
  return (
    <Paper
      variant="outlined"
      onClick={onClick}
      sx={{
        p: 2,
        borderRadius: 2,
        cursor: 'pointer',
        transition: 'border-color 0.15s, box-shadow 0.15s',
        '&:hover': { borderColor: 'primary.main', boxShadow: 1 },
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 1 }}>
        <Typography variant="subtitle2" fontWeight="bold" sx={{ wordBreak: 'break-word' }}>
          {title}
        </Typography>
        <Box sx={{ flexShrink: 0 }}>{statusChip}</Box>
      </Box>
      {meta && (
        <Box sx={{ mt: 1, display: 'flex', flexDirection: 'column', gap: 0.5 }}>
          {meta}
        </Box>
      )}
    </Paper>
  );
}
