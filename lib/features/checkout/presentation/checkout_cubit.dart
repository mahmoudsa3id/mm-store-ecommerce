import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/utils/image_upload.dart';
import '../../cart/domain/cart_item.dart';
import '../../home/domain/entities/home_entity.dart';
import '../data/checkout_repository.dart';

sealed class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => const [];
}

final class CheckoutInitial extends CheckoutState {}

final class CheckoutLoading extends CheckoutState {}

final class CheckoutReady extends CheckoutState {
  const CheckoutReady(this.settings);

  final StoreSettings settings;

  @override
  List<Object?> get props => [settings];
}

final class CheckoutSubmitting extends CheckoutState {}

final class CheckoutSuccess extends CheckoutState {
  const CheckoutSuccess(this.result);

  final OrderCreationResult result;

  @override
  List<Object?> get props => [result.orderId, result.orderNumber];
}

final class CheckoutFailure extends CheckoutState {
  const CheckoutFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(this.repository) : super(CheckoutInitial());

  final CheckoutRepository repository;

  static const _uuid = Uuid();

  StoreSettings? settings;
  String? _requestId;
  PickedImageData? _proof;
  OrderCreationResult? _createdOrder;
  String? _proofPath;

  PickedImageData? get proof => _proof;

  Future<PickedImageData?> chooseProof() async {
    try {
      final picked = await repository.pickProof();
      if (picked != null) {
        _proof = picked;
      }
      return picked;
    } catch (error) {
      if (!isClosed) {
        emit(CheckoutFailure(mapFailure(error).message));
      }
      return null;
    }
  }

  Future<void> load() async {
    emit(CheckoutLoading());

    try {
      settings = await repository.getSettings();
      emit(CheckoutReady(settings!));
    } catch (error) {
      emit(CheckoutFailure(mapFailure(error).message));
    }
  }

  Future<void> submit({
    required String name,
    required String phone,
    required String city,
    required String address,
    required String paymentMethod,
    required List<CartItem> items,
  }) async {
    emit(CheckoutSubmitting());

    try {
      _requestId ??= _uuid.v4();

      if (_proof == null) {
        _proof = await repository.pickProof();
        if (_proof == null) {
          throw const AppFailure('يجب إرفاق صورة الدفع قبل تأكيد الطلب.');
        }
      }

      _createdOrder ??= await repository.createOrder(
        name: name,
        phone: phone,
        city: city,
        address: address,
        paymentMethod: paymentMethod,
        items: items,
        clientRequestId: _requestId!,
      );

      if (_proof != null && _proofPath == null) {
        _proofPath = await repository.uploadProof(
          orderId: _createdOrder!.orderId,
          accessToken: _createdOrder!.accessToken,
          image: _proof!,
        );
      }

      if (_proofPath != null) {
        await repository.attachProof(
          orderId: _createdOrder!.orderId,
          accessToken: _createdOrder!.accessToken,
          path: _proofPath!,
        );
      }

      final result = _createdOrder!;
      emit(CheckoutSuccess(result));
      _requestId = null;
      _proof = null;
      _createdOrder = null;
      _proofPath = null;
    } catch (error) {
      emit(CheckoutFailure(mapFailure(error).message));
    }
  }
}
