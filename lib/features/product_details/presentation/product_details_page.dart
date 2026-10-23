import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mm_store/core/router/app_route_names.dart';

import 'package:mm_store/features/cart/domain/cart_item.dart';
import 'package:mm_store/features/cart/presentation/cart_cubit.dart';
import 'package:mm_store/features/catalog/data/catalog_repository.dart';
import 'package:mm_store/features/favorites/presentation/favorites_cubit.dart';
import 'package:mm_store/features/home/domain/entities/home_entity.dart';
import 'package:mm_store/features/home/domain/entities/product_color_variant.dart';

import '../../../../core/constants/app_constants.dart';

abstract final class _DetailsText {
  static const addToCart = 'أضف للسلة';
  static const buyNow = 'شراء الآن';
  static const viewCart = 'عرض السلة';
  static const addedToCart = 'تمت إضافة المنتج للسلة';
  static const color = 'اللون';
  static const size = 'المقاس';
  static const quantity = 'الكمية';
}

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String? _selectedColor;
  String? _selectedImage;
  String? _selectedSize;

  int _quantity = 1;

  Future<ProductEntity>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _future ??= context.read<CatalogRepository>().getProduct(widget.productId);
  }

  // ============================================================
  // COLOR VARIANTS
  // ============================================================

  List<ProductColorVariant> _variants(ProductEntity product) {
    return product.colorVariants
        .where((variant) => variant.color.trim().isNotEmpty)
        .toList(growable: false);
  }

  // ============================================================
  // INITIAL SELECTION
  // ============================================================

  void _initializeSelection(ProductEntity product) {
    if (_selectedColor != null) {
      return;
    }

    final variants = _variants(product);

    if (variants.isNotEmpty) {
      final first = variants.first;

      _selectedColor = first.color;

      final image = first.imageUrl.trim();

      if (image.isNotEmpty) {
        _selectedImage = image;
      }

      return;
    }

    // Legacy fallback
    if (product.colors.isNotEmpty) {
      _selectedColor = product.colors.first;

      if (product.images.isNotEmpty) {
        final image = product.images.first.trim();

        if (image.isNotEmpty) {
          _selectedImage = image;
        }
      }
    }
  }

  // ============================================================
  // SELECT COLOR
  // ============================================================

  void _selectColor(ProductColorVariant variant) {
    final color = variant.color.trim();
    final image = variant.imageUrl.trim();

    if (color.isEmpty) {
      return;
    }

    setState(() {
      _selectedColor = color;
      _selectedImage = image.isEmpty ? null : image;
    });
  }

  // ============================================================
  // SELECT LEGACY COLOR
  // ============================================================

  void _selectLegacyColor(ProductEntity product, String color, int index) {
    setState(() {
      _selectedColor = color;

      if (index < product.images.length) {
        final image = product.images[index].trim();

        _selectedImage = image.isEmpty ? null : image;
      }
    });
  }

  // ============================================================
  // BUILD CART ITEM
  // ============================================================

  CartItem _buildCartItem(ProductEntity product) {
    return CartItem(
      productId: product.id,
      name: product.name,
      image: _selectedImage?.trim() ?? '',
      price: product.price,
      quantity: _quantity,
      size: _selectedSize,
      color: _selectedColor,
    );
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  Future<void> _addToCart(ProductEntity product, {bool buyNow = false}) async {
    // لو المنتج عنده مقاسات لازم يختار مقاس
    if (product.sizes.isNotEmpty && _selectedSize == null) {
      _showMessage('اختار المقاس أولًا', icon: Icons.checkroom_rounded);
      return;
    }

    final item = _buildCartItem(product);

    try {
      await context.read<CartCubit>().add(item);

      if (!mounted) {
        return;
      }

      if (buyNow) {
        context.pushNamed(AppRouteNames.checkout);
        return;
      }

      _showCartSnackBar();
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'تعذر إضافة المنتج للسلة',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  // ============================================================
  // CART SNACKBAR
  // ============================================================

  void _showCartSnackBar() {
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 4),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppConstants.black,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppConstants.gold.withValues(alpha: .35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppConstants.gold.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: AppConstants.gold,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            const Expanded(
              child: Text(
                _DetailsText.addedToCart,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                messenger.hideCurrentSnackBar();

                context.pushNamed(AppRouteNames.cart);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.gold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              child: const Text(
                _DetailsText.viewCart,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );

    messenger.showSnackBar(snackBar);
  }

  // ============================================================
  // NORMAL MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    IconData icon = Icons.info_outline_rounded,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              Icon(icon, color: AppConstants.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.page,

      appBar: AppBar(
        backgroundColor: AppConstants.page,
        elevation: 0,

        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),

        actions: [
          if (_future != null)
            FutureBuilder<ProductEntity>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _FavoriteButton(product: snapshot.data!),
                );
              },
            ),
        ],
      ),

      body: FutureBuilder<ProductEntity>(
        future: _future,

        builder: (context, snapshot) {
          // ========================================================
          // LOADING
          // ========================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppConstants.gold),
            );
          }

          // ========================================================
          // ERROR
          // ========================================================

          if (snapshot.hasError || snapshot.data == null) {
            return _Failure(
              onRetry: () {
                setState(() {
                  _future = context.read<CatalogRepository>().getProduct(
                    widget.productId,
                  );
                });
              },
            );
          }

          final product = snapshot.data!;

          _initializeSelection(product);

          final variants = _variants(product);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              // ====================================================
              // PRODUCT IMAGE
              // ====================================================
              _ProductImage(imageUrl: _selectedImage),

              const SizedBox(height: 22),

              // ====================================================
              // NAME
              // ====================================================
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 12),

              // ====================================================
              // PRICE
              // ====================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${AppConstants.currency} '
                    '${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppConstants.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  if (product.oldPrice != null) ...[
                    const SizedBox(width: 10),

                    Text(
                      '${AppConstants.currency} '
                      '${product.oldPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppConstants.muted,
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),

              // ====================================================
              // DESCRIPTION
              // ====================================================
              if (product.description.trim().isNotEmpty) ...[
                const SizedBox(height: 16),

                Text(
                  product.description,
                  style: const TextStyle(
                    color: AppConstants.muted,
                    height: 1.75,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              // ====================================================
              // COLORS
              // ====================================================
              if (variants.isNotEmpty) ...[
                const SizedBox(height: 26),

                const Text(
                  _DetailsText.color,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final variant in variants)
                      _ColorButton(
                        variant: variant,
                        selected: _selectedColor == variant.color,
                        onTap: () {
                          _selectColor(variant);
                        },
                      ),
                  ],
                ),
              ]
              // ====================================================
              // LEGACY COLORS
              // ====================================================
              else if (product.colors.isNotEmpty) ...[
                const SizedBox(height: 26),

                const Text(
                  _DetailsText.color,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (int i = 0; i < product.colors.length; i++)
                      _LegacyColorButton(
                        color: product.colors[i],
                        selected: _selectedColor == product.colors[i],
                        onTap: () {
                          _selectLegacyColor(product, product.colors[i], i);
                        },
                      ),
                  ],
                ),
              ],

              // ====================================================
              // SIZES
              // ====================================================
              if (product.sizes.isNotEmpty) ...[
                const SizedBox(height: 26),

                const Text(
                  _DetailsText.size,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final size in product.sizes)
                      ChoiceChip(
                        label: Text(size),
                        selected: _selectedSize == size,
                        onSelected: (_) {
                          setState(() {
                            _selectedSize = size;
                          });
                        },
                      ),
                  ],
                ),
              ],

              // ====================================================
              // QUANTITY
              // ====================================================
              const SizedBox(height: 26),

              _QuantitySelector(
                quantity: _quantity,

                onDecrease: _quantity > 1
                    ? () {
                        setState(() {
                          _quantity--;
                        });
                      }
                    : null,

                onIncrease: () {
                  setState(() {
                    _quantity++;
                  });
                },
              ),

              // ====================================================
              // ACTIONS
              // ====================================================
              const SizedBox(height: 18),

              Row(
                children: [
                  // ==================================================
                  // ADD TO CART
                  // ==================================================
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _addToCart(product);
                      },
                      icon: const Icon(Icons.shopping_bag_outlined, size: 21),
                      label: const Text(
                        _DetailsText.addToCart,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.textPrimary,
                        side: const BorderSide(
                          color: AppConstants.textPrimary,
                          width: 1.4,
                        ),
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ==================================================
                  // BUY NOW
                  // ==================================================
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        _addToCart(product, buyNow: true);
                      },
                      icon: const Icon(Icons.flash_on_rounded, size: 21),
                      label: const Text(
                        _DetailsText.buyNow,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConstants.gold,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ====================================================
              // CART COUNT INFO
              // ====================================================
              BlocBuilder<CartCubit, CartState>(
                buildWhen: (previous, current) =>
                    previous.count != current.count,
                builder: (context, state) {
                  if (state.count == 0) {
                    return const SizedBox.shrink();
                  }

                  return Center(
                    child: Text(
                      'في السلة ${state.count} قطعة',
                      style: const TextStyle(
                        color: AppConstants.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// PRODUCT IMAGE
// ============================================================================

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,

      child: SizedBox(
        key: ValueKey(url),
        height: 430,
        width: double.infinity,

        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),

          child: url.isEmpty
              ? const _ImagePlaceholder()
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  memCacheWidth: 1200,
                  fadeInDuration: const Duration(milliseconds: 180),

                  placeholder: (_, __) {
                    return const _ImageLoading();
                  },

                  errorWidget: (_, __, ___) {
                    return const _ImagePlaceholder();
                  },
                ),
        ),
      ),
    );
  }
}

// ============================================================================
// COLOR BUTTON
// ============================================================================

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final ProductColorVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(variant.color);

    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        width: 50,
        height: 50,

        padding: const EdgeInsets.all(3),

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          border: Border.all(
            color: selected ? AppConstants.gold : Colors.black12,
            width: selected ? 3 : 1,
          ),

          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppConstants.gold.withValues(alpha: .30),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),

        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),

          child: selected
              ? const Icon(Icons.check_rounded, size: 21, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

// ============================================================================
// LEGACY COLOR BUTTON
// ============================================================================

class _LegacyColorButton extends StatelessWidget {
  const _LegacyColorButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final parsed = _parseColor(color);

    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        width: 50,
        height: 50,

        padding: const EdgeInsets.all(3),

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          border: Border.all(
            color: selected ? AppConstants.gold : Colors.black12,
            width: selected ? 3 : 1,
          ),
        ),

        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: parsed),

          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 21)
              : null,
        ),
      ),
    );
  }
}

