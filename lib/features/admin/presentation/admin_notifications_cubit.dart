import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/notifications/admin_fcm_service.dart';
import '../../../core/notifications/admin_notification_service.dart';

class AdminNotificationsState extends Equatable {
  const AdminNotificationsState({this.unread = 0, this.started = false});

  final int unread;
  final bool started;

  AdminNotificationsState copyWith({int? unread, bool? started}) {
    return AdminNotificationsState(
      unread: unread ?? this.unread,
      started: started ?? this.started,
    );
  }

  @override
  List<Object?> get props => [unread, started];
}

class AdminNotificationsCubit extends Cubit<AdminNotificationsState> {
  AdminNotificationsCubit(this.service, this.fcm)
    : super(const AdminNotificationsState());

  final AdminNotificationService service;
  final AdminFcmService fcm;
  StreamSubscription<RemoteMessage>? _subscription;

  Future<void> start() async {
    if (state.started) return;

    final storedUnread = await service.unreadCount();
    if (isClosed) return;
    emit(state.copyWith(unread: storedUnread, started: true));

    await _subscription?.cancel();
    _subscription = fcm.newOrderMessages.listen((_) {
      if (isClosed) return;
      emit(state.copyWith(unread: state.unread + 1));
    });
  }

  Future<bool> requestPermission() => fcm.requestPermission();

  Future<void> clear() async {
    await service.markAllRead();
    if (!isClosed) emit(state.copyWith(unread: 0));
  }

  Future<String?> openLatestUnreadOrder() async {
    final orderId = await service.latestUnreadOrderId();
    if (orderId == null || orderId.isEmpty) return null;

    await service.markOrderRead(orderId);
    if (!isClosed && state.unread > 0) {
      emit(state.copyWith(unread: state.unread - 1));
    }
    return orderId;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
