abstract final class AppRoutes {
  static const home = '/';
  static const catalog = '/catalog';

  static const categories = '/categories';
  static const categoryProducts = '/categories/:categoryId';
  static const search = '/search';
  static const productDetails = '/product/:productId';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orderSuccess = '/order-success';
  static const favorites = '/favorites';

  static const adminLogin = '/admin/login';
  static const admin = '/admin';
  static const adminOrders = '/admin/orders';
  static const adminProducts = '/admin/products';
  static const adminSettings = '/admin/settings';
  static const adminContent = '/admin/content';
}
