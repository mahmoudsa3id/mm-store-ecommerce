import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAuthRepository {
  AdminAuthRepository(this.client);
  final SupabaseClient client;

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
    try {
      final ok = await client.rpc('is_admin');
      if (ok != true) {
        await client.auth.signOut();
        throw StateError('NOT_ADMIN');
      }
    } catch (_) {
      await client.auth.signOut();
      rethrow;
    }
  }

  Future<void> signOut() => client.auth.signOut();
}
