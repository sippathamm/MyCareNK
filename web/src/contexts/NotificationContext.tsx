import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react';
import { supabase } from '../lib/supabase';

interface NotificationContextValue {
  unreadCount: number;
  toastOpen: boolean;
  toastMessage: string;
  clearUnread: () => void;
  closeToast: () => void;
}

const NotificationContext = createContext<NotificationContextValue | null>(null);

function playBeep(): void {
  try {
    const ctx = new AudioContext();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.type = 'sine';
    osc.frequency.setValueAtTime(880, ctx.currentTime);
    gain.gain.setValueAtTime(0.3, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.5);
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.5);
    osc.onended = () => ctx.close();
  } catch {
    // AudioContext may be blocked until user interaction — silently ignore
  }
}

export function NotificationProvider({ children }: { children: ReactNode }) {
  const [unreadCount, setUnreadCount] = useState(0);
  const [toastOpen, setToastOpen] = useState(false);
  const [toastMessage, setToastMessage] = useState('');

  const clearUnread = useCallback(() => setUnreadCount(0), []);
  const closeToast = useCallback(() => setToastOpen(false), []);

  useEffect(() => {
    const channel = supabase
      .channel('notification-condom-requests')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'condom_requests' },
        (payload) => {
          const row = payload.new as Record<string, unknown>;
          const ref = row.reference_number as string | undefined;
          setUnreadCount(prev => prev + 1);
          setToastMessage(`คำขอใหม่${ref ? `: ${ref}` : ''}`);
          setToastOpen(true);
          playBeep();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  return (
    <NotificationContext.Provider value={{ unreadCount, toastOpen, toastMessage, clearUnread, closeToast }}>
      {children}
    </NotificationContext.Provider>
  );
}

export function useNotification(): NotificationContextValue {
  const ctx = useContext(NotificationContext);
  if (!ctx) {
    throw new Error('useNotification must be used inside <NotificationProvider>');
  }
  return ctx;
}
