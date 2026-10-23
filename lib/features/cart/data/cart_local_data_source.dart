import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/cart_item.dart';

class CartLocalDataSource {
  CartLocalDataSource(this.prefs);
  final SharedPreferences prefs;
  static const _key = 'mm_store_cart_v2';

  List<CartItem> read() {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map>();
    return list.map((e) => CartItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> write(List<CartItem> items) async => prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
}
