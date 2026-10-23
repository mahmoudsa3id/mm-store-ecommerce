import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/admin_settings_repository.dart';

class AdminSettingsState extends Equatable {
  const AdminSettingsState({
    this.data = const {},
    this.loading = false,
    this.saving = false,
    this.error,
    this.saved = false,
  });

  final Map<String, dynamic> data;
  final bool loading;
  final bool saving;
  final String? error;
  final bool saved;

  AdminSettingsState copyWith({
    Map<String, dynamic>? data,
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
    bool? saved,
  }) {
    return AdminSettingsState(
      data: data ?? this.data,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
      saved: saved ?? this.saved,
    );
  }

  @override
  List<Object?> get props => [data, loading, saving, error, saved];
}

class AdminSettingsCubit extends Cubit<AdminSettingsState> {
  AdminSettingsCubit(this.repo) : super(const AdminSettingsState());

  final AdminSettingsRepository repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true, saved: false));
    final result = await repo.get();
    result.fold(
      (failure) => emit(
        state.copyWith(
          loading: false,
          error: failure.message,
        ),
      ),
      (data) => emit(
        AdminSettingsState(data: data),
      ),
    );
  }

  Future<bool> save(Map<String, dynamic> data) async {
    emit(state.copyWith(saving: true, clearError: true, saved: false));
    final result = await repo.save(data);

    return result.fold(
      (failure) {
        emit(state.copyWith(saving: false, error: failure.message));
        return false;
      },
      (_) {
        emit(
          AdminSettingsState(
            data: {...state.data, ...data},
            saved: true,
          ),
        );
        return true;
      },
    );
  }
}
