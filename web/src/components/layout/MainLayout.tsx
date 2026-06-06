import { useRef, useState, useEffect, useMemo, type ReactNode } from 'react';
import {
  Box, Typography, Button, Avatar, Drawer, List, ListItem, ListItemButton,
  ListItemIcon, ListItemText, AppBar, Toolbar, Divider, CircularProgress,
  IconButton, Badge, Snackbar, Alert, Tooltip, Tab, Tabs,
  Dialog, DialogTitle, DialogContent, DialogActions,
  Chip, Menu, MenuItem,
} from '@mui/material';
import { useNavigate, useLocation } from 'react-router-dom';
import DashboardIcon from '@mui/icons-material/Dashboard';
import ReceiptIcon from '@mui/icons-material/Receipt';
import PeopleIcon from '@mui/icons-material/People';
import LogoutIcon from '@mui/icons-material/Logout';
import NotificationsIcon from '@mui/icons-material/Notifications';
import MenuIcon from '@mui/icons-material/Menu';
import MenuOpenIcon from '@mui/icons-material/MenuOpen';
import InventoryIcon from '@mui/icons-material/Inventory2';
import AssessmentIcon from '@mui/icons-material/Assessment';
import ManageSearchIcon from '@mui/icons-material/ManageSearch';
import CalendarMonthIcon from '@mui/icons-material/CalendarMonth';
import ArticleIcon from '@mui/icons-material/Article';
import SystemUpdateAltIcon from '@mui/icons-material/SystemUpdateAlt';
import OpenInNewIcon from '@mui/icons-material/OpenInNew';
import DownloadIcon from '@mui/icons-material/Download';
import ArrowDropDownIcon from '@mui/icons-material/ArrowDropDown';
import { QRCodeSVG } from 'qrcode.react';

const APP_RELEASES_URL = 'https://github.com/sippathamm/MyCareNK/releases';
import { useAuth } from '../../hooks/useAuth';
import { supabase } from '../../lib/supabase';
import WhatsNewDialog, { type WhatsNewData } from '../shared/WhatsNewDialog';

declare const __APP_VERSION__: string;

const getWebBranch = (v: string): string =>
  v.includes('-preview') ? 'preview' : v.includes('-dev') ? 'dev' : 'main';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useServiceCenters } from '../../hooks/useServiceCenters';
import { useNotification, STATUS_CONFIG, APPOINTMENT_STATUS_CONFIG, type RequestStatus, type AppointmentEventType } from '../../contexts/NotificationContext';
import { ServiceCenterFilterContext } from '../../contexts/ServiceCenterFilterContext';
import NotificationPanel from '../notifications/NotificationPanel';

const DRAWER_OPEN_WIDTH = 260;
const DRAWER_CLOSED_WIDTH = 64;

const ROLE_LABELS: Record<string, string> = {
  staff: 'เจ้าหน้าที่',
  admin: 'ผู้ดูแล',
  superadmin: 'ผู้ดูแลสูงสุด',
};

interface MainLayoutProps {
  children: ReactNode;
}

