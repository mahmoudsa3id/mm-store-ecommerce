import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../domain/entities/home_entity.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key, required this.data, this.onAction});

  final HeroContent data;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 120),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.horizontalPadding,
          10,
          AppConstants.horizontalPadding,
          0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AspectRatio(
            aspectRatio: 1.68,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Background(image: data.image),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: [
                        Color(0xEE000000),
                        Color(0xB8000000),
                        Color(0x24000000),
                      ],
                      stops: [.0, .5, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.gold,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'MM / MEN’S ESSENTIALS',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        data.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: onAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppConstants.gold,
                          foregroundColor: AppConstants.black,
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: Text(data.button),
                      ),
                    ],
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

class _Background extends StatelessWidget {
  const _Background({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    if (image.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        memCacheWidth: 1280,
        errorWidget: (_, __, ___) => const ColoredBox(
          color: AppConstants.black,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white24,
          ),
        ),
      );
    }

    return SvgPicture.asset(
      image.isEmpty ? 'assets/svgs/mm_store_hero.svg' : image,
      fit: BoxFit.cover,
    );
  }
}
