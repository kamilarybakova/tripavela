import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sembast/sembast.dart';

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
      .record('supabase_places');
  static const _host = 'cvznqdmdqaijzwegyida.supabase.co';
  static const _publishableKey =
      'sb_publishable_pa4NioNxxVrYG3Ucdq8-Mw_5PI5J6TZ';

  Future<List<RemotePlace>?> readCache() async {
    final saved = await _cache.get(database);
    return saved == null ? null : _decode(saved['places']);
  }

  Future<List<RemotePlace>> refresh() async {
    final client = http.Client();
    final rows = <dynamic>[];
    final places = <RemotePlace>[];
    try {
      while (true) {
        final response = await client
            .get(
              Uri.https(_host, '/rest/v1/places', {
                'select': 'id,name,description,cover_url,latitude,longitude',
                'is_published': 'eq.true',
                'order': 'id.asc',
                'limit': '100',
                if (places.isNotEmpty) 'id': 'gt.${places.last.id}',
              }),
              headers: {'apikey': _publishableKey},
            )
            .timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) {
          throw StateError('Places API returned HTTP ${response.statusCode}');
        }
        final page = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        if (page.isEmpty) break;
        places.addAll(_decode(page));
        rows.addAll(page);
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
