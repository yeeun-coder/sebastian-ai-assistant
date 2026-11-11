import { createTheme } from '@mui/material/styles';

export const theme = createTheme({
  palette: {
    primary: {
      main: '#321fdb',
      light: '#5856d6',
      dark: '#1f1498',
    },
    secondary: {
      main: '#3c4b64',
      light: '#636f83',
      dark: '#303c54',
    },
    success: {
      main: '#2eb85c',
      light: '#51cc7a',
      dark: '#1e9e4c',
    },
    info: {
      main: '#3399ff',
      light: '#66b2ff',
      dark: '#2982d9',
    },
    warning: {
      main: '#f9b115',
      light: '#fac444',
      dark: '#d69b12',
    },
    error: {
      main: '#e55353',
      light: '#eb7575',
      dark: '#c93e3e',
    },
    background: {
      default: '#ebedef',
      paper: '#fff',
    },
    text: {
      primary: '#3c4b64',
      secondary: '#768192',
    },
  },
  typography: {
    fontFamily: [
      'Pretendard',
      '-apple-system',
      'BlinkMacSystemFont',
      '"Segoe UI"',
      'Roboto',
      '"Helvetica Neue"',
      'Arial',
      'sans-serif',
    ].join(','),
    fontSize: 14,
    h5: { fontWeight: 600 },
    h6: { fontWeight: 600 },
  },
  shape: {
    borderRadius: 6,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          fontWeight: 500,
          borderRadius: 6,
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 6,
          boxShadow: '0 0.125rem 0.25rem rgba(8,10,12,0.075)',
        },
      },
      defaultProps: {
        elevation: 0,
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 6,
          border: '1px solid #d8dbe0',
          boxShadow: 'none',
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          boxShadow: '0 0.125rem 0.25rem rgba(8,10,12,0.075)',
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          borderRadius: 4,
          fontWeight: 500,
        },
      },
    },
  },
});
