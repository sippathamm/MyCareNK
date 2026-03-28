import React from 'react';
import { Box, Typography, Button, Container } from '@mui/material';
import LocalHospitalIcon from '@mui/icons-material/LocalHospital';

function App() {
  return (
    <Container maxWidth="sm">
      <Box sx={{ mt: 10, display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
        <LocalHospitalIcon color="primary" sx={{ fontSize: 60, mb: 2 }} />
        <Typography variant="h4" component="h1" gutterBottom fontWeight="bold" color="primary">
          Condom & Lubricant Delivery
        </Typography>
        <Typography variant="body1" color="text.secondary" paragraph sx={{ mb: 4 }}>
          Hello World! This is the basic empty setup for the dashboard interface.
          Material-UI and Supabase are properly initialized.
        </Typography>
        <Button variant="contained" color="primary" size="large">
          Get Started
        </Button>
      </Box>
    </Container>
  );
}

export default App;
