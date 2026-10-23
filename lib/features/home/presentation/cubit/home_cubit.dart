import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_failure.dart';
import '../../domain/entities/home_entity.dart';
import '../../domain/usecases/get_home_content.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => const [];
}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeLoaded extends HomeState {
  const HomeLoaded(this.data);

  final HomeContent data;

  @override
  List<Object?> get props => [data];
}

final class HomeFailure extends HomeState {
  const HomeFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this.getHomeContent) : super(HomeInitial());

  final GetHomeContent getHomeContent;

  Future<void> load({bool forceRefresh = false}) async {
    if (state is! HomeLoaded) {
      emit(HomeLoading());
    }

    try {
      final data = await getHomeContent(forceRefresh: forceRefresh);
      emit(HomeLoaded(data));
    } catch (error) {
      final failure = mapFailure(error);
      emit(HomeFailure(failure.message));
    }
  }
}
