import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/image_upload.dart';

class AdminContentRepository {
  AdminContentRepository(this.client, this.uploads);

  final SupabaseClient client;
  final ImageUploadService uploads;

  Future<Map<String, dynamic>> content(String key) async {
    final row = await client
        .from('store_content')
        .select('key,value')
        .eq('key', key)
        .maybeSingle();
    if (row == null) return <String, dynamic>{};
    return Map<String, dynamic>.from((row['value'] as Map?) ?? const {});
  }

  Future<void> saveContent(String key, Map<String, dynamic> value) async {
    await client.from('store_content').upsert({
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> categories() async {
    final rows = await client
        .from('categories')
        .select('id,name,image_url,sort_order,is_active')
        .order('sort_order')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> upsertCategory({
    String? id,
    required String name,
    required String imageUrl,
    required int sortOrder,
    required bool isActive,
  }) async {
    final payload = {
      'name': name.trim(),
      'image_url': imageUrl.trim(),
      'sort_order': sortOrder,
      'is_active': isActive,
    };
    if (id == null) {
      await client.from('categories').insert(payload);
    } else {
      await client.from('categories').update(payload).eq('id', id);
    }
  }

  Future<List<Map<String, dynamic>>> banners() async {
    final rows = await client
        .from('banners')
        .select('id,image_url,title,button_text,target,sort_order,is_active')
        .order('sort_order')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> upsertBanner({
    String? id,
    required String imageUrl,
    required String title,
    required String buttonText,
    required String target,
    required int sortOrder,
    required bool isActive,
  }) async {
    final payload = {
      'image_url': imageUrl.trim(),
      'title': title.trim(),
      'button_text': buttonText.trim(),
      'target': target.trim().isEmpty ? 'new' : target.trim(),
      'sort_order': sortOrder,
      'is_active': isActive,
    };
    if (id == null) {
      await client.from('banners').insert(payload);
    } else {
      await client.from('banners').update(payload).eq('id', id);
    }
  }

  Future<void> deleteCategory(String id) async {
    await client.from('categories').delete().eq('id', id);
  }

  Future<void> deleteBanner(String id) async {
    await client.from('banners').delete().eq('id', id);
  }

  Future<void> deleteService(String id) async {
    await client.from('services').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> services() async {
    final rows = await client
        .from('services')
        .select('id,title,subtitle,icon,sort_order,is_active')
        .order('sort_order');
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> upsertService({
    String? id,
    required String title,
    required String subtitle,
    required String icon,
    required int sortOrder,
    required bool isActive,
  }) async {
    final payload = {
      'title': title.trim(),
      'subtitle': subtitle.trim(),
      'icon': icon.trim().isEmpty ? 'verified' : icon.trim(),
      'sort_order': sortOrder,
      'is_active': isActive,
    };
    if (id == null) {
      await client.from('services').insert(payload);
    } else {
      await client.from('services').update(payload).eq('id', id);
    }
  }

  Future<String> uploadPublicImage(PickedImageData image) =>
      uploads.uploadStoreImage(image);
}
