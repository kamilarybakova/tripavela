import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/data/store.dart';
import 'package:tripavela/navigation/navigation_controller.dart';
import 'package:tripavela/navigation/navigation_model.dart';
import 'package:tripavela/navigation/navigation_services.dart';

FootRoute exampleRoute() => FootRoute.fromJson(
  Map<String, dynamic>.from(
    (jsonDecode(File('assets/data/navigation_example.json').readAsStringSync())
        as Map)['route'],
  ),
);

class FakeLocation implements NavigationLocationSource {
  final stream = StreamController<NavigationFix>.broadcast(sync: true);
  LocationIssue? failure;
  int checks = 0;
  @override
  Future<void> ensureReady({required bool requestPermission}) async {
    checks++;
    if (failure != null) throw LocationFailure(failure!);
  }

  @override
  Stream<NavigationFix> watch() => stream.stream;
  void emit(LatLng point, {double accuracy = 5, DateTime? at}) => stream.add(
    NavigationFix(point, accuracy: accuracy, timestamp: at ?? DateTime.now()),
  );
}

class FakeRouting implements FootRoutingService {
  final List<Completer<FootRoute>> pending = [];
  bool defer = false, closed = false;
  int calls = 0;
  @override
  Future<FootRoute> route(LatLng origin, LatLng destination) {
    calls++;
    if (defer) {
      final c = Completer<FootRoute>();
      pending.add(c);
      return c.future;
    }
    return Future.value(
      FootRoute(
        points: [origin, destination],
        meters: metersBetween(origin, destination),
        seconds: 120,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void close() {
    closed = true;
  }
}

class FakeExamples implements NavigationExamples {
  @override
  Future<FootRoute?> load(String destinationId) async =>
      destinationId == 'p00' ? exampleRoute() : null;
}

WalkNavigationController controller(
  FakeLocation location,
  FakeRouting routing, {
  NavigationCache? cache,
}) => WalkNavigationController(
  destinationId: 'p00',
  destination: exampleRoute().points.last,
  location: location,
  routing: routing,
  cache: cache ?? MemoryNavigationCache(),
  examples: FakeExamples(),
);
Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Walking client uses foot endpoint and preserves street geometry and ferry metadata',
    () async {
      final route = exampleRoute();
      final service = OsrmFootRoutingService(
        client: MockClient((request) async {
          expect(request.url.host, 'routing.openstreetmap.de');
          expect(request.url.path, contains('/routed-foot/route/v1/foot/'));
          expect(request.url.queryParameters['geometries'], 'geojson');
          return http.Response(
            jsonEncode({
              'code': 'Ok',
              'routes': [
                {
                  'distance': route.meters,
                  'duration': route.seconds,
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': route.points
                        .map((p) => [p.longitude, p.latitude])
                        .toList(),
                  },
                  'legs': [
                    {
                      'steps': [
                        {'mode': 'ferry'},
                      ],
                    },
                  ],
                },
              ],
            }),
            200,
          );
        }),
      );
      final result = await service.route(route.points.first, route.points.last);
      expect(result.points.length, greaterThan(2));
      expect(result.includesFerry, true);
      expect(FootRoute.fromJson(result.toJson()).includesFerry, true);
      service.close();
    },
  );
  test('NoRoute does not create a direct-line walking route', () async {
    final service = OsrmFootRoutingService(
      client: MockClient(
        (_) async => http.Response('{"code":"NoRoute","routes":[]}', 200),
      ),
    );
    await expectLater(
      service.route(exampleRoute().points.first, exampleRoute().points.last),
      throwsA(isA<RoutingFailure>()),
    );
    service.close();
  });
  test(
    'Remaining distance follows route geometry and detects an off-route location',
    () {
      final route = exampleRoute();
      final start = progressOnRoute(route.points.first, route),
          end = progressOnRoute(route.points.last, route);
      expect(start.remainingMeters, greaterThan(100));
      expect(end.remainingMeters, lessThan(2));
      expect(
        progressOnRoute(const LatLng(41.01, 29.05), route).offRouteMeters,
        greaterThan(500),
      );
    },
  );
  test(
    'GPS does not send coordinates to routing before explicit approval; suspending cancels GPS',
    () async {
      final gps = FakeLocation(), routing = FakeRouting();
      final nav = controller(gps, routing);
      await nav.startLocation();
      gps.emit(exampleRoute().points.first);
      await flush();
      expect(routing.calls, 0);
      expect(nav.tracking, true);
      nav.approveOnlineRouting();
      await flush();
      expect(routing.calls, 1);
      expect(nav.path, isNotNull);
      nav.setAvailable(false);
      await flush();
      expect(gps.stream.hasListener, false);
      expect(nav.tracking, false);
      nav.dispose();
      await gps.stream.close();
    },
  );
  test(
    'Destination change ignores stale route responses and clears previous geometry',
    () async {
      final gps = FakeLocation(), routing = FakeRouting()..defer = true;
      final memory = MemoryNavigationCache();
      final nav = controller(gps, routing, cache: memory);
      await nav.startLocation();
      gps.emit(exampleRoute().points.first);
      nav.approveOnlineRouting();
      final next = const LatLng(40.991, 29.027);
      nav.changeDestination('p01', next);
      expect(routing.pending.length, 2);
      routing.pending.first.complete(exampleRoute());
      await flush();
      expect(nav.path, isNull);
      final fresh = FootRoute(
        points: [exampleRoute().points.first, next],
        meters: 200,
        seconds: 150,
        createdAt: DateTime.now(),
      );
      routing.pending.last.complete(fresh);
      await flush();
      expect(nav.path, same(fresh));
      expect(memory.id, 'p01');
      nav.dispose();
      await gps.stream.close();
    },
  );
  test(
    'Poor accuracy, distant location and denied permission do not trigger a routing request',
    () async {
      final gps = FakeLocation(), routing = FakeRouting();
      final nav = controller(gps, routing);
      gps.failure = LocationIssue.deniedForever;
      await nav.startLocation();
      expect(nav.locationIssue, LocationIssue.deniedForever);
      gps.failure = null;
      await nav.startLocation();
      nav.onlineApproved = true;
      gps.emit(exampleRoute().points.first, accuracy: 500);
      await flush();
      expect(nav.routeIssue, RouteIssue.poorAccuracy);
      expect(routing.calls, 0);
      gps.emit(const LatLng(42.87, 74.6));
      await flush();
      expect(nav.routeIssue, RouteIssue.tooFar);
      expect(routing.calls, 0);
      nav.dispose();
      await gps.stream.close();
    },
  );
  test(
    'Demo never requests device location or writes a fictitious user route to cache',
    () async {
      final gps = FakeLocation(),
          routing = FakeRouting(),
          cache = MemoryNavigationCache();
      final nav = controller(gps, routing, cache: cache);
      await nav.showDemo();
      expect(nav.isDemo, true);
      expect(gps.checks, 0);
      expect(routing.calls, 0);
      expect(cache.value, isNull);
      expect(nav.remainingMeters, greaterThan(100));
      nav.dispose();
      await gps.stream.close();
    },
  );
  test(
    'Only the current destination cache restores; clear all removes cached routes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final db = await databaseFactoryMemory.openDatabase('nav-cache');
      final store = TravelStore();
      await store.init(database: db);
      final cache = SembastNavigationCache(db, 'trip');
      final destination = exampleRoute().points.last;
      await cache.save('p00', destination, exampleRoute());
      expect(await cache.load('p00', destination), isNotNull);
      expect(await cache.load('p01', destination), isNull);
      expect(
        await SembastNavigationCache(
          db,
          'another-trip',
        ).load('p00', destination),
        isNull,
      );
      await store.clearData('all');
      expect(await cache.load('p00', destination), isNull);
      store.dispose();
      await db.close();
    },
  );
}
