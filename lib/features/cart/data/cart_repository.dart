import '../domain/cart_item.dart';
import 'cart_local_data_source.dart';

class CartRepository {
  CartRepository(this.local);
  final CartLocalDataSource local;
  List<CartItem> read() => local.read();
  Future<void> save(List<CartItem> items) => local.write(items);
}
