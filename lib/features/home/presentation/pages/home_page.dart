import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_route_names.dart';
import '../../../../core/widgets/premium_background.dart';
import '../../../../core/widgets/premium_lottie.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../core/widgets/whatsapp_fab.dart';
import '../../../cart/presentation/cart_cubit.dart';
import '../cubit/home_cubit.dart';
import '../widgets/about_section.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/category_section.dart';
import '../widgets/hero_banner.dart';
import '../widgets/home_header.dart';
import '../widgets/product_section.dart';
import '../widgets/promo_banner.dart';
import '../widgets/service_strip.dart';
import '../widgets/social_contact_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int navIndex = 0;
  final GlobalKey _bestSellersKey = GlobalKey();
  final GlobalKey _newArrivalsKey = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;

    unawaited(
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
        alignment: 0.08,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.page,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return const _HomeLoading();
          }

          if (state is HomeFailure) {
            return _HomeFailure(message: state.message);
          }

          final data = (state as HomeLoaded).data;
          final cartCount = context.watch<CartCubit>().state.count;

          return Stack(
            children: [
              const Positioned.fill(child: PremiumBackground()),
              RefreshIndicator.adaptive(
                color: AppConstants.gold,
                onRefresh: () =>
                    context.read<HomeCubit>().load(forceRefresh: true),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: HomeHeader(
                        cartCount: cartCount,
                        onCartTap: () => context.pushNamed(AppRouteNames.cart),
                        onSearchTap: () =>
                            context.pushNamed(AppRouteNames.search),
                        onFavoriteTap: () =>
                            context.pushNamed(AppRouteNames.favorites),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ResponsiveContainer(
                        child: HeroBanner(
                          data: data.hero,
                          onAction: () =>
                              context.pushNamed(AppRouteNames.categories),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppConstants.sectionGap),
                    ),
                    SliverToBoxAdapter(
                      child: ResponsiveContainer(
                        child: CategorySection(items: data.categories),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 22)),
                    SliverToBoxAdapter(
                      child: ResponsiveContainer(
                        child: ServiceStrip(items: data.services),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    SliverToBoxAdapter(
                      child: ResponsiveContainer(
                        child: ProductSection(
                          key: _bestSellersKey,
                          title: 'الأكثر مبيعًا',
                          subtitle: 'اختيارات MM Store الأكثر طلبًا',
                          items: data.bestSellers,
                          sort: 'best',
                        ),
                      ),
                    ),
                    if (data.banners.isNotEmpty)
                      SliverToBoxAdapter(
                        child: ResponsiveContainer(
                          child: PromoBanner(
                            data: data.banners.first,
                            onButtonTap: () =>
                                _scrollToSection(_bestSellersKey),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: ResponsiveContainer(
                        child: ProductSection(
                          key: _newArrivalsKey,
                          title: 'وصل حديثًا',
                          subtitle: 'أحدث القطع لتجديد إطلالتك',
                          items: data.newArrivals,
                          sort: 'new',
                        ),
                      ),
                    ),
                    if (data.banners.length > 1)
                      SliverToBoxAdapter(
                        child: ResponsiveContainer(
                          child: PromoBanner(
                            data: data.banners.last,
                            onButtonTap: () =>
                                _scrollToSection(_newArrivalsKey),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: ResponsiveContainer(
                        child: AboutSection(about: data.about),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ResponsiveContainer(
                        child: SocialContactSection(
                          socials: data.socials,
                          contact: data.contact,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is! HomeLoaded) return const SizedBox.shrink();
          return WhatsAppFab(phone: state.data.settings.whatsapp);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: navIndex,
        cartCount: context.watch<CartCubit>().state.count,
        onChanged: (index) {
          setState(() => navIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              context.pushNamed(AppRouteNames.categories);
              break;
            case 2:
              context.pushNamed(AppRouteNames.favorites);
              break;
            case 3:
              context.pushNamed(AppRouteNames.cart);
              break;
          }
        },
      ),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned.fill(child: PremiumBackground()),
        Center(
          child: PremiumLottie(
            asset: 'assets/lottie/mm_pulse.json',
            width: 96,
            height: 96,
          ),
        ),
      ],
    );
  }
}

class _HomeFailure extends StatelessWidget {
  const _HomeFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 46),
            const SizedBox(height: 14),
            const Text(
              'تعذر تحميل المتجر',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppConstants.muted),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () =>
                  context.read<HomeCubit>().load(forceRefresh: true),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
