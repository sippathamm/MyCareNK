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
import FiberNewIcon from '@mui/icons-material/FiberNew';
import CancelIcon from '@mui/icons-material/Cancel';
import NotificationsNoneIcon from '@mui/icons-material/NotificationsNone';
import { useNavigate } from 'react-router-dom';
import { useNotification, type NotificationItem } from '../../contexts/NotificationContext';

function formatRelativeTime(dateStr: string): string {
  const diffMs = Date.now() - new Date(dateStr).getTime();
  const seconds = Math.floor(diffMs / 1000);
  if (seconds < 60) return 'เมื่อกี้';
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes} นาทีที่แล้ว`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} ชั่วโมงที่แล้ว`;
  const days = Math.floor(hours / 24);
  return `${days} วันที่แล้ว`;
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
    navigate('/requests');
  };

  const handleMarkAll = () => {
    markAllAsRead();
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
          <Button size="small" onClick={handleMarkAll} sx={{ fontSize: '0.75rem', textTransform: 'none', py: 0 }}>
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
          {notifications.map((item, idx) => (
            <Box key={item.id}>
              <ListItemButton
                onClick={() => handleItemClick(item)}
                sx={{
                  px: 2,
                  py: 1.5,
                  alignItems: 'flex-start',
                  gap: 1.5,
                  backgroundColor: item.is_read ? 'transparent' : 'rgba(255, 138, 80, 0.06)',
                  '&:hover': { backgroundColor: 'rgba(255, 138, 80, 0.12)' },
                }}
              >
                {/* Icon */}
                <Box sx={{ mt: 0.25, flexShrink: 0 }}>
                  {item.event_type === 'new_request' ? (
                    <FiberNewIcon sx={{ color: '#4CAF50', fontSize: 22 }} />
                  ) : (
                    <CancelIcon sx={{ color: '#9E9E9E', fontSize: 22 }} />
                  )}
                </Box>

                {/* Content */}
                <Box sx={{ flex: 1, minWidth: 0 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
                    <Typography variant="body2" fontWeight={item.is_read ? 400 : 600} noWrap>
                      {item.event_type === 'new_request' ? 'คำขอใหม่' : 'ยกเลิกคำขอ'}
                    </Typography>
                    {!item.is_read && (
                      <Box sx={{ width: 7, height: 7, borderRadius: '50%', bgcolor: '#FF8A50', flexShrink: 0 }} />
                    )}
                  </Box>
                  <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                    {item.reference_number}
                  </Typography>
                  <Typography variant="caption" color="text.disabled">
                    {formatRelativeTime(item.created_at)}
                  </Typography>
                </Box>

                {/* Type chip */}
                <Chip
                  label={item.event_type === 'new_request' ? 'รอดำเนินการ' : 'ยกเลิก'}
                  size="small"
                  sx={{
                    fontSize: '0.65rem',
                    height: 20,
                    flexShrink: 0,
                    bgcolor: item.event_type === 'new_request' ? '#E8F5E9' : '#F5F5F5',
                    color: item.event_type === 'new_request' ? '#2E7D32' : '#616161',
                  }}
                />
              </ListItemButton>
              {idx < notifications.length - 1 && <Divider />}
            </Box>
          ))}
        </List>
      )}
    </Popover>
  );
}
