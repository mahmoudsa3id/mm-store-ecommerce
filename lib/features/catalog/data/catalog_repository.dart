import 'package:mm_store/features/home/domain/entities/product_color_variant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../home/domain/entities/home_entity.dart';

class CatalogRepository {
  CatalogRepository(this.client);

  final SupabaseClient client;

  static const _productColumns =
      'id,name,image_url,images,price,old_price,rating,review_count,colors,color_variants,sizes,description,category_id,created_at,sales_count';

  Future<List<CategoryEntity>> getCategories() async {
    final rows = await client
        .from('categories')
        .select('id,name,image_url')
        .eq('is_active', true)
        .order('sort_order');

    return (rows as List)
        .map((e) => _categoryFromMap(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  Future<List<ProductEntity>> getProducts({
    int page = 0,
    int pageSize = 20,
    String? categoryId,
    String? search,
    String sort = 'new',
  }) async {
    var query = client
        .from('products')
        .select(_productColumns)
        .eq('is_active', true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }

    final normalizedSearch = search?.trim();
    if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
      query = query.ilike('name', '%$normalizedSearch%');
    }

    final start = page * pageSize;
    final end = start + pageSize - 1;

    final rows = sort == 'best'
        ? await query
              .order('sales_count', ascending: false)
              .order('created_at', ascending: false)
              .range(start, end)
        : await query.order('created_at', ascending: false).range(start, end);

    return (rows as List)
        .map((e) => _productFromMap(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  Future<List<ProductEntity>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return const <ProductEntity>[];

    final rows = await client
        .from('products')
        .select(_productColumns)
        .eq('is_active', true)
        .inFilter('id', ids);

    final byId = <String, ProductEntity>{};
    for (final row in rows as List) {
      final product = _productFromMap(Map<String, dynamic>.from(row as Map));
      byId[product.id] = product;
    }

    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<ProductEntity> getProduct(String id) async {
    final row = await client
        .from('products')
        .select(_productColumns)
        .eq('id', id)
        .maybeSingle();

    if (row == null) {
      throw StateError('PRODUCT_NOT_FOUND');
    }

    return _productFromMap(Map<String, dynamic>.from(row));
  }

  CategoryEntity _categoryFromMap(Map<String, dynamic> map) {
    return CategoryEntity(
      id: map['id'].toString(),
      name: (map['name'] ?? '').toString(),
      image: (map['image_url'] ?? '').toString(),
    );
  }

  ProductEntity _productFromMap(Map<String, dynamic> map) {
    return ProductEntity(
      id: map['id'].toString(),
      name: (map['name'] ?? '').toString(),
      image: (map['image_url'] ?? '').toString(),
      images: List<String>.from((map['images'] as List?) ?? const []),
      price: (map['price'] as num? ?? 0).toDouble(),
      oldPrice: (map['old_price'] as num?)?.toDouble(),
      rating: (map['rating'] as num? ?? 0).toDouble(),
      reviewCount: (map['review_count'] as num? ?? 0).toInt(),
      colors: List<String>.from((map['colors'] as List?) ?? const []),
      colorVariants:
          (map['color_variants'] as List?)
              ?.map(
                (e) => ProductColorVariant.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(growable: false) ??
          const [],
      sizes: List<String>.from((map['sizes'] as List?) ?? const []),
      description: (map['description'] ?? '').toString(),
      categoryId: map['category_id']?.toString(),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
      countSales: (map['sales_count'] as num? ?? 0).toInt(),
    );
  }
}
