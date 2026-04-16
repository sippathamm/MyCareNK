import { createTheme } from '@mui/material';

const theme = createTheme({
  palette: {
    primary: {
      main: '#FF9F6B',
      contrastText: '#ffffff',
    },
    error: {
      main: '#EF7070',
      contrastText: '#ffffff',
    },
    warning: {
      main: '#FF9F6B',
      contrastText: '#ffffff',
    },
    info: {
      main: '#64B5F6',
      contrastText: '#ffffff',
    },
    secondary: {
      main: '#BA68C8',
      contrastText: '#ffffff',
    },
    success: {
      main: '#81C784',
      contrastText: '#ffffff',
    },
    background: {
      default: '#F4F6F8',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
    button: {
      textTransform: 'none',
      fontWeight: 600,
    },
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 8,
        },
        containedPrimary: {
          '&:hover': {
            backgroundColor: '#FF9F6B',
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 12,
        },
      },
    },
    MuiDialog: {
      styleOverrides: {
        paper: {
          borderRadius: 16,
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          fontWeight: 600,
        },
      },
    },
    MuiListItemButton: {
      styleOverrides: {
        root: {
          borderRadius: 8,
        },
      },
    },
  },
});

export default theme;
