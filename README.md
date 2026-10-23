# MM Store — Premium Production Flutter Ecommerce

MM Store is a responsive Flutter ecommerce storefront with a dedicated admin application, Supabase backend, guest checkout, local favorites, image optimization and premium black/gold UI.

## Architecture

- Flutter / Dart 3.12+
- BLoC / Cubit
- Feature-first structure
- Repository pattern
- GetIt dependency injection
- dartz `Either` for typed failures in critical flows
- Centralized error mapping
- Supabase Auth / PostgreSQL / Storage / Realtime
- SharedPreferences for guest cart and favorites
- Lottie micro-interactions
- Responsive containers and grids for mobile, tablet and web
- Cairo typography

## Brand system

The design system is centralized in:

`lib/core/constants/app_constants.dart`

The UI is built around the MM Store identity:

- deep black backgrounds
- crown gold accents
- gold glow / glass panels
- premium RTL typography
- the MM Store hero artwork as a subtle background texture

## Customer app

Web:

```bash
flutter pub get
flutter run -d chrome -t lib/main.dart
```

Android:

```bash
flutter run --flavor customer -t lib/main.dart
```

Release web:

```bash
flutter build web --release -t lib/main.dart
```

## Admin app

The admin application uses its own Dart entrypoint and the Android `admin` product flavor.

Web:

```bash
flutter run -d chrome -t lib/main_admin.dart
```

Android:

```bash
flutter run --flavor admin -t lib/main_admin.dart
```

The admin account must exist in Supabase Auth and its user UUID must be present in `public.admin_users`.

## Supabase setup

For a fresh development database:

`supabase/MM_STORE_SETUP_FINAL.sql`

For the already-configured production database:

`supabase/MM_STORE_MIGRATION_FINAL.sql`

Do not rerun the reset setup script on a production database because it drops and recreates the MM Store tables.

The admin controls:

- products and product images
- categories and category images
- banners and banner images
- Hero / About / Social / Contact content
- services
- cash number
- InstaPay number
- phone / WhatsApp
- shipping fee
- free-shipping threshold
- order/payment status

Customer checkout reads the payment settings directly from Supabase, so changing Cash or InstaPay numbers in Admin Settings changes checkout without a new build.

## Favorites

Favorites are guest/local only. Product IDs are stored in SharedPreferences and product details are refreshed from Supabase. The heart state is shared by product cards, product details and the Favorites page.

## Image optimization

Images selected by the admin are optimized before upload:

- products: resize to a maximum width of 1200px, WebP quality 82
- store media: resize to a maximum width of 1600px, WebP quality 82
- payment proofs: resize to a maximum width of 1600px, WebP quality 78

The processing runs off the UI isolate and public media is uploaded with long cache headers.

## Notifications

New orders create a persistent row in `public.admin_notifications` through a database trigger.

The admin app subscribes to that table through Supabase Realtime and shows:

- unread count on the admin notification bell
- in-app SnackBar for new orders
- Android / iOS / desktop local notifications
- browser notifications on supported web browsers after permission is granted

The Web Notifications API requires permission to be requested from a user action such as clicking the notification control. citeturn435933search2turn435933search3

This implementation is designed for a running admin session. True push delivery when the web admin is completely closed requires a Web Push/FCM service worker and a server-side push sender.

Supabase Flutter Realtime supports listening to Postgres table changes; this project uses that capability for admin order notifications. citeturn729685search3turn729685search5

## Production verification

Run these on a machine with Flutter SDK installed:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build web --release -t lib/main.dart
flutter build web --release -t lib/main_admin.dart
```

Android release signing still needs the final production keystore configured for the store owner. The project currently keeps the development/debug signing configuration so the flavor can be run locally without a private keystore.
