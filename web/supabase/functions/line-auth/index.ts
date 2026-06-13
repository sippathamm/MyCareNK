import { createClient } from 'jsr:@supabase/supabase-js@2';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse<T = undefined>(
  httpStatus: number,
  responseStatus: 'success' | 'error',
  message: string,
  result?: T
): Response {
  const body = {
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

  const authRes = await fetch(`${Deno.env.get('SUPABASE_URL')}/auth/v1/user`, {
    headers: {
      Authorization: authHeader,
      apikey: Deno.env.get('SUPABASE_ANON_KEY')!,
    },
  });

  if (!authRes.ok) {
    return jsonResponse(401, 'error', 'กรุณาเข้าสู่ระบบ');
  }

  const user = await authRes.json();

  let body: { code?: string; redirect_uri?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, 'error', 'ข้อมูลคำขอไม่ถูกต้อง');
  }

  const { code, redirect_uri } = body;
  if (!code || !redirect_uri) {
    return jsonResponse(400, 'error', 'ข้อมูลไม่ครบถ้วน');
  }

  const channelId = Deno.env.get('LINE_LOGIN_CHANNEL_ID');
  const channelSecret = Deno.env.get('LINE_LOGIN_CHANNEL_SECRET');
  if (!channelId || !channelSecret) {
    return jsonResponse(500, 'error', 'การตั้งค่า LINE ไม่สมบูรณ์');
  }

  // Exchange authorization code for access token
  const tokenRes = await fetch('https://api.line.me/oauth2/v2.1/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri,
      client_id: channelId,
      client_secret: channelSecret,
    }),
  });

  if (!tokenRes.ok) {
    const errBody = await tokenRes.text();
    console.error('LINE token exchange failed:', errBody);
    return jsonResponse(400, 'error', 'ไม่สามารถเชื่อมต่อ LINE ได้ กรุณาลองใหม่อีกครั้ง');
  }

  const tokenData: { access_token: string } = await tokenRes.json();

  // Fetch LINE profile (userId, displayName, pictureUrl)
  const profileRes = await fetch('https://api.line.me/v2/profile', {
    headers: { Authorization: `Bearer ${tokenData.access_token}` },
  });

  if (!profileRes.ok) {
    return jsonResponse(400, 'error', 'ไม่สามารถดึงข้อมูล LINE ได้');
  }

  const lineProfile: {
    userId: string;
    displayName: string;
    pictureUrl?: string;
  } = await profileRes.json();

  const serviceClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const { error } = await serviceClient
    .from('staff_profiles')
    .update({
      line_user_id: lineProfile.userId,
      line_display_name: lineProfile.displayName,
      line_picture_url: lineProfile.pictureUrl ?? null,
    })
    .eq('staff_user_id', user.id);

  if (error) {
    // Unique constraint: this LINE account is already linked to another staff
    if (error.code === '23505') {
      return jsonResponse(409, 'error', 'บัญชี LINE นี้ถูกเชื่อมต่อกับบัญชีอื่นแล้ว');
    }
    console.error('DB update error:', error);
    return jsonResponse(500, 'error', 'เกิดข้อผิดพลาดภายใน');
  }

  return jsonResponse(200, 'success', 'เชื่อมต่อ LINE สำเร็จ', {
    line_user_id: lineProfile.userId,
    line_display_name: lineProfile.displayName,
    line_picture_url: lineProfile.pictureUrl ?? null,
  });
});
