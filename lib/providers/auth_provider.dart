import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/client.dart';

/// Holds the API base URL + Bearer token. Persisted in platform secure storage.
class AuthState {
  final String? baseUrl;
  final String? token;

  const AuthState({this.baseUrl, this.token});

  bool get isAuthenticated =>
      baseUrl != null && baseUrl!.isNotEmpty && token != null && token!.isNotEmpty;

  AuthState copyWith({String? baseUrl, String? token}) =>
      AuthState(baseUrl: baseUrl ?? this.baseUrl, token: token ?? this.token);
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const _kBaseUrl = 'watchlog_base_url';
  static const _kToken = 'watchlog_token';

  final FlutterSecureStorage _storage;

  AuthNotifier(this._storage) : super(const AuthState());

  Future<void> load() async {
    final url = await _storage.read(key: _kBaseUrl);
    final token = await _storage.read(key: _kToken);
    state = AuthState(baseUrl: url, token: token);
  }

  Future<void> signIn(String baseUrl, String token) async {
    final cleaned = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    await _storage.write(key: _kBaseUrl, value: cleaned);
    await _storage.write(key: _kToken, value: token);
    state = AuthState(baseUrl: cleaned, token: token);
  }

  Future<void> signOut() async {
    await _storage.delete(key: _kBaseUrl);
    await _storage.delete(key: _kToken);
    state = const AuthState();
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  ),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(secureStorageProvider));
});

final apiProvider = Provider<WatchlogApi?>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return null;
  return WatchlogApi(baseUrl: auth.baseUrl!, token: auth.token!);
});
