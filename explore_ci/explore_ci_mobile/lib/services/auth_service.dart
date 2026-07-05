import '../config/api_config.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _client = ApiClient.instance;
  final _tokens = TokenStorage.instance;

  /// POST /api/auth/register/
  Future<AppUser> register({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    final res = await _client.post(
      ApiConfig.register,
      auth: false,
      body: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      },
    );
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  /// POST /api/auth/login/ -> stocke access + refresh
  Future<void> login({required String email, required String password}) async {
    final res = await _client.post(
      ApiConfig.login,
      auth: false,
      body: {'email': email, 'password': password},
    );
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    await _tokens.saveTokens(access: data['access'] as String, refresh: data['refresh'] as String);
  }

  /// GET /api/auth/me/
  Future<AppUser> fetchCurrentUser() async {
    final res = await _client.get(ApiConfig.me);
    final data = _client.decodeOrThrow(res) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  Future<bool> isLoggedIn() => _tokens.hasSession();

  Future<void> logout() => _tokens.clear();
}
