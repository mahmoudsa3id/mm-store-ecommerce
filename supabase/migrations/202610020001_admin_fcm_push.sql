create table if not exists public.admin_device_tokens (
  token text primary key,
  admin_user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null,
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);

create index if not exists admin_device_tokens_active_idx
on public.admin_device_tokens(is_active)
where is_active;

alter table public.admin_device_tokens enable row level security;

drop policy if exists admin_device_tokens_admin_select
on public.admin_device_tokens;
create policy admin_device_tokens_admin_select
on public.admin_device_tokens
for select to authenticated
using (admin_user_id = auth.uid() and public.is_admin());

drop policy if exists admin_device_tokens_admin_insert
on public.admin_device_tokens;
create policy admin_device_tokens_admin_insert
on public.admin_device_tokens
for insert to authenticated
with check (admin_user_id = auth.uid() and public.is_admin());

drop policy if exists admin_device_tokens_admin_update
on public.admin_device_tokens;
create policy admin_device_tokens_admin_update
on public.admin_device_tokens
for update to authenticated
using (public.is_admin())
with check (admin_user_id = auth.uid() and public.is_admin());

drop policy if exists admin_device_tokens_admin_delete
on public.admin_device_tokens;
create policy admin_device_tokens_admin_delete
on public.admin_device_tokens
for delete to authenticated
using (admin_user_id = auth.uid() and public.is_admin());

grant select, insert, update, delete
on public.admin_device_tokens to authenticated;

create table if not exists public.admin_order_pushes (
  order_id uuid primary key references public.orders(id) on delete cascade,
  status text not null default 'sending'
    check (status in ('sending', 'sent', 'failed')),
  attempt_count integer not null default 1,
  last_error text,
  sent_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.admin_order_pushes enable row level security;
revoke all on public.admin_order_pushes from anon, authenticated;
grant select, insert, update, delete on public.admin_order_pushes to service_role;

create or replace function public.claim_admin_order_push(p_order_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  current_status text;
  current_updated_at timestamptz;
begin
  insert into public.admin_order_pushes(order_id, status)
  values (p_order_id, 'sending')
  on conflict (order_id) do nothing;

  if found then
    return true;
  end if;

  select status, updated_at
  into current_status, current_updated_at
  from public.admin_order_pushes
  where order_id = p_order_id
  for update;

  if current_status = 'failed'
    or (current_status = 'sending' and current_updated_at < now() - interval '2 minutes') then
    update public.admin_order_pushes
    set status = 'sending',
        attempt_count = attempt_count + 1,
        last_error = null,
        updated_at = now()
    where order_id = p_order_id;
    return true;
  end if;

  return false;
end;
$$;

revoke all on function public.claim_admin_order_push(uuid) from public, anon, authenticated;
grant execute on function public.claim_admin_order_push(uuid) to service_role;

create schema if not exists extensions;
create extension if not exists pg_net with schema extensions;

create or replace function public.enqueue_admin_order_push()
returns trigger
language plpgsql
security definer
set search_path = public, net, vault
as $$
declare
  push_url text;
  push_secret text;
begin
  select decrypted_secret into push_url
  from vault.decrypted_secrets
  where name = 'admin_order_push_url'
  limit 1;

  select decrypted_secret into push_secret
  from vault.decrypted_secrets
  where name = 'admin_order_push_secret'
  limit 1;

  if push_url is null or push_secret is null then
    raise warning 'Admin order push URL or secret is not configured in Vault';
    return new;
  end if;

  perform net.http_post(
    url := push_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-admin-order-secret', push_secret
    ),
    body := jsonb_build_object('orderId', new.id)
  );

  return new;
end;
$$;

drop trigger if exists orders_enqueue_admin_fcm_push on public.orders;
create trigger orders_enqueue_admin_fcm_push
after insert on public.orders
for each row execute function public.enqueue_admin_order_push();

do $$
begin
  if exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'admin_notifications'
  ) then
    alter publication supabase_realtime drop table public.admin_notifications;
  end if;
end;
$$;