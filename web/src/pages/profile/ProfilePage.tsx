import { useState, useEffect, useCallback } from 'react';
import {
  Box, Typography, Card, CardContent, Avatar, Button, Chip,
  CircularProgress, Alert, Divider,
} from '@mui/material';
import LinkIcon from '@mui/icons-material/Link';
import LinkOffIcon from '@mui/icons-material/LinkOff';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import { useLocation } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { useRoleAccess } from '../../hooks/useRoleAccess';

const ROLE_LABELS: Record<string, string> = {
  staff: 'เจ้าหน้าที่',
  admin: 'ผู้ดูแล',
  superadmin: 'ผู้ดูแลสูงสุด',
};

const LINE_LOGIN_CHANNEL_ID = import.meta.env.VITE_LINE_LOGIN_CHANNEL_ID as string | undefined;
const REDIRECT_URI = `${window.location.origin}/line-callback`;

interface LineProfile {
  line_user_id: string | null;
  line_display_name: string | null;
  line_picture_url: string | null;
}

export default function ProfilePage() {
  const { profile, role, serviceCenters } = useRoleAccess();
  const location = useLocation();

  const [lineProfile, setLineProfile] = useState<LineProfile>({
    line_user_id: null,
    line_display_name: null,
    line_picture_url: null,
  });
  const [loadingLine, setLoadingLine] = useState(true);
  const [unlinking, setUnlinking] = useState(false);
  const [alert, setAlert] = useState<{ severity: 'success' | 'error'; message: string } | null>(null);

  const fetchLineProfile = useCallback(async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const { data } = await supabase
      .from('staff_profiles')
      .select('line_user_id, line_display_name, line_picture_url')
      .eq('staff_user_id', user.id)
      .single();
    if (data) {
      setLineProfile({
        line_user_id: data.line_user_id ?? null,
        line_display_name: data.line_display_name ?? null,
        line_picture_url: data.line_picture_url ?? null,
      });
    }
    setLoadingLine(false);
  }, []);

  useEffect(() => {
    fetchLineProfile();
  }, [fetchLineProfile]);

  // Show success/error from LINE callback redirect
  useEffect(() => {
    const params = new URLSearchParams(location.search);
    if (params.get('linked') === 'true') {
      setAlert({ severity: 'success', message: 'เชื่อมต่อ LINE สำเร็จ' });
      fetchLineProfile();
    } else if (params.get('error')) {
      setAlert({ severity: 'error', message: params.get('error') ?? 'เกิดข้อผิดพลาด' });
    }
  }, [location.search, fetchLineProfile]);

  const handleConnect = () => {
    if (!LINE_LOGIN_CHANNEL_ID) {
      setAlert({ severity: 'error', message: 'ยังไม่ได้ตั้งค่า LINE Login Channel ID' });
      return;
    }
    const bytes = new Uint8Array(16);
    crypto.getRandomValues(bytes);
    const state = Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
    sessionStorage.setItem('line_oauth_state', state);
    const params = new URLSearchParams({
      response_type: 'code',
      client_id: LINE_LOGIN_CHANNEL_ID,
      redirect_uri: REDIRECT_URI,
      state,
      scope: 'profile',
    });
    window.location.href = `https://access.line.me/oauth2/v2.1/authorize?${params}`;
  };

  const handleUnlink = async () => {
    setUnlinking(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setUnlinking(false); return; }
    const { error } = await supabase
      .from('staff_profiles')
      .update({ line_user_id: null, line_display_name: null, line_picture_url: null })
      .eq('staff_user_id', user.id);
    if (error) {
      setAlert({ severity: 'error', message: 'ยกเลิกการเชื่อมต่อไม่สำเร็จ' });
    } else {
      setLineProfile({ line_user_id: null, line_display_name: null, line_picture_url: null });
      setAlert({ severity: 'success', message: 'ยกเลิกการเชื่อมต่อ LINE แล้ว' });
    }
    setUnlinking(false);
  };

  const isLinked = !!lineProfile.line_user_id;

  return (
    <Box sx={{ maxWidth: 600, mx: 'auto' }}>
      <Typography variant="h5" fontWeight="bold" mb={3}>โปรไฟล์</Typography>

      {alert && (
        <Alert
          severity={alert.severity}
          onClose={() => setAlert(null)}
          sx={{ mb: 2 }}
        >
          {alert.message}
        </Alert>
      )}

      {/* Staff info */}
      <Card variant="outlined" sx={{ mb: 3 }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
            <Avatar sx={{ bgcolor: 'primary.main', width: 56, height: 56, fontSize: '1.5rem' }}>
              {profile?.first_name?.[0]?.toUpperCase() ?? 'U'}
            </Avatar>
            <Box>
              <Typography variant="h6" fontWeight="bold">
                {profile?.first_name} {profile?.last_name}
              </Typography>
              <Chip
                label={role ? (ROLE_LABELS[role] ?? role) : ''}
                size="small"
                sx={{ bgcolor: 'rgba(255,159,107,0.12)', color: 'primary.main' }}
              />
            </Box>
          </Box>
          {serviceCenters.length > 0 && (
            <>
              <Divider sx={{ my: 1.5 }} />
              <Typography variant="body2" color="text.secondary" mb={0.5}>สถานบริการ</Typography>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                {serviceCenters.map((sc) => (
                  <Chip key={sc} label={sc} size="small" variant="outlined" />
                ))}
              </Box>
            </>
          )}
        </CardContent>
      </Card>

      {/* LINE link */}
      <Card variant="outlined">
        <CardContent>
          <Typography variant="subtitle1" fontWeight="bold" mb={2}>
            การเชื่อมต่อ LINE
          </Typography>
          <Typography variant="body2" color="text.secondary" mb={2}>
            เชื่อมต่อบัญชี LINE เพื่อรับการแจ้งเตือนรายการใหม่ผ่าน LINE Official Account
          </Typography>

          {loadingLine ? (
            <CircularProgress size={24} />
          ) : isLinked ? (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap' }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                {lineProfile.line_picture_url ? (
                  <Avatar src={lineProfile.line_picture_url} sx={{ width: 40, height: 40 }} />
                ) : (
                  <Avatar sx={{ width: 40, height: 40, bgcolor: '#06C755' }}>L</Avatar>
                )}
                <Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                    <CheckCircleIcon sx={{ color: 'success.main', fontSize: 16 }} />
                    <Typography variant="body2" color="success.main" fontWeight="bold">
                      เชื่อมต่อแล้ว
                    </Typography>
                  </Box>
                  <Typography variant="body2">{lineProfile.line_display_name}</Typography>
                </Box>
              </Box>
              <Button
                variant="outlined"
                color="error"
                size="small"
                startIcon={<LinkOffIcon />}
                onClick={handleUnlink}
                loading={unlinking}
              >
                ยกเลิกการเชื่อมต่อ
              </Button>
            </Box>
          ) : (
            <Button
              variant="contained"
              startIcon={<LinkIcon />}
              onClick={handleConnect}
              sx={{ bgcolor: '#06C755', '&:hover': { bgcolor: '#05b54d' } }}
            >
              เชื่อมต่อ LINE
            </Button>
          )}
        </CardContent>
      </Card>
    </Box>
  );
}
