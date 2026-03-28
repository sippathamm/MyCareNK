import React, { useState } from 'react';
import { Box, Typography, CircularProgress, Alert, Button } from '@mui/material';
import { supabase } from '../lib/supabase';
import CloudDoneIcon from '@mui/icons-material/CloudDone';
import CloudOffIcon from '@mui/icons-material/CloudOff';

const SupabaseConnectionTest: React.FC = () => {
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [message, setMessage] = useState<string>('');

  const checkConnection = async () => {
    setStatus('loading');
    try {
      // Try to fetch a simple request to verify the connection and API Key
      // This will return an error if the key is invalid, even if the table doesn't exist
      const { error } = await supabase.from('_connection_test').select('*').limit(1);

      if (error) {
        // If the error is only "table not found", it means the connection itself worked
        const isTableNotFound = 
          error.code === 'PGRST116' || 
          error.message.includes('relation "_connection_test" does not exist') ||
          error.message.includes('Could not find the table');

        if (isTableNotFound) {
          setStatus('success');
          setMessage('Successfully connected to Supabase!');
        } else {
          setStatus('error');
          setMessage(`Supabase Error: ${error.message}`);
        }
      } else {
        setStatus('success');
        setMessage('Successfully connected to Supabase!');
      }
    } catch (err: any) {
      setStatus('error');
      setMessage(`Connection Error: ${err.message || 'Unknown error'}`);
    }
  };

  return (
    <Box sx={{ mt: 4, p: 3, border: '1px solid', borderColor: 'divider', borderRadius: 2, bgcolor: 'background.paper', width: '100%', maxWidth: 400 }}>
      <Typography variant="h6" gutterBottom align="center">
        Supabase Connection Test
      </Typography>

      {status === 'idle' && (
        <Button variant="outlined" fullWidth onClick={checkConnection}>
          Test Connection
        </Button>
      )}

      {status === 'loading' && (
        <Box sx={{ display: 'flex', justifyContent: 'center', p: 2 }}>
          <CircularProgress size={24} sx={{ mr: 1 }} />
          <Typography>Connecting...</Typography>
        </Box>
      )}

      {status === 'success' && (
        <Alert icon={<CloudDoneIcon fontSize="inherit" />} severity="success" sx={{ mt: 1 }}>
          <Typography variant="body2">{message}</Typography>
        </Alert>
      )}

      {status === 'error' && (
        <Alert icon={<CloudOffIcon fontSize="inherit" />} severity="error" sx={{ mt: 1 }}>
          <Typography variant="body2">{message}</Typography>
        </Alert>
      )}

      {(status === 'success' || status === 'error') && (
        <Button variant="text" fullWidth size="small" onClick={checkConnection} sx={{ mt: 1 }}>
          Test Again
        </Button>
      )}
    </Box>
  );
};

export default SupabaseConnectionTest;
