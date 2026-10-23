import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_route_names.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/widgets/premium_lottie.dart';
import '../../../core/widgets/premium_panel.dart';
import 'admin_auth_cubit.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AdminAuthCubit>().login(
      _email.text.trim(),
      _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.page,
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: PremiumPanel(
                  padding: const EdgeInsets.all(26),
                  child: BlocListener<AdminAuthCubit, AdminAuthState>(
                    listener: (context, state) {
                      if (state is AdminAuthenticated) {
                        context.goNamed(AppRouteNames.admin);
                      }
                      if (state is AdminAuthFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFFB42318),
                            content: Text(state.message),
                          ),
                        );
                      }
                    },
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const PremiumLottie(
                            asset: 'assets/lottie/mm_pulse.json',
                            width: 120,
                            height: 120,
                          ),
                          const Text(
                            'MM Store Admin',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'ادخل لإدارة الطلبات والمنتجات والمحتوى',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppConstants.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) =>
                                value == null || !value.contains('@')
                                ? 'اكتب بريدًا صحيحًا'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.length < 6
                                ? 'كلمة المرور قصيرة'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          BlocBuilder<AdminAuthCubit, AdminAuthState>(
                            builder: (context, state) {
                              final loading = state is AdminAuthenticating;
                              return SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: loading ? null : _submit,
                                  icon: loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppConstants.textPrimary,
                                          ),
                                        )
                                      : const Icon(Icons.login_rounded),
                                  label: Text(
                                    loading ? 'جارٍ الدخول...' : 'دخول الإدارة',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
