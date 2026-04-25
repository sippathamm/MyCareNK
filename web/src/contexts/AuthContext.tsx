import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import { validateEmail, validatePassword } from '../utils/validation';
import { MESSAGES } from '../constants/messages';

interface AuthContextValue {
  session: Session | null;
  isInitializing: boolean;
  loading: boolean;
  errorMsg: string;
  login: (email: string, password: string) => Promise<boolean>;
  logout: () => Promise<void>;
  sendPasswordReset: (email: string) => Promise<boolean>;
  updatePassword: (newPassword: string, confirmPassword: string) => Promise<boolean>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const verifyStaffRole = async (userId: string): Promise<boolean> => {
  const { data, error } = await supabase
    .from('staff_profiles')
    .select('user_id')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) {
    console.error('Error verifying staff role:', error.message);
    return false;
  }
  return !!data;
};

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [isInitializing, setIsInitializing] = useState(true);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const clearError = () => setErrorMsg('');

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      if (session) {
        const isStaff = await verifyStaffRole(session.user.id);
        if (isStaff) setSession(session);
        else await supabase.auth.signOut();
      }
      setIsInitializing(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'SIGNED_OUT') setSession(null);
    });

    return () => subscription.unsubscribe();
  }, []);

  const login = async (email: string, password: string): Promise<boolean> => {
    const emailError = validateEmail(email);
    if (emailError) { setErrorMsg(emailError); return false; }

    setLoading(true);
    clearError();

    const { data, error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) {
      setErrorMsg(
        error.message === 'Invalid login credentials'
          ? MESSAGES.error.loginInvalid
          : error.message
      );
      setLoading(false);
      return false;
    }

    if (data.user) {
      const isStaff = await verifyStaffRole(data.user.id);
      if (!isStaff) {
        await supabase.auth.signOut();
        setErrorMsg(MESSAGES.error.notStaff);
        setLoading(false);
        return false;
      }
      setSession(data.session);
    }

    setLoading(false);
    return true;
  };

  const logout = async () => {
    setLoading(true);
    await supabase.auth.signOut();
    setLoading(false);
  };

  const sendPasswordReset = async (email: string): Promise<boolean> => {
    const emailError = validateEmail(email);
    if (emailError) { setErrorMsg(emailError); return false; }

    setLoading(true);
    clearError();

    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/update-password`,
    });

    setLoading(false);
    if (error) { setErrorMsg(error.message); return false; }
    return true;
  };

  const updatePassword = async (newPassword: string, confirmPassword: string): Promise<boolean> => {
    const passwordError = validatePassword(newPassword);
    if (passwordError) { setErrorMsg(passwordError); return false; }
    if (!confirmPassword) { setErrorMsg(MESSAGES.error.confirmPasswordEmpty); return false; }
    if (newPassword !== confirmPassword) { setErrorMsg(MESSAGES.error.passwordMismatch); return false; }

    setLoading(true);
    clearError();

    const { error } = await supabase.auth.updateUser({ password: newPassword });

    setLoading(false);
    if (error) {
      setErrorMsg(
        error.message === 'New password should be different from the old password'
          ? MESSAGES.error.passwordSameAsOld
          : error.message
      );
      return false;
    }
    return true;
  };

  return (
    <AuthContext.Provider value={{ session, isInitializing, loading, errorMsg, login, logout, sendPasswordReset, updatePassword }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>');
  return ctx;
}
