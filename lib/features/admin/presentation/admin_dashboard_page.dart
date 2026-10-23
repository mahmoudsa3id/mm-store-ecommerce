import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_route_names.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/widgets/premium_panel.dart';
import 'admin_auth_cubit.dart';
import 'admin_dashboard_cubit.dart';
import 'admin_notifications_cubit.dart';
import 'widgets/admin_notification_bell.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminDashboardCubit>().load();
    context.read<AdminNotificationsCubit>().start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.page,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MM Store Admin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(
              'إدارة المتجر بالكامل من مكان واحد',
              style: TextStyle(
                fontSize: 10,
                color: AppConstants.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          const AdminNotificationBell(),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await context.read<AdminAuthCubit>().logout();
              if (!context.mounted) return;
              context.goNamed(AppRouteNames.adminLogin);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        builder: (context, state) {
          if (state.loading && state.data.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: AppConstants.gold,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppConstants.muted),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          context.read<AdminDashboardCubit>().load(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator.adaptive(
            color: AppConstants.gold,
            backgroundColor: AppConstants.surface,
            onRefresh: context.read<AdminDashboardCubit>().load,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final content = [
                  const AnimatedEntrance(child: _WelcomeBanner()),
                  const SizedBox(height: 16),
                  _Metrics(data: state.data),
                  const SizedBox(height: 18),
                  _QuickActions(wide: wide),
                ];

                return Stack(
                  children: [
                    const Positioned.fill(child: PremiumBackground()),
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: content,
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppConstants.surfaceElevated, AppConstants.black],
        ),
        border: Border.all(color: AppConstants.gold.withValues(alpha: .32)),
        boxShadow: const [AppConstants.goldGlow],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً بيك 👋',
                  style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'تابع الطلبات، المنتجات، المحتوى، وأرقام الدفع من هنا.',
                  style: TextStyle(
                    color: AppConstants.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.auto_awesome_rounded, color: AppConstants.gold, size: 44),
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 5
            : constraints.maxWidth >= 620
            ? 3
            : 2;
        final metrics = [
          _MetricData(
            'إجمالي الطلبات',
            '${data['total_orders'] ?? 0}',
            Icons.receipt_long_outlined,
          ),
          _MetricData(
            'طلبات اليوم',
            '${data['today_orders'] ?? 0}',
            Icons.today_outlined,
          ),
          _MetricData(
            'قيد التنفيذ',
            '${data['pending_orders'] ?? 0}',
            Icons.timelapse_rounded,
          ),
          _MetricData(
            'تم البيع',
            '${data['sold_orders'] ?? 0}',
            Icons.check_circle_outline_rounded,
          ),
          _MetricData(
            'الإيراد',
            '${data['revenue'] ?? 0} EGP',
            Icons.payments_outlined,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 138,
          ),
          itemBuilder: (_, index) => AnimatedEntrance(
            delay: Duration(milliseconds: 60 * index),
            child: _MetricCard(data: metrics[index]),
          ),
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData(this.title, this.value, this.icon);
  final String title;
  final String value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppConstants.gold.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.gold.withValues(alpha: .22),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: AppConstants.gold,
            ),
          ),
          const Spacer(),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 11,
              color: AppConstants.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              data.value,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        'الطلبات',
        'راجع وغيّر حالة الطلبات',
        Icons.receipt_long_rounded,
        AppRouteNames.adminOrders,
      ),
      _ActionData(
        'المنتجات',
        'إضافة وتعديل الصور والأسعار',
        Icons.inventory_2_rounded,
        AppRouteNames.adminProducts,
      ),
      _ActionData(
        'المحتوى',
        'الأقسام والبنرات وHero',
        Icons.dashboard_customize_rounded,
        AppRouteNames.adminContent,
      ),
      _ActionData(
        'الإعدادات',
        'كاش وInstaPay والشحن',
        Icons.settings_rounded,
        AppRouteNames.adminSettings,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إدارة المتجر',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: wide ? 4 : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: wide ? 1.35 : 1.1,
          ),
          itemBuilder: (_, index) => _QuickActionCard(
            data: actions[index],
            onTap: () => context.pushNamed(actions[index].route),
          ),
        ),
      ],
    );
  }
}

class _ActionData {
  const _ActionData(this.title, this.subtitle, this.icon, this.route);
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({required this.data, required this.onTap});
  final _ActionData data;
  final VoidCallback onTap;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedScale(
        scale: hovered ? 1.015 : 1,
        duration: const Duration(milliseconds: 160),
        child: PremiumPanel(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.data.icon, size: 28, color: AppConstants.gold),
                const Spacer(),
                Text(
                  widget.data.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppConstants.muted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

