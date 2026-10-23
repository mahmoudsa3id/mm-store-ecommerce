import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/home_entity.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_route_names.dart';
import '../../../../core/widgets/section_header.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key, required this.items});
  final List<CategoryEntity> items;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppConstants.horizontalPadding,
    ),
    child: Column(
      children: [
        SectionHeader(
          title: 'تسوق حسب القسم',
          subtitle: 'اختار إطلالتك',
          onViewAll: () => c.pushNamed(AppRouteNames.categories),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final x = items[i];
              return GestureDetector(
                onTap: () => c.pushNamed(
                  AppRouteNames.categoryProducts,
                  pathParameters: {'categoryId': x.id},
                ),
                child: Container(
                  width: 118,
                  decoration: BoxDecoration(
                    color: AppConstants.black,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .14),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: x.image,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: AppConstants.black),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: .85),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 12,
                        child: Text(
                          x.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 28,
                        right: 28,
                        bottom: 7,
                        child: Container(height: 2, color: AppConstants.gold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