// ============================================================================
// FAVORITE
// ============================================================================

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final favorite = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.isFavorite(product.id),
    );

    return Material(
      color: Colors.black.withValues(alpha: .08),
      shape: const CircleBorder(),

      child: InkWell(
        onTap: () {
          context.read<FavoritesCubit>().toggle(product);
        },

        child: Padding(
          padding: const EdgeInsets.all(10),

          child: Icon(
            favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,

            color: favorite
                ? AppConstants.goldBright
                : AppConstants.textPrimary,

            size: 22,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// QUANTITY
// ============================================================================

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          const Text(
            _DetailsText.quantity,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),

          const Spacer(),

          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),

          Text(
            '$quantity',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),

          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// IMAGE LOADING
// ============================================================================

class _ImageLoading extends StatelessWidget {
  const _ImageLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppConstants.surface,
      child: Center(child: CircularProgressIndicator(color: AppConstants.gold)),
    );
  }
}

// ============================================================================
// IMAGE PLACEHOLDER
// ============================================================================

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppConstants.surface,
      child: Center(
        child: Icon(Icons.image_outlined, size: 56, color: AppConstants.muted),
      ),
    );
  }
}

// ============================================================================
// FAILURE
// ============================================================================

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.error_outline_rounded, size: 46),

            const SizedBox(height: 12),

            const Text(
              'تعذر تحميل المنتج',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 16),

            FilledButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PARSE COLOR
// ============================================================================

Color _parseColor(String value) {
  var hex = value.replaceAll('#', '').trim();

  if (hex.startsWith('0x')) {
    hex = hex.substring(2);
  }

  if (hex.length == 6) {
    hex = 'FF$hex';
  }

  if (hex.length != 8) {
    return AppConstants.black;
  }

  final parsed = int.tryParse(hex, radix: 16);

  if (parsed == null) {
    return AppConstants.black;
  }

  return Color(parsed);
}
