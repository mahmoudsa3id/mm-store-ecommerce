import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../home/domain/entities/home_entity.dart';
import '../data/favorites_repository.dart';

sealed class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => const [];
}

final class FavoritesInitial extends FavoritesState {}

final class FavoritesLoading extends FavoritesState {}

final class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded({required this.ids, required this.products});

  final Set<String> ids;
  final List<ProductEntity> products;

  @override
  List<Object?> get props => [ids, products];
}

final class FavoritesFailure extends FavoritesState {
  const FavoritesFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this._repository, [this._catalog]) : super(FavoritesInitial());

  final FavoritesRepository _repository;
  final CatalogRepository? _catalog;

  Set<String> get ids => switch (state) {
    FavoritesLoaded(:final ids) => ids,
    _ => const <String>{},
  };

  bool isFavorite(String productId) => ids.contains(productId);

  Future<void> load() async {
    emit(FavoritesLoading());

    final result = _repository.loadIds();
    final ids = result.getOrElse(() => <String>{});

    if (result.isLeft()) {
      emit(
        FavoritesFailure(
          result.fold((failure) => failure.message, (_) => 'حدث خطأ'),
        ),
      );
      return;
    }

    try {
      final products = ids.isEmpty || _catalog == null
          ? const <ProductEntity>[]
          : await _catalog.getProductsByIds(ids.toList());
      emit(FavoritesLoaded(ids: ids, products: products));
    } catch (error) {
      emit(FavoritesFailure(error.toString()));
    }
  }

  Future<void> toggle(ProductEntity product) async {
    final updated = {...ids};
    if (updated.contains(product.id)) {
      updated.remove(product.id);
    } else {
      updated.add(product.id);
    }

    final result = await _repository.saveIds(updated);
    if (result.isLeft()) {
      emit(
        FavoritesFailure(
          result.fold((failure) => failure.message, (_) => 'تعذر حفظ المفضلة'),
        ),
      );
      return;
    }

    try {
      final products = updated.isEmpty || _catalog == null
          ? const <ProductEntity>[]
          : await _catalog.getProductsByIds(updated.toList());
      emit(FavoritesLoaded(ids: updated, products: products));
    } catch (error) {
      final currentProducts = switch (state) {
        FavoritesLoaded(:final products) => products,
        _ => const <ProductEntity>[],
      };
      emit(FavoritesLoaded(ids: updated, products: currentProducts));
    }
  }

  Future<void> remove(String productId) async {
    final updated = {...ids}..remove(productId);
    final result = await _repository.saveIds(updated);

    if (result.isLeft()) {
      emit(
        FavoritesFailure(
          result.fold((failure) => failure.message, (_) => 'تعذر حذف المفضلة'),
        ),
      );
      return;
    }

    try {
      final products = updated.isEmpty || _catalog == null
          ? const <ProductEntity>[]
          : await _catalog.getProductsByIds(updated.toList());
      emit(FavoritesLoaded(ids: updated, products: products));
    } catch (error) {
      emit(FavoritesFailure(error.toString()));
    }
  }
}
