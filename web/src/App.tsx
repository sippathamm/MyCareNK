import { useState, useEffect } from 'react';
import { Box, Typography, Button, Container, TextField, Paper, Link, Alert, CircularProgress, IconButton, InputAdornment } from '@mui/material';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import LockResetIcon from '@mui/icons-material/LockReset';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import Visibility from '@mui/icons-material/Visibility';
import VisibilityOff from '@mui/icons-material/VisibilityOff';
import Avatar from '@mui/material/Avatar';
import { supabase } from './lib/supabase';
import type { Session } from '@supabase/supabase-js';
import packageInfo from '../package.json';

function App() {
  const [session, setSession] = useState<Session | null>(null);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [view, setView] = useState<'login' | 'forgot_password'>('login');
  const [resetSuccess, setResetSuccess] = useState(false);

  const handleClickShowPassword = () => setShowPassword((show) => !show);
  const handleMouseDownPassword = (e: React.MouseEvent<HTMLButtonElement>) => e.preventDefault();

  // ฟังก์ชันตรวจสอบสิทธิ์เจ้าหน้าที่
  const verifyStaffRole = async (userId: string) => {
    try {
      const { data, error } = await supabase
        .from('staff_roles')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();

      if (error) {
        console.error('Error verifying staff role:', error.message);
        return false;
      }

      return !!data;
    } catch (err) {
      console.error('Unexpected error verifying staff role:', err);
      return false;
    }
  };

  // ตรวจสอบสถานะการเข้าสู่ระบบปัจจุบันเมื่อโหลดแอป
  useEffect(() => {
    const checkSession = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (session) {
        const isStaff = await verifyStaffRole(session.user.id);
        if (isStaff) {
          setSession(session);
        } else {
          await supabase.auth.signOut();
          setSession(null);
        }
      }
    };

    checkSession();

    // อัปเดตสถานะอัตโนมัติเมื่อมีการล็อกอินหรือออกจากระบบ
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (_event, session) => {
      if (session) {
        const isStaff = await verifyStaffRole(session.user.id);
        if (isStaff) {
          setSession(session);
        } else {
          await supabase.auth.signOut();
          setSession(null);
        }
      } else {
        setSession(null);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) return;

    // ตรวจสอบรูปแบบของอีเมลอย่างเข้มงวด
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      setErrorMsg('รูปแบบอีเมลไม่ถูกต้อง กรุณาตรวจสอบและลองใหม่อีกครั้ง');
      return;
    }

    setLoading(true);
    setErrorMsg('');
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      setErrorMsg(error.message);
      setLoading(false);
      return;
    }

    if (data.user) {
      const isStaff = await verifyStaffRole(data.user.id);
      if (!isStaff) {
        await supabase.auth.signOut();
        setErrorMsg('บัญชีนี้ไม่มีสิทธิ์เข้าใช้งานในส่วนของเจ้าหน้าที่');
      }
    }

    setLoading(false);
  };

  const handleLogout = async () => {
    setLoading(true);
    await supabase.auth.signOut();
    setLoading(false);
    setEmail('');
    setPassword('');
  };

  if (session) {
    return (
      <Container maxWidth="sm">
        <Box sx={{ mt: 10, display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
          <Typography variant="h4" component="h1" gutterBottom fontWeight="bold" color="primary">
            ยินดีต้อนรับ, {session.user.email?.split('@')[0] || 'ผู้ใช้งาน'}!
          </Typography>
          <Typography variant="body1" color="text.secondary" paragraph sx={{ mb: 4 }}>
            คุณได้เข้าสู่ระบบส่วนของเจ้าหน้าที่แล้ว
          </Typography>
          <Button variant="contained" color="primary" onClick={handleLogout} disabled={loading} sx={{ borderRadius: 2 }}>
            ออกจากระบบ
          </Button>
        </Box>
      </Container>
    );
  }

  const handleForgotPassword = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) {
      setErrorMsg('กรุณากรอกอีเมล');
      return;
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      setErrorMsg('รูปแบบอีเมลไม่ถูกต้อง');
      return;
    }

    setLoading(true);
    setErrorMsg('');
    // จำลองการโหลด
    setTimeout(() => {
      setLoading(false);
      setResetSuccess(true);
    }, 1000);
  };

  if (view === 'forgot_password') {
    return (
      <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        <Typography component="h1" variant="h4" sx={{ mb: 4, fontWeight: 'bold', color: 'primary.main', textAlign: 'center', whiteSpace: 'nowrap' }}>
          MyCareNK สำหรับเจ้าหน้าที่
        </Typography>
        <Container component="main" maxWidth="xs">
          <Paper elevation={3} sx={{ p: 4, display: 'flex', flexDirection: 'column', alignItems: 'center', width: '100%', borderRadius: 3 }}>
            <Box sx={{ width: '100%', display: 'flex', justifyContent: 'flex-start', mb: 1 }}>
              <IconButton
                onClick={() => {
                  setView('login');
                  setErrorMsg('');
                  setResetSuccess(false);
                }}
                disabled={loading}
                sx={{ ml: -2 }}
              >
                <ArrowBackIcon />
              </IconButton>
            </Box>

            <Avatar sx={{ m: 1, mb: 3, bgcolor: 'info.main', width: 56, height: 56 }}>
              <LockResetIcon fontSize="large" />
            </Avatar>
            <Typography component="h2" variant="h5" sx={{ mb: 3, fontWeight: 'bold', textAlign: 'center' }}>
              เปลี่ยนรหัสผ่าน
            </Typography>

            {errorMsg && (
              <Alert severity="error" sx={{ width: '100%', mb: 2 }}>
                {errorMsg}
              </Alert>
            )}

            {resetSuccess ? (
              <Box sx={{ width: '100%', textAlign: 'left' }}>
                <Alert severity="success" sx={{ mb: 3 }}>
                  เราได้ส่งลิงก์สำหรับเปลี่ยนรหัสผ่านไปยังอีเมลของคุณแล้ว
                </Alert>
                <Button
                  fullWidth
                  variant="outlined"
                  onClick={() => {
                    setView('login');
                    setResetSuccess(false);
                  }}
                  sx={{ py: 1.5, borderRadius: 2, fontWeight: 'bold' }}
                >
                  กลับไปหน้าเข้าสู่ระบบ
                </Button>
              </Box>
            ) : (
              <Box component="form" onSubmit={handleForgotPassword} sx={{ width: '100%' }}>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2, textAlign: 'center' }}>
                  กรุณากรอกอีเมลที่ใช้ลงทะเบียน เพื่อรับลิงก์สร้างรหัสผ่านใหม่
                </Typography>
                <TextField
                  margin="normal"
                  required
                  fullWidth
                  id="reset-email"
                  label="อีเมล"
                  name="email"
                  autoComplete="email"
                  autoFocus
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={loading}
                />

                <Button
                  type="submit"
                  fullWidth
                  variant="contained"
                  color="primary"
                  disabled={loading}
                  sx={{ mt: 3, mb: 2, py: 1.5, borderRadius: 2, fontWeight: 'bold' }}
                >
                  {loading ? <CircularProgress size={24} color="inherit" /> : 'ส่งลิงก์เปลี่ยนรหัสผ่าน'}
                </Button>
              </Box>
            )}
          </Paper>
        </Container>
      </Box>
    );
  }

  return (
    <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
      <Typography component="h1" variant="h4" sx={{ mb: 4, fontWeight: 'bold', color: 'primary.main', textAlign: 'center', whiteSpace: 'nowrap' }}>
        MyCareNK สำหรับเจ้าหน้าที่
      </Typography>
      <Container component="main" maxWidth="xs">
        <Paper elevation={3} sx={{ p: 4, display: 'flex', flexDirection: 'column', alignItems: 'center', width: '100%', borderRadius: 3 }}>
          <Avatar sx={{ m: 1, mb: 3, bgcolor: 'primary.main', width: 56, height: 56 }}>
            <LockOutlinedIcon fontSize="large" />
          </Avatar>
          <Typography component="h2" variant="h5" sx={{ mb: 3, fontWeight: 'bold' }}>
            เข้าสู่ระบบ
          </Typography>

          {errorMsg && (
            <Alert severity="error" sx={{ width: '100%', mb: 2 }}>
              {errorMsg === 'Invalid login credentials' ? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' : errorMsg}
            </Alert>
          )}

          <Box component="form" onSubmit={handleLogin} sx={{ width: '100%' }}>
            <TextField
              margin="normal"
              required
              fullWidth
              id="email"
              label="อีเมล"
              name="email"
              autoComplete="email"
              autoFocus
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={loading}
            />
            <TextField
              margin="normal"
              required
              fullWidth
              name="password"
              label="รหัสผ่าน"
              type={showPassword ? 'text' : 'password'}
              id="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={loading}
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton
                      aria-label="toggle password visibility"
                      onClick={handleClickShowPassword}
                      onMouseDown={handleMouseDownPassword}
                      edge="end"
                    >
                      {showPassword ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />
            <Button
              type="submit"
              fullWidth
              variant="contained"
              disabled={loading}
              sx={{ mt: 3, mb: 2, py: 1.5, borderRadius: 2, fontWeight: 'bold' }}
            >
              {loading ? <CircularProgress size={24} color="inherit" /> : 'เข้าสู่ระบบ'}
            </Button>
            <Box sx={{ display: 'flex', justifyContent: 'center' }}>
              <Link
                component="button"
                type="button"
                variant="body2"
                color="primary"
                onClick={() => {
                  setView('forgot_password');
                  setErrorMsg('');
                }}
                sx={{ textDecoration: 'none', '&:hover': { textDecoration: 'underline' } }}
              >
                ลืมรหัสผ่าน?
              </Link>
            </Box>
          </Box>
        </Paper>
      </Container>
      <Box sx={{ mt: 4, opacity: 0.7 }}>
        <Typography variant="caption" color="text.secondary">
          v{packageInfo.version}
        </Typography>
      </Box>
    </Box>
  );
}

export default App;
