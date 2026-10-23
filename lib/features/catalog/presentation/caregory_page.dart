import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_route_names.dart';
import '../data/catalog_repository.dart';
import '../../home/domain/entities/home_entity.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late Future<List<CategoryEntity>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    _categoriesFuture = context.read<CatalogRepository>().getCategories();
  }

  Future<void> _refresh() async {
    setState(_loadCategories);
    await _categoriesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.page,

      appBar: AppBar(
        backgroundColor: AppConstants.page,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
        title: const Text(
          'الأقسام',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),

      body: FutureBuilder<List<CategoryEntity>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _CategoriesLoading();
          }

          // Error
          if (snapshot.hasError) {
            return _CategoriesError(
              onRetry: () {
                setState(_loadCategories);
              },
            );
          }

          final categories = snapshot.data ?? const [];

          // Empty
          if (categories.isEmpty) {
            return const _EmptyCategories();
          }

          return RefreshIndicator(
            color: AppConstants.gold,
            backgroundColor: AppConstants.black,
            onRefresh: _refresh,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: .78,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return _CategoryCard(
                  category: category,
                  onTap: () {
                    if (category.id.isEmpty) return;

                    context.pushNamed(
                      AppRouteNames.categoryProducts,
                      pathParameters: {'categoryId': category.id},
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// CATEGORY CARD
// ============================================================================

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final CategoryEntity category;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.category.name;
    final imageUrl = widget.category.image;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? .97 : 1,
        duration: const Duration(milliseconds: 160),
        child: Container(
          decoration: BoxDecoration(
            color: AppConstants.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .16),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // IMAGE
              Positioned.fill(
                child: imageUrl.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFF151515),
                        child: Icon(
                          Icons.image_outlined,
                          size: 45,
                          color: Colors.white24,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 600,
                        placeholder: (_, __) => const ColoredBox(
                          color: Color(0xFF151515),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppConstants.gold,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const ColoredBox(
                          color: Color(0xFF151515),
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 42,
                            color: Colors.white24,
                          ),
                        ),
                      ),
              ),

              // DARK GRADIENT
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x15000000),
                        Color(0xE6000000),
                      ],
                      stops: [0, .40, 1],
                    ),
                  ),
                ),
              ),

              // GOLD GLOW
              Positioned(
                right: -40,
                bottom: -50,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppConstants.gold.withValues(alpha: .20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // CONTENT
              PositionedDirectional(
                start: 14,
                end: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'اكتشف المجموعة',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppConstants.gold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LOADING
// ============================================================================

class _CategoriesLoading extends StatelessWidget {
  const _CategoriesLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: .78,
      ),
      itemBuilder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppConstants.gold,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// ERROR
// ============================================================================

class _CategoriesError extends StatelessWidget {
  const _CategoriesError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: AppConstants.muted,
            ),

            const SizedBox(height: 14),

            const Text(
              'تعذر تحميل الأقسام',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 14),

            ElevatedButton(
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
// EMPTY
// ============================================================================

class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined, size: 52, color: AppConstants.muted),
          SizedBox(height: 12),
          Text(
            'لا توجد أقسام حاليًا',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
