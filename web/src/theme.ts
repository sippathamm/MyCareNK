import { createTheme } from '@mui/material';

const theme = createTheme({
  palette: {
    primary: {
      main: '#FF8A50',
    },
    background: {
      default: '#f4f6f8',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
  },
  components: {
    MuiButtonBase: {
      styleOverrides: {
        root: {
          '& .MuiTouchRipple-root .MuiTouchRipple-child': {
            backgroundColor: 'white',
          },
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        containedPrimary: {
          '&:hover': {
            backgroundColor: '#FF8A50',
            filter: 'brightness(1.1)',
          },
        },
      },
    },
  },
});

export default theme;
