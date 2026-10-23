import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/image_upload.dart';

class AdminOrdersRepository {
  AdminOrdersRepository(this.client, this.uploads);

  final SupabaseClient client;
  final ImageUploadService uploads;

  Future<List<Map<String, dynamic>>> getOrders() async {
    final rows = await client
        .from('orders')
        .select('''
          id,
          order_number,
          customer_name,
          phone,
          city,
          address,
          payment_method,
          payment_status,
          order_status,
          subtotal,
          shipping_fee,
          total,
          payment_proof_path,
          created_at,
          order_items(
            id,
            product_id,
            product_name,
            unit_price,
            quantity,
            size,
            color,
            product:products!order_items_product_id_fkey(
              image_url,
              images,
              color_variants
            )
          )
        ''')
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Stream<List<Map<String, dynamic>>> watchOrders() {
    return client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100)
        .map((rows) => rows.map(Map<String, dynamic>.from).toList());
  }

  Future<void> updateStatus(String id, String status) async {
    await client.from('orders').update({'order_status': status}).eq('id', id);
  }

  Future<void> updatePayment(String id, String status) async {
    await client
        .from('orders')
        .update({'payment_status': status})
        .eq('id', id);
  }

  Future<void> deleteOrder(String id) async {
    await client.from('orders').delete().eq('id', id);
  }

  Future<String?> signedProof(String? path) async {
    if (path == null || path.isEmpty) return null;
    return uploads.createPaymentProofSignedUrl(path);
  }
}
