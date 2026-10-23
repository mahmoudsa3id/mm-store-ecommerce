import '../entities/home_entity.dart';
import '../repositories/home_repository.dart';

class GetHomeContent {
  const GetHomeContent(this.repository);
  final HomeRepository repository;

  Future<HomeContent> call({bool forceRefresh = false}) =>
      repository.getHome(forceRefresh: forceRefresh);
}
