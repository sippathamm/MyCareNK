export const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

export interface ApiResponse<T = undefined> {
  code: number;
  status: 'success' | 'error';
  message: string;
  result?: T;
}

export function jsonResponse<T = undefined>(
  httpStatus: number,
  responseStatus: 'success' | 'error',
  message: string,
  result?: T
): Response {
  const body: ApiResponse<T> = {
    code: httpStatus,
    status: responseStatus,
    message,
    ...(result !== undefined && { result }),
  };

  return new Response(JSON.stringify(body), {
    status: httpStatus,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}
