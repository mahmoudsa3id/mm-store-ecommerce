import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_route_names.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/widgets/premium_panel.dart';
import 'cart_cubit.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('السلة')),
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              if (state.items.isEmpty) {
                return const _EmptyCart();
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final item = state.items[index];
                        return PremiumPanel(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: item.image,
                                  width: 78,
                                  height: 78,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const ColoredBox(
                                    color: AppConstants.black,
                                    child: SizedBox(
                                      width: 78,
                                      height: 78,
                                      child: Icon(Icons.image_outlined),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${AppConstants.currency} ${item.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppConstants.gold,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Row(
                                      children: [
                                        _QtyButton(
                                          icon: Icons.remove_rounded,
                                          onTap: () => context
                                              .read<CartCubit>()
                                              .decrease(item),
                                        ),
                                        SizedBox(
                                          width: 38,
                                          child: Text(
                                            '${item.quantity}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        _QtyButton(
                                          icon: Icons.add_rounded,
                                          onTap: () => context
                                              .read<CartCubit>()
                                              .increase(item),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'حذف',
                                onPressed: () =>
                                    context.read<CartCubit>().remove(item),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: PremiumPanel(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'الإجمالي',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  '${AppConstants.currency} ${state.subtotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: AppConstants.gold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                onPressed: () => context
                                    .pushNamed(AppRouteNames.checkout),
                                child: const Text('إتمام الطلب'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppConstants.black,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppConstants.border),
        ),
        child: Icon(icon, size: 17, color: AppConstants.gold),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PremiumPanel(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppConstants.gold.withValues(alpha: .1),
                shape: BoxShape.circle,
                border: Border.all(color: AppConstants.gold.withValues(alpha: .28)),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 32,
                color: AppConstants.gold,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'السلة فاضية',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'ضيف منتجاتك المفضلة وارجع هنا لإتمام الطلب.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.muted),
            ),
          ],
        ),
      ),
    );
  }
}
