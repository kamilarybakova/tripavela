import 'dart:convert';
import 'dart:io';
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
  int requests = 0;
  @override
  Future<void> ensureReady({required bool requestPermission}) async {
    requests++;
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

class OfflineExamples implements NavigationExamples {
  @override
  Future<FootRoute?> load(String id) async => FootRoute.fromJson(
    Map<String, dynamic>.from(
      (jsonDecode(
            File('assets/data/navigation_example.json').readAsStringSync(),
          )
          as Map)['route'],
    ),
  );
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
      expect(
        layer.tileProvider.headers['User-Agent'],
        contains('Tripavela'),
      );
      // Exercise the mutation performed by TileLayer on iOS and Android.
      provider.headers.putIfAbsent('X-Native-Regression', () => 'allowed');
      expect(provider.headers['X-Native-Regression'], 'allowed');
      provider.dispose();
    },
  );
  for (final preview in [false, true]) {
    testWidgets(
      preview
          ? 'Offline map example draws a real walking shape and updates remaining distance without GPS'
          : 'Active map shows only current and visited places; changing stop moves the camera',
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
            database: await databaseFactoryMemory.openDatabase('map-$preview'),
          );
          id = await store.start('r0');
        });
        final location = NoDeviceLocation();
        WalkNavigationController? engine;
        final environment = NavigationEnvironment(
          networkTiles: false,
          factory: (tripId, destinationId, destination, db) =>
              engine = WalkNavigationController(
                destinationId: destinationId,
                destination: destination,
                location: location,
                routing: NoNetworkRouting(),
                cache: MemoryNavigationCache(),
                examples: OfflineExamples(),
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
            child: MaterialApp.router(
              theme: travelTheme(),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
          1,
        );
        if (!preview) {
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
          expect(location.requests, 0);
        } else {
          await engine!.showDemo();
          await tester.pumpAndSettle();
          expect(find.byType(PolylineLayer), findsOneWidget);
          expect(location.requests, 0);
          final before = engine!.remainingMeters!;
          engine!.toggleDemoWalk();
          await tester.pump(const Duration(seconds: 1));
          await tester.pump();
          expect(engine!.remainingMeters!, lessThan(before));
          engine!.toggleDemoWalk();
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        await store.db!.close();
      },
    );
  }
}
