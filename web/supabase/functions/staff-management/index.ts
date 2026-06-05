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

  const serviceClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  // Verify caller is admin or superadmin; load service_centers for SC scoping
  const { data: callerProfile, error: callerErr } = await serviceClient
    .from('staff_profiles')
    .select('role, service_centers')
    .eq('staff_user_id', user.id)
    .single();

  if (callerErr || !callerProfile || (callerProfile.role !== 'admin' && callerProfile.role !== 'superadmin')) {
    return jsonResponse(403, 'error', 'คุณไม่มีสิทธิ์ดำเนินการนี้');
  }

  const callerSCs: string[] = callerProfile.service_centers ?? [];
  const isAdmin = callerProfile.role === 'admin';

  let body: { action?: unknown; [key: string]: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, 'error', 'ข้อมูลคำขอไม่ถูกต้อง');
  }

  const { action } = body;

  // LIST
  if (action === 'list') {
    let profileQuery = serviceClient
      .from('staff_profiles')
      .select('staff_user_id, first_name, last_name, service_center, service_centers, role, created_at, updated_at')
      .order('created_at', { ascending: true });

    // Admin only sees staff in their SCs and cannot see superadmin accounts
    if (isAdmin) {
      profileQuery = profileQuery.in('service_center', callerSCs).neq('role', 'superadmin');
    }

    const { data: profiles, error: profileErr } = await profileQuery;

    if (profileErr) {
      return jsonResponse(500, 'error', 'เกิดข้อผิดพลาดของระบบ');
    }

    const { data: { users: authUsers }, error: authErr } = await serviceClient.auth.admin.listUsers({
      page: 1,
      perPage: 1000,
    });

    if (authErr) {
      return jsonResponse(500, 'error', 'เกิดข้อผิดพลาดของระบบ');
    }

    const authMap = new Map(authUsers.map(u => [u.id, { email: u.email ?? '', last_sign_in_at: u.last_sign_in_at ?? null }]));

    const staff = (profiles ?? []).map(p => ({
      staff_user_id: p.staff_user_id,
      first_name: p.first_name,
      last_name: p.last_name,
      service_center: p.service_center,
      service_centers: (p.service_centers as string[] | null) ?? (p.service_center ? [p.service_center] : []),
      role: p.role,
      created_at: p.created_at,
      updated_at: p.updated_at,
      email: authMap.get(p.staff_user_id as string)?.email ?? '',
      last_sign_in_at: authMap.get(p.staff_user_id as string)?.last_sign_in_at ?? null,
    }));

    return jsonResponse(200, 'success', 'ดึงข้อมูลสำเร็จ', { staff });
  }

  // CREATE
  if (action === 'create') {
    const { email, password, first_name, last_name, service_center, role, service_centers } = body as {
      email?: string; password?: string; first_name?: string; last_name?: string;
      service_center?: string; role?: string; service_centers?: string[];
    };

    if (!email || !password || !first_name || !last_name || !role) {
      return jsonResponse(400, 'error', 'ข้อมูลไม่ครบถ้วน');
    }

    if (isAdmin && role === 'superadmin') {
      return jsonResponse(403, 'error', 'ผู้ดูแลไม่สามารถสร้างบัญชีผู้ดูแลสูงสุดได้');
    }

    // Derive effective SC list from service_centers array (preferred) or service_center string
    const requestedSCs: string[] = (service_centers && service_centers.length > 0)
      ? service_centers
      : service_center ? [service_center] : [];

    // Staff and admin roles must have at least one SC
    if ((role === 'staff' || role === 'admin') && requestedSCs.length === 0) {
      return jsonResponse(400, 'error', 'เจ้าหน้าที่และผู้ดูแลต้องระบุสถานบริการ');
    }

    // Admin can only assign SCs they manage
    if (isAdmin && requestedSCs.length > 0 && !requestedSCs.every(sc => callerSCs.includes(sc))) {
      return jsonResponse(403, 'error', 'คุณไม่มีสิทธิ์สร้างบัญชีในสถานบริการนี้');
    }

    const primarySC: string | null = requestedSCs[0] ?? null;

    const { data: authData, error: authErr } = await serviceClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });

    if (authErr || !authData.user) {
      const raw = authErr?.message ?? '';
      const thMsg = raw.includes('already been registered') || raw.includes('already registered')
        ? 'อีเมลนี้ถูกใช้งานแล้ว'
        : raw || 'ไม่สามารถสร้างบัญชีได้';
      return jsonResponse(400, 'error', thMsg);
    }

    const userId = authData.user.id;

    const { data: profileData, error: profileErr } = await serviceClient
      .from('staff_profiles')
      .insert({ staff_user_id: userId, first_name, last_name, service_center: primarySC, role, service_centers: requestedSCs })
      .select('id')
      .single();

    if (profileErr) {
      await serviceClient.auth.admin.deleteUser(userId);
      return jsonResponse(500, 'error', 'เกิดข้อผิดพลาดของระบบ กรุณาลองใหม่');
    }

    await serviceClient.rpc('write_staff_change_log', {
      p_performed_by:         user.id,
      p_action:               'staff_created',
      p_target_table:         'staff_profiles',
      p_target_id:            profileData!.id,
      p_new_value:            { email, first_name, last_name, service_center: primarySC, service_centers: requestedSCs, role },
      p_target_staff_user_id: authData.user.id,
      p_target_name:          `${first_name} ${last_name}`,
    });

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

    // Snapshot profile + email before delete
    const [{ data: profileSnapshot }, authUserSnapshot] = await Promise.all([
      serviceClient.from('staff_profiles').select('id, first_name, last_name, service_center, role').eq('staff_user_id', user_id).single(),
      serviceClient.auth.admin.getUserById(user_id),
    ]);
    const snapshotEmail = authUserSnapshot.data?.user?.email ?? null;

    if (isAdmin && profileSnapshot?.role === 'superadmin') {
      return jsonResponse(403, 'error', 'ผู้ดูแลไม่สามารถลบบัญชีผู้ดูแลสูงสุดได้');
    }

    // Admin can only delete staff in their own SCs
    if (isAdmin && profileSnapshot?.service_center && !callerSCs.includes(profileSnapshot.service_center)) {
      return jsonResponse(403, 'error', 'คุณไม่มีสิทธิ์ลบบัญชีในสถานบริการนี้');
    }

    const { error: deleteErr } = await serviceClient.auth.admin.deleteUser(user_id);
    if (deleteErr) {
      return jsonResponse(500, 'error', 'ไม่สามารถลบบัญชีได้');
    }

    if (profileSnapshot) {
      await serviceClient.rpc('write_staff_change_log', {
        p_performed_by:         user.id,
        p_action:               'staff_deleted',
        p_target_table:         'staff_profiles',
        p_target_id:            profileSnapshot.id,
        p_old_value:            {
          email: snapshotEmail,
          first_name: profileSnapshot.first_name,
          last_name: profileSnapshot.last_name,
          service_center: profileSnapshot.service_center,
          role: profileSnapshot.role,
        },
        p_target_staff_user_id: user_id,
        p_target_name:          `${profileSnapshot.first_name} ${profileSnapshot.last_name}`,
      });
    }

    return jsonResponse(200, 'success', 'ลบบัญชีสำเร็จ');
  }

  // UPDATE
  if (action === 'update') {
    const { staff_user_id: user_id, first_name, last_name, service_center, role, email, service_centers } = body as {
      staff_user_id?: string; first_name?: string; last_name?: string;
      service_center?: string; role?: string; email?: string; service_centers?: string[];
    };

    if (!user_id || typeof user_id !== 'string') {
      return jsonResponse(400, 'error', 'ข้อมูลไม่ครบถ้วน');
    }

    const hasPotentialProfileUpdate = first_name !== undefined || last_name !== undefined || service_center !== undefined;
    const hasRoleUpdate = role !== undefined;
    const hasEmailUpdate = email !== undefined;
    const hasServiceCentersUpdate = service_centers !== undefined;

    // Fetch old values
    const needsProfileFetch = hasPotentialProfileUpdate || hasEmailUpdate || hasRoleUpdate || hasServiceCentersUpdate;
    const [profileBefore, authUserBefore] = await Promise.all([
      needsProfileFetch
        ? serviceClient.from('staff_profiles').select('id, first_name, last_name, service_center, service_centers, role').eq('staff_user_id', user_id).single()
        : Promise.resolve({ data: null, error: null }),
      hasEmailUpdate
        ? serviceClient.auth.admin.getUserById(user_id)
        : Promise.resolve({ data: { user: null }, error: null }),
    ]);

    // Admin cannot modify superadmin accounts or promote to superadmin
    if (isAdmin) {
      if (profileBefore.data?.role === 'superadmin') {
        return jsonResponse(403, 'error', 'ผู้ดูแลไม่สามารถแก้ไขข้อมูลผู้ดูแลสูงสุดได้');
      }
      if (role === 'superadmin') {
        return jsonResponse(403, 'error', 'ผู้ดูแลไม่สามารถกำหนดสิทธิ์ผู้ดูแลสูงสุดได้');
      }
      // Admin can only modify staff in their own SCs
      const targetSC = profileBefore.data?.service_center;
      if (targetSC && !callerSCs.includes(targetSC)) {
        return jsonResponse(403, 'error', 'คุณไม่มีสิทธิ์แก้ไขข้อมูลบัญชีในสถานบริการนี้');
      }
      // If moving staff to another SC, that SC must also be in admin's SCs
      if (service_center !== undefined && !callerSCs.includes(service_center)) {
        return jsonResponse(403, 'error', 'คุณไม่มีสิทธิ์โอนย้ายบัญชีไปยังสถานบริการนี้');
      }
    }

    // Diff: only keep fields that actually changed
    const changedProfileUpdates: Record<string, unknown> = {};
    if (first_name !== undefined && first_name !== profileBefore.data?.first_name) changedProfileUpdates.first_name = first_name;
    if (last_name !== undefined && last_name !== profileBefore.data?.last_name) changedProfileUpdates.last_name = last_name;
    if (service_center !== undefined && service_center !== profileBefore.data?.service_center) changedProfileUpdates.service_center = service_center;

    const oldEmail = authUserBefore.data?.user?.email ?? null;
    const oldRole = profileBefore.data?.role ?? null;
    const oldServiceCenters = profileBefore.data?.service_centers ?? null;

    const hasActualProfileChange = Object.keys(changedProfileUpdates).length > 0;
    const hasActualRoleChange = hasRoleUpdate && profileBefore.data != null && role !== oldRole;
    const hasActualEmailChange = hasEmailUpdate && email !== oldEmail;
    const hasActualServiceCentersChange = hasServiceCentersUpdate &&
      JSON.stringify((service_centers ?? []).sort()) !== JSON.stringify((oldServiceCenters ?? []).sort());

    if (!hasActualProfileChange && !hasActualRoleChange && !hasActualEmailChange && !hasActualServiceCentersChange) {
      return jsonResponse(200, 'success', 'แก้ไขข้อมูลสำเร็จ');
    }

    // Staff and admin roles must have at least one SC after update
    const effectiveRole = hasActualRoleChange ? role : profileBefore.data?.role;
    const effectiveSCs = hasActualServiceCentersChange ? (service_centers ?? []) : ((profileBefore.data?.service_centers as string[] | null) ?? []);
    if ((effectiveRole === 'staff' || effectiveRole === 'admin') && effectiveSCs.length === 0) {
      return jsonResponse(400, 'error', 'เจ้าหน้าที่และผู้ดูแลต้องระบุสถานบริการ');
    }

    // Build a single staff_profiles update
    const profileTableUpdates: Record<string, unknown> = { ...changedProfileUpdates };
    if (hasActualRoleChange) profileTableUpdates.role = role;
    if (hasActualServiceCentersChange) profileTableUpdates.service_centers = service_centers;
    // When service_center changes, sync service_centers[0] if not explicitly provided
    if (changedProfileUpdates.service_center !== undefined && !hasActualServiceCentersChange) {
      profileTableUpdates.service_centers = [service_center];
    }

    const tasks: Promise<{ error: unknown }>[] = [];

    if (Object.keys(profileTableUpdates).length > 0) {
      profileTableUpdates.updated_at = new Date().toISOString();
      tasks.push(serviceClient.from('staff_profiles').update(profileTableUpdates).eq('staff_user_id', user_id) as Promise<{ error: unknown }>);
    }

    if (hasActualEmailChange) {
      const { error: emailErr } = await serviceClient.auth.admin.updateUserById(user_id, { email, email_confirm: true });
      if (emailErr) {
        const raw = emailErr.message ?? '';
        const thMsg = raw.toLowerCase().includes('unable to validate email') || raw.toLowerCase().includes('invalid format')
          ? 'รูปแบบอีเมลไม่ถูกต้อง'
          : raw.includes('already been registered') || raw.includes('already registered')
            ? 'อีเมลนี้ถูกใช้งานแล้ว'
            : raw || 'ไม่สามารถอัปเดตอีเมลได้';
        return jsonResponse(400, 'error', thMsg);
      }
    }

    if (tasks.length > 0) {
      const results = await Promise.all(tasks);
      if (results.some(r => r.error)) {
        return jsonResponse(500, 'error', 'เกิดข้อผิดพลาดของระบบ');
      }
    }

    // Audit logging
    const auditTasks: Promise<unknown>[] = [];
    const targetName = profileBefore.data
      ? `${profileBefore.data.first_name} ${profileBefore.data.last_name}`
      : null;

    if (hasActualProfileChange && profileBefore.data) {
      const oldProfileValues: Record<string, unknown> = {};
      const newProfileValues: Record<string, unknown> = {};
      for (const key of Object.keys(changedProfileUpdates)) {
        oldProfileValues[key] = (profileBefore.data as Record<string, unknown>)[key];
        newProfileValues[key] = changedProfileUpdates[key];
      }
      auditTasks.push(serviceClient.rpc('write_staff_change_log', {
        p_performed_by:         user.id,
        p_action:               'staff_profile_updated',
        p_target_table:         'staff_profiles',
        p_target_id:            profileBefore.data.id,
        p_old_value:            oldProfileValues,
        p_new_value:            newProfileValues,
        p_target_staff_user_id: user_id,
        p_target_name:          targetName,
      }));
    }

    if (hasActualEmailChange && profileBefore.data) {
      auditTasks.push(serviceClient.rpc('write_staff_change_log', {
        p_performed_by:         user.id,
        p_action:               'email_updated',
        p_target_table:         'staff_profiles',
        p_target_id:            profileBefore.data.id,
        p_old_value:            { email: oldEmail },
        p_new_value:            { email },
        p_target_staff_user_id: user_id,
        p_target_name:          targetName,
      }));
    }

    if (hasActualRoleChange && profileBefore.data) {
      auditTasks.push(serviceClient.rpc('write_staff_change_log', {
        p_performed_by:         user.id,
        p_action:               'role_updated',
        p_target_table:         'staff_profiles',
        p_target_id:            profileBefore.data.id,
        p_old_value:            { role: oldRole },
        p_new_value:            { role },
        p_target_staff_user_id: user_id,
        p_target_name:          targetName,
      }));
    }

    if (auditTasks.length > 0) {
      await Promise.all(auditTasks);
    }

    return jsonResponse(200, 'success', 'แก้ไขข้อมูลสำเร็จ');
  }

  return jsonResponse(400, 'error', 'คำสั่งไม่ถูกต้อง');
});
