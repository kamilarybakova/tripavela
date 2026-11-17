import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

typedef AccountProfile = ({String id, String email, String name});
typedef AccountSession = ({
  AccountProfile profile,
  String token,
  DateTime expires,
});

class AccountApiError implements Exception {
  const AccountApiError(this.message, [this.status]);
  final String message;
  final int? status;
}

class AccountApi {
  static const _storage = FlutterSecureStorage();
  String get _key => 'tripavela.account:${tripavelaApiBase.origin}';

  Future<AccountSession> authenticate(
    String email,
    String password, {
    String? name,
  }) async {
    final result = (await _request(
      'POST',
      name == null ? 'login' : 'register',
      body: {'email': email, 'password': password, 'name': ?name},
    ))!;
    return (
      profile: _profile(result['profile'] as Map<String, dynamic>),
      token: result['access_token'] as String,
      expires: DateTime.now().add(
        Duration(seconds: result['expires_in'] as int),
      ),
    );
  }

  Future<void> remember(AccountSession session) async {
    if (kIsWeb) return;
    await _storage.write(
      key: _key,
      value: jsonEncode({
        'token': session.token,
        'expires': session.expires.toIso8601String(),
        'profile': {
          'id': session.profile.id,
          'email': session.profile.email,
          'name': session.profile.name,
        },
      }),
    );
  }

  Future<AccountSession?> restore() async {
    if (kIsWeb) return null;
    final saved = await _storage.read(key: _key);
    if (saved == null) return null;
    final value = jsonDecode(saved) as Map<String, dynamic>;
    final token = value['token'] as String;
    final expires = DateTime.parse(value['expires'] as String);
    if (!expires.isAfter(DateTime.now())) {
      await forget();
      return null;
    }
    try {
      final result = (await _request('GET', 'me', token: token))!;
      final session = (
        profile: _profile(result),
        token: token,
        expires: expires,
      );
      if (value['profile'] == null) {
        try {
          await remember(session);
        } on Exception {
          // An already verified session is usable even if storage is unavailable.
        }
      }
      return session;
    } on AccountApiError catch (error) {
      if (error.status == 401) {
        await forget();
      } else if ((error.status == null || error.status! >= 500) &&
          value['profile'] is Map<String, dynamic>) {
        return (
          profile: _profile(value['profile']),
          token: token,
          expires: expires,
        );
      }
      return null;
    }
  }

  Future<AccountProfile> updateName(String token, String name) async =>
      _profile(
        (await _request('PATCH', 'me', token: token, body: {'name': name}))!,
      );

  Future<Map<String, dynamic>> loadTravelData(String token) async =>
      (await _request('GET', 'travel-data', token: token))!;

  Future<Map<String, dynamic>> saveTravelChanges(
    String token,
    Map<String, dynamic> changes,
  ) async =>
      (await _request('PATCH', 'travel-data', token: token, body: changes))!;

  Future<void> forget() async {
    if (!kIsWeb) await _storage.delete(key: _key);
  }

  Future<void> revoke(String token) async {
    await _request('POST', 'logout', token: token);
  }

  AccountProfile _profile(Map<String, dynamic> value) => (
    id: value['id'] as String,
    email: value['email'] as String,
    name: value['name'] as String,
  );

  Future<void> uploadAtlasPhoto(
    String token,
    String id,
    List<int> bytes,
  ) async {
    await _send(
      'PUT',
      'atlas/photos/$id',
      token: token,
      bytes: bytes,
      binary: true,
    );
  }

  Future<List<int>> downloadAtlasPhoto(String token, String id) async =>
      (await _send(
        'GET',
        'atlas/photos/$id',
        token: token,
        binary: true,
      )).bodyBytes;

  Future<Map<String, dynamic>?> _request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final response = await _send(method, path, token: token, body: body);
    if (response.statusCode == 204) return null;
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<http.Response> _send(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
    List<int>? bytes,
    bool binary = false,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request(
        method,
        tripavelaApiBase.resolve('/api/v1/account/$path'),
      )..followRedirects = false;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.bodyBytes = utf8.encode(jsonEncode(body));
      } else if (bytes != null) {
        request.headers['Content-Type'] = 'application/octet-stream';
        request.bodyBytes = bytes;
      }
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(Duration(seconds: binary ? 25 : 4));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      String? detail;
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map && data['detail'] is String) detail = data['detail'];
      } on FormatException {
        // An upstream proxy may send a non-JSON error response.
      }
      throw AccountApiError(
        detail ?? 'Не удалось выполнить запрос.',
        response.statusCode,
      );
    } on AccountApiError {
      rethrow;
    } on Exception {
      throw const AccountApiError('Не удалось связаться с сервером Tripavela.');
    } finally {
      client.close();
    }
  }
}
