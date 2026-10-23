-- ============================================================
-- MM STORE FINAL NON-DESTRUCTIVE MIGRATION
-- Run AFTER the main MM Store setup has succeeded.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Store media bucket for hero/about/category/banner images
-- ------------------------------------------------------------

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'store-media',
  'store-media',
  true,
  10485760,
  array['image/jpeg','image/png','image/webp']
)
on conflict (id)
do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists store_media_public_read
on storage.objects;

create policy store_media_public_read
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'store-media');

drop policy if exists store_media_admin_insert
on storage.objects;

create policy store_media_admin_insert
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'store-media'
  and public.is_admin()
);

drop policy if exists store_media_admin_update
on storage.objects;

create policy store_media_admin_update
on storage.objects
for update
to authenticated
using (
  bucket_id = 'store-media'
  and public.is_admin()
)
with check (
  bucket_id = 'store-media'
  and public.is_admin()
);

drop policy if exists store_media_admin_delete
on storage.objects;

create policy store_media_admin_delete
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'store-media'
  and public.is_admin()
);


-- ------------------------------------------------------------
-- 2) Payment settings compatibility
-- ------------------------------------------------------------

alter table public.store_settings
add column if not exists cash_number text not null default '';


-- ------------------------------------------------------------
-- 3) Persistent admin notifications
-- ------------------------------------------------------------

create table if not exists public.admin_notifications (
  id uuid primary key default gen_random_uuid(),
  type text not null default 'new_order',
  order_id uuid not null references public.orders(id) on delete cascade,
  order_number text not null,
  customer_name text not null,
  total numeric(12,2) not null default 0,
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists admin_notifications_unread_idx
on public.admin_notifications(is_read, created_at desc);

create index if not exists admin_notifications_order_idx
on public.admin_notifications(order_id);

alter table public.admin_notifications
enable row level security;

drop policy if exists admin_notifications_admin_read
on public.admin_notifications;

create policy admin_notifications_admin_read
on public.admin_notifications
for select
to authenticated
using (public.is_admin());

drop policy if exists admin_notifications_admin_update
on public.admin_notifications;

create policy admin_notifications_admin_update
on public.admin_notifications
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());


-- ------------------------------------------------------------
-- 4) Create one persistent notification for every new order
-- ------------------------------------------------------------

create or replace function public.create_admin_order_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.admin_notifications (
    type,
    order_id,
    order_number,
    customer_name,
    total,
    title,
    body
  )
  values (
    'new_order',
    new.id,
    new.order_number,
    new.customer_name,
    new.total,
    'طلب جديد • #' || new.order_number,
    new.customer_name || ' • ' || new.total::text || ' EGP'
  );

  return new;
end;
$$;

drop trigger if exists orders_create_admin_notification
on public.orders;

create trigger orders_create_admin_notification
after insert
on public.orders
for each row
execute function public.create_admin_order_notification();


-- ------------------------------------------------------------
-- 5) Realtime for persistent admin notifications
-- ------------------------------------------------------------

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'admin_notifications'
  ) then
    alter publication supabase_realtime
    add table public.admin_notifications;
  end if;
end
$$;


-- ------------------------------------------------------------
-- 6) Required read/write grants
-- ------------------------------------------------------------

grant select on public.admin_notifications to authenticated;
grant update on public.admin_notifications to authenticated;

-- ------------------------------------------------------------
-- 7) Optional verification
-- ------------------------------------------------------------
-- select * from public.admin_notifications order by created_at desc limit 10;
-- select public.get_home_content();
-- ============================================================
