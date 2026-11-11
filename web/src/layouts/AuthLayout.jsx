import { Box, Paper, Typography } from '@mui/material';

export default function AuthLayout({ children }) {
  return (
    <Box
      sx={{
        minHeight: '100vh',
        width: '100vw',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(135deg, #321fdb 0%, #3c4b64 100%)',
        position: 'fixed',
        top: 0,
        left: 0,
      }}
    >
      <Paper
        sx={{
          p: { xs: 3, sm: 4 },
          width: '100%',
          maxWidth: 440,
          mx: 2,
          border: '1px solid #d8dbe0',
          boxShadow: '0 0.5rem 1rem rgba(8,10,12,0.15)',
        }}
      >
        <Box sx={{ textAlign: 'center', mb: 3 }}>
          <Typography
            variant="h4"
            component="h1"
            sx={{
              fontWeight: 700,
              color: '#321fdb',
              letterSpacing: 2,
            }}
          >
            SEBASTIAN
          </Typography>
          <Typography variant="body2" sx={{ color: '#768192', mt: 0.5 }}>
            관리자 페이지
          </Typography>
        </Box>
        {children}
      </Paper>
    </Box>
  );
}
