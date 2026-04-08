import { useState, useCallback } from 'react';
import { supabase } from '../lib/supabase';

interface SignPayloadState {
  payload: string | null;
  loading: boolean;
  error: string | null;
}

export function useSignPayload() {
  const [state, setState] = useState<SignPayloadState>({
    payload: null,
    loading: false,
    error: null,
  });

  const sign = useCallback(async (requestId: string): Promise<string | null> => {
    setState({ payload: null, loading: true, error: null });

    const { data, error } = await supabase.functions.invoke<{ payload: string }>('sign', {
      body: { request_id: requestId },
    });

    if (error || !data?.payload) {
      const message = error?.message ?? 'ไม่สามารถสร้าง QR Code ได้ กรุณาลองใหม่';
      setState({ payload: null, loading: false, error: message });
      return null;
    }

    setState({ payload: data.payload, loading: false, error: null });
    return data.payload;
  }, []);

  const reset = useCallback(() => {
    setState({ payload: null, loading: false, error: null });
  }, []);

  return { ...state, sign, reset };
}
