import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/widgets/premium_panel.dart';
import 'admin_orders_cubit.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key, this.initialOrderId});

  final String? initialOrderId;

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminOrdersCubit>().load();
    });
  }

  Future<void> _showProof(String path) async {
    final url = await context.read<AdminOrdersCubit>().repo.signedProof(path);

    if (!mounted || url == null || url.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('تعذر تحميل صورة الإثبات'),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),

                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmOrderDelete(Map<String, dynamic> order) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('حذف الطلب؟'),
            content: Text(
              'سيتم حذف الطلب رقم ${order['order_number'] ?? ''} نهائيًا من قاعدة البيانات.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB42318),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حذف الطلب'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الطلبات',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),

          BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
            builder: (context, state) {
              if (state.loading && state.items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.items.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد طلبات حتى الآن',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                );
              }

              final orders = [...state.items];
              final selectedIndex = orders.indexWhere(
                (order) => order['id']?.toString() == widget.initialOrderId,
              );
              if (selectedIndex > 0) {
                orders.insert(0, orders.removeAt(selectedIndex));
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];

                  final payment = (order['payment_status'] ?? 'pending')
                      .toString();

                  final status = (order['order_status'] ?? 'pending')
                      .toString();

                  final proof = (order['payment_proof_path'] ?? '').toString();

                  final rawItems = order['order_items'];

                  final items = rawItems is List
                      ? rawItems
                            .whereType<Map>()
                            .map((e) => Map<String, dynamic>.from(e))
                            .toList()
                      : <Map<String, dynamic>>[];

                  final orderId = order['id'].toString();

                  return Dismissible(
                    key: ValueKey('order-$orderId'),
                    direction: DismissDirection.startToEnd,
                    confirmDismiss: (_) => _confirmOrderDelete(order),
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: AlignmentDirectional.centerStart,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB42318),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'حذف الطلب',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onDismissed: (_) async {
                      final cubit = context.read<AdminOrdersCubit>();
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await cubit.deleteOrder(orderId);
                        if (!mounted) return;
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(content: Text('تم حذف الطلب')),
                          );
                      } catch (error) {
                        if (!mounted) return;
                        await cubit.load();
                        if (!mounted) return;
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text('تعذر حذف الطلب: $error'),
                              backgroundColor: const Color(0xFFB42318),
                            ),
                          );
                      }
                    },
                    child: PremiumPanel(
                      padding: EdgeInsets.zero,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                      initiallyExpanded:
                          order['id']?.toString() == widget.initialOrderId,
                      backgroundColor: Colors.transparent,
                      collapsedBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),

                      title: Text(
                        '#${order['order_number'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),

                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'الاسم: ${order['customer_name'] ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppConstants.muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'رقم الموبايل: ',
                                  style: TextStyle(color: AppConstants.muted),
                                ),
                                Flexible(
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      (order['phone'] ?? '').toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppConstants.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      children: [
                        // ========================================
                        // Order Information
                        // ========================================
                        _InfoRow(
                          title: 'العنوان',
                          value:
                              '${order['city'] ?? ''} - ${order['address'] ?? ''}',
                        ),

                        _InfoRow(
                          title: 'المجموع الفرعي',
                          value: '${order['subtotal'] ?? 0} EGP',
                        ),

                        _InfoRow(
                          title: 'الشحن',
                          value: '${order['shipping_fee'] ?? 0} EGP',
                        ),

                        _InfoRow(
                          title: 'الإجمالي',
                          value: '${order['total'] ?? 0} EGP',
                          emphasized: true,
                        ),

                        const SizedBox(height: 10),

                        // ========================================
                        // Products Header
                        // ========================================
                        const Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            'المنتجات',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ========================================
                        // Products
                        // ========================================
                        if (items.isEmpty)
                          const Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              'لا توجد منتجات',
                              style: TextStyle(color: AppConstants.muted),
                            ),
                          )
                        else
                          ...items.map((item) {
                            final productName = '${item['product_name'] ?? ''}';
                            final quantity = '${item['quantity'] ?? 0}';
                            final unitPrice = '${item['unit_price'] ?? 0}';
                            final size = '${item['size'] ?? ''}';
                            final color = '${item['color'] ?? ''}';
                            final productData = item['product'] is Map
                                ? Map<String, dynamic>.from(
                                    item['product'] as Map,
                                  )
                                : const <String, dynamic>{};
                            final productImages = productData['images'] is List
                                ? (productData['images'] as List)
                                      .whereType<String>()
                                      .where((image) => image.isNotEmpty)
                                      .toList()
                                : const <String>[];
                            final colorVariants =
                                productData['color_variants'] is List
                                ? (productData['color_variants'] as List)
                                      .whereType<Map>()
                                      .map(Map<String, dynamic>.from)
                                      .toList()
                                : const <Map<String, dynamic>>[];
                            String? selectedColorImage;
                            for (final variant in colorVariants) {
                              if (color.isNotEmpty &&
                                  variant['color']?.toString().toLowerCase() ==
                                      color.toLowerCase()) {
                                final image =
                                    variant['image_url']?.toString() ?? '';
                                if (image.isNotEmpty) {
                                  selectedColorImage = image;
                                  break;
                                }
                              }
                            }
                            final productImage = selectedColorImage ??
                                (productImages.isNotEmpty
                                    ? productImages.first
                                    : productData['image_url']?.toString() ??
                                          '');

                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.black.withValues(alpha: 0.04),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 58,
                                    height: 68,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.black.withValues(
                                        alpha: 0.07,
                                      ),
                                    ),
                                    child: productImage.isEmpty
                                        ? const Icon(
                                            Icons.shopping_bag_outlined,
                                            size: 22,
                                            color: AppConstants.muted,
                                          )
                                        : Image.network(
                                            productImage,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(
                                                  Icons.image_not_supported_outlined,
                                                  size: 22,
                                                  color: AppConstants.muted,
                                                ),
                                          ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'الكمية: $quantity',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppConstants.muted,
                                          ),
                                        ),
                                        if (size.isNotEmpty ||
                                            color.isNotEmpty) ...[
                                          const SizedBox(height: 5),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              if (size.isNotEmpty)
                                                _ProductOption(
                                                  label: 'المقاس: $size',
                                                ),
                                              if (color.isNotEmpty)
                                                _ProductOption(
                                                  label: 'اللون: $color',
                                                  swatch: _colorFromValue(color),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  Flexible(
                                    child: Text(
                                      '$unitPrice EGP',
                                      textAlign: TextAlign.end,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 8),

                        // ========================================
                        // Payment Proof
                        // ========================================
                        if (proof.isNotEmpty) ...[
                          const Divider(height: 24),

                          _ActionRow(
                            title: 'إثبات الدفع',
                            subtitle: 'صورة إثبات InstaPay',
                            trailing: OutlinedButton.icon(
                              onPressed: () {
                                _showProof(proof);
                              },
                              icon: const Icon(Icons.image_outlined, size: 18),
                              label: const Text('عرض الصورة'),
                            ),
                          ),
                        ],

                        const Divider(height: 24),

                        // ========================================
                        // Payment Status
                        // ========================================
                        _DropdownRow(
                          title: 'حالة الدفع',
                          value: payment,
                          items: const {
                            'pending': 'مراجعة',
                            'confirmed': 'مؤكد',
                            'rejected': 'مرفوض',
                          },
                          onChanged: (value) {
                            if (value == null) return;

                            context.read<AdminOrdersCubit>().setPayment(
                              orderId,
                              value,
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        // ========================================
                        // Order Status
                        // ========================================
                        _DropdownRow(
                          title: 'حالة الطلب',
                          subtitle: status == 'sold'
                              ? 'عند اختيار تم البيع يتم تحديث الأكثر مبيعًا تلقائيًا.'
                              : null,
                          value: status,
                          items: const {
                            'pending': 'جديد',
                            'confirmed': 'مؤكد',
                            'preparing': 'تجهيز',
                            'shipped': 'شحن',
                            'sold': 'تم البيع',
                            'cancelled': 'ملغي',
                          },
                          onChanged: (value) {
                            if (value == null) return;

                            context.read<AdminOrdersCubit>().setStatus(
                              orderId,
                              value,
                            );
                          },
                        ),
                      ],
                      ),
                    ),
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

Color? _colorFromValue(String value) {
  final normalized = value.trim().replaceFirst('#', '');
  if (!RegExp(r'^(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(normalized)) {
    return null;
  }
  final argb = normalized.length == 6 ? 'FF$normalized' : normalized;
  return Color(int.parse(argb, radix: 16));
}

class _ProductOption extends StatelessWidget {
  const _ProductOption({required this.label, this.swatch});

  final String label;
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (swatch != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: AppConstants.muted, width: .5),
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// Info Row
// ================================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.title,
    required this.value,
    this.emphasized = false,
  });

  final String title;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppConstants.muted,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              softWrap: true,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
                fontSize: emphasized ? 15 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// Action Row
// ================================================================

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppConstants.muted),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Flexible(child: trailing),
      ],
    );
  }
}

// ================================================================
// Dropdown Row
// ================================================================

class _DropdownRow extends StatelessWidget {
  const _DropdownRow({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = items.containsKey(value) ? value : items.keys.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),

                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppConstants.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          Flexible(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safeValue,
                isDense: true,
                isExpanded: false,
                onChanged: onChanged,
                items: items.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
