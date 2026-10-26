import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/data/store.dart';
import 'package:tripavela/planning/planner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalog = PlanningCatalog(
    Map<String, dynamic>.from(
      jsonDecode(File('assets/data/planning.json').readAsStringSync()),
    ),
  );
  final engine = TripPlanner(catalog);
  test(
    '4-day plans respect all hotel areas, vibes, pace, weekdays, tickets, arrival and return',
    () {
      for (final zone in catalog.zones) {
        for (final vibe in ['classic', 'art', 'food', 'sea']) {
          for (final pace in ['calm', 'balanced', 'active']) {
            for (var weekday = 0; weekday < 7; weekday++) {
              for (final tickets in [true, false]) {
                final brief = TripBrief(
                  date: DateTime(2026, 11, 2 + weekday),
                  zone: zone['id'],
                  vibe: vibe,
                  pace: pace,
                  tickets: tickets,
                  arrivalAt: 'IST',
                );
                final plan = engine.generate(brief, id: 'check');
                expect(plan.days.length, 4);
                final ids = <String>{};
                expect(plan.days.first.stops, isNotEmpty);
                for (final day in plan.days) {
                  expect(
                    day.walkMeters,
                    lessThanOrEqualTo(pace == 'calm' ? 4500 : 8500),
                  );
                  expect(
                    day.stops.where((s) => s.poi.paid).length,
                    lessThanOrEqualTo(1),
                  );
                  var previous = day.availableFrom;
                  for (final stop in day.stops) {
                    expect(
                      ids.add(stop.poi.id),
                      isTrue,
                      reason: '${zone['id']} $vibe ${stop.poi.id}',
                    );
                    expect(
                      stop.start,
                      greaterThanOrEqualTo(previous + stop.travel),
                    );
                    expect(stop.end, lessThanOrEqualTo(stop.poi.closes));
                    expect(stop.start, greaterThanOrEqualTo(stop.poi.opens));
                    expect(stop.poi.openOn(day.date), isTrue);
                    if (!tickets) expect(stop.poi.paid, isFalse);
                    if (day.index == 0 || day.index == 3) {
                      expect(stop.poi.zone, brief.zone);
                    }
                    previous = stop.end;
                  }
                  if (day.stops.isNotEmpty) {
                    expect(day.returnAt, lessThanOrEqualTo(day.availableUntil));
                  }
                }
                expect(
                  plan.days.first.stops.first.start,
                  greaterThanOrEqualTo(17 * 60),
                );
                expect(
                  plan.days.last.returnAt,
                  lessThanOrEqualTo(brief.departure - 30),
                );
              }
            }
          }
        }
      }
    },
  );
  test(
    'Vibe changes the main day, early departures and late arrivals stay realistic',
    () {
      final classic = engine.generate(
        TripBrief(date: DateTime(2026, 11, 2)),
        id: 'classic',
      );
      final food = engine.generate(
        TripBrief(date: DateTime(2026, 11, 2), vibe: 'food'),
        id: 'food',
      );
      expect(classic.days[1].stops.first.poi.zone, 'old');
      // The classic day already crosses to Galata; the next day opens the Bosphorus.
      expect(classic.days[2].stops.first.poi.zone, 'shore');
      expect(food.days[1].stops.first.poi.zone, 'asia');
      final short = engine.generate(
        TripBrief(
          date: DateTime(2026, 11, 2),
          arrivalAt: 'SAW',
          arrival: 23 * 60,
          departure: 7 * 60,
        ),
        id: 'late',
      );
      expect(short.days.first.stops, isEmpty);
      expect(short.days.last.stops, isEmpty);
      for (final days in [2, 3, 5, 6, 7]) {
        final p = engine.generate(
          TripBrief(date: DateTime(2026, 12, 30), days: days),
          id: '$days',
        );
        expect(p.days.length, days);
        expect(p.days.last.date, DateTime(2026, 12, 30 + days - 1));
        expect(
          TravelPlan.fromJson(jsonDecode(jsonEncode(p.toJson()))).toJson(),
          p.toJson(),
        );
      }
    },
  );
  test(
    'Plans persist independently from blind walks and reset with all local data',
    () async {
      SharedPreferences.setMockInitialValues({});
      final db = await databaseFactoryMemory.openDatabase('travel-plans');
      final store = TravelStore();
      await store.init(database: db);
      final walk = await store.start('r0');
      await store.arrive(walk);
      final plan = engine.generate(
        TripBrief(date: DateTime(2026, 11, 2), hotel: 'Мой отель'),
        id: 'saved-plan',
      );
      await store.saveTravelPlan(plan);
      await store.startPlannedDay(plan.id, 0);
      await store.markPlannedStop(plan.id, 0, 0, true);
      final reload = TravelStore();
      await reload.init(database: db);
      expect(reload.travelPlan(plan.id)!.days.first.started, isTrue);
      expect(reload.travelPlan(plan.id)!.days.first.visited, 1);
      expect(reload.travelPlan(plan.id)!.brief.hotel, 'Мой отель');
      expect(reload.active!['id'], walk);
      expect(reload.visits.length, 1);
      await reload.markPlannedStop(plan.id, 0, 0, false);
      expect(reload.travelPlan(plan.id)!.days.first.visited, 0);
      await reload.clearData('all');
      expect(reload.travelPlans, isEmpty);
      await db.close();
      store.dispose();
      reload.dispose();
    },
  );
}
