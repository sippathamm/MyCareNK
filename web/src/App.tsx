import { useEffect } from 'react';
import { Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import { supabase } from './lib/supabase';
import { useAuth } from './hooks/useAuth';
import ProtectedRoute from './components/shared/ProtectedRoute';
import LoginPage from './pages/auth/LoginPage';
import ForgotPasswordPage from './pages/auth/ForgotPasswordPage';
import UpdatePasswordPage from './pages/auth/UpdatePasswordPage';
import DashboardPage from './pages/dashboard/DashboardPage';
import RequestsPage from './pages/requests/RequestsPage';
import StaffManagementPage from './pages/staff/StaffManagementPage';
import MainLayout from './components/layout/MainLayout';

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
            ? null
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
            <MainLayout>
              <Routes>
                <Route path="dashboard" element={<DashboardPage session={session!} />} />
                <Route path="requests" element={<RequestsPage />} />
                <Route path="staff" element={<StaffManagementPage />} />
                <Route path="*" element={<Navigate to="/dashboard" replace />} />
              </Routes>
            </MainLayout>
          </ProtectedRoute>
        }
      />
    </Routes>
  );
}

export default App;
