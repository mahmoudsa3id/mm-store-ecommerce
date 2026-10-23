import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/image_upload.dart';
import '../../cart/domain/cart_item.dart';
import '../../home/domain/entities/home_entity.dart';

class OrderCreationResult {
  const OrderCreationResult({
    required this.orderId,
    required this.orderNumber,
    required this.accessToken,
    required this.total,
  });
  final String orderId;
  final String orderNumber;
  final String accessToken;
  final double total;
}

class CheckoutRepository {
  CheckoutRepository(this.client, this.uploads);
  final SupabaseClient client;
  final ImageUploadService uploads;

  Future<StoreSettings> getSettings() async {
    final row = await client
        .from('store_settings')
        .select()
        .eq('id', 1)
        .single();
    return StoreSettings(
      storeName: row['store_name'] as String,
      instapayNumber: (row['instapay_number'] ?? '') as String,
      cashNumber: (row['cash_number'] ?? '') as String,
      phone: (row['phone'] ?? '') as String,
      whatsapp: (row['whatsapp'] ?? '') as String,
      shippingFee: ((row['shipping_fee'] ?? 0) as num).toDouble(),
      freeShippingThreshold: ((row['free_shipping_threshold'] ?? 0) as num)
          .toDouble(),
    );
  }

  Future<OrderCreationResult> createOrder({
    required String name,
    required String phone,
    required String city,
    required String address,
    required String paymentMethod,
    required List<CartItem> items,
    required String clientRequestId,
  }) async {
    try {
      final params = {
        'p_customer_name': name.trim(),
        'p_phone': phone.trim(),
        'p_city': city.trim(),
        'p_address': address.trim(),
        'p_payment_method': paymentMethod,
        'p_items': items.map((e) => e.toJson()).toList(),
        'p_client_request_id': clientRequestId,
      };

      print('========== CREATE ORDER ==========');
      print('PARAMS: $params');

      final result = await client.rpc('create_order', params: params);

      print('SUPABASE RAW RESULT: $result');
      print('RESULT TYPE: ${result.runtimeType}');
      print('=================================');

      if (result is! Map) {
        throw Exception(
          'Invalid response from create_order: ${result.runtimeType}',
        );
      }

      final map = Map<String, dynamic>.from(result);

      return OrderCreationResult(
        orderId: map['order_id'].toString(),
        orderNumber: map['order_number']?.toString() ?? '',
        accessToken: map['access_token']?.toString() ?? '',
        total: (map['total'] as num?)?.toDouble() ?? 0,
      );
    } on PostgrestException catch (e, stackTrace) {
      print('========== SUPABASE ORDER ERROR ==========');
      print('CODE: ${e.code}');
      print('MESSAGE: ${e.message}');
      print('DETAIL: ${e.details}');
      print('HINT: ${e.hint}');
      print('STACK: $stackTrace');
      print('==========================================');

      rethrow;
    } catch (e, stackTrace) {
      print('========== ORDER ERROR ==========');
      print('ERROR: $e');
      print('STACK: $stackTrace');
      print('================================');

      rethrow;
    }
  }

  Future<PickedImageData?> pickProof() => uploads.pickImage();

  Future<String> uploadProof({
    required String orderId,
    required String accessToken,
    required PickedImageData image,
  }) => uploads.uploadPaymentProof(
    orderId: orderId,
    accessToken: accessToken,
    image: image,
  );

  Future<void> attachProof({
    required String orderId,
    required String accessToken,
    required String path,
  }) async {
    await client.rpc(
      'attach_payment_proof',
      params: {
        'p_order_id': orderId,
        'p_access_token': accessToken,
        'p_proof_path': path,
      },
    );
  }
}
