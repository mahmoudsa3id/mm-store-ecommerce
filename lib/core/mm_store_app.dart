import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'di/injection.dart';
import 'flavor/app_flavor.dart';
import 'notifications/admin_fcm_service.dart';
import 'router/app_route_names.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../features/admin/presentation/admin_auth_cubit.dart';
import '../features/cart/presentation/cart_cubit.dart';
import '../features/favorites/presentation/favorites_cubit.dart';
import '../features/home/presentation/cubit/home_cubit.dart';

class MMStoreApp extends StatefulWidget {
  const MMStoreApp({super.key, required this.flavor});

  final AppFlavor flavor;

  @override
  State<MMStoreApp> createState() => _MMStoreAppState();
}

class _MMStoreAppState extends State<MMStoreApp> {
  late final GoRouter _router = createRouter(widget.flavor);

  @override
  void initState() {
    super.initState();
    if (widget.flavor == AppFlavor.admin) {
      sl<AdminFcmService>().onOrderNotification = (orderId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _router.goNamed(
            AppRouteNames.adminOrders,
            queryParameters: {'orderId': orderId},
          );
        });
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        if (widget.flavor == AppFlavor.customer) ...[
          BlocProvider<CartCubit>(create: (_) => sl<CartCubit>()),
          BlocProvider<FavoritesCubit>(
            create: (_) => sl<FavoritesCubit>()..load(),
          ),
          BlocProvider<HomeCubit>(create: (_) => sl<HomeCubit>()..load()),
        ],
        if (widget.flavor == AppFlavor.admin)
          BlocProvider<AdminAuthCubit>(create: (_) => sl<AdminAuthCubit>()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: widget.flavor == AppFlavor.admin ? 'MM Store Admin' : 'MM Store',
        theme: AppTheme.light,
        routerConfig: _router,
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
