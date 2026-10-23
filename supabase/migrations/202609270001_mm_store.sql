create extension if not exists pgcrypto;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  image_url text not null default '',
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  image_url text not null default '',
  images jsonb not null default '[]'::jsonb,
  description text not null default '',
  price numeric(12,2) not null check (price >= 0),
  old_price numeric(12,2) check (old_price is null or old_price >= 0),
  rating numeric(3,2) not null default 0 check (rating >= 0 and rating <= 5),
  review_count integer not null default 0 check (review_count >= 0),
  colors jsonb not null default '[]'::jsonb,
  sizes jsonb not null default '[]'::jsonb,
  category_id uuid references public.categories(id) on delete set null,
  sales_count bigint not null default 0 check (sales_count >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.banners (
  id uuid primary key default gen_random_uuid(),
  image_url text not null default '',
  title text not null,
  button_text text not null default 'تسوق الآن',
  target text not null default 'new',
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text not null default '',
  icon text not null default 'verified',
  sort_order integer not null default 0,
  is_active boolean not null default true
);

create table if not exists public.store_content (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.store_settings (
  id integer primary key default 1 check (id = 1),
  store_name text not null default 'MM Store',
  instapay_number text not null default '',
  cash_number text not null default '',
  phone text not null default '',
  whatsapp text not null default '',
  shipping_fee numeric(12,2) not null default 60 check (shipping_fee >= 0),
  free_shipping_threshold numeric(12,2) not null default 1500 check (free_shipping_threshold >= 0),
  updated_at timestamptz not null default now()
);

alter table public.store_settings add column if not exists cash_number text not null default '';

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin' check (role = 'admin'),
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text unique not null,
  client_request_id uuid unique not null default gen_random_uuid(),
  access_token_hash text not null,
  customer_name text not null,
  phone text not null,
  city text not null,
  address text not null,
  payment_method text not null check (payment_method in ('cash', 'instapay')),
  payment_status text not null default 'pending' check (payment_status in ('pending', 'confirmed', 'rejected')),
  order_status text not null default 'pending' check (order_status in ('pending', 'confirmed', 'preparing', 'shipped', 'sold', 'cancelled')),
  subtotal numeric(12,2) not null check (subtotal >= 0),
  shipping_fee numeric(12,2) not null check (shipping_fee >= 0),
  total numeric(12,2) not null check (total >= 0),
  payment_proof_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  unit_price numeric(12,2) not null check (unit_price >= 0),
  quantity integer not null check (quantity > 0),
  size text,
  color text,
  created_at timestamptz not null default now()
);

create index if not exists products_active_created_idx on public.products(is_active, created_at desc);
create index if not exists products_active_sales_idx on public.products(is_active, sales_count desc, created_at desc);
create index if not exists products_category_created_idx on public.products(category_id, is_active, created_at desc);
create index if not exists orders_created_idx on public.orders(created_at desc);
create index if not exists orders_status_created_idx on public.orders(order_status, created_at desc);
create index if not exists orders_payment_status_idx on public.orders(payment_status, created_at desc);
create index if not exists order_items_order_idx on public.order_items(order_id);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
security invoker
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists products_touch_updated_at on public.products;
create trigger products_touch_updated_at before update on public.products for each row execute function public.touch_updated_at();
drop trigger if exists orders_touch_updated_at on public.orders;
create trigger orders_touch_updated_at before update on public.orders for each row execute function public.touch_updated_at();
drop trigger if exists settings_touch_updated_at on public.store_settings;
create trigger settings_touch_updated_at before update on public.store_settings for each row execute function public.touch_updated_at();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users
    where user_id = auth.uid()
  );
$$;

-- Sales are derived from orders marked as sold, never from cart creation.
create or replace function public.apply_sales_counter()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  direction integer := 0;
  row_item record;
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  if old.order_status <> 'sold' and new.order_status = 'sold' then
    if new.payment_status <> 'confirmed' then
      raise exception 'PAYMENT_NOT_CONFIRMED';
    end if;
    direction := 1;
  elsif old.order_status = 'sold' and new.order_status <> 'sold' then
    direction := -1;
  else
    return new;
  end if;

  for row_item in select product_id, quantity from public.order_items where order_id = new.id and product_id is not null loop
    update public.products
    set sales_count = greatest(0, sales_count + (direction * row_item.quantity))
    where id = row_item.product_id;
  end loop;

  return new;
