import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stocke les tokens JWT (access + refresh) de façon sécurisée sur l'appareil.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final _storage = const FlutterSecureStorage();

  static const _accessKey = 'explore_ci_access_token';
  static const _refreshKey = 'explore_ci_refresh_token';

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> saveAccessToken(String access) async {
    await _storage.write(key: _accessKey, value: access);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
