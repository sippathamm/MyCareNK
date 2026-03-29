import { useState, useEffect } from 'react';
import { Box, Typography, Button, Container, TextField, Paper, Link, Alert, CircularProgress, IconButton, InputAdornment } from '@mui/material';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
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

  const handleClickShowPassword = () => setShowPassword((show) => !show);
  const handleMouseDownPassword = (e: React.MouseEvent<HTMLButtonElement>) => e.preventDefault();

  // ตรวจสอบสถานะการเข้าสู่ระบบปัจจุบันเมื่อโหลดแอป
  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
    });

    // อัปเดตสถานะอัตโนมัติเมื่อมีการล็อกอินหรือออกจากระบบ
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
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
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      setErrorMsg(error.message);
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
              <Link href="#" variant="body2" color="primary" sx={{ textDecoration: 'none', '&:hover': { textDecoration: 'underline' } }}>
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