end;
$$;

drop trigger if exists orders_apply_sales on public.orders;
create trigger orders_apply_sales after update of order_status on public.orders for each row execute function public.apply_sales_counter();


create or replace function public.prevent_invalid_sold_payment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.order_status = 'sold' and new.payment_status <> 'confirmed' then
    raise exception 'SOLD_ORDER_PAYMENT_MUST_REMAIN_CONFIRMED';
  end if;
  return new;
end;
$$;

drop trigger if exists orders_validate_sold_payment on public.orders;
create trigger orders_validate_sold_payment
before update of payment_status on public.orders
for each row execute function public.prevent_invalid_sold_payment();

create or replace function public.get_home_content()
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  select jsonb_build_object(
    'hero', coalesce((select value from public.store_content where key = 'hero'), '{}'::jsonb),
    'about', coalesce((select value from public.store_content where key = 'about'), '{}'::jsonb),
    'socials', coalesce((select value from public.store_content where key = 'socials'), '{}'::jsonb),
    'contact', coalesce((select value from public.store_content where key = 'contact'), '{}'::jsonb),
    'categories', coalesce((
      select jsonb_agg(to_jsonb(c) order by c.sort_order, c.created_at)
      from (select id,name,image_url,sort_order,created_at from public.categories where is_active order by sort_order, created_at limit 12) c
    ), '[]'::jsonb),
    'services', coalesce((
      select jsonb_agg(to_jsonb(s) order by s.sort_order)
      from (select title,subtitle,icon from public.services where is_active order by sort_order limit 8) s
    ), '[]'::jsonb),
    'best_sellers', coalesce((
      select jsonb_agg(to_jsonb(p) order by p.sales_count desc, p.created_at desc)
      from (select id,name,image_url,images,description,price,old_price,rating,review_count,colors,sizes,category_id,created_at,sales_count from public.products where is_active order by sales_count desc, created_at desc limit 8) p
    ), '[]'::jsonb),
    'new_arrivals', coalesce((
      select jsonb_agg(to_jsonb(p) order by p.created_at desc)
      from (select id,name,image_url,images,description,price,old_price,rating,review_count,colors,sizes,category_id,created_at,sales_count from public.products where is_active order by created_at desc limit 8) p
    ), '[]'::jsonb),
    'banners', coalesce((
      select jsonb_agg(to_jsonb(b) order by b.sort_order, b.created_at)
      from (select image_url,title,button_text,target from public.banners where is_active order by sort_order, created_at limit 8) b
    ), '[]'::jsonb),
    'settings', coalesce((select to_jsonb(s) from public.store_settings s where id = 1), '{}'::jsonb)
  );
$$;

grant execute on function public.get_home_content() to anon, authenticated;

