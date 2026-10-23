import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_failure.dart';

import '../data/admin_content_repository.dart';

class AdminContentState {
  const AdminContentState({
    this.hero = const {},
    this.about = const {},
    this.socials = const {},
    this.contact = const {},
    this.categories = const [],
    this.banners = const [],
    this.services = const [],
    this.loading = false,
    this.saving = false,
    this.error,
  });

  final Map<String, dynamic> hero;
  final Map<String, dynamic> about;
  final Map<String, dynamic> socials;
  final Map<String, dynamic> contact;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> banners;
  final List<Map<String, dynamic>> services;
  final bool loading;
  final bool saving;
  final String? error;

  AdminContentState copyWith({
    Map<String, dynamic>? hero,
    Map<String, dynamic>? about,
    Map<String, dynamic>? socials,
    Map<String, dynamic>? contact,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? banners,
    List<Map<String, dynamic>>? services,
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
  }) {
    return AdminContentState(
      hero: hero ?? this.hero,
      about: about ?? this.about,
      socials: socials ?? this.socials,
      contact: contact ?? this.contact,
      categories: categories ?? this.categories,
      banners: banners ?? this.banners,
      services: services ?? this.services,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminContentCubit extends Cubit<AdminContentState> {
  AdminContentCubit(this.repo) : super(const AdminContentState());

  final AdminContentRepository repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final results = await Future.wait([
        repo.content('hero'),
        repo.content('about'),
        repo.content('socials'),
        repo.content('contact'),
        repo.categories(),
        repo.banners(),
        repo.services(),
      ]);
      emit(
        AdminContentState(
          hero: results[0] as Map<String, dynamic>,
          about: results[1] as Map<String, dynamic>,
          socials: results[2] as Map<String, dynamic>,
          contact: results[3] as Map<String, dynamic>,
          categories: results[4] as List<Map<String, dynamic>>,
          banners: results[5] as List<Map<String, dynamic>>,
          services: results[6] as List<Map<String, dynamic>>,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: mapFailure(e).message));
    }
  }

  Future<void> saveContent(String key, Map<String, dynamic> value) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await repo.saveContent(key, value);
      final updated = Map<String, dynamic>.from(value);
      if (key == 'hero') emit(state.copyWith(hero: updated, saving: false));
      if (key == 'about') emit(state.copyWith(about: updated, saving: false));
      if (key == 'socials')
        emit(state.copyWith(socials: updated, saving: false));
      if (key == 'contact')
        emit(state.copyWith(contact: updated, saving: false));
    } catch (e) {
      emit(state.copyWith(saving: false, error: mapFailure(e).message));
      rethrow;
    }
  }

  Future<void> saveCategory({
    String? id,
    required String name,
    required String imageUrl,
    required int sortOrder,
    required bool isActive,
  }) async {
    await repo.upsertCategory(
      id: id,
      name: name,
      imageUrl: imageUrl,
      sortOrder: sortOrder,
      isActive: isActive,
    );
    await _refreshLists();
  }

  Future<void> saveBanner({
    String? id,
    required String imageUrl,
    required String title,
    required String buttonText,
    required String target,
    required int sortOrder,
    required bool isActive,
  }) async {
    await repo.upsertBanner(
      id: id,
      imageUrl: imageUrl,
      title: title,
      buttonText: buttonText,
      target: target,
      sortOrder: sortOrder,
      isActive: isActive,
    );
    await _refreshLists();
  }

  Future<void> saveService({
    String? id,
    required String title,
    required String subtitle,
    required String icon,
    required int sortOrder,
    required bool isActive,
  }) async {
    await repo.upsertService(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: icon,
      sortOrder: sortOrder,
      isActive: isActive,
    );
    await _refreshLists();
  }

  Future<void> deleteCategory(String id) async {
    await repo.deleteCategory(id);
    await _refreshLists();
  }

  Future<void> deleteBanner(String id) async {
    await repo.deleteBanner(id);
    await _refreshLists();
  }

  Future<void> deleteService(String id) async {
    await repo.deleteService(id);
    await _refreshLists();
  }

  Future<void> _refreshLists() async {
    emit(state.copyWith(saving: true));
    try {
      final results = await Future.wait([
        repo.categories(),
        repo.banners(),
        repo.services(),
      ]);
      emit(
        state.copyWith(
          categories: results[0],
          banners: results[1],
          services: results[2],
          saving: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(saving: false, error: mapFailure(e).message));
      rethrow;
    }
  }
}
