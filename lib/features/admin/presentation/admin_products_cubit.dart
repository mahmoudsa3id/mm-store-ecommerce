import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/utils/image_upload.dart';
import '../../home/domain/entities/product_color_variant.dart';
import '../data/admin_products_repository.dart';

class AdminProductsState {
  const AdminProductsState({
    this.items = const [],
    this.categories = const [],
    this.loading = false,
    this.error,
  });

  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> categories;
  final bool loading;
  final String? error;

  AdminProductsState copyWith({
    List<Map<String, dynamic>>? items,
    List<Map<String, dynamic>>? categories,
    bool? loading,
    String? error,
  }) {
    return AdminProductsState(
      items: items ?? this.items,
      categories: categories ?? this.categories,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class AdminProductsCubit extends Cubit<AdminProductsState> {
  AdminProductsCubit(this.repo) : super(const AdminProductsState());

  final AdminProductsRepository repo;

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));

    try {
      final results = await Future.wait([repo.list(), repo.categories()]);

      emit(
        AdminProductsState(
          items: results[0],
          categories: results[1],
          loading: false,
        ),
      );
    } catch (error) {
      emit(state.copyWith(loading: false, error: mapFailure(error).message));
    }
  }

  // ============================================================
  // TOGGLE ACTIVE
  // ============================================================
  // ============================================================
  // DELETE PRODUCT
  // ============================================================

  Future<void> delete(String id) async {
    try {
      await repo.delete(id);

      await load();
    } catch (error) {
      emit(state.copyWith(error: mapFailure(error).message));

      rethrow;
    }
  }

  Future<void> toggle(String id, bool value) async {
    try {
      await repo.setActive(id, value);

      await load();
    } catch (error) {
      emit(state.copyWith(error: mapFailure(error).message));
    }
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

    /// الصور الجديدة لكل لون.
    required Map<String, PickedImageData> colorVariantImages,

    /// الألوان التي لديها صور محفوظة بالفعل.
    required List<ProductColorVariant> colorVariants,
  }) async {
    try {
      await repo.create(
        name: name,
        description: description,
        price: price,
        oldPrice: oldPrice,
        categoryId: categoryId,
        sizes: sizes,
        colorVariantImages: colorVariantImages,
        colorVariants: colorVariants,
      );

      await load();
    } catch (error) {
      emit(state.copyWith(error: mapFailure(error).message));

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

    /// الصور الجديدة لكل لون.
    required Map<String, PickedImageData> colorVariantImages,

    /// الألوان الموجودة مع صورها الحالية.
    required List<ProductColorVariant> colorVariants,
  }) async {
    try {
      await repo.update(
        id: id,
        name: name,
        description: description,
        price: price,
        oldPrice: oldPrice,
        categoryId: categoryId,
        sizes: sizes,
        colorVariantImages: colorVariantImages,
        colorVariants: colorVariants,
      );

      await load();
    } catch (error) {
      emit(state.copyWith(error: mapFailure(error).message));

      rethrow;
    }
  }
}
