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

  // Verify caller is an authenticated staff user
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }

  // Parse request body
  let body: { request_id?: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }

  const { request_id } = body;
  if (!request_id || typeof request_id !== 'string' || request_id.trim() === '') {
    return jsonResponse({ error: 'request_id is required' }, 400);
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
    return jsonResponse({ error: 'Request not found' }, 404);
  }

  const ref: string = requestRow.reference_number;

  // Compute HMAC-SHA256 signature
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

  const signatureBuffer = await crypto.subtle.sign(
    'HMAC',
    keyMaterial,
    new TextEncoder().encode(ref)
  );

  const sig = Array.from(new Uint8Array(signatureBuffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  const payload = JSON.stringify({ ref, sig });

  return jsonResponse({ payload });
});
