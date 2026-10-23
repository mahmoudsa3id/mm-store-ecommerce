import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';

SupabaseClient? _client;
Future<SupabaseClient>? _initialization;

Future<SupabaseClient> initSupabase() {
  if (!AppEnv.isConfigured) {
    return Future.error(
      StateError('Supabase configuration is missing.'),
    );
  }

  final existing = _client;
  if (existing != null) {
    return Future.value(existing);
  }

  final inFlight = _initialization;
  if (inFlight != null) {
    return inFlight;
  }

  final future = _initializeSupabase();
  _initialization = future;
  return future;
}

Future<SupabaseClient> _initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      publishableKey: AppEnv.supabasePublishableKey,
    );

    final client = Supabase.instance.client;
    _client = client;
    return client;
  } catch (error) {
    _initialization = null;
    rethrow;
  }
}
