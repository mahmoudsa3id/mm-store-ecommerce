import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mm_store/features/catalog/presentation/caregory_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../di/injection.dart';
import '../flavor/app_flavor.dart';
import '../../features/admin/presentation/admin_content_cubit.dart';
import '../../features/admin/presentation/admin_content_page.dart';
import '../../features/admin/presentation/admin_dashboard_cubit.dart';
import '../../features/admin/presentation/admin_dashboard_page.dart';
import '../../features/admin/presentation/admin_login_page.dart';
import '../../features/admin/presentation/admin_orders_cubit.dart';
import '../../features/admin/presentation/admin_orders_page.dart';
import '../../features/admin/presentation/admin_notifications_cubit.dart';
import '../../features/admin/presentation/admin_products_cubit.dart';
import '../../features/admin/presentation/admin_products_page.dart';
import '../../features/admin/presentation/admin_settings_cubit.dart';
import '../../features/admin/presentation/admin_settings_page.dart';
import '../../features/cart/presentation/cart_page.dart';
import '../../features/catalog/data/catalog_repository.dart';
import '../../features/catalog/presentation/catalog_page.dart';
import '../../features/checkout/data/checkout_repository.dart';
import '../../features/checkout/presentation/checkout_cubit.dart';
import '../../features/checkout/presentation/checkout_page.dart';
import '../../features/checkout/presentation/order_success_page.dart';
import '../../features/favorites/presentation/favorites_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/product_details/presentation/product_details_page.dart';
import '../../features/search/presentation/search_page.dart';
import 'app_route_names.dart';
import 'app_routes.dart';

GoRouter createRouter(AppFlavor flavor) {
  final customerRoutes = <RouteBase>[
    GoRoute(
      path: AppRoutes.home,
      name: AppRouteNames.home,
      builder: (_, __) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.categories,
      name: AppRouteNames.categories,
      builder: (_, __) => RepositoryProvider<CatalogRepository>.value(
        value: sl<CatalogRepository>(),
        child: const CategoriesPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.catalog,
      name: AppRouteNames.catalog,
      builder: (_, state) => RepositoryProvider<CatalogRepository>.value(
        value: sl<CatalogRepository>(),
        child: CatalogPage(
          sort: state.uri.queryParameters['sort'] == 'best' ? 'best' : 'new',
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.categoryProducts,
      name: AppRouteNames.categoryProducts,
      builder: (_, state) => RepositoryProvider<CatalogRepository>.value(
        value: sl<CatalogRepository>(),
        child: CatalogPage(categoryId: state.pathParameters['categoryId']),
      ),
    ),
    GoRoute(
      path: AppRoutes.search,
      name: AppRouteNames.search,
      builder: (_, state) => RepositoryProvider<CatalogRepository>.value(
        value: sl<CatalogRepository>(),
        child: SearchPage(initialQuery: state.uri.queryParameters['q']),
      ),
    ),
    GoRoute(
      path: AppRoutes.productDetails,
      name: AppRouteNames.productDetails,
      builder: (_, state) => RepositoryProvider<CatalogRepository>.value(
        value: sl<CatalogRepository>(),
        child: ProductDetailsPage(
          productId: state.pathParameters['productId']!,
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.cart,
      name: AppRouteNames.cart,
      builder: (_, __) => const CartPage(),
    ),
    GoRoute(
      path: AppRoutes.checkout,
      name: AppRouteNames.checkout,
      builder: (_, __) => BlocProvider(
        create: (_) => sl<CheckoutCubit>(),
        child: const CheckoutPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.orderSuccess,
      name: AppRouteNames.orderSuccess,
      builder: (_, state) =>
          OrderSuccessPage(result: state.extra! as OrderCreationResult),
    ),
    GoRoute(
      path: AppRoutes.favorites,
      name: AppRouteNames.favorites,
      builder: (_, __) => const FavoritesPage(),
    ),
  ];

  final adminRoutes = <RouteBase>[
    GoRoute(
      path: AppRoutes.adminLogin,
      name: AppRouteNames.adminLogin,
      builder: (_, __) => const AdminLoginPage(),
    ),
    GoRoute(
      path: AppRoutes.admin,
      name: AppRouteNames.admin,
      builder: (_, __) => MultiBlocProvider(
        providers: [
          BlocProvider<AdminDashboardCubit>(
            create: (_) => sl<AdminDashboardCubit>(),
          ),
          BlocProvider<AdminNotificationsCubit>(
            create: (_) => sl<AdminNotificationsCubit>(),
          ),
        ],
        child: const AdminDashboardPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminOrders,
      name: AppRouteNames.adminOrders,
      builder: (_, state) => BlocProvider(
        create: (_) => sl<AdminOrdersCubit>(),
        child: AdminOrdersPage(
          initialOrderId: state.uri.queryParameters['orderId'],
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminProducts,
      name: AppRouteNames.adminProducts,
      builder: (_, __) => BlocProvider(
        create: (_) => sl<AdminProductsCubit>(),
        child: const AdminProductsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminSettings,
      name: AppRouteNames.adminSettings,
      builder: (_, __) => BlocProvider(
        create: (_) => sl<AdminSettingsCubit>(),
        child: const AdminSettingsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminContent,
      name: AppRouteNames.adminContent,
      builder: (_, __) => BlocProvider(
        create: (_) => sl<AdminContentCubit>(),
        child: const AdminContentPage(),
      ),
    ),
  ];

  final isAdmin = flavor == AppFlavor.admin;

  return GoRouter(
    initialLocation: isAdmin ? AppRoutes.admin : AppRoutes.home,
    redirect: (context, state) async {
      if (!isAdmin) return null;

      final path = state.matchedLocation;
      final isAdminPath = path.startsWith('/admin');
      if (!isAdminPath) return AppRoutes.admin;

      final isLogin = path == AppRoutes.adminLogin;
      final client = sl<SupabaseClient>();
      final session = client.auth.currentSession;

      if (session == null) {
        return isLogin ? null : AppRoutes.adminLogin;
      }

      final isAdminUser = (await client.rpc('is_admin')) == true;
      if (!isAdminUser) {
        await client.auth.signOut();
        return AppRoutes.adminLogin;
      }

      return isLogin ? AppRoutes.admin : null;
    },
    routes: isAdmin ? adminRoutes : customerRoutes,
  );
}
