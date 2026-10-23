import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/widgets/premium_panel.dart';
import 'admin_settings_cubit.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  // ============================================================
  // Controllers
  // ============================================================

  final TextEditingController store = TextEditingController();
  final TextEditingController insta = TextEditingController();
  final TextEditingController cash = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController whatsapp = TextEditingController();
  final TextEditingController shipping = TextEditingController();
  final TextEditingController freeShipping = TextEditingController();

  bool hydrated = false;

  // ============================================================
  // Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    // Load settings after the page is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<AdminSettingsCubit>().load();
    });
  }

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    store.dispose();
    insta.dispose();
    cash.dispose();
    phone.dispose();
    whatsapp.dispose();
    shipping.dispose();
    freeShipping.dispose();

    super.dispose();
  }

  // ============================================================
  // Hydrate controllers
  // ============================================================

  void _hydrate(Map<String, dynamic> data) {
    if (!mounted || hydrated || data.isEmpty) return;

    hydrated = true;

    store.text = '${data['store_name'] ?? 'MM Store'}';

    insta.text = '${data['instapay_number'] ?? ''}';

    cash.text = '${data['cash_number'] ?? ''}';

    phone.text = '${data['phone'] ?? ''}';

    whatsapp.text = '${data['whatsapp'] ?? ''}';

    shipping.text = '${data['shipping_fee'] ?? 0}';

    freeShipping.text = '${data['free_shipping_threshold'] ?? 0}';
  }

  // ============================================================
  // Save
  // ============================================================

  Future<void> _save() async {
    if (!mounted) return;

    final shippingValue = double.tryParse(shipping.text.trim());

    final freeValue = double.tryParse(freeShipping.text.trim());

    if (shippingValue == null || freeValue == null) {
      _show('راجع قيم الشحن.', error: true);

      return;
    }

    final cubit = context.read<AdminSettingsCubit>();

    final ok = await cubit.save({
      'store_name': store.text.trim(),
      'instapay_number': insta.text.trim(),
      'cash_number': cash.text.trim(),
      'phone': phone.text.trim(),

      // WhatsApp number
      'whatsapp': whatsapp.text.trim(),

      'shipping_fee': shippingValue,
      'free_shipping_threshold': freeValue,
    });

    if (!mounted) return;

    _show(ok ? 'تم حفظ إعدادات المتجر' : 'تعذر حفظ الإعدادات', error: !ok);
  }

  // ============================================================
  // Snackbar
  // ============================================================

  void _show(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error ? const Color(0xFFB42318) : AppConstants.black,
          content: Text(text),
        ),
      );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إعدادات المتجر',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          onPressed: () {
            if (!mounted) return;

            context.pop();
          },
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),

          BlocConsumer<AdminSettingsCubit, AdminSettingsState>(
            // ==================================================
            // Listener
            // ==================================================
            listener: (context, state) {
              // IMPORTANT:
              // Hydrate controllers here, NOT inside build().
              if (!hydrated && state.data.isNotEmpty) {
                _hydrate(state.data);
              }

              if (state.error != null && !state.saving) {
                _show(state.error!, error: true);
              }
            },

            // ==================================================
            // Builder
            // ==================================================
            builder: (context, state) {
              if (state.loading && !hydrated) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // ============================================
                  // Header
                  // ============================================
                  const Text(
                    'بيانات الدفع والتواصل',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'الأرقام هنا هي التي سيعرضها Checkout للعميل مباشرة.',
                    style: TextStyle(color: AppConstants.muted),
                  ),

                  const SizedBox(height: 18),

                  // ============================================
                  // Store / Payment
                  // ============================================
                  PremiumPanel(
                    child: Column(
                      children: [
                        _Field(
                          controller: store,
                          label: 'اسم المتجر',
                          icon: Icons.storefront_outlined,
                        ),

                        const SizedBox(height: 12),

                        _Field(
                          controller: cash,
                          label: 'رقم الكاش / المحفظة',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 12),

                        _Field(
                          controller: insta,
                          label: 'رقم InstaPay',
                          icon: Icons.account_balance_wallet_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ============================================
                  // Contact
                  // ============================================
                  PremiumPanel(
                    child: Column(
                      children: [
                        _Field(
                          controller: phone,
                          label: 'رقم الهاتف',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 12),

                        _Field(
                          controller: whatsapp,
                          label: 'رقم WhatsApp',
                          icon: Icons.chat_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ============================================
                  // Shipping
                  // ============================================
                  PremiumPanel(
                    child: Column(
                      children: [
                        _Field(
                          controller: shipping,
                          label: 'رسوم الشحن',
                          icon: Icons.local_shipping_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _Field(
                          controller: freeShipping,
                          label: 'الحد الأدنى للشحن المجاني',
                          icon: Icons.local_offer_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ============================================
                  // Save
                  // ============================================
                  FilledButton.icon(
                    onPressed: state.saving ? null : _save,

                    icon: state.saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppConstants.black,
                            ),
                          )
                        : const Icon(Icons.save_rounded),

                    label: Text(
                      state.saving ? 'جارٍ الحفظ...' : 'حفظ الإعدادات',
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

// ================================================================
// Field
// ================================================================

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
