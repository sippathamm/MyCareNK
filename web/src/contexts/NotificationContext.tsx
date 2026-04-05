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

export interface NotificationItem {
  id: string;
  request_id: string;
  reference_number: string;
  event_type: 'new_request' | 'cancelled';
  created_at: string;
  is_read: boolean;
}

interface NotificationContextValue {
  notifications: NotificationItem[];
  unreadCount: number;
  panelOpen: boolean;
  setPanelOpen: (open: boolean) => void;
  toastOpen: boolean;
  toastMessage: string;
  closeToast: () => void;
  markAsRead: (id: string) => void;
  markAllAsRead: () => void;
}

// ---------------------------------------------------------------------------
// Audio — singleton AudioContext that resumes on first user interaction
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

  // Two-tone chime: 880 Hz → 1100 Hz
  osc.frequency.setValueAtTime(880, ctx.currentTime);
  osc.frequency.setValueAtTime(1100, ctx.currentTime + 0.15);
  gain.gain.setValueAtTime(0.25, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.4);
  osc.start(ctx.currentTime);
  osc.stop(ctx.currentTime + 0.4);
}

// ---------------------------------------------------------------------------
// Read-state helpers (localStorage, per-user)
// ---------------------------------------------------------------------------

function storageKey(userId: string) {
  return `notif_reads_${userId}`;
}

function loadReadIds(userId: string): Set<string> {
  try {
    const raw = localStorage.getItem(storageKey(userId));
    return raw ? new Set<string>(JSON.parse(raw) as string[]) : new Set();
  } catch {
    return new Set();
  }
}

function saveReadIds(userId: string, ids: Set<string>) {
  try {
    localStorage.setItem(storageKey(userId), JSON.stringify([...ids]));
  } catch { /* ignore quota errors */ }
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
  const [panelOpen, setPanelOpen] = useState(false);
  const [toastOpen, setToastOpen] = useState(false);
  const [toastMessage, setToastMessage] = useState('');

  // Load persisted read-state when user is known
  useEffect(() => {
    if (!userId) return;
    readIdsRef.current = loadReadIds(userId);
  }, [userId]);

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

  // Enrich raw rows with is_read flag
  const enrich = useCallback(
    (rows: Omit<NotificationItem, 'is_read'>[]): NotificationItem[] =>
      rows.map(r => ({ ...r, is_read: readIdsRef.current.has(r.id) })),
    []
  );

  // Initial fetch
  useEffect(() => {
    if (!userId) return;

    supabase
      .from('notifications')
      .select('id, request_id, reference_number, event_type, created_at')
      .order('created_at', { ascending: false })
      .limit(MAX_NOTIFICATIONS)
      .then(({ data }) => {
        if (data) setNotifications(enrich(data as Omit<NotificationItem, 'is_read'>[]));
      });
  }, [userId, enrich]);

  // Realtime subscription on notifications table
  useEffect(() => {
    if (!userId) return;

    const channel = supabase
      .channel('notification-panel')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'notifications' },
        (payload) => {
          const row = payload.new as Omit<NotificationItem, 'is_read'>;
          const item: NotificationItem = { ...row, is_read: false };

          setNotifications(prev => [item, ...prev].slice(0, MAX_NOTIFICATIONS));

          const label = row.event_type === 'new_request' ? 'คำขอใหม่' : 'ยกเลิกคำขอ';
          setToastMessage(`${label}: ${row.reference_number}`);
          setToastOpen(true);
          playNotificationSound();
        }
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [userId]);

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  const markAsRead = useCallback((id: string) => {
    if (!userId) return;
    readIdsRef.current = new Set([...readIdsRef.current, id]);
    saveReadIds(userId, readIdsRef.current);
    setNotifications(prev =>
      prev.map(n => n.id === id ? { ...n, is_read: true } : n)
    );
  }, [userId]);

  const markAllAsRead = useCallback(() => {
    if (!userId) return;
    setNotifications(prev => {
      const allIds = new Set([...readIdsRef.current, ...prev.map(n => n.id)]);
      readIdsRef.current = allIds;
      saveReadIds(userId, allIds);
      return prev.map(n => ({ ...n, is_read: true }));
    });
  }, [userId]);

  const closeToast = useCallback(() => setToastOpen(false), []);

  const unreadCount = notifications.filter(n => !n.is_read).length;

  return (
    <NotificationContext.Provider
      value={{ notifications, unreadCount, panelOpen, setPanelOpen, toastOpen, toastMessage, closeToast, markAsRead, markAllAsRead }}
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
