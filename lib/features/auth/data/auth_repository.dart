import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/user.dart';

class AuthRepository {
  AuthRepository({ApiClient? client, SecureStorage? storage})
      : _dio = (client ?? ApiClient.instance).dio,
        _storage = storage ?? SecureStorage.instance;

  final Dio _dio;
  final SecureStorage _storage;

  /// SimpleJWT token/obtain view accepts { username, password }. If your
  /// project uses email login, mount rest_framework_simplejwt with the
  /// email-based serializer and this call keeps working.
  Future<AppUser> login({required String identifier, required String password}) async {
    final r = await _dio.post<Map<String, dynamic>>(
      ApiConstants.tokenObtain,
      data: {'username': identifier, 'password': password},
    );
    final access = r.data?['access'] as String?;
    final refresh = r.data?['refresh'] as String?;
    if (access == null || refresh == null) {
      throw Exception('Invalid token response');
    }
    await _storage.saveTokens(access: access, refresh: refresh);
    return fetchMe();
  }

  Future<AppUser> fetchMe() async {
    final r = await _dio.get<Map<String, dynamic>>(ApiConstants.currentUser);
    final data = r.data ?? const <String, dynamic>{};
    final user = AppUser.fromJson(data);
    await _storage.saveRole(user.role.name);
    return user;
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (_) {
      // Ignore server errors on logout — always clear the local session.
    }
    await _storage.clear();
  }
}
