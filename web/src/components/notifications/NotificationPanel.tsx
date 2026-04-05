import {
  Popover,
  Box,
  Typography,
  List,
  ListItemButton,
  Divider,
  Button,
  Chip,
} from '@mui/material';
import NotificationsNoneIcon from '@mui/icons-material/NotificationsNone';
import { useNavigate } from 'react-router-dom';
import {
  useNotification,
  STATUS_CONFIG,
  type NotificationItem,
  type RequestStatus,
} from '../../contexts/NotificationContext';

function formatRelativeTime(dateStr: string): string {
  const diffMs = Date.now() - new Date(dateStr).getTime();
  const seconds = Math.floor(diffMs / 1000);
  if (seconds < 60) return 'เมื่อกี้';
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes} นาทีที่แล้ว`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} ชั่วโมงที่แล้ว`;
  return `${Math.floor(hours / 24)} วันที่แล้ว`;
}

// Dot indicator matching each status color
function StatusDot({ eventType }: { eventType: RequestStatus }) {
  const { color } = STATUS_CONFIG[eventType] ?? { color: '#9E9E9E' };
  return <Box sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: color, flexShrink: 0, mt: 0.4 }} />;
}

interface NotificationPanelProps {
  anchorEl: HTMLElement | null;
  onClose: () => void;
}

export default function NotificationPanel({ anchorEl, onClose }: NotificationPanelProps) {
  const navigate = useNavigate();
  const { notifications, markAsRead, markAllAsRead } = useNotification();

  const handleItemClick = (item: NotificationItem) => {
    markAsRead(item.id);
    onClose();
    navigate('/requests', { state: { openRequestId: item.request_id } });
  };

  return (
    <Popover
      open={Boolean(anchorEl)}
      anchorEl={anchorEl}
      onClose={onClose}
      anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      transformOrigin={{ vertical: 'top', horizontal: 'right' }}
      slotProps={{ paper: { sx: { width: 360, maxHeight: 500, borderRadius: 2, boxShadow: 4 } } }}
    >
      {/* Header */}
      <Box sx={{ px: 2, py: 1.5, display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid', borderColor: 'divider' }}>
        <Typography fontWeight="bold" fontSize="0.95rem">การแจ้งเตือน</Typography>
        {notifications.some(n => !n.is_read) && (
          <Button size="small" onClick={markAllAsRead} sx={{ fontSize: '0.75rem', textTransform: 'none', py: 0 }}>
            อ่านทั้งหมด
          </Button>
        )}
      </Box>

      {/* List */}
      {notifications.length === 0 ? (
        <Box sx={{ py: 5, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1, color: 'text.secondary' }}>
          <NotificationsNoneIcon sx={{ fontSize: 40, opacity: 0.4 }} />
          <Typography variant="body2">ไม่มีการแจ้งเตือน</Typography>
        </Box>
      ) : (
        <List disablePadding sx={{ overflowY: 'auto', maxHeight: 420 }}>
          {notifications.map((item, idx) => {
            const cfg = STATUS_CONFIG[item.event_type];
            return (
              <Box key={item.id}>
                <ListItemButton
                  onClick={() => handleItemClick(item)}
                  sx={{
                    px: 2,
                    py: 1.5,
                    alignItems: 'flex-start',
                    gap: 1.5,
                    backgroundColor: item.is_read ? 'transparent' : `${cfg.bg}`,
                    '&:hover': { filter: 'brightness(0.96)' },
                  }}
                >
                  {/* Status color dot */}
                  <StatusDot eventType={item.event_type} />

                  {/* Content */}
                  <Box sx={{ flex: 1, minWidth: 0 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Typography
                        variant="body2"
                        fontWeight={item.is_read ? 400 : 600}
                        sx={{ color: item.is_read ? 'text.primary' : cfg.color }}
                        noWrap
                      >
                        {cfg.label}
                      </Typography>
                      {!item.is_read && (
                        <Box sx={{ width: 6, height: 6, borderRadius: '50%', bgcolor: cfg.color, flexShrink: 0 }} />
                      )}
                    </Box>
                    <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }} noWrap>
                      {item.reference_number}
                    </Typography>
                    <Typography variant="caption" color="text.disabled">
                      {formatRelativeTime(item.created_at)}
                    </Typography>
                  </Box>

                  {/* Status chip */}
                  <Chip
                    label={cfg.label}
                    size="small"
                    sx={{
                      fontSize: '0.65rem',
                      height: 20,
                      flexShrink: 0,
                      bgcolor: cfg.bg,
                      color: cfg.color,
                      fontWeight: 600,
                      border: `1px solid ${cfg.color}30`,
                    }}
                  />
                </ListItemButton>
                {idx < notifications.length - 1 && <Divider />}
              </Box>
            );
          })}
        </List>
      )}
    </Popover>
  );
}
