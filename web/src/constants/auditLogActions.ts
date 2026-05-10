/**
 * Mirrors the audit_action enum defined in Supabase (public.audit_action).
 * These are the only values stored in audit_logs.action.
 *
 * Sources:
 *   staff_created         — Edge Function: staff-management (action=create)
 *   staff_deleted         — Edge Function: staff-management (action=delete)
 *   role_updated          — Edge Function: staff-management (action=update, role changed)
 *   staff_profile_updated — Edge Function: staff-management (action=update, profile fields changed)
 *   email_updated         — Edge Function: staff-management (action=update, email changed)
 *   restock               — trigger: on_inventory_transactions_insert_audit (transaction_type = 'restock')
 *   fulfillment           — trigger: on_inventory_transactions_insert_audit (transaction_type = 'fulfillment')
 *   adjustment            — trigger: on_inventory_transactions_insert_audit (transaction_type = 'adjustment')
 */
export const AUDIT_ACTION = {
  STAFF_CREATED:         'staff_created',
  STAFF_DELETED:         'staff_deleted',
  ROLE_UPDATED:          'role_updated',
  STAFF_PROFILE_UPDATED: 'staff_profile_updated',
  EMAIL_UPDATED:         'email_updated',
  RESTOCK:               'restock',
  FULFILLMENT:           'fulfillment',
  ADJUSTMENT:            'adjustment',
} as const;

export type AuditAction = typeof AUDIT_ACTION[keyof typeof AUDIT_ACTION];

// ─── Display labels (Thai) ────────────────────────────────────────────────────

export const AUDIT_ACTION_LABEL: Record<AuditAction, string> = {
  [AUDIT_ACTION.STAFF_CREATED]:         'เพิ่มเจ้าหน้าที่',
  [AUDIT_ACTION.STAFF_DELETED]:         'ลบเจ้าหน้าที่',
  [AUDIT_ACTION.ROLE_UPDATED]:          'แก้ไขระดับสิทธิ์เจ้าหน้าที่',
  [AUDIT_ACTION.STAFF_PROFILE_UPDATED]: 'แก้ไขโปรไฟล์เจ้าหน้าที่',
  [AUDIT_ACTION.EMAIL_UPDATED]:         'แก้ไขอีเมลเจ้าหน้าที่',
  [AUDIT_ACTION.RESTOCK]:               'เติมสต็อก',
  [AUDIT_ACTION.FULFILLMENT]:           'จ่ายสต็อก',
  [AUDIT_ACTION.ADJUSTMENT]:            'ปรับสต็อก',
};

// ─── Chip color mapping ───────────────────────────────────────────────────────

export const AUDIT_ACTION_COLOR: Record<AuditAction, { bg: string; color: string }> = {
  [AUDIT_ACTION.STAFF_CREATED]:         { bg: '#2E7D32', color: '#fff' },
  [AUDIT_ACTION.STAFF_DELETED]:         { bg: '#B71C1C', color: '#fff' },
  [AUDIT_ACTION.ROLE_UPDATED]:          { bg: '#7B1FA2', color: '#fff' },
  [AUDIT_ACTION.STAFF_PROFILE_UPDATED]: { bg: '#E65100', color: '#fff' },
  [AUDIT_ACTION.EMAIL_UPDATED]:         { bg: '#1565C0', color: '#fff' },
  [AUDIT_ACTION.RESTOCK]:               { bg: '#2E7D32', color: '#fff' },
  [AUDIT_ACTION.FULFILLMENT]:           { bg: '#1565C0', color: '#fff' },
  [AUDIT_ACTION.ADJUSTMENT]:            { bg: '#E65100', color: '#fff' },
};

export const AUDIT_ACTION_FALLBACK_COLOR = { bg: '#616161', color: '#fff' };
