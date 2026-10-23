import '../../domain/entities/home_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({this.remote});

  final HomeRemoteDataSource? remote;
  HomeContent? _cache;
  DateTime? _cachedAt;

  bool get _hasFreshCache =>
      _cache != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) < const Duration(minutes: 5);

  @override
  Future<HomeContent> getHome({bool forceRefresh = false}) async {
    if (!forceRefresh && _hasFreshCache) return _cache!;

    try {
      final result = await remote!.getHome();
      _cache = result;
      _cachedAt = DateTime.now();
      return result;
    } catch (_) {
      if (_cache != null) return _cache!;
      rethrow;
    }
  }
}
