import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/core/theme.dart';
import 'package:tripavela/data/store.dart';
import 'package:tripavela/navigation/navigation_controller.dart';
import 'package:tripavela/navigation/navigation_environment.dart';
import 'package:tripavela/navigation/navigation_model.dart';
import 'package:tripavela/navigation/navigation_services.dart';
import 'package:tripavela/ui/screens.dart';
import 'package:tripavela/navigation/walk_navigation_map.dart';

class NoDeviceLocation implements NavigationLocationSource {
  final requests = <bool>[];
  @override
  Future<void> ensureReady({required bool requestPermission}) async {
    requests.add(requestPermission);
    throw const LocationFailure(LocationIssue.denied);
  }

  @override
  Stream<NavigationFix> watch() => const Stream.empty();
}

class NoNetworkRouting implements FootRoutingService {
  @override
  Future<FootRoute> route(LatLng origin, LatLng destination) async =>
      throw const RoutingFailure(RouteIssue.network);
  @override
  void close() {}
}

void main() {
  test(
    'Native TileLayer accepts production headers without immutable-map failure',
    () {
      final provider = createNavigationTileProvider(
        cachingProvider: const DisabledMapCachingProvider(),
      );
      final layer = TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.travelRoulette',
        tileProvider: provider,
      );
      expect(layer.tileProvider.headers['User-Agent'], contains('Tripavela'));
      // Exercise the mutation performed by TileLayer on iOS and Android.
      provider.headers.putIfAbsent('X-Native-Regression', () => 'allowed');
      expect(provider.headers['X-Native-Regression'], 'allowed');
      provider.dispose();
    },
  );
  testWidgets(
    'Active map shows only current and visited places; changing stop moves the camera',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = TravelStore();
      String id = '';
      await tester.runAsync(() async {
        await store.init(
          database: await databaseFactoryMemory.openDatabase('active-map'),
        );
        id = await store.start('r0');
      });
      final location = NoDeviceLocation();
      final environment = NavigationEnvironment(
        networkTiles: false,
        factory: (tripId, destinationId, destination, db) =>
            WalkNavigationController(
              destinationId: destinationId,
              destination: destination,
              location: location,
              routing: NoNetworkRouting(),
              cache: MemoryNavigationCache(),
            ),
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (c, s) => TravelScreen(code: 's12', id: id),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWith((ref) => store),
            navigationEnvironmentProvider.overrideWithValue(environment),
          ],
          child: MaterialApp.router(theme: travelTheme(), routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
        1,
      );
      final address = store.places[store.route('r0').places.first]!.address;
      expect(find.text(address), findsNothing);
      final details = find.text('О месте');
      await tester.ensureVisible(details);
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(find.text(address), findsOneWidget);
      await tester.ensureVisible(details);
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(find.text(address), findsNothing);

      for (final hidden in store.route('r0').places.skip(1)) {
        expect(find.text(store.places[hidden]!.name), findsNothing);
      }
      await tester.runAsync(() async {
        await store.arrive(id);
        await store.advance(id);
      });
      await tester.pumpAndSettle();
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
        2,
      );
      final expected = store.places[store.route('r0').places[1]]!;
      final camera = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!
          .camera;
      expect(camera.center.latitude, closeTo(expected.data['lat'], .00001));
      expect(location.requests, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await store.db!.close();
    },
  );

  testWidgets(
    'Location explanation can only proceed to the permission request',
    (tester) async {
      final db = await databaseFactoryMemory.openDatabase(
        'location-explanation',
      );
      addTearDown(db.close);
      final location = NoDeviceLocation();
      final environment = NavigationEnvironment(
        networkTiles: false,
        factory: (tripId, destinationId, destination, db) =>
            WalkNavigationController(
              destinationId: destinationId,
              destination: destination,
              location: location,
              routing: NoNetworkRouting(),
              cache: MemoryNavigationCache(),
            ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WalkNavigationMap(
                tripId: 'trip',
                destinationId: 'stop',
                destinationName: 'Stop',
                destination: const LatLng(41, 29),
                visited: const [],
                db: db,
                environment: environment,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Путь от меня'));
      await tester.pumpAndSettle();

      final title = find.text('Путь от вашего местоположения');
      expect(title, findsOneWidget);
      expect(find.text('Отмена'), findsNothing);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(title, findsOneWidget);
      await tester.drag(title, const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(title, findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(title, findsOneWidget);
      expect(location.requests, isEmpty);

      await tester.tap(find.text('Продолжить'));
      await tester.pumpAndSettle();
      expect(title, findsNothing);
      expect(location.requests, [true]);
      expect(find.textContaining('продолжить по адресу'), findsWidgets);
      expect(find.byType(FlutterMap), findsOneWidget);
    },
  );
}
