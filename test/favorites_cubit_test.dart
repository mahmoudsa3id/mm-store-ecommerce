import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mm_store/features/favorites/data/favorites_local_data_source.dart';
import 'package:mm_store/features/favorites/data/favorites_repository.dart';
import 'package:mm_store/features/favorites/presentation/favorites_cubit.dart';
import 'package:mm_store/features/home/domain/entities/home_entity.dart';

void main() {
  test('FavoritesCubit persists and toggles favorites locally', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cubit = FavoritesCubit(
      FavoritesRepository(FavoritesLocalDataSource(prefs)),
    );

    const product = ProductEntity(
      id: 'product-1',
      name: 'Test',
      image: '',
      images: [],
      price: 100,
      oldPrice: null,
      rating: 4,
      reviewCount: 1,
      colors: [],
      sizes: [],
      description: '',
      categoryId: null,
      createdAt: null,
      countSales: 0,
    );

    await cubit.load();
    expect(cubit.isFavorite(product.id), isFalse);

    await cubit.toggle(product);
    expect(cubit.isFavorite(product.id), isTrue);
    expect(prefs.getStringList('mm_store_favorite_product_ids'), ['product-1']);

    await cubit.remove(product.id);
    expect(cubit.isFavorite(product.id), isFalse);
    expect(prefs.getStringList('mm_store_favorite_product_ids'), isEmpty);

    await cubit.close();
  });
}
