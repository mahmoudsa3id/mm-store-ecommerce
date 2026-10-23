import 'package:flutter_test/flutter_test.dart';
import 'package:mm_store/features/home/domain/entities/home_entity.dart';
import 'package:mm_store/features/home/domain/repositories/home_repository.dart';
import 'package:mm_store/features/home/domain/usecases/get_home_content.dart';
import 'package:mm_store/features/home/presentation/cubit/home_cubit.dart';

class FakeHomeRepository implements HomeRepository {
  @override
  Future<HomeContent> getHome({bool forceRefresh = false}) async =>
      const HomeContent(
        hero: HeroContent(
          image: '',
          title: 'Hero',
          subtitle: 'Sub',
          button: 'Go',
        ),
        categories: [],
        services: [],
        bestSellers: [],
        newArrivals: [],
        banners: [],
        about: AboutEntity(title: '', description: '', image: ''),
        socials: SocialEntity(
          instagram: '',
          facebook: '',
          tiktok: '',
          telegram: '',
        ),
        contact: ContactEntity(phone: '', email: '', address: ''),
        settings: StoreSettings.empty,
      );
}

void main() {
  test('HomeCubit emits loaded state', () async {
    final cubit = HomeCubit(GetHomeContent(FakeHomeRepository()));
    await cubit.load();
    expect(cubit.state, isA<HomeLoaded>());
    await cubit.close();
  });
}
