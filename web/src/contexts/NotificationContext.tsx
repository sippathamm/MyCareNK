import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from './AuthContext';
import { useRoleAccess } from '../hooks/useRoleAccess';
import type { Enums, Tables } from '../lib/database.types';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type RequestStatus = Enums<'request_status'>;
export type AppointmentEventType = Enums<'appointment_status'>;

export type NotificationItem = Tables<'staff_notifications'> & { is_read: boolean };

// eslint-disable-next-line react-refresh/only-export-components
export function isAppointmentNotification(item: NotificationItem): boolean {
  return item.source_type === 'doctor_appointment';
}

// eslint-disable-next-line react-refresh/only-export-components
export function isStockNotification(item: NotificationItem): boolean {
  return item.source_type === 'stock_operation';
}

// eslint-disable-next-line react-refresh/only-export-components
export function isStaffManagementNotification(item: NotificationItem): boolean {
  return item.source_type === 'staff_management';
}

// eslint-disable-next-line react-refresh/only-export-components
export function isServiceCenterManagementNotification(item: NotificationItem): boolean {
  return item.source_type === 'service_center_management';
}

// eslint-disable-next-line react-refresh/only-export-components
export const STOCK_OPERATION_CONFIG: Record<string, { label: string; color: string; bg: string }> = {
  restock:    { label: 'เติมสต็อก', color: '#4CAF50', bg: '#EBF7EC' },
  adjustment: { label: 'ปรับสต็อก', color: '#FF9800', bg: '#FFF3E0' },
};

// eslint-disable-next-line react-refresh/only-export-components
export const STAFF_MANAGEMENT_CONFIG: { label: string; color: string; bg: string } = {
  label: 'การจัดการเจ้าหน้าที่',
  color: '#5C6BC0',
  bg: '#EDE7F6',
};

// eslint-disable-next-line react-refresh/only-export-components
export const SERVICE_CENTER_MANAGEMENT_CONFIG: { label: string; color: string; bg: string } = {
  label: 'การจัดการสถานบริการ',
  color: '#0288D1',
  bg: '#E3F2FD',
};

// eslint-disable-next-line react-refresh/only-export-components
export const APPOINTMENT_STATUS_CONFIG: Record<AppointmentEventType, { label: string; color: string; bg: string }> = {
  pending:            { label: 'นัดหมายใหม่',           color: '#FF9F6B', bg: '#FFF0E6' },
  confirmed:          { label: 'ยืนยันนัดหมาย',           color: '#BA68C8', bg: '#F5EAF9' },
  completed:          { label: 'นัดหมายเสร็จสิ้น',        color: '#81C784', bg: '#EBF7EC' },
  cancelled_by_user:  { label: 'ยกเลิกโดยผู้ใช้',        color: '#9E9E9E', bg: '#F5F5F5' },
  cancelled_by_staff: { label: 'ยกเลิกโดยเจ้าหน้าที่',   color: '#9E9E9E', bg: '#F5F5F5' },
};

interface NotificationContextValue {
  notifications: NotificationItem[];
  unreadCount: number;
  toastOpen: boolean;
  toastMessage: string;
  toastEventType: RequestStatus | null;
  toastIsAppointment: boolean;
  toastAppointmentEventType: AppointmentEventType | null;
  toastIsStock: boolean;
  toastIsStaffManagement: boolean;
  toastIsServiceCenterManagement: boolean;
  closeToast: () => void;
  markAsRead: (id: string) => void;
  markAllAsRead: () => void;
  deleteNotification: (id: string) => void;
}

// ---------------------------------------------------------------------------
// Audio — singleton AudioContext, resumes on first user interaction
// ---------------------------------------------------------------------------

let _audioCtx: AudioContext | null = null;

function getAudioCtx(): AudioContext | null {
  try {
    if (!_audioCtx) _audioCtx = new AudioContext();
    return _audioCtx;
  } catch {
    return null;
  }
}

