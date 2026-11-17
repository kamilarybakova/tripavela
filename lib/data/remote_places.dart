import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sembast/sembast.dart';

import 'api_config.dart';

typedef RemotePlace = ({
  int id,
  String name,
  String description,
  String coverUrl,
  double? latitude,
  double? longitude,
});

class RemotePlaces {
  RemotePlaces(this.database);

  final Database database;
  static final _cache = stringMapStoreFactory
      .store('catalog')
      .record('fastapi_places:${tripavelaApiBase.origin}');
  static const _pageSize = 100;

  Future<List<RemotePlace>?> readCache() async {
    final saved = await _cache.get(database);
    return saved == null ? null : _decode(saved['places']);
  }

  Future<List<RemotePlace>> refresh() async {
    final client = http.Client();
    final rows = <dynamic>[];
    final places = <RemotePlace>[];
    try {
      int? afterId;
      while (true) {
        final uri = tripavelaApiBase
            .resolve('/api/v1/places')
            .replace(
              queryParameters: {
                'limit': '$_pageSize',
                if (afterId != null) 'after_id': '$afterId',
              },
            );
        final response = await client
            .get(uri)
            .timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) {
          throw StateError('Places API returned HTTP ${response.statusCode}');
        }
        final page = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        final decoded = _decode(page);
        for (final place in decoded) {
          if (place.id <= (afterId ?? 0)) {
            throw const FormatException('Place IDs must increase across pages');
          }
          afterId = place.id;
        }
        places.addAll(decoded);
        rows.addAll(page);
        if (page.length < _pageSize) break;
      }
      await _cache.put(database, {'places': rows});
      return places;
    } finally {
      client.close();
    }
  }

  static List<RemotePlace> _decode(Object? rows) => [
    for (final row in rows as List)
      (
        id: row['id'] as int,
        name: row['name'] as String,
        description: row['description'] as String,
        coverUrl: row['cover_url'] as String? ?? '',
        latitude: (row['latitude'] as num?)?.toDouble(),
        longitude: (row['longitude'] as num?)?.toDouble(),
      ),
  ];
}
