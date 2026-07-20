import { useCallback, useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import type { Json } from '../lib/database.types';

export interface NotificationSetting {
  source_type: string;
  event_type: string;
  notify_staff: boolean;
  notify_admin: boolean;
  notify_superadmin: boolean;
}

export function useNotificationSettings(): {
  settings: NotificationSetting[];
  loading: boolean;
  error: string | null;
  save: (updated: NotificationSetting[]) => Promise<string | null>;
} {
  const [settings, setSettings] = useState<NotificationSetting[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      const { data, error: fetchErr } = await supabase
        .from('notification_settings')
        .select('source_type, event_type, notify_staff, notify_admin, notify_superadmin')
        .order('source_type')
        .order('event_type');
      if (cancelled) return;
      if (fetchErr) {
        setError(fetchErr.message);
      } else {
        setSettings(data ?? []);
      }
      setLoading(false);
    })();
    return () => { cancelled = true; };
  }, []);

  const save = useCallback(async (updated: NotificationSetting[]): Promise<string | null> => {
    const { error: rpcErr } = await supabase.rpc('update_notification_settings', {
      p_settings: updated as unknown as Json,
    });
    if (rpcErr) return rpcErr.message;
    setSettings(prev =>
      prev.map(s => {
        const u = updated.find(x => x.source_type === s.source_type && x.event_type === s.event_type);
        return u ? { ...s, ...u } : s;
      })
    );
    return null;
  }, []);

  return { settings, loading, error, save };
}
