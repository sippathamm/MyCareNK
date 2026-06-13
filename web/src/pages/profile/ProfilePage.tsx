import { useState, useEffect, useCallback } from 'react';
import {
  Box, Typography, Card, CardContent, Avatar, Button, Chip,
  CircularProgress, Divider, Grid, Snackbar, Alert,
} from '@mui/material';
import LinkIcon from '@mui/icons-material/Link';
import LinkOffIcon from '@mui/icons-material/LinkOff';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import InfoOutlinedIcon from '@mui/icons-material/InfoOutlined';
import { useLocation } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useServiceCenters } from '../../hooks/useServiceCenters';

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

interface SnackbarState {
  open: boolean;
  message: string;
  severity: 'success' | 'error';
}

export default function ProfilePage() {
  const { session } = useAuth();
  const { profile, role, serviceCenters, isSuperadmin } = useRoleAccess();
  const { centers: allCenters } = useServiceCenters(isSuperadmin);
  const location = useLocation();

  const [lineProfile, setLineProfile] = useState<LineProfile>({
    line_user_id: null,
    line_display_name: null,
    line_picture_url: null,
  });
  const [loadingLine, setLoadingLine] = useState(true);
  const [unlinking, setUnlinking] = useState(false);
  const [snackbar, setSnackbar] = useState<SnackbarState>({ open: false, message: '', severity: 'success' });

  const showSnackbar = useCallback((message: string, severity: 'success' | 'error') => {
    setSnackbar({ open: true, message, severity });
  }, []);

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

  useEffect(() => {
    const params = new URLSearchParams(location.search);
    if (params.get('linked') === 'true') {
      showSnackbar('เชื่อมต่อ LINE สำเร็จ', 'success');
      fetchLineProfile();
    } else if (params.get('error')) {
      showSnackbar(params.get('error') ?? 'เกิดข้อผิดพลาด', 'error');
    }
  }, [location.search, fetchLineProfile, showSnackbar]);

  const handleConnect = () => {
    if (!LINE_LOGIN_CHANNEL_ID) {
      showSnackbar('ยังไม่ได้ตั้งค่า LINE Login Channel ID', 'error');
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
      showSnackbar('ยกเลิกการเชื่อมต่อไม่สำเร็จ', 'error');
    } else {
      setLineProfile({ line_user_id: null, line_display_name: null, line_picture_url: null });
      showSnackbar('ยกเลิกการเชื่อมต่อ LINE แล้ว', 'success');
    }
    setUnlinking(false);
  };

  const isLinked = !!lineProfile.line_user_id;
  const displayCenters = isSuperadmin ? allCenters.map((c) => c.name) : serviceCenters;

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Typography variant="h5" fontWeight="bold" mb={3}>โปรไฟล์</Typography>

      <Grid container spacing={3} alignItems="flex-start">
        {/* ── Left column: staff info ───────────────────────────── */}
        <Grid size={{ xs: 12, md: 5 }}>
          <Card variant="outlined">
            <CardContent sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              {/* Avatar + name + role */}
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
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

              <Divider />

              {/* Email */}
              <Box>
                <Typography variant="caption" color="text.secondary">อีเมล</Typography>
                <Typography variant="body2">{session?.user?.email ?? '-'}</Typography>
              </Box>

              {/* Service centers */}
              {displayCenters.length > 0 && (
                <Box>
                  <Typography variant="caption" color="text.secondary">สถานบริการ</Typography>
                  <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5, mt: 0.5 }}>
                    {displayCenters.map((sc) => (
                      <Chip key={sc} label={sc} size="small" variant="outlined" />
                    ))}
                  </Box>
                </Box>
              )}

              {/* Notice for staff / admin */}
              {!isSuperadmin && (
                <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1, bgcolor: 'grey.50', borderRadius: 1, p: 1.5 }}>
                  <InfoOutlinedIcon sx={{ fontSize: 16, color: 'text.secondary', mt: 0.25 }} />
                  <Typography variant="caption" color="text.secondary">
                    หากต้องการแก้ไขข้อมูล โปรดติดต่อผู้ดูแลสูงสุด
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* ── Right column: LINE link ───────────────────────────── */}
        <Grid size={{ xs: 12, md: 7 }}>
          <Card variant="outlined">
            <CardContent>
              <Typography variant="subtitle1" fontWeight="bold" mb={1}>
                การเชื่อมต่อ LINE
              </Typography>
              <Typography variant="body2" color="text.secondary" mb={2}>
                เชื่อมต่อบัญชี LINE เพื่อรับการแจ้งเตือนรายการใหม่ผ่าน LINE Official Account
              </Typography>

              {loadingLine ? (
                <CircularProgress size={24} />
              ) : isLinked ? (
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
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

                  {/* Add friend banner */}
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, bgcolor: '#F0FFF4', border: '1px solid #06C755', borderRadius: 2, p: 2 }}>
                    <Box
                      component="img"
                      src="https://qr-official.line.me/gs/M_663mvfrd_GW.png?oat_content=qr"
                      alt="QR Code LINE OA"
                      sx={{ width: 80, height: 80, borderRadius: 1, flexShrink: 0 }}
                    />
                    <Box sx={{ flex: 1 }}>
                      <Typography variant="body2" fontWeight="bold" mb={0.5}>
                        เพิ่ม LINE OA เป็นเพื่อนเพื่อรับการแจ้งเตือน
                      </Typography>
                      <Typography variant="caption" color="text.secondary" display="block" mb={1}>
                        สแกน QR Code หรือกดปุ่มด้านล่างเพื่อเพิ่มเพื่อน
                      </Typography>
                      <Button
                        component="a"
                        href="https://lin.ee/YSncBQN"
                        target="_blank"
                        rel="noopener noreferrer"
                        size="small"
                        variant="contained"
                        sx={{ bgcolor: '#06C755', '&:hover': { bgcolor: '#05b54d' } }}
                      >
                        เพิ่มเพื่อน LINE OA
                      </Button>
                    </Box>
                  </Box>
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
        </Grid>
      </Grid>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert
          severity={snackbar.severity}
          variant="filled"
          onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
