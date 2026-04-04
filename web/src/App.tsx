import { useEffect } from 'react';
import { Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import { supabase } from './lib/supabase';
import { useAuth } from './hooks/useAuth';
import ProtectedRoute from './components/shared/ProtectedRoute';
import LoginPage from './pages/auth/LoginPage';
import ForgotPasswordPage from './pages/auth/ForgotPasswordPage';
import UpdatePasswordPage from './pages/auth/UpdatePasswordPage';
import DashboardPage from './pages/dashboard/DashboardPage';

function App() {
  const navigate = useNavigate();
  const { session, isInitializing, loading, errorMsg, login, logout, sendPasswordReset, updatePassword } = useAuth();

  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') navigate('/update-password', { replace: true });
    });
    return () => subscription.unsubscribe();
  }, [navigate]);

  return (
    <Routes>
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
      <Route
        path="/dashboard"
        element={
          <ProtectedRoute session={session} isInitializing={isInitializing}>
            <DashboardPage session={session!} loading={loading} onLogout={logout} />
          </ProtectedRoute>
        }
      />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default App;
