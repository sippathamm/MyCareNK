import { createClient } from 'jsr:@supabase/supabase-js@2';
import { CORS_HEADERS, jsonResponse } from '../_shared/response.ts';

/** Constant-time string comparison to prevent timing oracle attacks */
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  const aBytes = new TextEncoder().encode(a);
  const bBytes = new TextEncoder().encode(b);
  let diff = 0;
  for (let i = 0; i < aBytes.length; i++) {
    diff |= aBytes[i] ^ bBytes[i];
  }
  return diff === 0;
}

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

  // Verify caller is an authenticated user (from user app)
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) {
    return jsonResponse(401, 'error', 'กรุณาเข้าสู่ระบบ');
  }

  // Parse body
  let body: { payload?: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, 'error', 'QR Code ไม่ถูกต้อง');
  }

  if (!body.payload || typeof body.payload !== 'string') {
    return jsonResponse(400, 'error', 'QR Code ไม่ถูกต้อง');
  }

  // Parse inner payload
  let inner: { ref?: unknown; sig?: unknown };
  try {
    inner = JSON.parse(body.payload);
  } catch {
    return jsonResponse(400, 'error', 'QR Code ไม่ถูกต้อง');
  }

  const { ref, sig } = inner;

  // Input sanitization (#52): ref must be non-empty string, sig must be 64-char hex
  if (!ref || typeof ref !== 'string' || ref.trim() === '') {
    return jsonResponse(400, 'error', 'QR Code ไม่ถูกต้อง');
  }
  if (!sig || typeof sig !== 'string' || !/^[0-9a-f]{64}$/.test(sig)) {
    return jsonResponse(400, 'error', 'QR Code ไม่ถูกต้อง');
  }

  // Recompute expected HMAC-SHA256 (#56)
  const secretKey = Deno.env.get('SIGNATURE_SECRET_KEY');
  if (!secretKey) {
    return jsonResponse(500, 'error', 'เกิดข้อผิดพลาดของระบบ กรุณาลองใหม่');
  }

  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secretKey),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const expectedBuffer = await crypto.subtle.sign(
    'HMAC',
    keyMaterial,
    new TextEncoder().encode(ref)
  );

  const expectedSig = Array.from(new Uint8Array(expectedBuffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  // Timing-safe comparison (#56) — invalid signature means fake/tampered QR
  if (!timingSafeEqual(expectedSig, sig)) {
    return jsonResponse(400, 'error', 'QR Code ไม่ถูกต้อง');
  }

  // Signature verified — look up request via service-role client
  const serviceClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const { data: requestRow, error: dbError } = await serviceClient
    .from('condom_requests')
    .select('id, user_id, request_status')
    .eq('reference_number', ref)
    .single();

  if (dbError || !requestRow) {
    return jsonResponse(404, 'error', 'ไม่พบคำขอ');
  }

  // Strict ownership check (#55): request must belong to the authenticated user
  if (requestRow.user_id !== user.id) {
    return jsonResponse(403, 'error', 'QR Code นี้ไม่ใช่ของคุณ');
  }

  // Only allow completing a 'ready' request (prevents replay/double-completion)
  if (requestRow.request_status !== 'ready') {
    return jsonResponse(409, 'error', 'ไม่สามารถรับสินค้าได้ในสถานะนี้');
  }

  // Mark as completed (#55)
  const { error: updateError } = await serviceClient
    .from('condom_requests')
    .update({ request_status: 'completed' })
    .eq('id', requestRow.id);

  if (updateError) {
    return jsonResponse(500, 'error', 'เกิดข้อผิดพลาดของระบบ กรุณาลองใหม่');
  }

  return jsonResponse(200, 'success', 'รับสินค้าสำเร็จ', { reference_number: ref });
});
