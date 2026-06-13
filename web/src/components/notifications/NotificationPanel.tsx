import {
  Popover,
  Box,
  Typography,
  List,
  ListItemButton,
  Divider,
  Button,
  IconButton,
  Chip,
} from '@mui/material';
import NotificationsNoneIcon from '@mui/icons-material/NotificationsNone';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import { useNavigate } from 'react-router-dom';
import {
  useNotification,
  STATUS_CONFIG,
  APPOINTMENT_STATUS_CONFIG,
  STOCK_OPERATION_CONFIG,
  STAFF_MANAGEMENT_CONFIG,
  isAppointmentNotification,
  isStockNotification,
  isStaffManagementNotification,
  renderStockMessageJSX,
  renderStaffManagementMessageJSX,
  type NotificationItem,
  type RequestStatus,
  type AppointmentEventType,
} from '../../contexts/NotificationContext';
import { useRoleAccess } from '../../hooks/useRoleAccess';

function getNotifConfig(item: NotificationItem) {
  if (isAppointmentNotification(item)) {
    return APPOINTMENT_STATUS_CONFIG[item.event_type as AppointmentEventType] ?? APPOINTMENT_STATUS_CONFIG.pending;
  }
  if (isStockNotification(item)) {
    return STOCK_OPERATION_CONFIG[item.event_type] ?? STOCK_OPERATION_CONFIG.restock;
  }
  if (isStaffManagementNotification(item)) {
    return STAFF_MANAGEMENT_CONFIG;
  }
  return STATUS_CONFIG[item.event_type as RequestStatus];
}

const PANEL_LIMIT = 15;

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

function StatusDot({ item }: { item: NotificationItem }) {
  const color = item.is_read ? (getNotifConfig(item)?.color ?? '#9E9E9E') : '#F44336';
  return <Box sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: color, flexShrink: 0, mt: 0.4 }} />;
}

interface NotificationPanelProps {
  anchorEl: HTMLElement | null;
  onClose: () => void;
}

export default function NotificationPanel({ anchorEl, onClose }: NotificationPanelProps) {
  const navigate = useNavigate();
  const { notifications, markAsRead, markAllAsRead, deleteNotification } = useNotification();
  const { isAdmin, isSuperadmin } = useRoleAccess();
  const isViewerStaff = !isAdmin && !isSuperadmin;

  const handleItemClick = (item: NotificationItem) => {
    markAsRead(item.id);
    onClose();
    if (isAppointmentNotification(item)) {
      navigate('/appointments', { state: { openAppointmentId: item.source_id } });
    } else if (isStockNotification(item)) {
      navigate('/inventory');
    } else if (isStaffManagementNotification(item)) {
      navigate('/staff');
    } else {
      navigate('/requests', { state: { openRequestId: item.source_id } });
    }
  };

  const handleDelete = (e: React.MouseEvent, id: string) => {
    e.stopPropagation();
    deleteNotification(id);
  };

  const handleViewAll = () => {
    onClose();
    navigate('/notifications');
  };

  const displayed = notifications.slice(0, PANEL_LIMIT);

  return (
    <Popover
      open={Boolean(anchorEl)}
      anchorEl={anchorEl}
      onClose={onClose}
      anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      transformOrigin={{ vertical: 'top', horizontal: 'right' }}
      slotProps={{ paper: { sx: { width: 360, borderRadius: 2, boxShadow: 4 } } }}
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
        <>
          <List disablePadding sx={{ overflowY: 'auto', maxHeight: 420 }}>
            {displayed.map((item, idx) => {
              const cfg = getNotifConfig(item);
              const isStock = isStockNotification(item);
              const isStaffMgmt = isStaffManagementNotification(item);
              const isSystem = isStock || isStaffMgmt;
              const jsxMessage = isStock
                ? renderStockMessageJSX(
                    item.metadata as { actor_name: string; service_center_name: string; action_type: string },
                    isViewerStaff,
                  )
                : isStaffMgmt
                  ? renderStaffManagementMessageJSX(item.metadata as { actor_name: string; target_name: string; action_type: string })
                  : null;
              return (
                <Box key={item.id}>
                  <ListItemButton
                    onClick={() => handleItemClick(item)}
                    sx={{
                      px: 2,
                      py: 1.5,
                      alignItems: 'flex-start',
                      gap: 1.5,
                      '&:hover': { filter: 'brightness(0.96)' },
                    }}
                  >
                    {/* Status color dot */}
                    <StatusDot item={item} />

                    {/* Content */}
                    <Box sx={{ flex: 1, minWidth: 0 }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        {isSystem ? (
                          <Chip label="ระบบ" size="small" sx={{ height: 20, fontSize: '0.68rem', borderRadius: 1 }} />
                        ) : (
                          <Typography
                            variant="body2"
                            fontWeight={item.is_read ? 400 : 600}
                            sx={{ color: item.is_read ? 'text.primary' : '#FF9F6B' }}
                            noWrap
                          >
                            {cfg.label}
                          </Typography>
                        )}
                        {!item.is_read && (
                          <Box sx={{ width: 6, height: 6, borderRadius: '50%', bgcolor: '#F44336', flexShrink: 0 }} />
                        )}
                      </Box>
                      {isSystem && (
                        <Typography
                          variant="body2"
                          fontWeight={item.is_read ? 400 : 600}
                          sx={{ color: item.is_read ? 'text.primary' : '#FF9F6B', mt: 0.25, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
                        >
                          {jsxMessage}
                        </Typography>
                      )}
                      {!isSystem && (
                        <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }} noWrap>
                          {item.reference_number}
                        </Typography>
                      )}
                      <Typography variant="caption" color="text.disabled">
                        {formatRelativeTime(item.created_at)}
                      </Typography>
                    </Box>

                    {/* Delete button */}
                    <IconButton
                      size="small"
                      onClick={(e) => handleDelete(e, item.id)}
                      sx={{ color: 'text.disabled', '&:hover': { color: 'error.main' }, flexShrink: 0, mt: '-4px', mr: '-4px' }}
                    >
                      <DeleteOutlineIcon fontSize="small" />
                    </IconButton>
                  </ListItemButton>
                  {idx < displayed.length - 1 && <Divider />}
                </Box>
              );
            })}
          </List>

          {/* Footer: always show "ดูทั้งหมด" when there are notifications */}
          {(
            <Box sx={{ borderTop: '1px solid', borderColor: 'divider' }}>
              <Button
                fullWidth
                size="small"
                onClick={handleViewAll}
                sx={{ py: 1.2, fontSize: '0.8rem', textTransform: 'none', color: 'text.secondary' }}
              >
                ดูทั้งหมด ({notifications.length} รายการ)
              </Button>
            </Box>
          )}
        </>
      )}
    </Popover>
  );
}
