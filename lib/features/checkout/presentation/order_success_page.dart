import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_route_names.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../data/checkout_repository.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key, required this.result});

  final OrderCreationResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.page,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AnimatedEntrance(
                child: Column(
                  children: [
                    // Success Icon
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: AppConstants.gold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.gold.withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 62,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Title
                    const Text(
                      'تم طلب الأوردر بنجاح 🎉',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: AppConstants.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Description
                    const Text(
                      'تم استلام طلبك بنجاح، وسيتم التواصل معك '
                      'لتأكيد الطلب وتجهيز الشحنة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppConstants.muted,
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Order Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppConstants.gold.withValues(alpha: 0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Label
                          const Text(
                            'رقم الطلب',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Order Number
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SelectableText(
                              result.orderNumber,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Divider
                          Container(height: 1, color: Colors.white12),

                          const SizedBox(height: 18),

                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'الإجمالي',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${result.total.toStringAsFixed(0)} ${AppConstants.currency}',
                                style: const TextStyle(
                                  color: AppConstants.gold,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Track order hint
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConstants.gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppConstants.gold.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppConstants.gold,
                            size: 21,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'احتفظ برقم الطلب لاستخدامه عند متابعة حالة طلبك.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: AppConstants.muted,
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Home Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: () {
                          context.goNamed(AppRouteNames.home);
                        },
                        icon: const Icon(Icons.home_rounded),
                        label: const Text(
                          'العودة للرئيسية',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Order number small fallback
                    Text(
                      'Order: ${result.orderNumber}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppConstants.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
