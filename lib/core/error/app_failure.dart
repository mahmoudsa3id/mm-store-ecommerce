import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppFailure implements Exception {
  const AppFailure(
    this.message, {
    this.code,
    this.cause,
  });

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => message;
}

AppFailure mapFailure(Object error) {
  if (error is AppFailure) return error;

  if (error is StateError && error.message.isNotEmpty) {
    return AppFailure(error.message.toString(), cause: error);
  }

  if (error is AuthException) {
    return AppFailure(
      'بيانات الدخول غير صحيحة أو الحساب غير مفعّل.',
      code: error.statusCode,
      cause: error,
    );
  }

  if (error is PostgrestException) {
    switch (error.code) {
      case '42501':
        return AppFailure(
          'ليست لديك صلاحية لتنفيذ هذا الإجراء.',
          code: error.code,
          cause: error,
        );
      case '23505':
        return AppFailure(
          'هذه البيانات موجودة بالفعل.',
          code: error.code,
          cause: error,
        );
      default:
        if (kDebugMode) {
          debugPrint('Supabase error ${error.code}: ${error.message}');
        }
        return AppFailure(
          'تعذر تنفيذ العملية على المتجر.',
          code: error.code,
          cause: error,
        );
    }
  }

  final raw = error.toString().toLowerCase();
  if (raw.contains('socketexception') ||
      raw.contains('network') ||
      raw.contains('connection')) {
    return AppFailure('تعذر الاتصال بالإنترنت. حاول مرة أخرى.', cause: error);
  }

  if (raw.contains('permission') || raw.contains('row-level security')) {
    return AppFailure(
      'ليست لديك صلاحية لتنفيذ هذا الإجراء.',
      cause: error,
    );
  }

  return AppFailure(
    'حدث خطأ غير متوقع. حاول مرة أخرى.',
    cause: error,
  );
}
