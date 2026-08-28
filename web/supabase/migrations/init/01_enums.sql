-- ============================================================
-- 01_enums.sql — MyCareNK
-- Project: timuuxjeffzqtsqnjbnz | ap-southeast-1
-- All custom Postgres enum types.
-- Apply order: 1 of 8 (must precede functions and tables)
-- ============================================================


CREATE TYPE public.request_status AS ENUM (
  'pending',
  'preparing',
  'ready',
  'completed',
  'cancelled_by_user',
  'cancelled_by_staff'
);

CREATE TYPE public.role AS ENUM (
  'staff',
  'admin',
  'superadmin'
);

CREATE TYPE public.transaction_type AS ENUM (
  'restock',
  'fulfillment',
  'adjustment'
);

CREATE TYPE public.audit_action AS ENUM (
  'role_updated',
  'staff_profile_updated',
  'restock',
  'fulfillment',
  'adjustment',
  'staff_created',
  'staff_deleted',
  'email_updated'
);

CREATE TYPE public.consultation_status AS ENUM (
  'pending',
  'confirmed',
  'completed',
  'cancelled_by_user',
  'cancelled_by_staff'
);

CREATE TYPE public.article_status AS ENUM (
  'draft',
  'published',
  'hidden'
);