async function playNotificationSound(): Promise<void> {
  const ctx = getAudioCtx();
  if (!ctx) return;
  if (ctx.state === 'suspended') {
    try { await ctx.resume(); } catch { return; }
  }
  if (ctx.state !== 'running') return;

  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.type = 'sine';
  osc.frequency.setValueAtTime(880, ctx.currentTime);
  osc.frequency.setValueAtTime(1100, ctx.currentTime + 0.15);
  gain.gain.setValueAtTime(0.25, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.4);
  osc.start(ctx.currentTime);
  osc.stop(ctx.currentTime + 0.4);
}

// ---------------------------------------------------------------------------
// Context
// ---------------------------------------------------------------------------

const NotificationContext = createContext<NotificationContextValue | null>(null);

const MAX_NOTIFICATIONS = 50;

export function NotificationProvider({ children }: { children: ReactNode }) {
  const { session } = useAuth();
  const userId = session?.user?.id ?? '';
  const { role, loading: roleLoading, serviceCenters, isSuperadmin, isAdmin } = useRoleAccess();

  const readIdsRef = useRef<Set<string>>(new Set());
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [readIds, setReadIds] = useState<Set<string>>(new Set());
  const [toastOpen, setToastOpen] = useState(false);
  const [toastMessage, setToastMessage] = useState('');
  const [toastEventType, setToastEventType] = useState<RequestStatus | null>(null);
  const [toastIsAppointment, setToastIsAppointment] = useState(false);
  const [toastAppointmentEventType, setToastAppointmentEventType] = useState<AppointmentEventType | null>(null);
  const [toastIsStock, setToastIsStock] = useState(false);
  const [toastIsStaffManagement, setToastIsStaffManagement] = useState(false);
  const [toastIsServiceCenterManagement, setToastIsServiceCenterManagement] = useState(false);

  // Keep ref in sync for stable callbacks
  useEffect(() => { readIdsRef.current = readIds; }, [readIds]);

  // Request browser Notification permission once if not yet decided
  useEffect(() => {
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission().catch(() => {});
    }
  }, []);

  // Resume AudioContext on any user interaction (bypass browser autoplay policy)
  useEffect(() => {
    const resume = () => {
      const ctx = getAudioCtx();
      if (ctx?.state === 'suspended') ctx.resume().catch(() => {});
    };
    window.addEventListener('click', resume);
    window.addEventListener('keydown', resume);
    return () => {
      window.removeEventListener('click', resume);
      window.removeEventListener('keydown', resume);
    };
  }, []);

  // Initial load: fetch notifications + read state + hidden state from DB
  // RLS handles filtering automatically:
  //   staff       → service_center=own SC
  //   admin/super → all rows at own SC / everything
  useEffect(() => {
    if (!userId || roleLoading) return;

    let cancelled = false;

    (async () => {
      const [{ data: readsData }, { data: hiddenData }, { data: notifData }] = await Promise.all([
        supabase
          .from('staff_notification_reads')
          .select('notification_id')
          .eq('staff_user_id', userId),
        supabase
          .from('staff_notification_hidden')
          .select('notification_id')
          .eq('staff_user_id', userId),
        supabase
          .from('staff_notifications')
          .select('id, source_type, source_id, event_type, service_center, metadata, created_at')
          .order('created_at', { ascending: false })
          .limit(MAX_NOTIFICATIONS),
      ]);

      if (cancelled) return;

      const ids = new Set<string>((readsData ?? []).map(r => r.notification_id));
      const hiddenIds = new Set<string>((hiddenData ?? []).map(r => r.notification_id));
      setReadIds(ids);
      setNotifications(
        (notifData ?? [])
          .filter(r => !hiddenIds.has(r.id))
          .map(r => ({ ...r, is_read: ids.has(r.id) }))
      );
    })();

    return () => { cancelled = true; };
  }, [userId, roleLoading]);

  // Realtime: new notification inserted
  // staff → server-side filter by service_center; RLS enforces own SC
  // admin/superadmin → no filter, receive all events
  useEffect(() => {
    if (!userId || roleLoading) return;

    // staff: filter by own SC; admin: filter by their SCs array; superadmin: no filter
    const scFilter = isSuperadmin ? undefined
      : serviceCenters.length === 1 ? `service_center=eq.${serviceCenters[0]}`
      : serviceCenters.length > 1 ? `service_center=in.(${serviceCenters.join(',')})`
      : undefined;

    const channel = supabase
      .channel('notification-inserts')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'staff_notifications',
          ...(scFilter ? { filter: scFilter } : {}),
        },
        (payload) => {
          const row = payload.new as Tables<'staff_notifications'>;
          const isAppointment = row.source_type === 'doctor_appointment';
          const isStock = row.source_type === 'stock_operation';
          const isStaffMgmt = row.source_type === 'staff_management';
          const isSCMgmt = row.source_type === 'service_center_management';
          const aptEventType = isAppointment ? (row.event_type as AppointmentEventType) : null;
          const item: NotificationItem = { ...row, is_read: false };
          const message = isStock
            ? buildStockMessage(
                row.metadata as { actor_name: string; service_center_name: string; action_type: string },
                !isAdmin && !isSuperadmin,
              )
            : isStaffMgmt
              ? buildStaffManagementMessage(row.metadata as { actor_name: string; target_name: string; action_type: string })
              : isSCMgmt
                ? buildServiceCenterManagementMessage(row.metadata as { actor_name: string; action_type: string; service_center_name: string })
                : buildToastMessage(row.event_type as RequestStatus, (row.metadata as { reference_number?: string })?.reference_number ?? '', isAppointment, aptEventType);
          setNotifications(prev => [item, ...prev].slice(0, MAX_NOTIFICATIONS));
          setToastIsAppointment(isAppointment);
          setToastIsStock(isStock);
          setToastIsStaffManagement(isStaffMgmt);
          setToastIsServiceCenterManagement(isSCMgmt);
          setToastAppointmentEventType(aptEventType);
          setToastEventType(isAppointment || isStock || isStaffMgmt || isSCMgmt ? null : row.event_type as RequestStatus);
          setToastMessage(message);
          setToastOpen(true);
          playNotificationSound();
          if ('Notification' in window && document.hidden && Notification.permission === 'granted') {
            new Notification('MyCareNK — แจ้งเตือนใหม่', { body: message, icon: '/favicon.png', tag: row.id });
          }
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [userId, role, serviceCenters, isSuperadmin, isAdmin, roleLoading]);

  // Realtime: soft-delete hidden row inserted on another device → hide locally
  useEffect(() => {
    if (!userId) return;

    const channel = supabase
      .channel('notification-hidden-sync')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'staff_notification_hidden',
          filter: `staff_user_id=eq.${userId}`,
        },
        (payload) => {
          const { notification_id } = payload.new as { notification_id: string };
          setNotifications(prev => prev.filter(n => n.id !== notification_id));
          setReadIds(prev => { const next = new Set(prev); next.delete(notification_id); return next; });
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [userId]);

  // Realtime: read state synced from another device
  useEffect(() => {
    if (!userId) return;

    const channel = supabase
      .channel('notification-reads-sync')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'staff_notification_reads',
          filter: `staff_user_id=eq.${userId}`,
        },
        (payload) => {
          const { notification_id } = payload.new as { notification_id: string };
          setReadIds(prev => {
            if (prev.has(notification_id)) return prev;
            const next = new Set([...prev, notification_id]);
            return next;
          });
          setNotifications(prev =>
            prev.map(n => n.id === notification_id ? { ...n, is_read: true } : n)
          );
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [userId]);

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  const markAsRead = useCallback(async (id: string) => {
    if (!userId || readIdsRef.current.has(id)) return;
    // Optimistic update
    setReadIds(prev => new Set([...prev, id]));
    setNotifications(prev => prev.map(n => n.id === id ? { ...n, is_read: true } : n));
    // Persist to DB
    await supabase.from('staff_notification_reads').upsert(
      { notification_id: id, staff_user_id: userId },
      { onConflict: 'notification_id,staff_user_id' }
    );
  }, [userId]);

  const markAllAsRead = useCallback(async () => {
    if (!userId) return;
    const unread = notifications.filter(n => !readIdsRef.current.has(n.id));
    if (unread.length === 0) return;
    // Optimistic update
    const newIds = new Set([...readIdsRef.current, ...unread.map(n => n.id)]);
    setReadIds(newIds);
    setNotifications(prev => prev.map(n => ({ ...n, is_read: true })));
    // Batch persist
    await supabase.from('staff_notification_reads').upsert(
      unread.map(n => ({ notification_id: n.id, staff_user_id: userId })),
      { onConflict: 'notification_id,staff_user_id' }
    );
  }, [userId, notifications]);

  const closeToast = useCallback(() => {
    setToastOpen(false);
    setToastIsAppointment(false);
    setToastIsStock(false);
    setToastIsStaffManagement(false);
    setToastIsServiceCenterManagement(false);
    setToastAppointmentEventType(null);
  }, []);

  const deleteNotification = useCallback(async (id: string) => {
    if (!userId) return;
    // Optimistic update
    setNotifications(prev => prev.filter(n => n.id !== id));
    setReadIds(prev => { const next = new Set(prev); next.delete(id); return next; });
    // Soft delete: insert into staff_notification_hidden (per-user isolation)
    await supabase.from('staff_notification_hidden').upsert(
      { notification_id: id, staff_user_id: userId },
      { onConflict: 'notification_id,staff_user_id' }
    );
  }, [userId]);

  const unreadCount = notifications.filter(n => !n.is_read).length;

  return (
    <NotificationContext.Provider
      value={{ notifications, unreadCount, toastOpen, toastMessage, toastEventType, toastIsAppointment, toastAppointmentEventType, toastIsStock, toastIsStaffManagement, toastIsServiceCenterManagement, closeToast, markAsRead, markAllAsRead, deleteNotification }}
    >
      {children}
    </NotificationContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useNotification(): NotificationContextValue {
  const ctx = useContext(NotificationContext);
  if (!ctx) throw new Error('useNotification must be used inside <NotificationProvider>');
  return ctx;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// eslint-disable-next-line react-refresh/only-export-components
export const STATUS_CONFIG: Record<RequestStatus, { label: string; color: string; bg: string }> = {
  pending:            { label: 'คำขอใหม่',              color: '#FF9F6B', bg: '#FFF0E6' },
  preparing:          { label: 'กำลังเตรียม',           color: '#64B5F6', bg: '#EBF4FF' },
  ready:              { label: 'รอรับ',               color: '#BA68C8', bg: '#F5EAF9' },
  completed:          { label: 'คำขอเสร็จสิ้น',          color: '#81C784', bg: '#EBF7EC' },
  cancelled_by_user:  { label: 'ยกเลิกโดยผู้ใช้',       color: '#9E9E9E', bg: '#F5F5F5' },
  cancelled_by_staff: { label: 'ยกเลิกโดยเจ้าหน้าที่', color: '#9E9E9E', bg: '#F5F5F5' },
};

function buildToastMessage(
  eventType: RequestStatus,
  referenceNumber: string,
  isAppointment = false,
  appointmentEventType: AppointmentEventType | null = null,
): string {
  const label = isAppointment
    ? (APPOINTMENT_STATUS_CONFIG[appointmentEventType ?? 'pending']?.label ?? 'นัดหมาย')
    : (STATUS_CONFIG[eventType]?.label ?? eventType);
  return `${label}: ${referenceNumber}`;
}

// eslint-disable-next-line react-refresh/only-export-components
export function buildStockMessage(
  metadata: { actor_name: string; service_center_name: string; action_type: string },
  isViewerStaff: boolean,
): string {
  const actionLabel = metadata.action_type === 'restock' ? 'เติมสต็อก' : 'ปรับสต็อก';
  if (isViewerStaff) {
    return `สถานบริการของคุณถูก${actionLabel} โดย ${metadata.actor_name}`;
  }
  return `สถานบริการ ${metadata.service_center_name} ถูก${actionLabel} โดย ${metadata.actor_name}`;
}

// eslint-disable-next-line react-refresh/only-export-components
export function buildStaffManagementMessage(
  metadata: { actor_name: string; target_name: string; action_type: string },
): string {
  const { actor_name, target_name, action_type } = metadata;
  switch (action_type) {
    case 'add':          return `${actor_name} เพิ่ม ${target_name}`;
    case 'remove':       return `${actor_name} ลบ ${target_name}`;
    case 'edit_profile': return `${actor_name} แก้ไขโปรไฟล์ ${target_name}`;
    case 'edit_email':   return `${actor_name} แก้ไขอีเมล ${target_name}`;
    case 'edit_role':    return `${actor_name} แก้ไขระดับสิทธิ์ ${target_name}`;
    default:             return `${actor_name} แก้ไข ${target_name}`;
  }
}

// eslint-disable-next-line react-refresh/only-export-components
export function renderStockMessageJSX(
  metadata: { actor_name: string; service_center_name: string; action_type: string },
  isViewerStaff: boolean,
): ReactNode {
  const actionLabel = metadata.action_type === 'restock' ? 'เติมสต็อก' : 'ปรับสต็อก';
  if (isViewerStaff) {
    return <>สถานบริการของคุณถูก{actionLabel} โดย <strong>{metadata.actor_name}</strong></>;
  }
  return <>สถานบริการ <strong>{metadata.service_center_name}</strong> ถูก{actionLabel} โดย <strong>{metadata.actor_name}</strong></>;
}

// eslint-disable-next-line react-refresh/only-export-components
export function renderStaffManagementMessageJSX(
  metadata: { actor_name: string; target_name: string; action_type: string },
): ReactNode {
  const { actor_name, target_name, action_type } = metadata;
  const actor = <strong>{actor_name}</strong>;
  const target = <strong>{target_name}</strong>;
  switch (action_type) {
    case 'add':          return <>{actor} เพิ่ม {target}</>;
    case 'remove':       return <>{actor} ลบ {target}</>;
    case 'edit_profile': return <>{actor} แก้ไขโปรไฟล์ {target}</>;
    case 'edit_email':   return <>{actor} แก้ไขอีเมล {target}</>;
    case 'edit_role':    return <>{actor} แก้ไขระดับสิทธิ์ {target}</>;
    default:             return <>{actor} แก้ไข {target}</>;
  }
}

// eslint-disable-next-line react-refresh/only-export-components
export function getNotifTitle(item: NotificationItem): string {
  if (isStockNotification(item)) {
    return item.event_type === 'restock' ? 'เติมสต็อก' : 'ปรับสต็อก';
  }
  if (isStaffManagementNotification(item)) {
    const titles: Record<string, string> = {
      add:          'เพิ่มเจ้าหน้าที่',
      remove:       'ลบเจ้าหน้าที่',
      edit_profile: 'แก้ไขโปรไฟล์เจ้าหน้าที่',
      edit_email:   'แก้ไขอีเมลเจ้าหน้าที่',
      edit_role:    'แก้ไขระดับสิทธิ์',
    };
    return titles[item.event_type] ?? item.event_type;
  }
  if (isServiceCenterManagementNotification(item)) {
    return item.event_type === 'add' ? 'เพิ่มสถานบริการ' : 'ลบสถานบริการ';
  }
  return (item.metadata as { reference_number?: string })?.reference_number ?? '';
}

// eslint-disable-next-line react-refresh/only-export-components
export function buildServiceCenterManagementMessage(
  metadata: { actor_name: string; action_type: string; service_center_name: string },
): string {
  const { actor_name, action_type, service_center_name } = metadata;
  return action_type === 'add'
    ? `${actor_name} เพิ่มสถานบริการ ${service_center_name}`
    : `${actor_name} ลบสถานบริการ ${service_center_name}`;
}

// eslint-disable-next-line react-refresh/only-export-components
export function renderServiceCenterManagementMessageJSX(
  metadata: { actor_name: string; action_type: string; service_center_name: string },
): ReactNode {
  const { actor_name, action_type, service_center_name } = metadata;
  const actor = <strong>{actor_name}</strong>;
  const sc = <strong>{service_center_name}</strong>;
  return action_type === 'add'
    ? <>{actor} เพิ่มสถานบริการ {sc}</>
    : <>{actor} ลบสถานบริการ {sc}</>;
}
