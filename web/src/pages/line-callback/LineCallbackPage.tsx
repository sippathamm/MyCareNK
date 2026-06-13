import { useEffect, useRef } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Box, CircularProgress, Typography } from '@mui/material';
import { supabase } from '../../lib/supabase';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL as string;
const REDIRECT_URI = `${window.location.origin}/line-callback`;

export default function LineCallbackPage() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const called = useRef(false);

  useEffect(() => {
    if (called.current) return;
    called.current = true;

    const code = searchParams.get('code');
    const state = searchParams.get('state');
    const storedState = sessionStorage.getItem('line_oauth_state');

    if (!code) {
      navigate('/profile?error=' + encodeURIComponent('ไม่ได้รับรหัสจาก LINE'), { replace: true });
      return;
    }

    if (!state || state !== storedState) {
      navigate('/profile?error=' + encodeURIComponent('การตรวจสอบความปลอดภัยล้มเหลว'), { replace: true });
      return;
    }

    sessionStorage.removeItem('line_oauth_state');

    (async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        navigate('/login', { replace: true });
        return;
      }

      const res = await fetch(`${SUPABASE_URL}/functions/v1/line-auth`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({ code, redirect_uri: REDIRECT_URI }),
      });

      const json = await res.json();
      if (json.status === 'success') {
        navigate('/profile?linked=true', { replace: true });
      } else {
        navigate('/profile?error=' + encodeURIComponent(json.message ?? 'เกิดข้อผิดพลาด'), { replace: true });
      }
    })();
  }, [searchParams, navigate]);

  return (
    <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 2 }}>
      <CircularProgress />
      <Typography variant="body2" color="text.secondary">กำลังเชื่อมต่อ LINE...</Typography>
    </Box>
  );
}
