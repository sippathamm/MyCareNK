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
  const { role, profile, loading: roleLoading } = useRoleAccess();
  const serviceCenter = profile?.service_center ?? null;

  const readIdsRef = useRef<Set<string>>(new Set());
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [readIds, setReadIds] = useState<Set<string>>(new Set());
  const [toastOpen, setToastOpen] = useState(false);
  const [toastMessage, setToastMessage] = useState('');
  const [toastEventType, setToastEventType] = useState<RequestStatus | null>(null);
  const [toastIsAppointment, setToastIsAppointment] = useState(false);
  const [toastAppointmentEventType, setToastAppointmentEventType] = useState<AppointmentEventType | null>(null);

  // Keep ref in sync for stable callbacks
  useEffect(() => { readIdsRef.current = readIds; }, [readIds]);

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

  // Initial load: fetch notifications + read state from DB
  // RLS handles filtering automatically:
  //   staff       → notify_staff=true AND service_center=own SC
  //   admin/super → all rows
  useEffect(() => {
    if (!userId || roleLoading) return;

    let cancelled = false;

    (async () => {
      const [{ data: readsData }, { data: notifData }] = await Promise.all([
        supabase
          .from('staff_notification_reads')
          .select('notification_id')
          .eq('staff_user_id', userId),
        supabase
          .from('staff_notifications')
          .select('id, source_type, source_id, reference_number, event_type, notify_staff, service_center, metadata, created_at')
          .order('created_at', { ascending: false })
          .limit(MAX_NOTIFICATIONS),
      ]);

      if (cancelled) return;

      const ids = new Set<string>((readsData ?? []).map(r => r.notification_id));
      setReadIds(ids);
      setNotifications((notifData ?? []).map(r => ({ ...r, is_read: ids.has(r.id) })));
    })();

    return () => { cancelled = true; };
  }, [userId, roleLoading]);

  // Realtime: new notification inserted
  // staff → server-side filter by service_center; RLS additionally enforces notify_staff=true
  // admin/superadmin → no filter, receive all events
  useEffect(() => {
    if (!userId || roleLoading) return;

    const scFilter = role === 'staff' && serviceCenter
      ? `service_center=eq.${serviceCenter}`
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
          const aptEventType = isAppointment ? (row.event_type as AppointmentEventType) : null;
          const item: NotificationItem = { ...row, is_read: false };
          setNotifications(prev => [item, ...prev].slice(0, MAX_NOTIFICATIONS));
          setToastIsAppointment(isAppointment);
          setToastAppointmentEventType(aptEventType);
          setToastEventType(isAppointment ? null : row.event_type as RequestStatus);
          setToastMessage(buildToastMessage(row.event_type as RequestStatus, row.reference_number, isAppointment, aptEventType));
          setToastOpen(true);
          playNotificationSound();
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [userId, role, serviceCenter, roleLoading]);

  // Realtime: notification deleted (sync across devices)
  useEffect(() => {
    if (!userId) return;

    const channel = supabase
      .channel('notification-deletes')
      .on(
        'postgres_changes',
        { event: 'DELETE', schema: 'public', table: 'staff_notifications' },
        (payload) => {
          const deletedId = (payload.old as { id?: string }).id;
          if (!deletedId) return;
          setNotifications(prev => prev.filter(n => n.id !== deletedId));
          setReadIds(prev => { const next = new Set(prev); next.delete(deletedId); return next; });
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
    setToastAppointmentEventType(null);
  }, []);

  const deleteNotification = useCallback(async (id: string) => {
    // Optimistic update
    setNotifications(prev => prev.filter(n => n.id !== id));
    setReadIds(prev => { const next = new Set(prev); next.delete(id); return next; });
    // Delete from DB (cascade deletes staff_notification_reads rows too)
    await supabase.from('staff_notifications').delete().eq('id', id);
  }, []);

  const unreadCount = notifications.filter(n => !n.is_read).length;

  return (
    <NotificationContext.Provider
      value={{ notifications, unreadCount, toastOpen, toastMessage, toastEventType, toastIsAppointment, toastAppointmentEventType, closeToast, markAsRead, markAllAsRead, deleteNotification }}
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
