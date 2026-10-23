-- ============================================================
-- MM STORE V4 FIX
-- 1) Fix create_order for Supabase environments where
--    gen_random_bytes() is not exposed in SQL runtime.
-- 2) Allow payment proof for BOTH cash and InstaPay.
-- 3) Keep realtime admin order notifications consistent.
-- ============================================================

create extension if not exists pgcrypto;

alter table public.store_settings
add column if not exists cash_number text not null default '';

-- ------------------------------------------------------------
-- CREATE ORDER - FIXED ORDER NUMBER GENERATION
-- ------------------------------------------------------------

create or replace function public.create_order(
  p_customer_name text,
  p_phone text,
  p_city text,
  p_address text,
  p_payment_method text,
  p_items jsonb,
  p_client_request_id uuid default gen_random_uuid()
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  item jsonb;
  product_row record;
  v_subtotal numeric(12,2) := 0;
  v_shipping numeric(12,2) := 0;
  v_total numeric(12,2) := 0;
  v_order_id uuid := gen_random_uuid();
  v_order_number text;
  v_raw_token text := p_client_request_id::text;
  v_existing record;
  v_settings record;
  v_quantity integer;
  v_size text;
  v_color text;
begin
  if nullif(trim(p_customer_name), '') is null
     or length(trim(p_customer_name)) < 2 then
    raise exception 'INVALID_NAME';
  end if;

  if regexp_replace(p_phone, '[^0-9+]', '', 'g') !~ '^[0-9+]{10,15}$' then
    raise exception 'INVALID_PHONE';
  end if;

  if nullif(trim(p_city), '') is null
     or nullif(trim(p_address), '') is null then
    raise exception 'INVALID_ADDRESS';
  end if;

  if p_payment_method not in ('cash', 'instapay') then
    raise exception 'INVALID_PAYMENT_METHOD';
  end if;

  if jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_CART';
  end if;

  select *
  into v_existing
  from public.orders
  where client_request_id = p_client_request_id
  limit 1;

  if found then
    return jsonb_build_object(
      'order_id', v_existing.id,
      'order_number', v_existing.order_number,
      'access_token', v_raw_token,
      'subtotal', v_existing.subtotal,
      'shipping_fee', v_existing.shipping_fee,
      'total', v_existing.total
    );
  end if;

  select *
  into v_settings
  from public.store_settings
  where id = 1;

  if not found then
    raise exception 'STORE_SETTINGS_NOT_FOUND';
  end if;

  for item in
    select value from jsonb_array_elements(p_items)
  loop
    v_quantity := greatest(
      1,
      least(coalesce((item->>'quantity')::int, 1), 99)
    );

    select id, name, price, is_active
    into product_row
    from public.products
    where id = (item->>'productId')::uuid
    for update;

    if not found or not product_row.is_active then
      raise exception 'PRODUCT_UNAVAILABLE';
    end if;

    v_subtotal := v_subtotal + (product_row.price * v_quantity);
  end loop;

  if v_subtotal < v_settings.free_shipping_threshold then
    v_shipping := v_settings.shipping_fee;
  end if;

  v_total := v_subtotal + v_shipping;

  -- UUID-backed suffix instead of gen_random_bytes().
  v_order_number :=
    'MM-' ||
    to_char(clock_timestamp(), 'YYMMDDHH24MISS') ||
    '-' ||
    upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));

  insert into public.orders(
    id,
    order_number,
    client_request_id,
    access_token_hash,
    customer_name,
    phone,
    city,
    address,
    payment_method,
    payment_status,
    order_status,
    subtotal,
    shipping_fee,
    total
  )
  values(
    v_order_id,
    v_order_number,
    p_client_request_id,
    crypt(v_raw_token, gen_salt('bf')),
    trim(p_customer_name),
    trim(p_phone),
    trim(p_city),
    trim(p_address),
    p_payment_method,
    case when p_payment_method = 'cash' then 'confirmed' else 'pending' end,
    'pending',
    v_subtotal,
    v_shipping,
    v_total
  );

  for item in
    select value from jsonb_array_elements(p_items)
  loop
    v_quantity := greatest(
      1,
      least(coalesce((item->>'quantity')::int, 1), 99)
    );

    v_size := nullif(trim(item->>'size'), '');
    v_color := nullif(trim(item->>'color'), '');

    select id, name, price, is_active
    into product_row
    from public.products
    where id = (item->>'productId')::uuid
    for update;

    if not found or not product_row.is_active then
      raise exception 'PRODUCT_UNAVAILABLE';
    end if;

    insert into public.order_items(
      order_id,
      product_id,
      product_name,
      unit_price,
      quantity,
      size,
      color
    )
    values(
      v_order_id,
      product_row.id,
      product_row.name,
      product_row.price,
      v_quantity,
      v_size,
      v_color
    );
  end loop;

  return jsonb_build_object(
    'order_id', v_order_id,
    'order_number', v_order_number,
    'access_token', v_raw_token,
    'subtotal', v_subtotal,
    'shipping_fee', v_shipping,
    'total', v_total
  );

