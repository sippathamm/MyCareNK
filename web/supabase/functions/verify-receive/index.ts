import { createClient } from 'jsr:@supabase/supabase-js@2';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

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
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return jsonResponse({ error: 'Missing authorization header' }, 401);
  }

  // Verify caller is an authenticated user (from user app)
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }

  // Parse body
  let body: { payload?: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }

  if (!body.payload || typeof body.payload !== 'string') {
    return jsonResponse({ error: 'payload field is required and must be a string' }, 400);
  }

  // Parse inner payload
  let inner: { ref?: unknown; sig?: unknown };
  try {
    inner = JSON.parse(body.payload);
  } catch {
    return jsonResponse({ error: 'payload is not valid JSON' }, 400);
  }

  const { ref, sig } = inner;

  // Input sanitization (#52): ref must be non-empty string, sig must be 64-char hex
  if (!ref || typeof ref !== 'string' || ref.trim() === '') {
    return jsonResponse({ error: 'Invalid payload: ref is missing or empty' }, 400);
  }
  if (!sig || typeof sig !== 'string' || !/^[0-9a-f]{64}$/.test(sig)) {
    return jsonResponse({ error: 'Invalid payload: sig is missing or malformed' }, 400);
  }

  // Recompute expected HMAC-SHA256 (#56)
  const secretKey = Deno.env.get('SIGNATURE_SECRET_KEY');
  if (!secretKey) {
    return jsonResponse({ error: 'Server configuration error' }, 500);
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

  // Timing-safe comparison (#56)
  if (!timingSafeEqual(expectedSig, sig)) {
    return jsonResponse({ error: 'Invalid signature' }, 403);
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
    return jsonResponse({ error: 'Request not found' }, 404);
  }

  // Strict ownership check (#55): request must belong to the authenticated user
  if (requestRow.user_id !== user.id) {
    return jsonResponse({ error: 'Forbidden: request does not belong to you' }, 403);
  }

  // Only allow completing a 'ready' request (prevents replay/double-completion)
  if (requestRow.request_status !== 'ready') {
    return jsonResponse(
      { error: `Cannot complete request with status: ${requestRow.request_status}` },
      409
    );
  }

  // Mark as completed (#55)
  const { error: updateError } = await serviceClient
    .from('condom_requests')
    .update({ request_status: 'completed' })
    .eq('id', requestRow.id);

  if (updateError) {
    return jsonResponse({ error: 'Failed to update request status' }, 500);
  }

  return jsonResponse({ success: true, reference_number: ref });
});
