import { useMediaQuery, useTheme } from '@mui/material';

/**
 * True below the `md` breakpoint (< 900px) — phones and small tablets.
 * Used to switch the sidebar to a temporary drawer, render DataGrids as
 * card lists / hidden columns, and open dialogs full-screen.
 */
export function useIsMobile(): boolean {
  const theme = useTheme();
  return useMediaQuery(theme.breakpoints.down('md'));
}

/**
 * True below the `sm` breakpoint (< 600px) — narrow phones.
 * Used to collapse filters/grids to a single column and shrink the AppBar.
 */
export function useIsCompact(): boolean {
  const theme = useTheme();
  return useMediaQuery(theme.breakpoints.down('sm'));
}
