import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_failure.dart';
import '../data/admin_dashboard_repository.dart';

class AdminDashboardState {
  const AdminDashboardState({
    this.data = const {},
    this.loading = false,
    this.error,
  });

  final Map<String, dynamic> data;
  final bool loading;
  final String? error;

  AdminDashboardState copyWith({
    Map<String, dynamic>? data,
    bool? loading,
    String? error,
  }) => AdminDashboardState(
    data: data ?? this.data,
    loading: loading ?? this.loading,
    error: error,
  );
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this.repo) : super(const AdminDashboardState());

  final AdminDashboardRepository repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      emit(AdminDashboardState(data: await repo.get()));
    } catch (error) {
      emit(AdminDashboardState(error: mapFailure(error).message));
    }
  }
}
