import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:tripavela/data/api_config.dart';
import 'package:tripavela/data/remote_places.dart';

Map<String, Object?> place(int id) => {
  'id': id,
  'name': 'Место $id',
  'description': 'Описание',
  'cover_url': id == 1 ? 'http://127.0.0.1:8000/media/city.jpg' : null,
  'latitude': 41,
  'longitude': 29.1,
};

http.Response jsonResponse(Object data) => http.Response.bytes(
  utf8.encode(jsonEncode(data)),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  late Database database;
  late RemotePlaces catalog;

  setUp(() async {
    database = await databaseFactoryMemory.openDatabase('remote-places');
    catalog = RemotePlaces(database);
  });
  tearDown(() async {
    await database.close();
    await databaseFactoryMemory.deleteDatabase('remote-places');
  });

  test(
    'uses the local FastAPI URL, follows its cursor and caches results',
    () async {
      final requests = <Uri>[];
      final places = await http.runWithClient(
        catalog.refresh,
        () => MockClient((request) async {
          requests.add(request.url);
          expect(request.headers.containsKey('apikey'), isFalse);
          return jsonResponse(
            requests.length == 1
                ? List.generate(100, (index) => place(index + 1))
                : [place(101)],
          );
        }),
      );

      expect(requests.map((uri) => uri.toString()), [
        'http://127.0.0.1:8000/api/v1/places?limit=100',
        'http://127.0.0.1:8000/api/v1/places?limit=100&after_id=100',
      ]);
      expect(places.length, 101);
      expect(places.first.name, 'Место 1');
      expect(places.first.latitude, 41.0);
      expect(places.first.coverUrl, 'http://127.0.0.1:8000/media/city.jpg');
      expect(await catalog.readCache(), places);
    },
  );

  test('a failed later page preserves the last complete cache', () async {
    final original = await http.runWithClient(
      catalog.refresh,
      () => MockClient((_) async => jsonResponse([place(1)])),
    );
    await expectLater(
      http.runWithClient(
        catalog.refresh,
        () => MockClient((request) async {
          if (request.url.queryParameters.containsKey('after_id')) {
            return http.Response('', 503);
          }
          return jsonResponse(List.generate(100, (index) => place(index + 2)));
        }),
      ),
      throwsStateError,
    );
    expect(await catalog.readCache(), original);
  });

  test('allows local API covers and escapes media path segments', () {
    final image = tripavelaMediaUri('test photo.jpg');
    expect(image.toString(), 'http://127.0.0.1:8000/media/test%20photo.jpg');
    expect(isNetworkPhoto(image), isTrue);
    expect(isNetworkPhoto(Uri.parse('https://example.com/photo.jpg')), isTrue);
    expect(isNetworkPhoto(Uri.parse('http://example.com/photo.jpg')), isFalse);
  });
}
