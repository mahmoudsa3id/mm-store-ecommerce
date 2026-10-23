
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mm_store/features/cart/data/cart_local_data_source.dart';
import 'package:mm_store/features/cart/data/cart_repository.dart';
import 'package:mm_store/features/cart/domain/cart_item.dart';
import 'package:mm_store/features/cart/presentation/cart_cubit.dart';

void main() {
  test('CartCubit adds and totals items', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cubit = CartCubit(CartRepository(CartLocalDataSource(prefs)));
    await cubit.add(const CartItem(productId: '1', name: 'T', image: '', price: 100, quantity: 2));
    expect(cubit.state.count, 2);
    expect(cubit.state.subtotal, 200);
    await cubit.close();
  });
}
