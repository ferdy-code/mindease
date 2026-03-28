class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'http://10.20.30.6:4000';
  static const String tokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String userKey = 'user_data';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
