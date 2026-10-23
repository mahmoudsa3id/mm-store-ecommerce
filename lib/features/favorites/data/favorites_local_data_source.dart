import 'package:shared_preferences/shared_preferences.dart';

class FavoritesLocalDataSource {
  FavoritesLocalDataSource(this._prefs);

  static const _key = 'mm_store_favorite_product_ids';
  final SharedPreferences _prefs;

  Set<String> readIds() {
    final raw = _prefs.getStringList(_key) ?? const <String>[];
    return raw.where((id) => id.trim().isNotEmpty).toSet();
  }

  Future<void> saveIds(Set<String> ids) async {
    final sorted = ids.toList()..sort();
    await _prefs.setStringList(_key, sorted);
  }
}
