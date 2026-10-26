import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/data/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Istanbul content is complete, local and geographically coherent',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = TravelStore();
      await store.init(
        database: await databaseFactoryMemory.openDatabase('istanbul-content'),
      );
      expect(store.cityData['id'], 'istanbul');
      expect(store.cityData['currency'], 'TRY');
      expect(store.cityData['utcOffset'], 3);
      expect(store.routes.length, 15);
      expect(
        store.places.values.where((p) => p.data['cityId'] == 'istanbul').length,
        109,
      );
      final used = <String>{};
      for (final route in store.routes) {
        final ids = [...route.places, ...route.branches, route.alternative];
        expect(ids.toSet().length, 6);
        expect(route.requiredMax, 0);
        expect(File(route.image).existsSync(), true);
        for (final key in [
          'gettingThere',
          'practical',
          'budgetNote',
          'distanceNote',
        ]) {
          expect((route.data[key] as String).length, greaterThan(40));
        }
        for (final id in ids) {
          used.add(id);
          final place = store.places[id]!;
          // Short factual introductions replace repeated generated task paragraphs.
          expect(place.story.length, greaterThan(70));
          expect(place.address, contains('İstanbul'));
          expect(place.sources, isNotEmpty);
          expect(
            place.sources.every((url) => Uri.parse(url).scheme == 'https'),
            true,
          );
          expect(place.hours, isNotEmpty);
          expect(place.access, isNotEmpty);
          expect(place.cost, isNotEmpty);
          expect(place.mission, isNotEmpty);
          expect(File(place.image).existsSync(), true);
          expect(place.data['lat'] as double, inInclusiveRange(40.95, 41.2));
          expect(place.data['lon'] as double, inInclusiveRange(28.9, 29.1));
          for (final other in ids.where((x) => x != id)) {
            final edge =
                (route.data['transitions'] as Map)['$id|$other'] as Map;
            expect(edge['meters'] as int, inInclusiveRange(25, 4000));
            expect(edge['minutes'] as int, greaterThan(0));
          }
        }
      }
      expect(used.length, 90);
      await store.db!.close();
      store.dispose();
    },
  );

  test(
    'Both choices on every Istanbul route finish and persist real discoveries',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = TravelStore();
      await store.init(
        database: await databaseFactoryMemory.openDatabase('istanbul-journeys'),
      );
      for (final route in store.routes) {
        for (var choice = 0; choice < 2; choice++) {
          final id = await store.start(route.id);
          await store.arrive(id);
          await store.advance(id);
          await store.replace(id, route.alternative, 'Слишком многолюдно');
          await store.arrive(id);
          expect(await store.advance(id), true);
          await store.branch(id, choice);
          expect(
            store.session(id)['stops'][2]['place'],
            route.branches[choice],
          );
          await store.arrive(id);
          await store.advance(id);
          await store.arrive(id);
          await store.advance(id);
          expect(store.session(id)['status'], 'completed');
          expect(store.visitedCount(store.session(id)), 4);
        }
      }
      final restored = TravelStore();
      await restored.init(database: store.db);
      expect(restored.sessions.length, 30);
      expect(restored.visits.length, 120);
      expect(
        restored.visits.every((v) => restored.places.containsKey(v['place'])),
        true,
      );
      restored.dispose();
      await store.db!.close();
      store.dispose();
    },
  );
}