grant execute on function public.is_admin() to anon, authenticated;

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
  if nullif(trim(p_customer_name), '') is null or length(trim(p_customer_name)) < 2 then raise exception 'INVALID_NAME'; end if;
  if regexp_replace(p_phone, '[^0-9+]', '', 'g') !~ '^[0-9+]{10,15}$' then raise exception 'INVALID_PHONE'; end if;
  if nullif(trim(p_city), '') is null or nullif(trim(p_address), '') is null then raise exception 'INVALID_ADDRESS'; end if;
  if p_payment_method not in ('cash','instapay') then raise exception 'INVALID_PAYMENT_METHOD'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then raise exception 'EMPTY_CART'; end if;

  select * into v_existing from public.orders where client_request_id = p_client_request_id limit 1;
  if found then
    return jsonb_build_object('order_id',v_existing.id,'order_number',v_existing.order_number,'access_token',v_raw_token,'subtotal',v_existing.subtotal,'shipping_fee',v_existing.shipping_fee,'total',v_existing.total);
  end if;

  select * into v_settings from public.store_settings where id = 1;
  if not found then raise exception 'STORE_SETTINGS_NOT_FOUND'; end if;

  -- Calculate against current database prices. Client-supplied prices are never trusted.
  for item in select value from jsonb_array_elements(p_items) loop
    v_quantity := greatest(1, least(coalesce((item->>'quantity')::int, 1), 99));
    select id, name, price, is_active into product_row from public.products where id = (item->>'productId')::uuid for update;
    if not found or not product_row.is_active then raise exception 'PRODUCT_UNAVAILABLE'; end if;
    v_subtotal := v_subtotal + (product_row.price * v_quantity);
  end loop;

  if v_subtotal < v_settings.free_shipping_threshold then v_shipping := v_settings.shipping_fee; end if;
  v_total := v_subtotal + v_shipping;
  v_order_number := 'MM-' || to_char(clock_timestamp(), 'YYMMDDHH24MISS') || '-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));

  insert into public.orders(
    id,order_number,client_request_id,access_token_hash,customer_name,phone,city,address,
    payment_method,payment_status,order_status,subtotal,shipping_fee,total
  ) values (
    v_order_id,v_order_number,p_client_request_id,crypt(v_raw_token,gen_salt('bf')),trim(p_customer_name),trim(p_phone),trim(p_city),trim(p_address),
    p_payment_method,case when p_payment_method='cash' then 'confirmed' else 'pending' end,'pending',v_subtotal,v_shipping,v_total
  );

  for item in select value from jsonb_array_elements(p_items) loop
    v_quantity := greatest(1, least(coalesce((item->>'quantity')::int, 1), 99));
    v_size := nullif(trim(item->>'size'), '');
    v_color := nullif(trim(item->>'color'), '');
    select id, name, price, is_active into product_row from public.products where id = (item->>'productId')::uuid for update;
    if not found or not product_row.is_active then raise exception 'PRODUCT_UNAVAILABLE'; end if;
    insert into public.order_items(order_id,product_id,product_name,unit_price,quantity,size,color)
    values(v_order_id,product_row.id,product_row.name,product_row.price,v_quantity,v_size,v_color);
  end loop;

  return jsonb_build_object('order_id',v_order_id,'order_number',v_order_number,'access_token',v_raw_token,'subtotal',v_subtotal,'shipping_fee',v_shipping,'total',v_total);
exception when unique_violation then
  select * into v_existing from public.orders where client_request_id = p_client_request_id limit 1;
  if found then
    return jsonb_build_object('order_id',v_existing.id,'order_number',v_existing.order_number,'access_token',v_raw_token,'subtotal',v_existing.subtotal,'shipping_fee',v_existing.shipping_fee,'total',v_existing.total);
  end if;
  raise;
end;
$$;

grant execute on function public.create_order(text,text,text,text,text,jsonb,uuid) to anon;

-- Attach an InstaPay proof using the per-order access token returned during checkout.
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
  select id, access_token_hash, payment_method, payment_proof_path into o from public.orders where id = p_order_id;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if o.payment_method <> 'instapay' then raise exception 'NOT_INSTAPAY_ORDER'; end if;
  if crypt(p_access_token, o.access_token_hash) <> o.access_token_hash then raise exception 'INVALID_ACCESS_TOKEN'; end if;
  if o.payment_proof_path is not null then raise exception 'PROOF_ALREADY_ATTACHED'; end if;
  if p_proof_path !~ ('^orders/' || p_order_id::text || '/[^/]+/.+\.(jpg|jpeg|png|webp)$') then raise exception 'INVALID_PROOF_PATH'; end if;

  update public.orders set payment_proof_path = p_proof_path where id = p_order_id;
end;
$$;

grant execute on function public.create_order(text,text,text,text,text,jsonb,uuid) to anon;
grant execute on function public.attach_payment_proof(uuid,text,text) to anon;

create or replace function public.get_admin_dashboard()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  if not public.is_admin() then raise exception 'NOT_ADMIN'; end if;
  select jsonb_build_object(
    'total_orders',(select count(*) from public.orders),
    'today_orders',(select count(*) from public.orders where created_at >= current_date),
    'pending_orders',(select count(*) from public.orders where order_status in ('pending','confirmed','preparing','shipped')),
    'sold_orders',(select count(*) from public.orders where order_status='sold'),
    'revenue',(select coalesce(sum(total),0) from public.orders where order_status='sold')
  ) into result;
  return result;
end;
$$;
grant execute on function public.get_admin_dashboard() to authenticated;

-- RLS
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.banners enable row level security;
alter table public.services enable row level security;
alter table public.store_content enable row level security;
alter table public.store_settings enable row level security;
alter table public.admin_users enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

