import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/data/store.dart';
import 'package:tripavela/planning/planner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Stops, trip places and route covers use distinct real local JPEGs with source credits',
    () {
      final catalog =
          jsonDecode(File('assets/data/catalog.json').readAsStringSync())
              as Map;
      final planning =
          jsonDecode(File('assets/data/planning.json').readAsStringSync())
              as Map;
      final manifest =
          (jsonDecode(
                    File(
                      'assets/images/place-photo-credits.json',
                    ).readAsStringSync(),
                  )
                  as List)
              .cast<Map>();
      final entries = [
        ...catalog['places'],
        ...catalog['routes'],
        ...(planning['pois'] as List).where((p) => p['id'] != 'galataport'),
      ];
      expect(entries.length, 175);
      expect(entries.map((p) => p['image']).toSet().length, 175);
      expect(manifest.length, 175);
      expect(manifest.map((p) => p['sourceKey']).toSet().length, 175);
      final contents = <String>{};
      for (final entry in entries) {
        final asset = entry['image'] as String;
        final bytes = File(asset).readAsBytesSync();
        expect(bytes.length, greaterThan(3000), reason: asset);
        expect(bytes.take(2), [255, 216], reason: asset);
        expect(
          contents.add(base64Encode(bytes)),
          isTrue,
          reason: 'Repeated photo: $asset',
        );
        final credit = manifest.singleWhere((p) => p['asset'] == asset);
        expect(credit['author'], isNotEmpty);
        expect(credit['license'], isNotEmpty);
        expect(Uri.parse(credit['source']).host, 'commons.wikimedia.org');
      }
    },
  );
  test(
    'Refreshing saved plan photos preserves all itinerary and walking progress',
    () async {
      SharedPreferences.setMockInitialValues({});
      final db = await databaseFactoryMemory.openDatabase('photo-migration');
      final store = TravelStore();
      await store.init(database: db);
      final walk = await store.start('r0');
      await store.arrive(walk);
      final plan = TripPlanner(
        store.planningCatalog,
      ).generate(TripBrief(date: DateTime(2026, 11, 2)), id: 'photo-plan');
      await store.saveTravelPlan(plan);
      await store.markPlannedStop(plan.id, 0, 0, true);
      await store.change((s) {
        for (final day in (s['travelPlans'] as List).single['days']) {
          for (final stop in day['stops']) {
            stop['poi']['image'] = 'assets/images/city.jpg';
          }
        }
      });
      final reload = TravelStore();
      await reload.init(database: db);
      final refreshed = reload.travelPlan(plan.id)!;
      expect(refreshed.days.first.visited, 1);
      expect(
        refreshed.days.first.stops.first.start,
        plan.days.first.stops.first.start,
      );
      for (final day in refreshed.days) {
        for (final stop in day.stops) {
          expect(
            stop.poi.data['image'],
            reload.planningCatalog.pois[stop.poi.id]!.data['image'],
          );
        }
      }
      expect(reload.visits.length, 1);
      expect(reload.session(walk)['stops'][0]['result'], 'visited');
      await db.close();
      store.dispose();
      reload.dispose();
    },
  );
}
