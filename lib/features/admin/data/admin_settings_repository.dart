import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';

class AdminSettingsRepository {
  AdminSettingsRepository(this.client);

  final SupabaseClient client;

  Future<Either<AppFailure, Map<String, dynamic>>> get() async {
    try {
      final row = await client
          .from('store_settings')
          .select()
          .eq('id', 1)
          .single();
      return Right(Map<String, dynamic>.from(row));
    } catch (error) {
      return Left(mapFailure(error));
    }
  }

  Future<Either<AppFailure, Unit>> save(Map<String, dynamic> value) async {
    try {
      await client.from('store_settings').upsert({
        'id': 1,
        ...value,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return const Right(unit);
    } catch (error) {
      return Left(mapFailure(error));
    }
  }
}
