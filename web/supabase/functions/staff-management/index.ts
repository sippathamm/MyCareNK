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

  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) {
    return jsonResponse(401, 'error', 'กรุณาเข้าสู่ระบบ');
  }

  const serviceClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  // Verify caller is admin or superadmin
  const { data: callerRole, error: roleErr } = await serviceClient
    .from('staff_roles')
    .select('role')
    .eq('user_id', user.id)
    .single();

  if (roleErr || !callerRole || (callerRole.role !== 'admin' && callerRole.role !== 'superadmin')) {
    return jsonResponse(403, 'error', 'คุณไม่มีสิทธิ์ดำเนินการนี้');
  }

  let body: { action?: unknown; [key: string]: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, 'error', 'ข้อมูลคำขอไม่ถูกต้อง');
  }

  const { action } = body;

  // LIST
  if (action === 'list') {
    const [{ data: profiles, error: profileErr }, { data: roles, error: rolesErr }] = await Promise.all([
      serviceClient
        .from('staff_profiles')
        .select('user_id, first_name, last_name, service_center, created_at, updated_at')
        .order('created_at', { ascending: true }),
      serviceClient.from('staff_roles').select('user_id, role'),
    ]);

    if (profileErr || rolesErr) {
      return jsonResponse(500, 'error', 'เกิดข้อผิดพลาดของระบบ');
    }

    const { data: { users: authUsers }, error: authErr } = await serviceClient.auth.admin.listUsers({
      page: 1,
      perPage: 1000,
    });

    if (authErr) {
      return jsonResponse(500, 'error', 'เกิดข้อผิดพลาดของระบบ');
    }

    const roleMap = new Map((roles ?? []).map(r => [r.user_id as string, r.role as string]));
    const authMap = new Map(authUsers.map(u => [u.id, { email: u.email ?? '', last_sign_in_at: u.last_sign_in_at ?? null }]));

    const staff = (profiles ?? []).map(p => ({
      user_id: p.user_id,
      first_name: p.first_name,
      last_name: p.last_name,
      service_center: p.service_center,
      created_at: p.created_at,
      updated_at: p.updated_at,
      role: roleMap.get(p.user_id as string) ?? 'staff',
      email: authMap.get(p.user_id as string)?.email ?? '',
      last_sign_in_at: authMap.get(p.user_id as string)?.last_sign_in_at ?? null,
    }));

    return jsonResponse(200, 'success', 'ดึงข้อมูลสำเร็จ', { staff });
  }

  // CREATE
  if (action === 'create') {
    const { email, password, first_name, last_name, service_center, role } = body as {
      email?: string; password?: string; first_name?: string; last_name?: string;
      service_center?: string; role?: string;
    };

    if (!email || !password || !first_name || !last_name || !service_center || !role) {
      return jsonResponse(400, 'error', 'ข้อมูลไม่ครบถ้วน');
    }

    const { data: authData, error: authErr } = await serviceClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });

    if (authErr || !authData.user) {
      return jsonResponse(400, 'error', authErr?.message ?? 'ไม่สามารถสร้างบัญชีได้');
    }

    const userId = authData.user.id;

    const [profileResult, roleResult] = await Promise.all([
      serviceClient.from('staff_profiles').insert({ user_id: userId, first_name, last_name, service_center }),
      serviceClient.from('staff_roles').insert({ user_id: userId, role }),
    ]);

    if (profileResult.error || roleResult.error) {
      await serviceClient.auth.admin.deleteUser(userId);
      return jsonResponse(500, 'error', 'เกิดข้อผิดพลาดของระบบ กรุณาลองใหม่');
    }

    return jsonResponse(201, 'success', 'สร้างบัญชีสำเร็จ', { user_id: userId });
  }

  // DELETE
  if (action === 'delete') {
    const { user_id } = body as { user_id?: string };
    if (!user_id || typeof user_id !== 'string') {
      return jsonResponse(400, 'error', 'ข้อมูลไม่ครบถ้วน');
    }
    if (user_id === user.id) {
      return jsonResponse(400, 'error', 'ไม่สามารถลบบัญชีของตัวเองได้');
    }

    const { error: deleteErr } = await serviceClient.auth.admin.deleteUser(user_id);
    if (deleteErr) {
      return jsonResponse(500, 'error', 'ไม่สามารถลบบัญชีได้');
    }

    return jsonResponse(200, 'success', 'ลบบัญชีสำเร็จ');
  }

  // UPDATE
  if (action === 'update') {
    const { user_id, first_name, last_name, service_center, role } = body as {
      user_id?: string; first_name?: string; last_name?: string;
      service_center?: string; role?: string;
    };

    if (!user_id || typeof user_id !== 'string') {
      return jsonResponse(400, 'error', 'ข้อมูลไม่ครบถ้วน');
    }

    const profileUpdates: Record<string, unknown> = {};
    if (first_name !== undefined) profileUpdates.first_name = first_name;
    if (last_name !== undefined) profileUpdates.last_name = last_name;
    if (service_center !== undefined) profileUpdates.service_center = service_center;

    const tasks: Promise<{ error: unknown }>[] = [];

    if (Object.keys(profileUpdates).length > 0) {
      profileUpdates.updated_at = new Date().toISOString();
      tasks.push(serviceClient.from('staff_profiles').update(profileUpdates).eq('user_id', user_id) as Promise<{ error: unknown }>);
    }

    if (role !== undefined) {
      tasks.push(serviceClient.from('staff_roles').update({ role }).eq('user_id', user_id) as Promise<{ error: unknown }>);
    }

    if (tasks.length === 0) {
      return jsonResponse(400, 'error', 'ไม่มีข้อมูลที่ต้องการแก้ไข');
    }

    const results = await Promise.all(tasks);
    if (results.some(r => r.error)) {
      return jsonResponse(500, 'error', 'เกิดข้อผิดพลาดของระบบ');
    }

    return jsonResponse(200, 'success', 'แก้ไขข้อมูลสำเร็จ');
  }

  return jsonResponse(400, 'error', 'คำสั่งไม่ถูกต้อง');
});
