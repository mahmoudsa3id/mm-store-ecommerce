import 'package:get_it/get_it.dart';
import 'package:mm_store/core/notifications/admin_fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/admin/data/admin_auth_repository.dart';
import '../../features/admin/data/admin_content_repository.dart';
import '../../features/admin/data/admin_dashboard_repository.dart';
import '../../features/admin/data/admin_orders_repository.dart';
import '../../features/admin/data/admin_products_repository.dart';
import '../../features/admin/data/admin_settings_repository.dart';
import '../../features/admin/presentation/admin_auth_cubit.dart';
import '../../features/admin/presentation/admin_content_cubit.dart';
import '../../features/admin/presentation/admin_dashboard_cubit.dart';
import '../../features/admin/presentation/admin_orders_cubit.dart';
import '../../features/admin/presentation/admin_products_cubit.dart';
import '../../features/admin/presentation/admin_settings_cubit.dart';
import '../../features/admin/presentation/admin_notifications_cubit.dart';
import '../notifications/admin_notification_service.dart';
import '../../features/cart/data/cart_local_data_source.dart';
import '../../features/cart/data/cart_repository.dart';
import '../../features/cart/presentation/cart_cubit.dart';
import '../../features/catalog/data/catalog_repository.dart';
import '../../features/checkout/data/checkout_repository.dart';
import '../../features/checkout/presentation/checkout_cubit.dart';
import '../../features/favorites/data/favorites_local_data_source.dart';
import '../../features/favorites/data/favorites_repository.dart';
import '../../features/favorites/presentation/favorites_cubit.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/usecases/get_home_content.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../utils/image_upload.dart';
import '../flavor/app_flavor.dart';

final sl = GetIt.instance;

Future<void> configureDependencies(
  SupabaseClient client, {
  required AppFlavor flavor,
}) async {
  final prefs = sl.isRegistered<SharedPreferences>()
      ? sl<SharedPreferences>()
      : await SharedPreferences.getInstance();

  if (!sl.isRegistered<SharedPreferences>()) {
    sl.registerSingleton<SharedPreferences>(prefs);
  }

  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerSingleton<SupabaseClient>(client);
  }

  sl.allowReassignment = true;

  if (!sl.isRegistered<CartRepository>()) {
    sl.registerLazySingleton(
      () => CartRepository(CartLocalDataSource(sl<SharedPreferences>())),
    );
  }
  if (!sl.isRegistered<CartCubit>()) {
    sl.registerFactory(() => CartCubit(sl<CartRepository>()));
  }
  sl.registerLazySingleton<AdminFcmService>(
    () => AdminFcmService(sl<SupabaseClient>()),
  );
  if (!sl.isRegistered<ImageUploadService>()) {
    sl.registerLazySingleton(() => ImageUploadService(client));
  }

  if (!sl.isRegistered<HomeRemoteDataSource>()) {
    sl.registerLazySingleton(() => HomeRemoteDataSource(client));
  }

  if (!sl.isRegistered<HomeRepositoryImpl>()) {
    sl.registerLazySingleton(
      () => HomeRepositoryImpl(remote: sl<HomeRemoteDataSource>()),
    );
  }
  if (!sl.isRegistered<GetHomeContent>()) {
    sl.registerLazySingleton(() => GetHomeContent(sl<HomeRepositoryImpl>()));
  }
  if (!sl.isRegistered<HomeCubit>()) {
    sl.registerFactory(() => HomeCubit(sl<GetHomeContent>()));
  }

  if (!sl.isRegistered<CatalogRepository>()) {
    sl.registerLazySingleton(() => CatalogRepository(client));
  }

  if (!sl.isRegistered<CheckoutRepository>()) {
    sl.registerLazySingleton(
      () => CheckoutRepository(client, sl<ImageUploadService>()),
    );
  }
  if (!sl.isRegistered<CheckoutCubit>()) {
    sl.registerFactory(() => CheckoutCubit(sl<CheckoutRepository>()));
  }

  if (!sl.isRegistered<FavoritesLocalDataSource>()) {
    sl.registerLazySingleton(
      () => FavoritesLocalDataSource(sl<SharedPreferences>()),
    );
  }
  if (!sl.isRegistered<FavoritesRepository>()) {
    sl.registerLazySingleton(
      () => FavoritesRepository(sl<FavoritesLocalDataSource>()),
    );
  }
  if (!sl.isRegistered<FavoritesCubit>()) {
    sl.registerFactory(
      () => FavoritesCubit(sl<FavoritesRepository>(), sl<CatalogRepository>()),
    );
  }

  if (flavor == AppFlavor.admin) {
    if (!sl.isRegistered<AdminAuthRepository>()) {
      sl.registerLazySingleton(() => AdminAuthRepository(client));
    }
    if (!sl.isRegistered<AdminAuthCubit>()) {
      sl.registerFactory(
        () => AdminAuthCubit(sl<AdminAuthRepository>(), sl<AdminFcmService>()),
      );
    }

    if (!sl.isRegistered<AdminOrdersRepository>()) {
      sl.registerLazySingleton(
        () => AdminOrdersRepository(client, sl<ImageUploadService>()),
      );
    }
    if (!sl.isRegistered<AdminOrdersCubit>()) {
      sl.registerFactory(() => AdminOrdersCubit(sl<AdminOrdersRepository>()));
    }

    if (!sl.isRegistered<AdminProductsRepository>()) {
      sl.registerLazySingleton(
        () => AdminProductsRepository(client, sl<ImageUploadService>()),
      );
    }
    if (!sl.isRegistered<AdminProductsCubit>()) {
      sl.registerFactory(
        () => AdminProductsCubit(sl<AdminProductsRepository>()),
      );
    }

    if (!sl.isRegistered<AdminDashboardRepository>()) {
      sl.registerLazySingleton(() => AdminDashboardRepository(client));
    }
    if (!sl.isRegistered<AdminDashboardCubit>()) {
      sl.registerFactory(
        () => AdminDashboardCubit(sl<AdminDashboardRepository>()),
      );
    }

    if (!sl.isRegistered<AdminSettingsRepository>()) {
      sl.registerLazySingleton(() => AdminSettingsRepository(client));
    }
    if (!sl.isRegistered<AdminSettingsCubit>()) {
      sl.registerFactory(
        () => AdminSettingsCubit(sl<AdminSettingsRepository>()),
      );
    }

    if (!sl.isRegistered<AdminNotificationService>()) {
      sl.registerLazySingleton(() => AdminNotificationService(client));
    }
    if (!sl.isRegistered<AdminNotificationsCubit>()) {
      sl.registerFactory(
        () => AdminNotificationsCubit(
          sl<AdminNotificationService>(),
          sl<AdminFcmService>(),
        ),
      );
    }

    if (!sl.isRegistered<AdminContentRepository>()) {
      sl.registerLazySingleton(
        () => AdminContentRepository(client, sl<ImageUploadService>()),
      );
    }
    if (!sl.isRegistered<AdminContentCubit>()) {
      sl.registerFactory(() => AdminContentCubit(sl<AdminContentRepository>()));
    }
  }
}
