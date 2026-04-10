import { useState, useCallback } from 'react';
import { supabase } from '../lib/supabase';

interface ApiResponse<T = undefined> {
  code: number;
  status: 'success' | 'error';
  message: string;
  result?: T;
}

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

    const { data, error } = await supabase.functions.invoke<ApiResponse<{ payload: string }>>('sign', {
      body: { request_id: requestId },
    });

    if (error || data?.status !== 'success' || !data.result?.payload) {
      const message = data?.message ?? 'ไม่สามารถสร้าง QR Code ได้ กรุณาลองใหม่';
      setState({ payload: null, loading: false, error: message });
      return null;
    }

    setState({ payload: data.result.payload, loading: false, error: null });
    return data.result.payload;
  }, []);

  const reset = useCallback(() => {
    setState({ payload: null, loading: false, error: null });
  }, []);

  return { ...state, sign, reset };
}
