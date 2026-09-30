/// Central place for API configuration.
///
/// Override at build time:
///   flutter build apk --dart-define=API_BASE_URL=https://ml.eijack.com/api
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ml.eijack.com/api',
  );

  // Django REST Framework + SimpleJWT default endpoints.
  // Adjust the paths after `baseUrl` if your project mounts them elsewhere.
  static const String tokenObtain = '/auth/token/';
  static const String tokenRefresh = '/auth/token/refresh/';
  static const String currentUser = '/auth/me/';
  static const String logout = '/auth/logout/';

  // Business endpoints (edit to match your project).
  static const String orders = '/orders/';
  static const String trips = '/trips/';
  static const String drivers = '/drivers/';
  static const String customers = '/customers/';
  static const String dashboard = '/dashboard/summary/';
}
