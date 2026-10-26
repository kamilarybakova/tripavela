import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/data/store.dart';
import 'package:tripavela/planning/planner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Five cities have 15 complete walks; switching preserves saved trips and archived walks',
    () async {
      SharedPreferences.setMockInitialValues({});
      final db = await databaseFactoryMemory.openDatabase('five-cities');
      final store = TravelStore();
      await store.init(database: db);
      expect(store.ready, true);
      expect(store.cities.length, 5);
      final walk = await store.start('r5'); // historical route stays usable
      await store.arrive(walk);
      final plan = TripPlanner(
        store.planningCatalog,
      ).generate(TripBrief(date: DateTime(2026, 11, 2)), id: 'saved-istanbul');
      await store.saveTravelPlan(plan);
      for (final city in store.cities.keys) {
        await store.selectCity(city);
        expect(store.routes.length, 15);
        expect(store.routes.every((r) => r.data['cityId'] == city), true);
        for (final r in store.routes) {
          final ids = [...r.places, ...r.branches, r.alternative];
          expect(ids.toSet().length, 6);
          expect(ids.every(store.places.containsKey), true);
          expect(ids.map((id) => store.places[id]!.image).toSet().length, 6);
          for (final id in ids) {
            final p = store.places[id]!;
            expect(File(p.image).existsSync(), true, reason: id);
            expect(p.sources, isNotEmpty);
            expect(p.mission, isNotEmpty);
          }
        }
        expect(store.active!['id'], walk);
        expect(store.travelPlan(plan.id)!.brief.cityId, 'istanbul');
        expect(store.route('r5').name, isNotEmpty);
      }
      final reload = TravelStore();
      await reload.init(database: db);
      expect(reload.cityId, 'nhatrang');
      expect(reload.session(walk)['stops'][0]['result'], 'visited');
      expect(reload.planningFor('baku').zones.length, 5);
      expect(reload.formatMoney(2500, forCity: 'baku'), '25 ₼');
      expect(reload.formatMoney(2500, forCity: 'tbilisi'), '25 ₾');
      await db.close();
      store.dispose();
      reload.dispose();
    },
  );

  test(
    'Multi-day plans stay in their city and respect shopping, opening windows and hotel return',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = TravelStore();
      await store.init(
        database: await databaseFactoryMemory.openDatabase('planning-cities'),
      );
      for (final city in store.cities.keys) {
        final c = store.planningFor(city);
        for (final zone in c.zones) {
          for (final shopping in [false, true]) {
            for (final duration in [2, 4, 7]) {
              final b = TripBrief(
                cityId: city,
                zone: zone['id'],
                date: DateTime(2026, 11, 2),
                days: duration,
                interests: ['История', 'Еда', if (shopping) 'Шопинг'],
              );
              final plan = TripPlanner(c).generate(b, id: '$city-$duration');
              expect(plan.days.length, duration);
              final used = <String>{};
              for (final day in plan.days) {
                for (final s in day.stops) {
                  expect(c.pois.containsKey(s.poi.id), true);
                  expect(used.add(s.poi.id), true);
                  expect(s.start, greaterThanOrEqualTo(s.poi.opens));
                  expect(s.end, lessThanOrEqualTo(s.poi.closes));
                  if (!shopping) expect(s.poi.kind, isNot('Шопинг'));
                  if (day.index == 0 || day.index == duration - 1) {
                    expect(s.poi.zone, b.zone);
                  }
                }
                if (day.stops.isNotEmpty) {
                  expect(day.returnAt, lessThanOrEqualTo(day.availableUntil));
                }
              }
              if (duration >= 4 && shopping) {
                expect(
                  plan.days
                      .expand((d) => d.stops)
                      .any((s) => s.poi.kind == 'Шопинг'),
                  true,
                  reason: '$city ${zone['id']}',
                );
              }
              if (duration == 4 && city != 'istanbul') {
                expect(plan.days[1].stops, isNotEmpty);
                expect(plan.days[2].stops, isNotEmpty);
                expect(
                  plan.days[1].stops.first.poi.zone,
                  isNot(plan.days[2].stops.first.poi.zone),
                );
              }
              expect(TravelPlan.fromJson(plan.toJson()).brief.cityId, city);
            }
          }
        }
      }
      await store.db!.close();
      store.dispose();
    },
  );
}
