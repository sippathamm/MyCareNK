import { createClient } from 'jsr:@supabase/supabase-js@2';
import { CORS_HEADERS, jsonResponse } from '../_shared/response.ts';

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  if (req.method !== 'POST') {
    return jsonResponse(405, 'error', 'วิธีการร้องขอไม่ถูกต้อง');
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return jsonResponse(401, 'error', 'กรุณาเข้าสู่ระบบ');
  }

  // Verify caller is an authenticated staff user
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) {
    return jsonResponse(401, 'error', 'กรุณาเข้าสู่ระบบ');
  }

  // Parse request body
  let body: { request_id?: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, 'error', 'ข้อมูลคำขอไม่ถูกต้อง');
  }

  const { request_id } = body;
  if (!request_id || typeof request_id !== 'string' || request_id.trim() === '') {
    return jsonResponse(400, 'error', 'ข้อมูลคำขอไม่ถูกต้อง');
  }

  // Look up reference_number via service-role client (bypasses RLS)
  const serviceClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const { data: requestRow, error: dbError } = await serviceClient
    .from('condom_requests')
    .select('reference_number')
    .eq('id', request_id)
    .single();

  if (dbError || !requestRow) {
    return jsonResponse(404, 'error', 'ไม่พบคำขอ');
  }

  const ref: string = requestRow.reference_number;

  // Compute HMAC-SHA256 signature
  const secretKey = Deno.env.get('SIGNATURE_SECRET_KEY');
  if (!secretKey) {
    console.error('[sign] SIGNATURE_SECRET_KEY is not set');
    return jsonResponse(500, 'error', 'เกิดข้อผิดพลาดของระบบ กรุณาลองใหม่');
  }

  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secretKey),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signatureBuffer = await crypto.subtle.sign(
    'HMAC',
    keyMaterial,
    new TextEncoder().encode(ref)
  );

  const sig = Array.from(new Uint8Array(signatureBuffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  const payload = JSON.stringify({ ref, sig });

  return jsonResponse(200, 'success', 'สร้าง QR Code สำเร็จ', { payload });
});
