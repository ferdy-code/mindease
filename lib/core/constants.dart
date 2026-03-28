class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'http://10.0.2.2:3000/api/v1';
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
