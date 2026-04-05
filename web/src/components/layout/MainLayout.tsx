import { useRef, useState, type ReactNode } from 'react';
import {
  Box, Typography, Button, Avatar, Drawer, List, ListItem, ListItemButton,
  ListItemIcon, ListItemText, AppBar, Toolbar, Divider, CircularProgress,
  IconButton, Badge, Snackbar, Alert,
} from '@mui/material';
import { useNavigate, useLocation } from 'react-router-dom';
import DashboardIcon from '@mui/icons-material/Dashboard';
import ReceiptIcon from '@mui/icons-material/Receipt';
import PeopleIcon from '@mui/icons-material/People';
import LogoutIcon from '@mui/icons-material/Logout';
import NotificationsIcon from '@mui/icons-material/Notifications';
import { useAuth } from '../../hooks/useAuth';
import { useRoleAccess } from '../../hooks/useRoleAccess';
import { useNotification, STATUS_CONFIG, type RequestStatus } from '../../contexts/NotificationContext';
import NotificationPanel from '../notifications/NotificationPanel';

const drawerWidth = 260;

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
  const { role, profile, loading } = useRoleAccess();
  const { unreadCount, toastOpen, toastMessage, toastEventType, closeToast } = useNotification();
  const toastCfg = toastEventType ? STATUS_CONFIG[toastEventType as RequestStatus] : null;

  const bellRef = useRef<HTMLButtonElement>(null);
  const [panelOpen, setPanelOpen] = useState(false);

  const handleBellClick = () => setPanelOpen(true);
  const handlePanelClose = () => setPanelOpen(false);

  const handleLogout = async () => {
    await logout();
    navigate('/login', { replace: true });
  };

  const navItems = [
    { text: 'แดชบอร์ด', icon: <DashboardIcon />, path: '/dashboard', show: true },
    { text: 'รายการคำขอ', icon: <ReceiptIcon />, path: '/requests', show: true },
    { text: 'จัดการเจ้าหน้าที่', icon: <PeopleIcon />, path: '/staff', show: role === 'admin' || role === 'superadmin' },
  ];

  if (loading) {
    return (
      <Box sx={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
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
        }}
      >
        <Toolbar sx={{ justifyContent: 'flex-end', gap: 2 }}>
          {/* Notification Bell */}
          <IconButton
            ref={bellRef}
            onClick={handleBellClick}
            size="large"
            aria-label="การแจ้งเตือน"
            color="inherit"
          >
            <Badge badgeContent={unreadCount > 0 ? unreadCount : undefined} color="error">
              <NotificationsIcon />
            </Badge>
          </IconButton>

          {profile && (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
              <Box sx={{ textAlign: 'right' }}>
                <Typography variant="body2" fontWeight="bold">
                  {profile.first_name} {profile.last_name}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {role ? ROLE_LABELS[role] ?? role : ''}{profile.service_center ? ` | ${profile.service_center}` : ''}
                </Typography>
              </Box>
              <Avatar sx={{ bgcolor: 'primary.main' }}>
                {profile.first_name?.[0]?.toUpperCase() || 'U'}
              </Avatar>
            </Box>
          )}
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
          },
        }}
        variant="permanent"
        anchor="left"
      >
        <Box sx={{ p: 3, textAlign: 'center' }}>
          <Typography variant="h5" fontWeight="900" color="white" letterSpacing={1}>
            <span style={{ color: '#FF8A50' }}>MyCareNK</span> Staff
          </Typography>
        </Box>
        <Divider sx={{ borderColor: 'rgba(255,255,255,0.12)' }} />
        <List sx={{ px: 2, pt: 2, gap: 1, display: 'flex', flexDirection: 'column' }}>
          {navItems.filter(item => item.show).map((item) => {
            const isActive = location.pathname.startsWith(item.path);
            return (
              <ListItem key={item.text} disablePadding sx={{ mb: 1 }}>
                <ListItemButton
                  onClick={() => navigate(item.path)}
                  sx={{
                    borderRadius: 2,
                    backgroundColor: isActive ? 'rgba(255, 138, 80, 0.15)' : 'transparent',
                    color: isActive ? '#FF8A50' : '#CBD5E1',
                    '&:hover': { backgroundColor: 'rgba(255, 138, 80, 0.25)', color: '#FF8A50' },
                    transition: 'all 0.2s',
                  }}
                >
                  <ListItemIcon sx={{ color: 'inherit', minWidth: 40 }}>
                    {item.icon}
                  </ListItemIcon>
                  <ListItemText
                    primary={item.text}
                    slotProps={{ primary: { fontWeight: isActive ? 600 : 500, fontSize: '0.95rem' } }}
                  />
                </ListItemButton>
              </ListItem>
            );
          })}
        </List>
        <Box sx={{ flexGrow: 1 }} />
        <Box sx={{ p: 2 }}>
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
        </Box>
      </Drawer>

      {/* Main Content */}
      <Box
        component="main"
        sx={{ flexGrow: 1, bgcolor: 'background.default', p: 3, minHeight: '100vh', width: `calc(100% - ${drawerWidth}px)` }}
      >
        <Toolbar />
        {children}
      </Box>

      {/* Notification Panel (Popover) */}
      <NotificationPanel
        anchorEl={panelOpen ? bellRef.current : null}
        onClose={handlePanelClose}
      />

      {/* Toast */}
      <Snackbar
        open={toastOpen}
        autoHideDuration={4000}
        onClose={closeToast}
        anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
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
    </Box>
  );
}
