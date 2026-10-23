import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_route_names.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/widgets/premium_panel.dart';
import '../../../core/utils/image_upload.dart';
import '../../cart/presentation/cart_cubit.dart';
import 'checkout_cubit.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final addressController = TextEditingController();
  String payment = 'cash';

  @override
  void initState() {
    super.initState();
    context.read<CheckoutCubit>().load();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    cityController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state is CheckoutSuccess) {
          context.read<CartCubit>().clear();
          context.goNamed(AppRouteNames.orderSuccess, extra: state.result);
        }
        if (state is CheckoutFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('تأكيد الطلب')),
        body: Stack(
          children: [
            const Positioned.fill(child: PremiumBackground()),
            BlocBuilder<CheckoutCubit, CheckoutState>(
              builder: (context, state) {
                final loading =
                    state is CheckoutLoading || state is CheckoutSubmitting;
                final settings = context.read<CheckoutCubit>().settings;
                final cart = context.watch<CartCubit>().state;
                final shipping = settings == null
                    ? 0.0
                    : (cart.subtotal >= settings.freeShippingThreshold
                          ? 0.0
                          : settings.shippingFee);
                final total = cart.subtotal + shipping;

                if (cart.items.isEmpty) {
                  return const Center(child: Text('السلة فاضية'));
                }

                if (settings == null && state is CheckoutFailure) {
                  return Center(
                    child: FilledButton(
                      onPressed: () => context.read<CheckoutCubit>().load(),
                      child: const Text('إعادة تحميل إعدادات المتجر'),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    final form = Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _CheckoutSectionTitle(
                            eyebrow: '01',
                            title: 'بيانات الاستلام',
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'الاسم بالكامل',
                            ),
                            validator: (value) =>
                                value == null || value.trim().length < 2
                                ? 'اكتب الاسم'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف',
                            ),
                            validator: (value) =>
                                value == null || value.trim().length < 10
                                ? 'اكتب رقم هاتف صحيح'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: cityController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'المحافظة / المدينة',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'اكتب المدينة'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: addressController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'العنوان بالتفصيل',
                            ),
                            validator: (value) =>
                                value == null || value.trim().length < 5
                                ? 'اكتب العنوان بالتفصيل'
                                : null,
                          ),
                          const SizedBox(height: 22),
                          const _CheckoutSectionTitle(
                            eyebrow: '02',
                            title: 'طريقة الدفع',
                          ),
                          const SizedBox(height: 10),
                          _PaymentOption(
                            selected: payment == 'cash',
                            icon: Icons.payments_outlined,
                            title: 'كاش / محفظة',
                            subtitle: settings?.cashNumber.isNotEmpty == true
                                ? settings!.cashNumber
                                : 'سيتم تأكيد طريقة الدفع عبر خدمة العملاء',
                            onTap: () => setState(() => payment = 'cash'),
                          ),
                          const SizedBox(height: 10),
                          _PaymentOption(
                            selected: payment == 'instapay',
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'InstaPay',
                            subtitle:
                                settings?.instapayNumber.isNotEmpty == true
                                ? settings!.instapayNumber
                                : 'سيظهر رقم InstaPay من إعدادات المتجر',
                            onTap: () => setState(() => payment = 'instapay'),
                          ),
                          if (payment == 'instapay' && settings != null) ...[
                            const SizedBox(height: 12),
                            _PaymentInfo(
                              text:
                                  'حوّل على ${settings.instapayNumber} ثم ارفع صورة الدفع.',
                            ),
                          ],
                          const SizedBox(height: 12),
                          _PaymentProofPicker(
                            proof: context.read<CheckoutCubit>().proof,
                            onPick: () async {
                              final picked = await context
                                  .read<CheckoutCubit>()
                                  .chooseProof();
                              if (picked != null && mounted) setState(() {});
                            },
                          ),
                        ],
                      ),
                    );

                    final summary = PremiumPanel(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'ملخص الطلب',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SummaryRow('المنتجات', '${cart.items.length}'),
                          _SummaryRow(
                            'المجموع الفرعي',
                            '${cart.subtotal.toStringAsFixed(0)} EGP',
                          ),
                          _SummaryRow(
                            'الشحن',
                            shipping == 0
                                ? 'مجاني'
                                : '${shipping.toStringAsFixed(0)} EGP',
                          ),
                          const Divider(height: 26),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'الإجمالي',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${total.toStringAsFixed(0)} EGP',
                                style: const TextStyle(
                                  color: AppConstants.goldBright,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 54,
                            child: FilledButton(
                              onPressed: loading || settings == null
                                  ? null
                                  : () {
                                      if (!formKey.currentState!.validate())
                                        return;
                                      context.read<CheckoutCubit>().submit(
                                        name: nameController.text,
                                        phone: phoneController.text,
                                        city: cityController.text,
                                        address: addressController.text,
                                        paymentMethod: payment,
                                        items: cart.items,
                                      );
                                    },
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : Text('تأكيد الطلب'),
                            ),
                          ),
                        ],
                      ),
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: PremiumPanel(child: form)),
                                    const SizedBox(width: 18),
                                    SizedBox(width: 360, child: summary),
                                  ],
                                )
                              : Column(
                                  children: [
                                    PremiumPanel(child: form),
                                    const SizedBox(height: 14),
                                    summary,
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutSectionTitle extends StatelessWidget {
  const _CheckoutSectionTitle({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppConstants.gold,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            eyebrow,
            style: const TextStyle(
              color: AppConstants.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _PaymentInfo extends StatelessWidget {
  const _PaymentInfo({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.gold.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppConstants.gold.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppConstants.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentProofPicker extends StatelessWidget {
  const _PaymentProofPicker({required this.proof, required this.onPick});

  final PickedImageData? proof;
  final VoidCallback onPick;

  bool get hasProof => proof != null;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: hasProof
              ? const Color(0xFF0F2A19)
              : AppConstants.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasProof ? const Color(0xFF25D366) : AppConstants.border,
          ),
        ),
        child: Row(
          children: [
            if (proof != null)
              Container(
                width: 54,
                height: 54,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppConstants.black,
                ),
                child: Image.memory(
                  proof!.bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppConstants.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppConstants.gold,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasProof ? 'تم اختيار صورة الدفع' : 'إرفاق صورة الدفع',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasProof ? 'اضغط لتغيير الصورة' : 'مطلوبة قبل تأكيد الطلب',
                    style: const TextStyle(
                      color: AppConstants.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasProof ? Icons.edit_outlined : Icons.chevron_left_rounded,
              color: hasProof ? AppConstants.gold : AppConstants.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppConstants.gold.withValues(alpha: .1)
              : AppConstants.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppConstants.gold : AppConstants.border,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? AppConstants.gold : AppConstants.black,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: selected ? AppConstants.black : AppConstants.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppConstants.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppConstants.gold : AppConstants.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppConstants.muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