exception
  when unique_violation then
    select *
    into v_existing
    from public.orders
    where client_request_id = p_client_request_id
    limit 1;

    if found then
      return jsonb_build_object(
        'order_id', v_existing.id,
        'order_number', v_existing.order_number,
        'access_token', v_raw_token,
        'subtotal', v_existing.subtotal,
        'shipping_fee', v_existing.shipping_fee,
        'total', v_existing.total
      );
    end if;

    raise;
end;
$$;

grant execute on function public.create_order(text,text,text,text,text,jsonb,uuid) to anon;


-- ------------------------------------------------------------
-- PAYMENT PROOF - ALLOW CASH AND INSTAPAY
-- ------------------------------------------------------------

create or replace function public.attach_payment_proof(
  p_order_id uuid,
  p_access_token text,
  p_proof_path text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  o record;
begin
  select id, access_token_hash, payment_method, payment_proof_path
  into o
  from public.orders
  where id = p_order_id;

  if not found then
    raise exception 'ORDER_NOT_FOUND';
  end if;

  if o.payment_method not in ('cash', 'instapay') then
    raise exception 'INVALID_PAYMENT_METHOD';
  end if;

  if crypt(p_access_token, o.access_token_hash) <> o.access_token_hash then
    raise exception 'INVALID_ACCESS_TOKEN';
  end if;

  if o.payment_proof_path is not null then
    raise exception 'PROOF_ALREADY_ATTACHED';
  end if;

  if p_proof_path !~ (
    '^orders/' || p_order_id::text || '/[^/]+/.+\.(jpg|jpeg|png|webp)$'
  ) then
    raise exception 'INVALID_PROOF_PATH';
  end if;

  update public.orders
  set payment_proof_path = p_proof_path
  where id = p_order_id;
end;
$$;

grant execute on function public.attach_payment_proof(uuid,text,text) to anon;


create or replace function public.can_upload_payment_proof(object_name text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  parts text[] := string_to_array(object_name, '/');
  o record;
begin
  if array_length(parts, 1) <> 4
     or parts[1] <> 'orders' then
    return false;
  end if;

  select id, access_token_hash, payment_method, payment_proof_path
  into o
  from public.orders
  where id = parts[2]::uuid;

  if not found
     or o.payment_method not in ('cash', 'instapay')
     or o.payment_proof_path is not null then
    return false;
  end if;

  return crypt(parts[3], o.access_token_hash) = o.access_token_hash;

exception
  when others then
    return false;
end;
$$;

grant execute on function public.can_upload_payment_proof(text) to anon, authenticated;


-- ------------------------------------------------------------
-- ADMIN NOTIFICATIONS - KEEP FIELDS COMPLETE
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

alter table public.admin_notifications enable row level security;

drop policy if exists admin_notifications_admin_read on public.admin_notifications;
create policy admin_notifications_admin_read
on public.admin_notifications
for select
to authenticated
using (public.is_admin());

drop policy if exists admin_notifications_admin_update on public.admin_notifications;
create policy admin_notifications_admin_update
on public.admin_notifications
for update

to authenticated
using (public.is_admin())
with check (public.is_admin());

grant select on public.admin_notifications to authenticated;
grant update on public.admin_notifications to authenticated;

create or replace function public.create_admin_order_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.admin_notifications(
    type,
    order_id,
    order_number,
    customer_name,
    total,
    title,
    body
  )
  values(
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

drop trigger if exists orders_create_admin_notification on public.orders;
create trigger orders_create_admin_notification
after insert on public.orders
for each row
execute function public.create_admin_order_notification();


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

-- ============================================================
-- VERIFY
-- ============================================================
-- select public.get_home_content();
-- select * from public.admin_notifications order by created_at desc limit 10;
