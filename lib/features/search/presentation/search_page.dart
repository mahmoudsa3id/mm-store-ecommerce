import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/widgets/premium_panel.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../home/presentation/widgets/product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController controller =
      TextEditingController(text: widget.initialQuery ?? '');
  Future<List> future = Future.value(const []);

  @override
  void initState() {
    super.initState();
    if ((widget.initialQuery ?? '').trim().isNotEmpty) {
      future = _query(widget.initialQuery!);
    }
  }

  Future<List> _query(String query) {
    return context.read<CatalogRepository>().getProducts(
          search: query.trim(),
          page: 0,
        );
  }

  void _search() {
    setState(() => future = _query(controller.text));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البحث')),
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    suffixIcon: IconButton(
                      onPressed: _search,
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'حصل خطأ أثناء البحث. جرّب مرة ثانية.',
                          style: TextStyle(color: AppConstants.muted),
                        ),
                      );
                    }
                    final items = snapshot.data ?? const [];
                    if (items.isEmpty) {
                      return const _EmptySearch();
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
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            childAspectRatio: .63,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: items.length,
                          itemBuilder: (_, index) =>
                              ProductCard(product: items[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PremiumPanel(
        margin: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.search_off_rounded, size: 36, color: AppConstants.gold),
            SizedBox(height: 10),
            Text('لا توجد نتائج', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
