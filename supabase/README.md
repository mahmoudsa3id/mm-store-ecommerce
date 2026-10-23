# MM Store Supabase

## Existing database

The current production setup has already been created from the corrected full schema.
Do not rerun the reset setup against a database that contains production data.

For the current project, run:

1. `MM_STORE_MIGRATION_FINAL.sql`
2. `migrations/202610020001_admin_fcm_push.sql`

This migration is non-destructive and adds:

- `store-media` bucket and admin policies.
- `cash_number` compatibility on `store_settings`.
- Persistent `admin_notifications` records.
- A trigger that creates an admin notification when a new order is inserted.
- FCM delivery to registered admin devices (after applying the Android push migration below).

## Fresh database

For a completely fresh development database, use the corrected:

`MM_STORE_SETUP_FINAL.sql`

It creates the full MM Store schema, RLS, storage, functions, seed data, and
the orders Realtime publication. Apply
`migrations/202610020001_admin_fcm_push.sql` afterward to enable Android FCM.

## Admin user

1. Create a user in Supabase Auth.
2. Copy the user UUID.
3. Run:

```sql
insert into public.admin_users(user_id)
values ('YOUR_AUTH_USER_UUID')
on conflict (user_id) do nothing;
```

## Notification behavior

Android admin order alerts are sent through FCM. The admin bell reads persisted
unread notification records; it does not subscribe to Supabase Realtime or show
a second local alert. Web push is not configured by this Android FCM flow.

## Android admin order push

The Android admin app receives order alerts through FCM. Apply
`migrations/202610020001_admin_fcm_push.sql` to add admin-only device tokens,
idempotent push tracking, and an after-insert database webhook. The webhook
does not use Supabase Realtime. Create these two Supabase Vault secrets, using
the deployed function URL and a long random value for the shared secret:

```sql
select vault.create_secret('https://<project-ref>.supabase.co/functions/v1/notify-admin-order', 'admin_order_push_url');
select vault.create_secret('<long-random-secret>', 'admin_order_push_secret');
```

Set the same random value and the Firebase service-account JSON as Edge Function
secrets, then deploy:

```sh
supabase secrets set ADMIN_ORDER_PUSH_SECRET='<long-random-secret>'
supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
supabase functions deploy notify-admin-order
```

The Firebase service account needs permission to send Firebase Cloud Messaging
messages. The function uses the Supabase service-role key supplied by the Edge
Functions runtime. The admin flavor uses the existing base Firebase client
application ID. The customer flavor has the `.customer` suffix and needs its
own Firebase Android app registration and matching source-set configuration.
