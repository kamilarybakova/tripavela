import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/data/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'published API catalog replaces bundled lists and is available offline',
    () async {
      SharedPreferences.setMockInitialValues({});
      final catalog =
          jsonDecode(File('assets/data/catalog.json').readAsStringSync())
              as Map;
      final planning =
          jsonDecode(File('assets/data/planning.json').readAsStringSync())
              as Map;
      catalog['city']['name'] = 'Стамбул из API';
      final routes = (catalog['routes'] as List).cast<Map>();
      final route = routes.firstWhere((route) => route['id'] == 'r0');
      route['name'] = 'Прогулка из API';
      catalog['routes'] = [route];
      final db = await databaseFactoryMemory.openDatabase('public-catalog');
      final online = TravelStore(loadRemoteCatalog: true);
      final offline = TravelStore(loadRemoteCatalog: true);
      addTearDown(db.close);
      addTearDown(online.dispose);
      addTearDown(offline.dispose);

      await http.runWithClient(
        () => online.init(database: db),
        () => MockClient((request) async {
          final data = switch (request.url.path) {
            '/api/v1/cities' => [catalog['city']],
            '/api/v1/cities/istanbul/catalog' => catalog,
            '/api/v1/cities/istanbul/planning' => planning,
            _ => throw StateError('Unexpected URL: ${request.url}'),
          };
          return http.Response.bytes(utf8.encode(jsonEncode(data)), 200);
        }),
      );
      expect(online.availableCities.map((city) => city['name']), [
        'Стамбул из API',
      ]);
      expect(online.routes.map((route) => route.name), ['Прогулка из API']);
      expect(online.route('r1').data['archived'], isTrue);
      expect(online.planningCatalog.cityId, 'istanbul');

      await http.runWithClient(
        () => offline.init(database: db),
        () => MockClient((_) async => http.Response('', 503)),
      );
      expect(offline.routes.map((route) => route.name), ['Прогулка из API']);
    },
  );
}
