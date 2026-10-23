import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_route_names.dart';
import '../admin_notifications_cubit.dart';

class AdminNotificationBell extends StatelessWidget {
  const AdminNotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminNotificationsCubit, AdminNotificationsState>(
      builder: (context, state) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
              tooltip: 'إشعارات الطلبات',
              onPressed: () async {
                final orderId = await context
                    .read<AdminNotificationsCubit>()
                    .openLatestUnreadOrder();
                if (!context.mounted) return;
                if (orderId == null) {
                  context.pushNamed(AppRouteNames.adminOrders);
                  return;
                }
                context.pushNamed(
                  AppRouteNames.adminOrders,
                  queryParameters: {'orderId': orderId},
                );
              },
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            if (state.unread > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 19),
                  height: 19,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppConstants.gold,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppConstants.black, width: 2),
                  ),
                  child: Text(
                    '${state.unread}',
                    style: const TextStyle(
                      color: AppConstants.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
