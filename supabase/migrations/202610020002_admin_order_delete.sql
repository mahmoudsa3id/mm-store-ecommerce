drop policy if exists orders_admin_delete on public.orders;
create policy orders_admin_delete
on public.orders
for delete to authenticated
using (public.is_admin());

grant delete on public.orders to authenticated;