export default function MainLayout({ children }: MainLayoutProps) {
  const navigate = useNavigate();
  const location = useLocation();
  const { logout } = useAuth();
  const { role, profile, loading, serviceCenters, isSuperadmin } = useRoleAccess();
  const { unreadCount, toastOpen, toastMessage, toastEventType, toastIsAppointment, toastAppointmentEventType, closeToast } = useNotification();
  const toastCfg = toastIsAppointment
    ? APPOINTMENT_STATUS_CONFIG[(toastAppointmentEventType ?? 'pending') as AppointmentEventType]
    : (toastEventType ? STATUS_CONFIG[toastEventType as RequestStatus] : null);

  const { centers: allCenters } = useServiceCenters(isSuperadmin ?? false);
  const chipCenters: string[] = isSuperadmin ? allCenters.map(c => c.name) : serviceCenters;
  const hasDropdown = chipCenters.length > 1;

  const [selectedServiceCenter, setSelectedServiceCenter] = useState<string | null>(null);
  const [anchorElSC, setAnchorElSC] = useState<HTMLElement | null>(null);

  const filterContextValue = useMemo(
    () => ({ selectedServiceCenter }),
    [selectedServiceCenter],
  );

  const bellRef = useRef<HTMLButtonElement>(null);
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [whatsNewOpen, setWhatsNewOpen] = useState(false);
  const [whatsNewData, setWhatsNewData] = useState<WhatsNewData | null>(null);
  const [downloadDialogOpen, setDownloadDialogOpen] = useState(false);
  const [downloadTab, setDownloadTab] = useState<'release' | 'preview'>('release');
  const [releaseUrl, setReleaseUrl] = useState<string | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [downloadUrlLoading, setDownloadUrlLoading] = useState(false);

  const drawerWidth = sidebarOpen ? DRAWER_OPEN_WIDTH : DRAWER_CLOSED_WIDTH;

  const handleBellClick = () => { setAnchorEl(bellRef.current); };
  const handlePanelClose = () => { setAnchorEl(null); };

  useEffect(() => {
    if (!downloadDialogOpen) return;
    setDownloadUrlLoading(true);
    setReleaseUrl(null);
    setPreviewUrl(null);
    (async () => {
      const fetchUrl = async (branch: string) => {
        const { data } = await supabase
          .from('app_versions' as never)
          .select('download_url')
          .eq('branch', branch)
          .order('created_at', { ascending: false })
          .limit(1);
        return (data as null | { download_url: string }[])?.[0]?.download_url ?? null;
      };
      const [main, preview] = await Promise.all([fetchUrl('main'), fetchUrl('preview')]);
      setReleaseUrl(main);
      setPreviewUrl(preview);
      setDownloadUrlLoading(false);
    })();
  }, [downloadDialogOpen]);

  useEffect(() => {
    if (loading || !role) return;
    (async () => {
      const branch = getWebBranch(__APP_VERSION__);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const { data } = await (supabase as any).rpc('get_latest_web_changelog', { p_branch: branch });
      const entry = (data as WhatsNewData[] | null)?.[0];
      if (!entry) return;
      if (localStorage.getItem('whats_new_seen_version') !== entry.version) {
        setWhatsNewData(entry);
        setWhatsNewOpen(true);
      }
    })();
  }, [loading, role]);

  const handleWhatsNewClose = () => {
    if (whatsNewData) localStorage.setItem('whats_new_seen_version', whatsNewData.version);
    setWhatsNewOpen(false);
  };

  const handleLogout = async () => {
    await logout();
    navigate('/login', { replace: true });
  };

  const navItems = [
    { text: 'แดชบอร์ด', icon: <DashboardIcon />, path: '/dashboard', show: true },
    { text: 'รายการคำขอ', icon: <ReceiptIcon />, path: '/requests', show: true },
    { text: 'รายการนัดหมาย', icon: <CalendarMonthIcon />, path: '/appointments', show: true },
    { text: 'สต็อกและพยากรณ์', icon: <InventoryIcon />, path: '/inventory', show: true },
    { text: 'ภาระงานเจ้าหน้าที่', icon: <AssessmentIcon />, path: '/staff-workload', show: role === 'admin' || role === 'superadmin' },
    { text: 'จัดการเจ้าหน้าที่', icon: <PeopleIcon />, path: '/staff', show: role === 'admin' || role === 'superadmin' },
    { text: 'บทความ', icon: <ArticleIcon />, path: '/articles', show: role === 'admin' || role === 'superadmin' },
    { text: 'บันทึกการตรวจสอบ', icon: <ManageSearchIcon />, path: '/audit-log', show: !!role },
  ];

  if (loading) {
    return (
      <Box sx={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <ServiceCenterFilterContext.Provider value={filterContextValue}>
    <Box sx={{ display: 'flex' }}>
      {/* App Bar */}
      <AppBar
        position="fixed"
        sx={{
          width: `calc(100% - ${drawerWidth}px)`,
          ml: `${drawerWidth}px`,
          backgroundColor: 'white',
          color: 'text.primary',
          boxShadow: 1,
          transition: 'width 0.3s ease, margin-left 0.3s ease',
        }}
      >
        <Toolbar sx={{ justifyContent: 'space-between', gap: 2 }}>
          <IconButton
            onClick={() => setSidebarOpen(prev => !prev)}
            size="large"
            color="inherit"
            aria-label={sidebarOpen ? 'ย่อ Sidebar' : 'ขยาย Sidebar'}
          >
            {sidebarOpen ? <MenuOpenIcon /> : <MenuIcon />}
          </IconButton>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            {/* Notification Bell */}
            <IconButton
              ref={bellRef}
              onClick={handleBellClick}
              size="large"
              aria-label="การแจ้งเตือน"
              color="inherit"
            >
              <Badge
                badgeContent={unreadCount > 0 ? unreadCount : undefined}
                color="error"
              >
                <NotificationsIcon />
              </Badge>
            </IconButton>

            {profile && (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                <Box sx={{ textAlign: 'right' }}>
                  <Typography variant="body2" fontWeight="bold">
                    {profile.first_name} {profile.last_name}
                  </Typography>
                  <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 0.5 }}>
                    <Typography variant="caption" color="text.secondary">
                      {role ? ROLE_LABELS[role] ?? role : ''}
                    </Typography>
                    {chipCenters.length > 0 && (
                      <Typography variant="caption" color="text.secondary">|</Typography>
                    )}
                    {chipCenters.length > 0 && (
                      hasDropdown ? (
                        <Chip
                          label={selectedServiceCenter ?? 'ทั้งหมด'}
                          size="small"
                          onClick={(e) => setAnchorElSC(e.currentTarget)}
                          onDelete={(e) => setAnchorElSC(e.currentTarget)}
                          deleteIcon={<ArrowDropDownIcon sx={{ fontSize: '16px !important' }} />}
                          sx={{
                            height: 18, fontSize: '0.7rem', cursor: 'pointer',
                            bgcolor: 'rgba(255,159,107,0.12)', color: 'primary.main',
                            '& .MuiChip-deleteIcon': { color: 'primary.main' },
                          }}
                        />
                      ) : (
                        <Chip
                          label={chipCenters[0]}
                          size="small"
                          sx={{ height: 18, fontSize: '0.7rem', bgcolor: 'rgba(255,159,107,0.12)', color: 'primary.main' }}
                        />
                      )
                    )}
                  </Box>
                </Box>
                <Avatar sx={{ bgcolor: 'primary.main' }}>
                  {profile.first_name?.[0]?.toUpperCase() || 'U'}
                </Avatar>
              </Box>
            )}
          </Box>
        </Toolbar>
      </AppBar>

      {/* Sidebar */}
      <Drawer
        sx={{
          width: drawerWidth,
          flexShrink: 0,
          '& .MuiDrawer-paper': {
            width: drawerWidth,
            boxSizing: 'border-box',
            backgroundColor: '#1E293B',
            color: 'white',
            overflowX: 'hidden',
            transition: 'width 0.3s ease',
          },
        }}
        variant="permanent"
        anchor="left"
      >
        {/* Logo */}
        <Box
          sx={{
            p: sidebarOpen ? 3 : 1,
            textAlign: 'center',
            height: 64,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            transition: 'padding 0.3s ease',
          }}
        >
          {sidebarOpen ? (
            <Typography variant="h5" fontWeight="900" color="white" letterSpacing={1} noWrap>
              <span style={{ color: '#FF9F6B' }}>MyCareNK</span> Staff
            </Typography>
          ) : (
            <Typography variant="h6" fontWeight="900" sx={{ color: '#FF9F6B' }}>
              M
            </Typography>
          )}
        </Box>
        <Divider sx={{ borderColor: 'rgba(255,255,255,0.12)' }} />

        {/* Nav Items */}
        <List sx={{ px: sidebarOpen ? 2 : 1, pt: 2, gap: 1, display: 'flex', flexDirection: 'column' }}>
          {navItems.filter(item => item.show).map((item) => {
            const isActive = location.pathname === item.path;
            return (
              <ListItem key={item.text} disablePadding sx={{ mb: 1 }}>
                <Tooltip title={sidebarOpen ? '' : item.text} placement="right">
                  <ListItemButton
                    onClick={() => navigate(item.path)}
                    sx={{
                      borderRadius: 2,
                      backgroundColor: isActive ? 'rgba(255, 159, 107, 0.15)' : 'transparent',
                      color: isActive ? '#FF9F6B' : '#CBD5E1',
                      justifyContent: sidebarOpen ? 'flex-start' : 'center',
                      px: sidebarOpen ? 2 : 1,
                      '&:hover': { backgroundColor: 'rgba(255, 159, 107, 0.25)', color: '#FF9F6B' },
                      transition: 'all 0.2s',
                    }}
                  >
                    <ListItemIcon sx={{ color: 'inherit', minWidth: sidebarOpen ? 40 : 'unset' }}>
                      {item.icon}
                    </ListItemIcon>
                    {sidebarOpen && (
                      <ListItemText
                        primary={item.text}
                        slotProps={{ primary: { fontWeight: isActive ? 600 : 500, fontSize: '0.95rem' } }}
                      />
                    )}
                  </ListItemButton>
                </Tooltip>
              </ListItem>
            );
          })}
        </List>

        <Box sx={{ flexGrow: 1 }} />

        {/* Download App + Logout */}
        <Box sx={{ p: sidebarOpen ? 2 : 1, pb: 2, display: 'flex', flexDirection: 'column', gap: 1 }}>
          <Tooltip title={sidebarOpen ? '' : 'ดาวน์โหลดแอป'} placement="right">
            {sidebarOpen ? (
              <Button
                fullWidth
                variant="outlined"
                color="inherit"
                startIcon={<SystemUpdateAltIcon />}
                onClick={() => setDownloadDialogOpen(true)}
                sx={{
                  borderColor: 'rgba(255,255,255,0.2)',
                  color: '#CBD5E1',
                  '&:hover': { borderColor: 'rgba(255,255,255,0.5)', backgroundColor: 'rgba(255,255,255,0.05)' },
                }}
              >
                ดาวน์โหลดแอป
              </Button>
            ) : (
              <IconButton
                onClick={() => setDownloadDialogOpen(true)}
                sx={{
                  color: '#CBD5E1',
                  width: '100%',
                  borderRadius: 2,
                  '&:hover': { backgroundColor: 'rgba(255,255,255,0.05)', color: 'white' },
                }}
              >
                <SystemUpdateAltIcon />
              </IconButton>
            )}
          </Tooltip>
          <Tooltip title={sidebarOpen ? '' : 'ออกจากระบบ'} placement="right">
            {sidebarOpen ? (
              <Button
                fullWidth
                variant="outlined"
                color="inherit"
                startIcon={<LogoutIcon />}
                onClick={handleLogout}
                sx={{
                  borderColor: 'rgba(255,255,255,0.2)',
                  color: '#CBD5E1',
                  '&:hover': { borderColor: 'rgba(255,255,255,0.5)', backgroundColor: 'rgba(255,255,255,0.05)' },
                }}
              >
                ออกจากระบบ
              </Button>
            ) : (
              <IconButton
                onClick={handleLogout}
                sx={{
                  color: '#CBD5E1',
                  width: '100%',
                  borderRadius: 2,
                  '&:hover': { backgroundColor: 'rgba(255,255,255,0.05)', color: 'white' },
                }}
              >
                <LogoutIcon />
              </IconButton>
            )}
          </Tooltip>
        </Box>
      </Drawer>

      {/* Main Content */}
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          bgcolor: 'background.default',
          p: 3,
          minHeight: '100vh',
          width: `calc(100% - ${drawerWidth}px)`,
          transition: 'width 0.3s ease',
        }}
      >
        <Toolbar />
        {children}
      </Box>

      {/* Download App Dialog */}
      <Dialog open={downloadDialogOpen} onClose={() => setDownloadDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: 'bold' }}>ดาวน์โหลดแอป MyCareNK</DialogTitle>
        <Tabs
          value={downloadTab}
          onChange={(_, v) => setDownloadTab(v)}
          variant="fullWidth"
          sx={{ borderBottom: 1, borderColor: 'divider', minHeight: 40 }}
        >
          <Tab label="RELEASE" value="release" sx={{ fontWeight: 'bold', fontSize: 12 }} />
          <Tab label="PREVIEW" value="preview" sx={{ fontWeight: 'bold', fontSize: 12 }} />
        </Tabs>
        <DialogContent>
          {(() => {
            const url = downloadTab === 'release' ? releaseUrl : previewUrl;
            return (
              <Box display="flex" flexDirection="column" alignItems="center" gap={2} py={1}>
                {downloadUrlLoading ? (
                  <Box display="flex" alignItems="center" justifyContent="center" height={200}>
                    <CircularProgress />
                  </Box>
                ) : url ? (
                  <QRCodeSVG value={url} size={200} />
                ) : (
                  <Box display="flex" alignItems="center" justifyContent="center" height={200}>
                    <Typography variant="body2" color="text.secondary">ไม่พบข้อมูล</Typography>
                  </Box>
                )}
                <Typography variant="body2" color="text.secondary" textAlign="center">
                  สแกน QR Code เพื่อดาวน์โหลด
                </Typography>
                <Box display="flex" flexDirection="row" gap={1} justifyContent="center">
                  <Button
                    variant="outlined"
                    color="primary"
                    startIcon={<OpenInNewIcon />}
                    href={APP_RELEASES_URL}
                    target="_blank"
                    rel="noopener noreferrer"
                    component="a"
                  >
                    เปิดหน้าดาวน์โหลด
                  </Button>
                  <Button
                    variant="contained"
                    color="primary"
                    startIcon={<DownloadIcon />}
                    href={url ?? '#'}
                    download
                    component="a"
                    disabled={!url}
                  >
                    ดาวน์โหลด
                  </Button>
                </Box>
              </Box>
            );
          })()}
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setDownloadDialogOpen(false)} color="inherit">ปิด</Button>
        </DialogActions>
      </Dialog>

      {/* SC Dropdown Menu */}
      <Menu
        anchorEl={anchorElSC}
        open={Boolean(anchorElSC)}
        onClose={() => setAnchorElSC(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        transformOrigin={{ vertical: 'top', horizontal: 'right' }}
      >
        <MenuItem
          selected={selectedServiceCenter === null}
          onClick={() => { setSelectedServiceCenter(null); setAnchorElSC(null); }}
        >
          ทั้งหมด
        </MenuItem>
        {chipCenters.map(name => (
          <MenuItem
            key={name}
            selected={selectedServiceCenter === name}
            onClick={() => { setSelectedServiceCenter(name); setAnchorElSC(null); }}
          >
            {name}
          </MenuItem>
        ))}
      </Menu>

      {/* Notification Panel (Popover) */}
      <NotificationPanel
        anchorEl={anchorEl}
        onClose={handlePanelClose}
      />

      {/* Toast */}
      <Snackbar
        open={toastOpen}
        autoHideDuration={4000}
        onClose={closeToast}
        anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
        sx={{ top: '80px !important' }}
      >
        <Alert
          onClose={closeToast}
          variant="filled"
          icon={false}
          sx={{
            width: '100%',
            bgcolor: toastCfg?.color ?? '#2196F3',
            color: 'white',
            '& .MuiAlert-action .MuiIconButton-root': { color: 'white' },
          }}
        >
          {toastMessage}
        </Alert>
      </Snackbar>
      {whatsNewData && (
        <WhatsNewDialog
          open={whatsNewOpen}
          onClose={handleWhatsNewClose}
          data={whatsNewData}
        />
      )}
    </Box>
    </ServiceCenterFilterContext.Provider>
  );
}
