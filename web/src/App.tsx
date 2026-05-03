import { useEffect } from 'react';
import { Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import { Box, CircularProgress } from '@mui/material';
import { supabase } from './lib/supabase';
import { useAuth } from './hooks/useAuth';
import ProtectedRoute from './components/shared/ProtectedRoute';
import LoginPage from './pages/auth/LoginPage';
import ForgotPasswordPage from './pages/auth/ForgotPasswordPage';
import UpdatePasswordPage from './pages/auth/UpdatePasswordPage';
import DashboardPage from './pages/dashboard/DashboardPage';
import RequestsPage from './pages/requests/RequestsPage';
import StaffManagementPage from './pages/staff/StaffManagementPage';
import StaffWorkloadPage from './pages/staff/StaffWorkloadPage';
import NotificationsPage from './pages/notifications/NotificationsPage';
import InventoryPage from './pages/inventory/InventoryPage';
import AuditLogPage from './pages/audit/AuditLogPage';
import MainLayout from './components/layout/MainLayout';
import { NotificationProvider } from './contexts/NotificationContext';

function App() {
  const navigate = useNavigate();
  const { session, isInitializing, loading, errorMsg, login, sendPasswordReset, updatePassword } = useAuth();

  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') navigate('/update-password', { replace: true });
    });
    return () => subscription.unsubscribe();
  }, [navigate]);

  return (
    <Routes>
      {/* Public Routes */}
      <Route
        path="/"
        element={
          isInitializing
            ? <Box sx={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><CircularProgress /></Box>
            : <Navigate to={session ? '/dashboard' : '/login'} replace />
        }
      />
      <Route
        path="/login"
        element={<LoginPage loading={loading} errorMsg={errorMsg} onLogin={login} />}
      />
      <Route
        path="/forgot-password"
        element={<ForgotPasswordPage loading={loading} errorMsg={errorMsg} onSubmit={sendPasswordReset} />}
      />
      <Route
        path="/update-password"
        element={<UpdatePasswordPage loading={loading} errorMsg={errorMsg} onSubmit={updatePassword} />}
      />

      {/* Protected Routes inside MainLayout */}
      <Route
        path="/*"
        element={
          <ProtectedRoute session={session} isInitializing={isInitializing}>
            <NotificationProvider>
              <MainLayout>
                <Routes>
                  <Route path="dashboard" element={<DashboardPage session={session!} />} />
                  <Route path="requests" element={<RequestsPage />} />
                  <Route path="staff" element={<StaffManagementPage />} />
                  <Route path="staff-workload" element={<StaffWorkloadPage />} />
                  <Route path="notifications" element={<NotificationsPage />} />
                  <Route path="inventory" element={<InventoryPage />} />
                  <Route path="audit-log" element={<AuditLogPage />} />
                  <Route path="*" element={<Navigate to="/dashboard" replace />} />
                </Routes>
              </MainLayout>
            </NotificationProvider>
          </ProtectedRoute>
        }
      />
    </Routes>
  );
}

export default App;
