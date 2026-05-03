import { Navigate } from 'react-router-dom';
import { Box, CircularProgress } from '@mui/material';
import type { Session } from '@supabase/supabase-js';
import type { ReactNode } from 'react';

interface ProtectedRouteProps {
  session: Session | null;
  isInitializing: boolean;
  children: ReactNode;
}

const ProtectedRoute = ({ session, isInitializing, children }: ProtectedRouteProps) => {
  if (isInitializing) {
    return (
      <Box sx={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <CircularProgress />
      </Box>
    );
  }

  if (!session) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
};

export default ProtectedRoute;
