import 'package:dartz/dartz.dart';

import '../../../core/error/app_failure.dart';
import 'favorites_local_data_source.dart';

class FavoritesRepository {
  FavoritesRepository(this._local);

  final FavoritesLocalDataSource _local;

  Either<AppFailure, Set<String>> loadIds() {
    try {
      return Right(_local.readIds());
    } catch (error) {
      return Left(mapFailure(error));
    }
  }

  Future<Either<AppFailure, Unit>> saveIds(Set<String> ids) async {
    try {
      await _local.saveIds(ids);
      return const Right(unit);
    } catch (error) {
      return Left(mapFailure(error));
    }
  }
}
