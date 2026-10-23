import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/home_entity.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_route_names.dart';
import '../../../../core/widgets/section_header.dart';
import 'product_card.dart';

class ProductSection extends StatelessWidget {
  const ProductSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.sort,
  });

  final String title;
  final String subtitle;
  final List<ProductEntity> items;
  final String sort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.horizontalPadding,
      ),
      child: Column(
        children: [
          SectionHeader(
            title: title,
            subtitle: subtitle,
            onViewAll: () => context.pushNamed(
              AppRouteNames.catalog,
              queryParameters: {'sort': sort},
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 330,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) =>
                  ProductCard(product: items[index], index: index),
            ),
          ),
        ],
      ),
    );
  }
}
