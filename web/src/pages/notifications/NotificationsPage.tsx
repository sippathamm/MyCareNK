import { Box, Typography, Paper, List, ListItemButton, Divider, Button, IconButton } from '@mui/material';
import NotificationsNoneIcon from '@mui/icons-material/NotificationsNone';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import { useNavigate } from 'react-router-dom';
import {
  useNotification,
  STATUS_CONFIG,
  APPOINTMENT_STATUS_CONFIG,
  isAppointmentNotification,
  type NotificationItem,
  type RequestStatus,
  type AppointmentEventType,
} from '../../contexts/NotificationContext';

function getNotifConfig(item: NotificationItem) {
  if (isAppointmentNotification(item)) {
    return APPOINTMENT_STATUS_CONFIG[item.event_type as AppointmentEventType] ?? APPOINTMENT_STATUS_CONFIG.pending;
  }
  return STATUS_CONFIG[item.event_type as RequestStatus];
}

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

function formatAbsoluteDateTime(dateStr: string): string {
  const date = new Date(dateStr);
  const datePart = date.toLocaleDateString('th-TH', { day: 'numeric', month: 'short', year: 'numeric' });
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');
  return `${datePart} ${hours}:${minutes} น.`;
}

function StatusDot({ item }: { item: NotificationItem }) {
  const color = item.is_read ? (getNotifConfig(item)?.color ?? '#9E9E9E') : '#F44336';
  return <Box sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: color, flexShrink: 0, mt: 0.5 }} />;
}

function NotificationRow({ item, onItemClick, onDelete }: {
  item: NotificationItem;
  onItemClick: (item: NotificationItem) => void;
  onDelete: (e: React.MouseEvent, id: string) => void;
}) {
  const cfg = getNotifConfig(item);
  return (
    <ListItemButton
      onClick={() => onItemClick(item)}
      sx={{
        px: 3,
        py: 1.5,
        alignItems: 'flex-start',
        gap: 2,
        borderLeft: item.is_read ? '3px solid transparent' : '3px solid #F44336',
        '&:hover': { filter: 'brightness(0.97)' },
      }}
    >
      <StatusDot item={item} />

      <Box sx={{ flex: 1, minWidth: 0 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Typography
            variant="body2"
            fontWeight={item.is_read ? 400 : 600}
            sx={{ color: item.is_read ? 'text.primary' : '#FF9F6B' }}
          >
            {cfg.label}
          </Typography>
          {!item.is_read && (
            <Box sx={{ width: 6, height: 6, borderRadius: '50%', bgcolor: '#F44336', flexShrink: 0 }} />
          )}
        </Box>
        <Typography variant="body2" color="text.secondary">
          {item.reference_number}
        </Typography>
        <Typography variant="caption" color="text.disabled">
          {formatAbsoluteDateTime(item.created_at)} · {formatRelativeTime(item.created_at)}
        </Typography>
      </Box>

      <IconButton
        size="small"
        onClick={(e) => onDelete(e, item.id)}
        sx={{ color: 'text.disabled', '&:hover': { color: 'error.main' }, flexShrink: 0 }}
      >
        <DeleteOutlineIcon fontSize="small" />
      </IconButton>
    </ListItemButton>
  );
}

export default function NotificationsPage() {
  const navigate = useNavigate();
  const { notifications, markAsRead, markAllAsRead, deleteNotification } = useNotification();

  const handleItemClick = (item: NotificationItem) => {
    markAsRead(item.id);
    if (isAppointmentNotification(item)) {
      navigate('/appointments', { state: { openAppointmentId: item.source_id } });
    } else {
      navigate('/requests', { state: { openRequestId: item.source_id } });
    }
  };

  const handleDelete = (e: React.MouseEvent, id: string) => {
    e.stopPropagation();
    deleteNotification(id);
  };

  const hasUnread = notifications.some(n => !n.is_read);

  return (
    <Box sx={{ width: '100%', maxWidth: 1200, margin: '0 auto' }}>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
        <Box>
          <Typography variant="h5" fontWeight="bold" gutterBottom>
            การแจ้งเตือน
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
            รายการแจ้งเตือนทั้งหมด ({notifications.length} รายการ)
          </Typography>
        </Box>
        {hasUnread && (
          <Button size="small" variant="outlined" onClick={markAllAsRead} sx={{ textTransform: 'none', height: 'fit-content' }}>
            อ่านทั้งหมด
          </Button>
        )}
      </Box>

      <Paper elevation={1} sx={{ borderRadius: 2, overflow: 'hidden' }}>
        {notifications.length === 0 ? (
          <Box sx={{ py: 10, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1.5, color: 'text.secondary' }}>
            <NotificationsNoneIcon sx={{ fontSize: 56, opacity: 0.3 }} />
            <Typography variant="body1">ไม่มีการแจ้งเตือน</Typography>
          </Box>
        ) : (
          <List disablePadding>
            {notifications.map((item, idx) => (
              <Box key={item.id}>
                <NotificationRow item={item} onItemClick={handleItemClick} onDelete={handleDelete} />
                {idx < notifications.length - 1 && <Divider />}
              </Box>
            ))}
          </List>
        )}
      </Paper>
    </Box>
  );
}
