import { Box, Container, Paper, Typography, type ContainerProps } from '@mui/material';
import type { ReactNode } from 'react';

interface AuthPageWrapperProps {
  children: ReactNode;
  maxWidth?: ContainerProps['maxWidth'];
}

const AuthPageWrapper = ({ children, maxWidth = 'xs' }: AuthPageWrapperProps) => (
  <Box sx={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', px: 2, py: 4, boxSizing: 'border-box' }}>
    <Typography
      component="h1"
      variant="h4"
      sx={{ mb: 1, fontWeight: 900, textAlign: 'center', whiteSpace: 'nowrap', letterSpacing: 1, fontSize: { xs: '1.75rem', sm: '2.125rem' } }}
    >
      <Box component="span" sx={{ color: 'primary.main' }}>MyCareNK</Box>
      {' '}
      <Box component="span" sx={{ color: 'text.primary' }}>Staff</Box>
    </Typography>
    <Typography
      variant="body2"
      sx={{ mb: 4, color: 'text.secondary', textAlign: 'center' }}
    >
      ระบบจัดการคำขอถุงยางอนามัย/เจลหล่อลื่นและนัดรับคำปรึกษา (PEP · PrEP · ตรวจเลือด)
    </Typography>
    <Container component="main" maxWidth={maxWidth}>
      <Paper elevation={3} sx={{ p: { xs: 3, sm: 4 }, display: 'flex', flexDirection: 'column', alignItems: 'center', width: '100%', borderRadius: 3 }}>
        {children}
      </Paper>
    </Container>
  </Box>
);

export default AuthPageWrapper;
