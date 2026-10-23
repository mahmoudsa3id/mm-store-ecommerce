enum AppFlavor { customer, admin }

abstract final class AppFlavorConfig {
  static const flavor = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'customer',
  );

  static bool get isAdmin => flavor == 'admin';

  static String get appName => isAdmin ? 'MM Store Admin' : 'MM Store';
}
