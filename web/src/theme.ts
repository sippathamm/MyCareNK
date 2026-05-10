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
          boxShadow: '0px 2px 6px rgba(0,0,0,0.18)',
          '&:hover': {
            boxShadow: '0px 4px 12px rgba(0,0,0,0.22)',
          },
          '&:active': {
            boxShadow: '0px 1px 4px rgba(0,0,0,0.14)',
          },
        },
        containedPrimary: {
          '&:hover': {
            backgroundColor: '#FF9F6B',
          },
        },
        containedInfo: {
          '&:hover': {
            backgroundColor: '#64B5F6',
          },
        },
        containedSuccess: {
          '&:hover': {
            backgroundColor: '#81C784',
          },
        },
        containedSecondary: {
          '&:hover': {
            backgroundColor: '#BA68C8',
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
