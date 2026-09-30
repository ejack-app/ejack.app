import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

class AuthState {
  const AuthState({this.user, this.loading = false, this.error});
  final AppUser? user;
  final bool loading;
  final String? error;

  AuthState copyWith({AppUser? user, bool? loading, String? error, bool clearUser = false, bool clearError = false}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState());
  final AuthRepository _repo;

  Future<void> bootstrap() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final access = await SecureStorage.instance.getAccess();
      if (access == null || access.isEmpty) {
        state = state.copyWith(loading: false, clearUser: true);
        return;
      }
      final me = await _repo.fetchMe();
      state = state.copyWith(user: me, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, clearUser: true, error: e.toString());
    }
  }

  Future<void> login(String identifier, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final me = await _repo.login(identifier: identifier, password: password);
      state = state.copyWith(user: me, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: _prettyError(e));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  String _prettyError(Object e) {
    final s = e.toString();
    if (s.contains('401')) return 'اسم المستخدم أو كلمة المرور غير صحيحة';
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'تعذر الاتصال بالخادم. تحقق من الإنترنت.';
    }
    return 'حدث خطأ غير متوقع';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);
