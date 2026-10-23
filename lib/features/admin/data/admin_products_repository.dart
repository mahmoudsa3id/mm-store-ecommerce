import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/image_upload.dart';
import '../../home/domain/entities/product_color_variant.dart';

class AdminProductsRepository {
  AdminProductsRepository(this.client, this.uploads);

  final SupabaseClient client;
  final ImageUploadService uploads;

  // ============================================================
  // LIST PRODUCTS
  // ============================================================

  Future<List<Map<String, dynamic>>> list() async {
    final rows = await client
        .from('products')
        .select(
          'id,'
          'name,'
          'image_url,'
          'images,'
          'description,'
          'price,'
          'old_price,'
          'color_variants,'
          'sizes,'
          'category_id,'
          'sales_count,'
          'is_active,'
          'created_at',
        )
        .order('created_at', ascending: false)
        .limit(200);

    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Future<List<Map<String, dynamic>>> categories() async {
    final rows = await client
        .from('categories')
        .select('id,name')
        .eq('is_active', true)
        .order('sort_order');

    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ============================================================
  // ACTIVE / INACTIVE
  // ============================================================

  Future<void> setActive(String id, bool value) async {
    await client.from('products').update({'is_active': value}).eq('id', id);
  }

  // ============================================================
  // CREATE PRODUCT
  // ============================================================

  Future<void> create({
    required String name,
    required String description,
    required double price,
    double? oldPrice,
    required String categoryId,
    required List<String> sizes,

    /// New images selected from device.
    ///
    /// key   = HEX color
    /// value = selected image
    required Map<String, PickedImageData> colorVariantImages,

    /// Existing variants.
    ///
    /// Normally this will be empty when creating
    /// a completely new product.
    required List<ProductColorVariant> colorVariants,
  }) async {
    final finalVariants = <Map<String, dynamic>>[];

    try {
      // ========================================================
      // EXISTING COLOR VARIANTS
      // ========================================================

      for (final variant in colorVariants) {
        if (variant.imageUrl.trim().isEmpty) {
          continue;
        }

        finalVariants.add({
          'color': variant.color,
          'image_url': variant.imageUrl,
        });
      }

      // ========================================================
      // NEW COLOR IMAGES
      // ========================================================

      for (final entry in colorVariantImages.entries) {
        final color = entry.key.trim().toUpperCase();

        if (color.isEmpty) {
          continue;
        }

        final imageUrl = await uploads.uploadProductImage(entry.value);

        // Prevent duplicate color.
        finalVariants.removeWhere(
          (item) => item['color'].toString().toUpperCase() == color,
        );

        finalVariants.add({'color': color, 'image_url': imageUrl});
      }

      // ========================================================
      // VALIDATION
      // ========================================================

      if (finalVariants.isEmpty) {
        throw StateError('PRODUCT_MUST_HAVE_COLOR_IMAGE');
      }

      // ========================================================
      // MAIN IMAGE
      // ========================================================
      //
      // We no longer have a separate main image.
      //
      // For backward compatibility with the existing
      // database columns, image_url is automatically
      // taken from the first color variant.
      //

      final firstImage = finalVariants.first['image_url']?.toString();

      // ========================================================
      // DATABASE INSERT
      // ========================================================

      await client.from('products').insert({
        'name': name.trim(),

        'description': description.trim(),

        'price': price,

        'old_price': oldPrice,

        'category_id': categoryId,

        'sizes': sizes,

        'color_variants': finalVariants,

        // Legacy compatibility.
        'image_url': firstImage,

        'images': firstImage == null ? <String>[] : <String>[firstImage],

        'is_active': true,

        'sales_count': 0,
      });
    } catch (_) {
      rethrow;
    }
  }

  // ============================================================
  // UPDATE PRODUCT
  // ============================================================

  Future<void> update({
    required String id,
    required String name,
    required String description,
    required double price,
    double? oldPrice,
    required String categoryId,
    required List<String> sizes,

    /// New images selected from device.
    required Map<String, PickedImageData> colorVariantImages,

    /// FINAL list of existing variants.
    ///
    /// Important:
    /// If a color was deleted in the UI,
    /// it will NOT exist here and therefore
    /// will be removed from the database.
    required List<ProductColorVariant> colorVariants,
  }) async {
    final finalVariants = <Map<String, dynamic>>[];

    // ==========================================================
    // EXISTING VARIANTS
    // ==========================================================

    for (final variant in colorVariants) {
      final color = variant.color.trim().toUpperCase();

      final imageUrl = variant.imageUrl.trim();

      if (color.isEmpty) {
        continue;
      }

      if (imageUrl.isEmpty) {
        continue;
      }

      finalVariants.add({'color': color, 'image_url': imageUrl});
    }

    // ==========================================================
    // NEW / REPLACED IMAGES
    // ==========================================================

    for (final entry in colorVariantImages.entries) {
      final color = entry.key.trim().toUpperCase();

      if (color.isEmpty) {
        continue;
      }

      final imageUrl = await uploads.uploadProductImage(entry.value);

      // Replace old image for same color.
      finalVariants.removeWhere(
        (item) => item['color'].toString().toUpperCase() == color,
      );

      finalVariants.add({'color': color, 'image_url': imageUrl});
    }

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (finalVariants.isEmpty) {
      throw StateError('PRODUCT_MUST_HAVE_COLOR_IMAGE');
    }

    // ==========================================================
    // REMOVE DUPLICATE COLORS
    // ==========================================================

    final uniqueVariants = <Map<String, dynamic>>[];

    final usedColors = <String>{};

    for (final variant in finalVariants) {
      final color = variant['color'].toString().toUpperCase();

      if (usedColors.contains(color)) {
        continue;
      }

      usedColors.add(color);
      uniqueVariants.add(variant);
    }

    // ==========================================================
    // FIRST IMAGE
    // ==========================================================

    final firstImage = uniqueVariants.first['image_url']?.toString();

    // ==========================================================
    // DATABASE PAYLOAD
    // ==========================================================

    final payload = <String, dynamic>{
      'name': name.trim(),

      'description': description.trim(),

      'price': price,

      'old_price': oldPrice,

      'category_id': categoryId,

      'sizes': sizes,

      'color_variants': uniqueVariants,

      // Legacy compatibility.
      'image_url': firstImage,

      'images': firstImage == null ? <String>[] : <String>[firstImage],
    };

    // ==========================================================
    // UPDATE
    // ==========================================================

    await client.from('products').update(payload).eq('id', id);
  } // ============================================================
  // DELETE PRODUCT
  // ============================================================

  Future<void> delete(String id) async {
    await client.from('products').delete().eq('id', id);
  }
}
