import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio dio = _createDio();

  Dio _createDio() {
    final client = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    client.interceptors.add(_AuthInterceptor(client));
    return client;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final prefs = await SharedPreferences.getInstance();
          final newToken = prefs.getString(AppConstants.tokenKey);
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(opts);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppConstants.tokenKey);
        await prefs.remove(AppConstants.refreshTokenKey);
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
    if (refreshToken == null) return false;

    final response = await Dio().post(
      '${AppConstants.apiBaseUrl}/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      await prefs.setString(
        AppConstants.tokenKey,
        data['accessToken'] as String,
      );
      if (data['refreshToken'] != null) {
        await prefs.setString(
          AppConstants.refreshTokenKey,
          data['refreshToken'] as String,
        );
      }
      return true;
    }
    return false;
  }
}
