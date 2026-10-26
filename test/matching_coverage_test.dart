import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/data/store.dart';
import 'package:tripavela/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TravelStore store;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    store = TravelStore();
    await store.init(
      database: await databaseFactoryMemory.openDatabase('coverage'),
    );
  });
  tearDownAll(() async {
    await store.db!.close();
    store.dispose();
  });

  test(
    '2048 filter combinations return exact routes or valid explicit proposals',
    () {
      var count = 0;
      const moods = [
        'Удивиться',
        'Замедлиться',
        'Попробовать новое',
        'Почувствовать город',
        'Провести время вместе',
        'Довериться случаю',
      ];
      const diets = [
        'Без предпочтений',
        'Вегетарианское',
        'Веганское',
        'Без алкоголя',
      ];
      for (var flags = 0; flags < 32; flags++) {
        for (final time in [60, 120, 240, 360]) {
          for (final budget in [0, 40000, 80000, 1000000]) {
            for (final distance in [2000, 4000, 7000, 100000]) {
              final f = defaultFilters()
                ..addAll({
                  'time': time,
                  'budget': budget,
                  'distance': distance,
                  'noStairs': flags & 1 != 0,
                  'stroller': flags & 2 != 0,
                  'rest': flags & 4 != 0,
                  'indoors': flags & 8 != 0,
                  'pace': flags & 16 != 0 ? 'calm' : 'normal',
                  'mood': moods[count % moods.length],
                  'diet': diets[count % diets.length],
                  'company': count.isEven ? 'С детьми' : 'Один / одна',
                  'startHour': [0, 10, 12, 17, 22][count % 5],
                  'startDate': count.isEven ? '2026-10-26' : '2026-10-22',
                });
              final original = jsonEncode(f);
              final exact = matchRoutes(store.routes, f);
              if (exact.isEmpty) {
                final proposals = suggestRoutes(store.routes, f);
                expect(proposals, isNotEmpty, reason: 'No result for $f');
                for (final p in proposals) {
                  expect(p.route.matches(p.filters), true);
                  expect(p.changes, isNotEmpty);
                }
              } else {
                expect(exact.every((r) => r.matches(f)), true);
              }
              expect(
                jsonEncode(f),
                original,
                reason: 'Requested filters changed silently',
              );
              count++;
            }
          }
        }
      }
      expect(count, 2048);
    },
  );

  test('Indoor venues respect Monday closures and opening hour', () {
    final indoors = store.routes.where((r) => r.indoor).toList();
    expect(indoors.length, 2);
    final monday = defaultFilters()
      ..addAll({'indoors': true, 'startDate': '2026-10-26', 'startHour': 12});
    expect(matchRoutes(store.routes, monday), isEmpty);
    final proposed = suggestRoutes(store.routes, monday);
    expect(proposed.every((p) => p.filters['indoors'] == true), true);
    expect(proposed.every((p) => p.filters['startDate'] == '2026-10-27'), true);
    final early = defaultFilters()..addAll({'indoors': true, 'startHour': 10});
    expect(matchRoutes(store.routes, early), isEmpty);
    final daytime = defaultFilters()
      ..addAll({'indoors': true, 'startHour': 12});
    expect(matchRoutes(store.routes, daytime).length, 2);
  });

  test(
    'One-hour calm free walk has an exact outdoor match; late demo has a proposal',
    () {
      final f = defaultFilters()
        ..addAll({
          'time': 60,
          'budget': 0,
          'pace': 'calm',
          'distance': 2000,
          'noStairs': true,
        });
      expect(matchRoutes(store.routes, f), isNotEmpty);
      expect(matchRoutes(store.routes, f, late: true), isEmpty);
      expect(suggestRoutes(store.routes, f, late: true), isNotEmpty);
    },
  );
}
