import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

Future<Map<String, dynamic>> downloadPublicCatalog() async {
  final client = http.Client();
  Future<Object?> get(String path, {bool optional = false}) async {
    final result = await client.get(tripavelaApiBase.resolve(path));
    if (optional && result.statusCode == 404) return null;
    if (result.statusCode != 200) {
      throw StateError('Catalog API returned HTTP ${result.statusCode}');
    }
    return jsonDecode(utf8.decode(result.bodyBytes));
  }

  Future<Map<String, dynamic>> download() async {
    final cities = (await get('/api/v1/cities')) as List;
    final catalogs = await Future.wait([
      for (final city in cities.cast<Map>())
        Future.wait([
          get(
            '/api/v1/cities/${Uri.encodeComponent(city['id'] as String)}/catalog',
          ),
          get(
            '/api/v1/cities/${Uri.encodeComponent(city['id'] as String)}/planning',
            optional: true,
          ),
        ]),
    ]);
    return {
      'catalogs': [
        for (final pair in catalogs) {'catalog': pair[0], 'planning': pair[1]},
      ],
    };
  }

  try {
    return await download().timeout(const Duration(seconds: 3));
  } finally {
    client.close();
  }
}
