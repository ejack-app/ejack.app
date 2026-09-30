import 'dart:async';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

/// Dio client with JWT auth + automatic access-token refresh.
///
/// Matches Django REST Framework + djangorestframework-simplejwt out of the box.
class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));

    _dio.interceptors.add(_AuthInterceptor(_dio));
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: false,
      requestBody: true,
      responseBody: true,
      error: true,
      compact: true,
    ));
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);
  final Dio _dio;
  final _storage = SecureStorage.instance;
  bool _refreshing = false;
  final _waiters = <Completer<void>>[];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final noAuth = options.path.contains(ApiConstants.tokenObtain) ||
        options.path.contains(ApiConstants.tokenRefresh);
    if (!noAuth) {
      final token = await _storage.getAccess();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    final isRefreshCall = path.contains(ApiConstants.tokenRefresh);

    if (status == 401 && !isRefreshCall) {
      final ok = await _refreshOnce();
      if (ok) {
        try {
          final retry = await _retry(err.requestOptions);
          return handler.resolve(retry);
        } catch (_) {}
      } else {
        await _storage.clear();
      }
    }
    handler.next(err);
  }

  Future<bool> _refreshOnce() async {
    if (_refreshing) {
      final c = Completer<void>();
      _waiters.add(c);
      await c.future;
      final t = await _storage.getAccess();
      return t != null && t.isNotEmpty;
    }
    _refreshing = true;
    try {
      final refresh = await _storage.getRefresh();
      if (refresh == null || refresh.isEmpty) return false;
      final r = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)).post(
        ApiConstants.tokenRefresh,
        data: {'refresh': refresh},
      );
      final access = r.data['access'] as String?;
      final newRefresh = r.data['refresh'] as String? ?? refresh;
      if (access == null) return false;
      await _storage.saveTokens(access: access, refresh: newRefresh);
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
      for (final c in _waiters) {
        if (!c.isCompleted) c.complete();
      }
      _waiters.clear();
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions r) {
    final opts = Options(method: r.method, headers: r.headers);
    return _dio.request<dynamic>(
      r.path,
      data: r.data,
      queryParameters: r.queryParameters,
      options: opts,
    );
  }
}
