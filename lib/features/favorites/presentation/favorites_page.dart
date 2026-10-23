import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/widgets/premium_lottie.dart';
import '../../home/presentation/widgets/product_card.dart';
import 'favorites_cubit.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.page,
      appBar: AppBar(
        title: const Text(
          'المفضلة',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),
          BlocBuilder<FavoritesCubit, FavoritesState>(
            builder: (context, state) {
              if (state is FavoritesLoading || state is FavoritesInitial) {
                return const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (state is FavoritesFailure) {
                return _Failure(message: state.message);
              }

              final loaded = state as FavoritesLoaded;
              if (loaded.products.isEmpty) {
                return const _EmptyFavorites();
              }

              return RefreshIndicator.adaptive(
                onRefresh: () => context.read<FavoritesCubit>().load(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1120
                        ? 5
                        : constraints.maxWidth >= 820
                        ? 4
                        : constraints.maxWidth >= 560
                        ? 3
                        : 2;

                    return GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: .60,
                      ),
                      itemCount: loaded.products.length,
                      itemBuilder: (_, index) => AnimatedEntrance(
                        delay: Duration(milliseconds: 45 * index),
                        child: LayoutBuilder(
                          builder: (context, box) => ProductCard(
                            product: loaded.products[index],
                            index: 0,
                            width: box.maxWidth > 10
                                ? box.maxWidth - 10
                                : box.maxWidth,
                          ),
                        ),
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
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PremiumLottie(
              asset: 'assets/lottie/mm_pulse.json',
              width: 150,
              height: 150,
            ),
            const Text(
              'لسه مفيش منتجات في المفضلة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'اضغط على القلب في أي منتج وهيظهر هنا تلقائيًا.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppConstants.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('ارجع للتسوق'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44),
            const SizedBox(height: 12),
            const Text(
              'تعذر تحميل المفضلة',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppConstants.muted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<FavoritesCubit>().load(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
