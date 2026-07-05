import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';

/// Exception levée pour toute erreur renvoyée par l'API (4xx/5xx).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Client HTTP central pour toute l'app.
///
/// - Ajoute automatiquement `Authorization: Bearer <access>` si connecté.
/// - Rafraîchit le token une fois en cas de 401, puis rejoue la requête.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final _tokens = TokenStorage.instance;

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final access = await _tokens.getAccessToken();
      if (access != null) headers['Authorization'] = 'Bearer $access';
    }
    return headers;
  }

  Future<http.Response> get(String url, {bool auth = true}) async {
    final res = await http.get(Uri.parse(url), headers: await _headers(auth: auth));
    return _retryOn401IfNeeded(res, () => get(url, auth: auth));
  }

  Future<http.Response> post(String url, {Map<String, dynamic>? body, bool auth = true}) async {
    final res = await http.post(
      Uri.parse(url),
      headers: await _headers(auth: auth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _retryOn401IfNeeded(res, () => post(url, body: body, auth: auth));
  }

  Future<http.Response> patch(String url, {Map<String, dynamic>? body, bool auth = true}) async {
    final res = await http.patch(
      Uri.parse(url),
      headers: await _headers(auth: auth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _retryOn401IfNeeded(res, () => patch(url, body: body, auth: auth));
  }

  Future<http.Response> delete(String url, {bool auth = true}) async {
    final res = await http.delete(Uri.parse(url), headers: await _headers(auth: auth));
    return _retryOn401IfNeeded(res, () => delete(url, auth: auth));
  }

  /// Si la requête échoue avec 401 (access token expiré), tente un refresh
  /// puis rejoue la requête une seule fois.
  Future<http.Response> _retryOn401IfNeeded(
    http.Response res,
    Future<http.Response> Function() retry,
  ) async {
    if (res.statusCode != 401) return res;

    final refreshed = await _tryRefreshToken();
    if (!refreshed) return res;

    return retry();
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = await _tokens.getRefreshToken();
    if (refresh == null) return false;

    final res = await http.post(
      Uri.parse(ApiConfig.tokenRefresh),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );

    if (res.statusCode != 200) {
      await _tokens.clear();
      return false;
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _tokens.saveAccessToken(data['access'] as String);
    return true;
  }

  /// Décode le corps JSON et lève [ApiException] si le statut n'est pas 2xx.
  dynamic decodeOrThrow(http.Response res) {
    final isSuccess = res.statusCode >= 200 && res.statusCode < 300;
    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;

    if (!isSuccess) {
      final message = decoded is Map ? decoded.toString() : (res.body.isEmpty ? 'Erreur ${res.statusCode}' : res.body);
      throw ApiException(res.statusCode, message);
    }
    return decoded;
  }
}
