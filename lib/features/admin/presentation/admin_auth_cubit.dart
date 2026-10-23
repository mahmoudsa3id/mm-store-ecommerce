import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/notifications/admin_fcm_service.dart';
import '../data/admin_auth_repository.dart';

sealed class AdminAuthState extends Equatable {
  const AdminAuthState();

  @override
  List<Object?> get props => const [];
}

final class AdminUnauthenticated extends AdminAuthState {}

final class AdminAuthenticating extends AdminAuthState {}

final class AdminAuthenticated extends AdminAuthState {}

final class AdminAuthFailure extends AdminAuthState {
  const AdminAuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AdminAuthCubit extends Cubit<AdminAuthState> {
  AdminAuthCubit(this.repo, this.fcm) : super(AdminUnauthenticated());

  final AdminAuthRepository repo;
  final AdminFcmService fcm;

  Future<void> login(String email, String password) async {
    emit(AdminAuthenticating());
    try {
      await repo.signIn(email.trim(), password);
      emit(AdminAuthenticated());
    } catch (error) {
      emit(AdminAuthFailure(mapFailure(error).message));
    }
  }

  Future<void> logout() async {
    try {
      await fcm.deactivateCurrentToken();
      await repo.signOut();
    } finally {
      emit(AdminUnauthenticated());
    }
  }
}
