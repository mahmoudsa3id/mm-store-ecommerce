import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    this.cartCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
        decoration: BoxDecoration(
          color: AppConstants.black.withValues(alpha: .98),
          border: const Border(top: BorderSide(color: AppConstants.border)),
          boxShadow: const [AppConstants.shadow],
        ),
        child: Row(
          children: [
            _Item(
              index: 0,
              icon: Icons.home_rounded,
              label: 'الرئيسية',
              current: currentIndex,
              onTap: onChanged,
            ),
            _Item(
              index: 1,
              icon: Icons.grid_view_rounded,
              label: 'الأقسام',
              current: currentIndex,
              onTap: onChanged,
            ),
            _Item(
              index: 2,
              icon: Icons.favorite_rounded,
              label: 'المفضلة',
              current: currentIndex,
              onTap: onChanged,
            ),
            _Item(
              index: 3,
              icon: Icons.shopping_bag_rounded,
              label: 'السلة',
              current: currentIndex,
              onTap: onChanged,
              badge: cartCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.index,
    required this.icon,
    required this.label,
    required this.current,
    required this.onTap,
    this.badge = 0,
  });

  final int index;
  final IconData icon;
  final String label;
  final int current;
  final ValueChanged<int> onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final selected = index == current;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppConstants.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected ? const [AppConstants.goldGlow] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 21,
                    color: selected
                        ? AppConstants.black
                        : AppConstants.textSecondary,
                  ),
                  if (badge > 0)
                    Positioned(
                      top: -8,
                      right: -10,
                      child: Container(
                        width: 17,
                        height: 17,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppConstants.textPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: AppConstants.black,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? AppConstants.black
                      : AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
