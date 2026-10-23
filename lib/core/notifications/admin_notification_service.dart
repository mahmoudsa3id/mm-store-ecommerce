import 'package:supabase_flutter/supabase_flutter.dart';

class AdminNotificationService {
  AdminNotificationService(this.client);

  final SupabaseClient client;

  Future<int> unreadCount() async {
    try {
      final rows = await client
          .from('admin_notifications')
          .select('id')
          .eq('is_read', false);
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAllRead() async {
    try {
      await client
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('is_read', false);
    } catch (_) {}
  }

  Future<String?> latestUnreadOrderId() async {
    try {
      final row = await client
          .from('admin_notifications')
          .select('order_id')
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row?['order_id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> markOrderRead(String orderId) async {
    await client
        .from('admin_notifications')
        .update({'is_read': true})
        .eq('order_id', orderId)
        .eq('is_read', false);
  }
}
