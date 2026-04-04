import { Box, Container, Paper, Typography, type ContainerProps } from '@mui/material';
import type { ReactNode } from 'react';

interface AuthPageWrapperProps {
  children: ReactNode;
  maxWidth?: ContainerProps['maxWidth'];
}

const AuthPageWrapper = ({ children, maxWidth = 'xs' }: AuthPageWrapperProps) => (
  <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
    <Typography
      component="h1"
      variant="h4"
      sx={{ mb: 4, fontWeight: 'bold', color: 'primary.main', textAlign: 'center', whiteSpace: 'nowrap' }}
    >
      MyCareNK สำหรับเจ้าหน้าที่
    </Typography>
    <Container component="main" maxWidth={maxWidth}>
      <Paper elevation={3} sx={{ p: 4, display: 'flex', flexDirection: 'column', alignItems: 'center', width: '100%', borderRadius: 3 }}>
        {children}
      </Paper>
    </Container>
  </Box>
);

export default AuthPageWrapper;
