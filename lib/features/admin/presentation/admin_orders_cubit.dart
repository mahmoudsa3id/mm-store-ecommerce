import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_failure.dart';

import '../data/admin_orders_repository.dart';

class AdminOrdersState {
  const AdminOrdersState({this.items = const [], this.loading = false, this.error});
  final List<Map<String, dynamic>> items;
  final bool loading;
  final String? error;

  AdminOrdersState copyWith({
    List<Map<String, dynamic>>? items,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AdminOrdersState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  AdminOrdersCubit(this.repo) : super(const AdminOrdersState());

  final AdminOrdersRepository repo;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final items = await repo.getOrders();
      emit(AdminOrdersState(items: items));
      _subscription ??= repo.watchOrders().listen((_) async {
        try {
          final refreshed = await repo.getOrders();
          if (!isClosed) emit(state.copyWith(items: refreshed));
        } catch (e) {
          if (!isClosed) emit(state.copyWith(error: mapFailure(e).message));
        }
      });
    } catch (e) {
      emit(AdminOrdersState(error: mapFailure(e).message));
    }
  }

  Future<void> setStatus(String id, String status) async {
    try {
      await repo.updateStatus(id, status);
    } catch (e) {
      emit(state.copyWith(error: mapFailure(e).message));
    }
  }

  Future<void> setPayment(String id, String status) async {
    try {
      await repo.updatePayment(id, status);
    } catch (e) {
      emit(state.copyWith(error: mapFailure(e).message));
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await repo.deleteOrder(id);
      if (isClosed) return;
      emit(
        state.copyWith(
          items: state.items
              .where((order) => order['id']?.toString() != id)
              .toList(),
          clearError: true,
        ),
      );
    } catch (error) {
      if (!isClosed) emit(state.copyWith(error: mapFailure(error).message));
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
