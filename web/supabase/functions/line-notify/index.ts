import { createClient } from 'jsr:@supabase/supabase-js@2';

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204 });
  }

  let notification: {
    id: string;
    source_type: string;
    event_type: string;
    service_centers: string[] | null;
    metadata: { reference_number?: string; [key: string]: unknown };
    [key: string]: unknown;
  };

  try {
    notification = await req.json();
  } catch {
    return new Response('Bad request', { status: 400 });
  }

  const { source_type } = notification;
  const service_centers = notification.service_centers ?? [];
  const reference_number = notification.metadata?.reference_number ?? '';

  if (service_centers.length === 0) {
    return new Response('OK', { status: 200 });
  }

  const serviceClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const { data: staffList, error } = await serviceClient
    .from('staff_profiles')
    .select('role, service_centers, line_user_id')
    .not('line_user_id', 'is', null);

  if (error || !staffList) {
    console.error('Failed to fetch staff_profiles:', error);
    return new Response('Error', { status: 500 });
  }

  // Filter in code to handle SC names with special characters safely.
  // A notification can target multiple SCs; match staff whose SCs overlap.
  const recipients = staffList.filter(
    (s) =>
      s.role === 'superadmin' ||
      (s.service_centers ?? []).some((sc: string) => service_centers.includes(sc))
  );

  if (recipients.length === 0) {
    return new Response('OK', { status: 200 });
  }

  const channelAccessToken = Deno.env.get('LINE_CHANNEL_ACCESS_TOKEN');
  if (!channelAccessToken) {
    console.error('LINE_CHANNEL_ACCESS_TOKEN not set');
    return new Response('Config error', { status: 500 });
  }

  const typeLabel =
    source_type === 'consultation' ? 'นัดรับคำปรึกษา' : 'ขอถุงยางอนามัย/เจลหล่อลื่น';
  const messageText = [
    'มีรายการใหม่เข้ามา!',
    `📍 สถานบริการ: ${service_centers.join(', ')}`,
    `📋 ประเภท: ${typeLabel}`,
    `🔖 รหัสอ้างอิง: ${reference_number}`,
  ].join('\n');

  // Send per-user; allSettled so one failure doesn't abort the rest
  const results = await Promise.allSettled(
    recipients.map((staff) =>
      fetch('https://api.line.me/v2/bot/message/push', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${channelAccessToken}`,
        },
        body: JSON.stringify({
          to: staff.line_user_id,
          messages: [{ type: 'text', text: messageText }],
        }),
      })
    )
  );

  const failures = results.filter((r) => r.status === 'rejected');
  if (failures.length > 0) {
    console.error(`${failures.length} LINE push(es) failed`);
  }

  return new Response('OK', { status: 200 });
});