drop policy if exists categories_public_read on public.categories;
create policy categories_public_read on public.categories for select to anon, authenticated using (is_active = true or public.is_admin());
drop policy if exists categories_admin_write on public.categories;
create policy categories_admin_write on public.categories for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists products_public_read on public.products;
create policy products_public_read on public.products for select to anon, authenticated using (is_active = true or public.is_admin());
drop policy if exists products_admin_write on public.products;
create policy products_admin_write on public.products for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists banners_public_read on public.banners;
create policy banners_public_read on public.banners for select to anon, authenticated using (is_active = true or public.is_admin());
drop policy if exists banners_admin_write on public.banners;
create policy banners_admin_write on public.banners for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists services_public_read on public.services;
create policy services_public_read on public.services for select to anon, authenticated using (is_active = true or public.is_admin());
drop policy if exists services_admin_write on public.services;
create policy services_admin_write on public.services for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists content_public_read on public.store_content;
create policy content_public_read on public.store_content for select to anon, authenticated using (true);
drop policy if exists content_admin_write on public.store_content;
create policy content_admin_write on public.store_content for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists settings_public_read on public.store_settings;
create policy settings_public_read on public.store_settings for select to anon, authenticated using (true);
drop policy if exists settings_admin_write on public.store_settings;
create policy settings_admin_write on public.store_settings for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists admin_users_self_read on public.admin_users;
create policy admin_users_self_read on public.admin_users for select to authenticated using (user_id = auth.uid());

drop policy if exists orders_admin_read on public.orders;
create policy orders_admin_read on public.orders for select to authenticated using (public.is_admin());
drop policy if exists orders_admin_update on public.orders;
create policy orders_admin_update on public.orders for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists order_items_admin_read on public.order_items;
create policy order_items_admin_read on public.order_items for select to authenticated using (public.is_admin());

-- Explicit grants: customer gets only RPC/read access; direct order writes are blocked.
grant select on public.categories, public.products, public.banners, public.services, public.store_content, public.store_settings to anon, authenticated;
grant select, insert, update, delete on public.categories, public.products, public.banners, public.services, public.store_content, public.store_settings to authenticated;
grant select on public.admin_users to authenticated;
grant select, update on public.orders to authenticated;
grant select on public.order_items to authenticated;

-- Storage buckets
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('product-images','product-images',true,10485760,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = excluded.public;
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('payment-proofs','payment-proofs',false,10485760,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = excluded.public;

-- Public CDN reads for catalog media.
drop policy if exists product_images_public_read on storage.objects;
create policy product_images_public_read on storage.objects for select to anon, authenticated using (bucket_id='product-images');
drop policy if exists product_images_admin_insert on storage.objects;
create policy product_images_admin_insert on storage.objects for insert to authenticated with check (bucket_id='product-images' and public.is_admin());
drop policy if exists product_images_admin_update on storage.objects;
create policy product_images_admin_update on storage.objects for update to authenticated using (bucket_id='product-images' and public.is_admin()) with check (bucket_id='product-images' and public.is_admin());
drop policy if exists product_images_admin_delete on storage.objects;
create policy product_images_admin_delete on storage.objects for delete to authenticated using (bucket_id='product-images' and public.is_admin());

-- Payment proof is private. The anonymous client can upload only beneath the exact order/access-token prefix.
create or replace function public.can_upload_payment_proof(object_name text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  parts text[] := string_to_array(object_name,'/');
  o record;
begin
  if array_length(parts,1) <> 4 or parts[1] <> 'orders' then return false; end if;
  select id,access_token_hash,payment_method,payment_proof_path into o from public.orders where id = parts[2]::uuid;
  if not found or o.payment_method <> 'instapay' or o.payment_proof_path is not null then return false; end if;
  return crypt(parts[3],o.access_token_hash)=o.access_token_hash;
exception when others then
  return false;
end;
$$;
grant execute on function public.can_upload_payment_proof(text) to anon, authenticated;

drop policy if exists payment_proofs_insert on storage.objects;
create policy payment_proofs_insert on storage.objects for insert to anon, authenticated with check (bucket_id='payment-proofs' and public.can_upload_payment_proof(name));
drop policy if exists payment_proofs_admin_read on storage.objects;
create policy payment_proofs_admin_read on storage.objects for select to authenticated using (bucket_id='payment-proofs' and public.is_admin());
drop policy if exists payment_proofs_admin_delete on storage.objects;
create policy payment_proofs_admin_delete on storage.objects for delete to authenticated using (bucket_id='payment-proofs' and public.is_admin());

-- Realtime for the admin orders screen.
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='orders') then
    alter publication supabase_realtime add table public.orders;
  end if;
end $$;
