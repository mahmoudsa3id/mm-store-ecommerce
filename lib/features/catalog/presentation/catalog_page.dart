import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/premium_background.dart';
import '../../home/domain/entities/home_entity.dart';
import '../../home/presentation/widgets/product_card.dart';
import '../data/catalog_repository.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, this.categoryId, this.sort = 'new'});

  final String? categoryId;
  final String sort;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  Future<List<ProductEntity>>? _future;
  int _page = 0;
  bool _loadingMore = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _loadPage(0);
  }

  @override
  void didUpdateWidget(covariant CatalogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sort != widget.sort ||
        oldWidget.categoryId != widget.categoryId) {
      _page = 0;
      _loadingMore = false;
      _future = _loadPage(0);
    }
  }

  Future<List<ProductEntity>> _loadPage(int page) {
    return context.read<CatalogRepository>().getProducts(
      categoryId: widget.categoryId,
      page: page,
      sort: widget.sort,
    );
  }

  Future<void> _next() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final items = await _loadPage(nextPage);
      if (!mounted) return;
      final current = await _future!;
      setState(() {
        _page = nextPage;
        _future = Future.value([...current, ...items]);
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sort == 'best' ? 'الأكثر مبيعًا' : 'وصل حديثًا'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),
          FutureBuilder<List<ProductEntity>>(
            future: _future!,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'تعذر تحميل المنتجات.',
                    style: TextStyle(color: AppConstants.muted),
                  ),
                );
              }
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return const Center(child: Text('لا توجد منتجات'));
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1200
                      ? 5
                      : constraints.maxWidth >= 900
                          ? 4
                          : constraints.maxWidth >= 600
                              ? 3
                              : 2;
                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        sliver: SliverGrid.builder(
                          itemCount: items.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 12,
                            childAspectRatio: .63,
                          ),
                          itemBuilder: (_, i) => ProductCard(product: items[i]),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          child: OutlinedButton.icon(
                            onPressed: _loadingMore ? null : _next,
                            icon: _loadingMore
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.expand_more_rounded),
                            label: Text(_loadingMore ? 'جارٍ التحميل...' : 'تحميل المزيد'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
