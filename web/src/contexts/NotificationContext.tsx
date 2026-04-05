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

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type RequestStatus =
  | 'pending'
  | 'preparing'
  | 'ready'
  | 'completed'
  | 'cancelled_by_user'
  | 'cancelled_by_staff';

export interface NotificationItem {
  id: string;
  request_id: string;
  reference_number: string;
  event_type: RequestStatus;
  created_at: string;
  is_read: boolean;
}

interface NotificationContextValue {
  notifications: NotificationItem[];
  unreadCount: number;
  toastOpen: boolean;
  toastMessage: string;
  toastEventType: RequestStatus | null;
  closeToast: () => void;
  markAsRead: (id: string) => void;
  markAllAsRead: () => void;
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

  const readIdsRef = useRef<Set<string>>(new Set());
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [readIds, setReadIds] = useState<Set<string>>(new Set());
  const [toastOpen, setToastOpen] = useState(false);
  const [toastMessage, setToastMessage] = useState('');
  const [toastEventType, setToastEventType] = useState<RequestStatus | null>(null);

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
  useEffect(() => {
    if (!userId) return;

    let cancelled = false;

    (async () => {
      const [{ data: notifData }, { data: readsData }] = await Promise.all([
        supabase
          .from('notifications')
          .select('id, request_id, reference_number, event_type, created_at')
          .order('created_at', { ascending: false })
          .limit(MAX_NOTIFICATIONS),
        supabase
          .from('notification_reads')
          .select('notification_id')
          .eq('staff_user_id', userId),
      ]);

      if (cancelled) return;

      const ids = new Set<string>((readsData ?? []).map(r => r.notification_id as string));
      setReadIds(ids);

      setNotifications(
        (notifData ?? []).map(r => ({
          ...(r as Omit<NotificationItem, 'is_read'>),
          is_read: ids.has(r.id as string),
        }))
      );
    })();

    return () => { cancelled = true; };
  }, [userId]);

  // Realtime: new notification inserted
  useEffect(() => {
    if (!userId) return;

    const channel = supabase
      .channel('notification-inserts')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'notifications' },
        (payload) => {
          const row = payload.new as Omit<NotificationItem, 'is_read'>;
          const item: NotificationItem = { ...row, is_read: false };
          setNotifications(prev => [item, ...prev].slice(0, MAX_NOTIFICATIONS));
          setToastEventType(row.event_type);
          setToastMessage(buildToastMessage(row.event_type, row.reference_number));
          setToastOpen(true);
          playNotificationSound();
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
          table: 'notification_reads',
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
    await supabase.from('notification_reads').upsert(
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
    await supabase.from('notification_reads').upsert(
      unread.map(n => ({ notification_id: n.id, staff_user_id: userId })),
      { onConflict: 'notification_id,staff_user_id' }
    );
  }, [userId, notifications]);

  const closeToast = useCallback(() => setToastOpen(false), []);

  const unreadCount = notifications.filter(n => !n.is_read).length;

  return (
    <NotificationContext.Provider
      value={{ notifications, unreadCount, toastOpen, toastMessage, toastEventType, closeToast, markAsRead, markAllAsRead }}
    >
      {children}
    </NotificationContext.Provider>
  );
}

export function useNotification(): NotificationContextValue {
  const ctx = useContext(NotificationContext);
  if (!ctx) throw new Error('useNotification must be used inside <NotificationProvider>');
  return ctx;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

export const STATUS_CONFIG: Record<RequestStatus, { label: string; color: string; bg: string }> = {
  pending:            { label: 'คำขอใหม่',              color: '#E65100', bg: '#FFF3E0' },
  preparing:          { label: 'กำลังเตรียม',           color: '#0D47A1', bg: '#E3F2FD' },
  ready:              { label: 'รอรับ',               color: '#6A1B9A', bg: '#F3E5F5' },
  completed:          { label: 'เสร็จสิ้น',             color: '#1B5E20', bg: '#E8F5E9' },
  cancelled_by_user:  { label: 'ยกเลิกโดยผู้ใช้',       color: '#616161', bg: '#F5F5F5' },
  cancelled_by_staff: { label: 'ยกเลิกโดยเจ้าหน้าที่', color: '#616161', bg: '#F5F5F5' },
};

function buildToastMessage(eventType: RequestStatus, referenceNumber: string): string {
  const label = STATUS_CONFIG[eventType]?.label ?? eventType;
  return `${label}: ${referenceNumber}`;
}
