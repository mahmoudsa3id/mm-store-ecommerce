import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_route_names.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../cart/domain/cart_item.dart';
import '../../../cart/presentation/cart_cubit.dart';
import '../../../favorites/presentation/favorites_cubit.dart';
import '../../domain/entities/home_entity.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.index = 0,
    this.width = 188,
  });

  final ProductEntity product;
  final int index;
  final double width;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;
  bool _pressed = false;

  ProductEntity get product => widget.product;

  String _money(double value) {
    return '${AppConstants.currency} ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final favorite = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.isFavorite(product.id),
    );

    return AnimatedEntrance(
      delay: Duration(milliseconds: 45 * widget.index),
      child: MouseRegion(
        onEnter: (_) {
          if (mounted) {
            setState(() => _hovered = true);
          }
        },
        onExit: (_) {
          if (mounted) {
            setState(() => _hovered = false);
          }
        },
        child: GestureDetector(
          onTapDown: (_) {
            if (mounted) {
              setState(() => _pressed = true);
            }
          },
          onTapCancel: () {
            if (mounted) {
              setState(() => _pressed = false);
            }
          },
          onTapUp: (_) {
            if (mounted) {
              setState(() => _pressed = false);
            }
          },
          onTap: () {
            context.pushNamed(
              AppRouteNames.productDetails,
              pathParameters: {'productId': product.id},
            );
          },
          child: AnimatedScale(
            scale: _pressed ? .985 : (_hovered ? 1.01 : 1),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Container(
              width: widget.width,

              // مهم:
              // margin صغيرة فقط، والـ card نفسه لا يعتمد
              // على محتوى غير محدود الارتفاع.
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),

              decoration: BoxDecoration(
                color: AppConstants.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _hovered
                      ? AppConstants.gold.withValues(alpha: .5)
                      : Colors.white.withValues(alpha: .05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _hovered ? .22 : .12),
                    blurRadius: _hovered ? 30 : 20,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),

              clipBehavior: Clip.antiAlias,

              child: Stack(
                children: [
                  // =================================================
                  // BACKGROUND
                  // =================================================
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1B1B1B), Color(0xFF070707)],
                        ),
                      ),
                    ),
                  ),

                  // =================================================
                  // GOLD GLOW
                  // =================================================
                  Positioned(
                    left: -28,
                    top: 92,
                    child: IgnorePointer(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppConstants.gold.withValues(alpha: .12),
                              AppConstants.gold.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // =================================================
                  // CONTENT
                  // =================================================
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =================================================
                      // IMAGE
                      // =================================================
                      _ProductImage(
                        image: product.image,
                        discountPercent: product.discountPercent,
                        favorite: favorite,
                        onFavorite: () {
                          context.read<FavoritesCubit>().toggle(product);
                        },
                      ),

                      // =================================================
                      // PRODUCT INFO
                      // =================================================
                      Padding(
                        padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // -------------------------------
                            // NAME
                            // -------------------------------
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // -------------------------------
                            // PRICE + ADD BUTTON
                            // -------------------------------
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _money(product.price),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppConstants.gold,
                                          fontSize: 15,
                                          height: 1.1,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),

                                      if (product.oldPrice != null) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          _money(product.oldPrice!),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 10,
                                            height: 1.1,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // -----------------------------
                                // ADD BUTTON
                                // -----------------------------
                                _ActionButton(
                                  icon: Icons.add_rounded,
                                  filled: true,
                                  onTap: () {
                                    context.read<CartCubit>().add(
                                      CartItem(
                                        productId: product.id,
                                        name: product.name,
                                        image: product.image,
                                        price: product.price,
                                        quantity: 1,
                                      ),
                                    );

                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          content: Text(
                                            'تمت إضافة المنتج للسلة',
                                          ),
                                          duration: Duration(milliseconds: 900),
                                        ),
                                      );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // =================================================
                  // BOTTOM GOLD LINE
                  // =================================================
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 0,
                    child: Container(
                      height: 2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppConstants.gold,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// PRODUCT IMAGE
// ==================================================================

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.image,
    required this.favorite,
    required this.onFavorite,
    this.discountPercent,
  });

  final String image;
  final bool favorite;
  final VoidCallback onFavorite;
  final int? discountPercent;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      // خلي الصورة أقل ارتفاعًا شوية عشان الكارد كله يبقى compact.
      aspectRatio: .94,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // =========================================================
          // IMAGE
          // =========================================================
          CachedNetworkImage(
            imageUrl: image,
            fit: BoxFit.cover,
            memCacheWidth: 720,
            placeholder: (_, __) => const ColoredBox(
              color: Color(0xFF111111),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 1.8),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => const ColoredBox(
              color: Color(0xFF151515),
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Colors.white30,
                size: 34,
              ),
            ),
          ),

          // =========================================================
          // IMAGE GRADIENT
          // =========================================================
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
                stops: [.45, 1],
              ),
            ),
          ),

          // =========================================================
          // FAVORITE
          // =========================================================
          PositionedDirectional(
            top: 12,
            end: 12,
            child: _ActionButton(
              icon: favorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              iconColor: favorite ? AppConstants.goldBright : Colors.white,
              onTap: onFavorite,
            ),
          ),

          // =========================================================
          // DISCOUNT
          // =========================================================
          if (discountPercent != null)
            PositionedDirectional(
              top: 12,
              start: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConstants.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '-$discountPercent%',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==================================================================
// ACTION BUTTON
// ==================================================================

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppConstants.gold : Colors.black.withValues(alpha: .56),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            icon,
            size: 18,
            color: iconColor ?? (filled ? Colors.black : Colors.white),
          ),
        ),
      ),
    );
  }
}
