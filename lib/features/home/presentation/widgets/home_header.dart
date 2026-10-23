import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/animated_entrance.dart';

class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  const HomeHeader({
    super.key,
    required this.cartCount,
    this.onCartTap,
    this.onSearchTap,
    this.onFavoriteTap,
  });

  final int cartCount;
  final VoidCallback? onCartTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFavoriteTap;

  @override
  Size get preferredSize => const Size.fromHeight(152);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppConstants.black.withValues(alpha: .96),
        border: const Border(bottom: BorderSide(color: AppConstants.border)),
        boxShadow: const [AppConstants.shadow],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppConstants.blackSoft,
                border: Border(bottom: BorderSide(color: AppConstants.border)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MiniInfo(
                    icon: Icons.local_shipping_outlined,
                    text: 'شحن سريع',
                  ),
                  _Dot(),
                  _MiniInfo(
                    icon: Icons.workspace_premium_outlined,
                    text: 'خامات مختارة',
                  ),
                  _Dot(),
                  _MiniInfo(
                    icon: Icons.assignment_return_outlined,
                    text: 'إرجاع سهل',
                  ),
                ],
              ),
            ),
            AnimatedEntrance(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    _HeaderIcon(
                      icon: Icons.favorite_border_rounded,
                      onTap: onFavoriteTap,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onSearchTap,
                      child: SizedBox(
                        width: 145,
                        height: 48,
                        child: SvgPicture.asset(
                          'assets/svgs/MM_Store_Logo_Premium.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _CartButton(count: cartCount, onTap: onCartTap),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: GestureDetector(
                onTap: onSearchTap,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceElevated,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppConstants.border),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 12),
                      Icon(
                        Icons.search_rounded,
                        size: 19,
                        color: AppConstants.gold,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ابحث عن منتج أو قسم...',
                        style: TextStyle(
                          color: AppConstants.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.circle, size: 3, color: AppConstants.gold),
        const SizedBox(width: 5),
        Icon(icon, size: 13, color: AppConstants.gold),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 12,
      color: AppConstants.border,
      margin: const EdgeInsets.symmetric(horizontal: 9),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConstants.surfaceElevated,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.favorite_border_rounded,
            size: 20,
            color: AppConstants.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppConstants.gold,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 21,
                color: AppConstants.black,
              ),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: -4,
            right: -3,
            child: Container(
              width: 19,
              height: 19,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: AppConstants.textPrimary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
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
  }
}
