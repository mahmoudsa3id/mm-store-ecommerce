import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/widgets/premium_panel.dart';

import '../../../features/home/domain/entities/product_color_variant.dart';

import 'admin_products_cubit.dart';
import 'widgets/admin_product_form_dialog.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  @override
  void initState() {
    super.initState();

    context.read<AdminProductsCubit>().load();
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<void> _add() async {
    final cubit = context.read<AdminProductsCubit>();

    final result = await AdminProductFormDialog.show(
      context,

      categories: cubit.state.categories,

      pickImage: cubit.repo.uploads.pickImage,
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      await cubit.create(
        name: result.name,
        description: result.description,
        price: result.price,
        oldPrice: result.oldPrice,
        categoryId: result.categoryId,

        sizes: result.sizes,

        colorVariants: result.colorVariants,

        colorVariantImages: result.colorVariantImages,
      );

      if (!mounted) return;

      _message('تم إضافة المنتج بنجاح');
    } catch (error) {
      if (!mounted) return;

      _message('تعذر إضافة المنتج: $error');
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _edit(Map<String, dynamic> item) async {
    final cubit = context.read<AdminProductsCubit>();

    final initialVariants = _parseVariants(item['color_variants']);

    final result = await AdminProductFormDialog.show(
      context,

      categories: cubit.state.categories,

      pickImage: cubit.repo.uploads.pickImage,

      initial: AdminProductFormResult(
        name: (item['name'] ?? '').toString(),

        description: (item['description'] ?? '').toString(),

        price: (item['price'] as num? ?? 0).toDouble(),

        oldPrice: (item['old_price'] as num?)?.toDouble(),

        categoryId: (item['category_id'] ?? '').toString(),

        sizes: List<String>.from((item['sizes'] as List?) ?? const []),

        sizeMode: _inferSizeMode(item, cubit.state.categories),

        colorVariants: initialVariants,

        colorVariantImages: const {},
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      await cubit.update(
        id: item['id'].toString(),

        name: result.name,
        description: result.description,
        price: result.price,
        oldPrice: result.oldPrice,
        categoryId: result.categoryId,

        sizes: result.sizes,

        colorVariants: result.colorVariants,

        colorVariantImages: result.colorVariantImages,
      );

      if (!mounted) return;

      _message('تم تحديث المنتج بنجاح');
    } catch (error) {
      if (!mounted) return;

      _message('تعذر تحديث المنتج: $error');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _delete(Map<String, dynamic> item) async {
    final name = (item['name'] ?? '').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('حذف المنتج'),
          content: Text('هل تريد حذف "$name"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await context.read<AdminProductsCubit>().delete(item['id'].toString());

      if (!mounted) return;

      _message('تم حذف المنتج');
    } catch (error) {
      if (!mounted) return;

      _message('تعذر حذف المنتج: $error');
    }
  }

  // ============================================================
  // PARSE VARIANTS
  // ============================================================

  List<ProductColorVariant> _parseVariants(dynamic value) {
    if (value == null) {
      return const [];
    }

    dynamic decoded = value;

    if (value is String) {
      try {
        decoded = jsonDecode(value);
      } catch (_) {
        return const [];
      }
    }

    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) =>
              ProductColorVariant.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  // ============================================================
  // SIZE MODE
  // ============================================================

  String _inferSizeMode(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> categories,
  ) {
    final selectedId = item['category_id']?.toString();

    final matches = categories.where(
      (category) => category['id']?.toString() == selectedId,
    );

    if (matches.isEmpty) {
      return 'clothing';
    }

    final name = matches.first['name']?.toString().toLowerCase() ?? '';

    return name.contains('بنطل') ||
            name.contains('pants') ||
            name.contains('jeans')
        ? 'pants'
        : 'clothing';
  }

  // ============================================================
  // FIRST COLOR IMAGE
  // ============================================================

  String _firstImage(Map<String, dynamic> item) {
    final variants = _parseVariants(item['color_variants']);

    for (final variant in variants) {
      if (variant.imageUrl.trim().isNotEmpty) {
        return variant.imageUrl;
      }
    }

    return '';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),

        actions: [
          IconButton.filledTonal(
            tooltip: 'إضافة منتج',

            onPressed: _add,

            icon: const Icon(Icons.add_box_outlined),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),

          BlocBuilder<AdminProductsCubit, AdminProductsState>(
            builder: (context, state) {
              // ==================================================
              // LOADING
              // ==================================================

              if (state.loading && state.items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // ==================================================
              // EMPTY
              // ==================================================

              if (state.items.isEmpty) {
                return const Center(child: Text('لا توجد منتجات'));
              }

              // ==================================================
              // LIST
              // ==================================================

              return RefreshIndicator.adaptive(
                onRefresh: context.read<AdminProductsCubit>().load,

                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),

                  itemCount: state.items.length,

                  separatorBuilder: (_, __) => const SizedBox(height: 10),

                  itemBuilder: (_, index) {
                    final product = state.items[index];

                    final image = _firstImage(product);

                    final variants = _parseVariants(product['color_variants']);

                    final sizes = List<String>.from(
                      (product['sizes'] as List?) ?? const [],
                    );

                    return PremiumPanel(
                      padding: const EdgeInsets.all(10),

                      child: Row(
                        children: [
                          // ======================================
                          // IMAGE
                          // ======================================
                          Container(
                            width: 72,
                            height: 82,

                            clipBehavior: Clip.antiAlias,

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppConstants.black,
                              border: Border.all(color: AppConstants.border),
                            ),

                            child: image.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: image,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: AppConstants.gold,
                                    ),
                                  )
                                : const Icon(
                                    Icons.palette_outlined,
                                    color: AppConstants.gold,
                                  ),
                          ),

                          const SizedBox(width: 12),

                          // ======================================
                          // INFO
                          // ======================================
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  (product['name'] ?? '').toString(),

                                  maxLines: 1,

                                  overflow: TextOverflow.ellipsis,

                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  '${product['price']} EGP • مبيعات ${product['sales_count'] ?? 0}',

                                  style: const TextStyle(
                                    color: AppConstants.muted,
                                    fontSize: 11,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // COLORS
                                Wrap(
                                  spacing: 5,
                                  runSpacing: 5,

                                  children: [
                                    ...variants
                                        .take(7)
                                        .map(
                                          (variant) => Container(
                                            width: 19,
                                            height: 19,
                                            decoration: BoxDecoration(
                                              color: _colorFromHex(
                                                variant.color,
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white12,
                                              ),
                                            ),
                                          ),
                                        ),

                                    if (sizes.isNotEmpty)
                                      Text(
                                        sizes.join(' • '),
                                        style: const TextStyle(
                                          color: AppConstants.muted,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 5),

                          // ======================================
                          // ACTIONS
                          // ======================================
                          Column(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              Switch(
                                value: product['is_active'] as bool? ?? true,

                                onChanged: (value) {
                                  context.read<AdminProductsCubit>().toggle(
                                    product['id'].toString(),
                                    value,
                                  );
                                },
                              ),

                              IconButton(
                                tooltip: 'تعديل',

                                onPressed: () => _edit(product),

                                icon: const Icon(Icons.edit_outlined),
                              ),

                              IconButton(
                                tooltip: 'حذف',

                                onPressed: () => _delete(product),

                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _colorFromHex(String hex) {
    var clean = hex.replaceAll('#', '');

    if (clean.length == 6) {
      clean = 'FF$clean';
    }

    final value = int.tryParse(clean, radix: 16);

    return value == null ? AppConstants.gold : Color(value);
  }
}
