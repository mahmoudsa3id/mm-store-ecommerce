import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/cart_repository.dart';
import '../domain/cart_item.dart';

class CartState {
  const CartState({this.items = const []});
  final List<CartItem> items;
  int get count => items.fold(0, (s, e) => s + e.quantity);
  double get subtotal => items.fold(0, (s, e) => s + e.total);
  CartState copyWith({List<CartItem>? items}) => CartState(items: items ?? this.items);
}

class CartCubit extends Cubit<CartState> {
  CartCubit(this.repository) : super(CartState(items: repository.read()));
  final CartRepository repository;

  Future<void> add(CartItem item) async {
    final list = [...state.items];
    final i = list.indexWhere((e) => e.productId == item.productId && e.size == item.size && e.color == item.color);
    if (i == -1) list.add(item); else list[i] = list[i].copyWith(quantity: list[i].quantity + item.quantity);
    emit(state.copyWith(items: list));
    await repository.save(list);
  }
  Future<void> increase(CartItem item) async => add(item.copyWith(quantity: 1));
  Future<void> decrease(CartItem item) async {
    final list = [...state.items];
    final i = list.indexWhere((e) => e.productId == item.productId && e.size == item.size && e.color == item.color);
    if (i == -1) return;
    if (list[i].quantity <= 1) list.removeAt(i); else list[i] = list[i].copyWith(quantity: list[i].quantity - 1);
    emit(state.copyWith(items: list));
    await repository.save(list);
  }
  Future<void> remove(CartItem item) async {
    final list = state.items.where((e) => !(e.productId == item.productId && e.size == item.size && e.color == item.color)).toList();
    emit(state.copyWith(items: list));
    await repository.save(list);
  }
  Future<void> clear() async { emit(const CartState()); await repository.save(const []); }
}
