import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_constants.dart';

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key, this.child, this.imageUrl});

  final Widget? child;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppConstants.page),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: .045,
              child: SvgPicture.asset(
                'assets/svgs/mm_store_hero.svg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ),
        if (imageUrl != null && imageUrl!.isNotEmpty && !imageUrl!.startsWith('assets/'))
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: .035,
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        PositionedDirectional(
          end: -34,
          bottom: -18,
          child: IgnorePointer(
            child: Opacity(
              opacity: .025,
              child: SizedBox(
                width: 230,
                child: SvgPicture.asset(
                  'assets/svgs/MM_Store_Logo_Premium.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -180,
          right: -120,
          child: _Glow(size: 420, opacity: .16),
        ),
        Positioned(
          bottom: -230,
          left: -180,
          child: _Glow(size: 470, opacity: .11),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppConstants.gold.withValues(alpha: opacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
