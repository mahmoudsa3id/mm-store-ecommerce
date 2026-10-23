import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import 'constants/app_constants.dart';
import 'di/injection.dart';
import 'flavor/app_flavor.dart';
import 'mm_store_app.dart';
import 'notifications/admin_fcm_service.dart';
import 'supabase/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> bootstrap(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(_StartupGate(flavor: flavor));
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({required this.flavor});

  final AppFlavor flavor;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  Object? _startupError;
  bool _ready = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _startupError = null;
    });

    try {
      try {
        await Firebase.initializeApp(
          options: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
              ? null
              : DefaultFirebaseOptions.currentPlatform,
        );
      } catch (error, stackTrace) {
        debugPrint('Firebase initialization error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      final client = await initSupabase();
      await configureDependencies(client, flavor: widget.flavor);

      if (widget.flavor == AppFlavor.admin) {
        try {
          await sl<AdminFcmService>().initialize();
        } catch (error, stackTrace) {
          debugPrint('Admin FCM initialization error: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      if (!mounted) return;
      setState(() {
        _ready = true;
        _starting = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Application startup error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _startupError = error;
        _starting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return MMStoreApp(flavor: widget.flavor);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: widget.flavor == AppFlavor.admin ? 'MM Store Admin' : 'MM Store',
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: AppConstants.page,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_startupError == null) ...[
                  const CircularProgressIndicator(color: AppConstants.gold),
                  const SizedBox(height: 18),
                  const Text(
                    'جارٍ تشغيل MM Store...',
                    style: TextStyle(color: AppConstants.textPrimary),
                  ),
                ] else ...[
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: AppConstants.gold,
                    size: 42,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'تعذر الاتصال بخدمات المتجر. تحقق من الإنترنت وحاول مرة أخرى.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppConstants.textPrimary),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _starting ? null : _initialize,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
