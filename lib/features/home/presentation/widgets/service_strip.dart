import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/home_entity.dart';

class ServiceStrip extends StatelessWidget {
  const ServiceStrip({super.key, required this.items});

  final List<ServiceEntity> items;

  IconData _icon(String name) => switch (name) {
    'verified' => Icons.verified_rounded,
    'shield' => Icons.shield_outlined,
    'truck' => Icons.local_shipping_rounded,
    'support' => Icons.support_agent_rounded,
    _ => Icons.workspace_premium_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppConstants.gold.withValues(alpha: .12)),
        boxShadow: const [AppConstants.shadow],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Expanded(
            child: _ServiceItem(
              icon: _icon(item.icon),
              title: item.title,
              subtitle: item.subtitle,
            ),
          );
        }),
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  const _ServiceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppConstants.black,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppConstants.gold.withValues(alpha: .25),
              ),
              boxShadow: const [AppConstants.goldGlow],
            ),
            child: Icon(icon, size: 21, color: AppConstants.gold),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppConstants.muted,
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: 22,
            height: 2,
            decoration: BoxDecoration(
              color: AppConstants.gold,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}
