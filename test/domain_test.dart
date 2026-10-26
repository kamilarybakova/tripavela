import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/data/store.dart';
import 'package:tripavela/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TravelStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = TravelStore();
    await store.init(
      database: await databaseFactoryMemory.openDatabase(
        'test_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    expect(store.ready, true);
  });
  tearDown(() async {
    await store.db?.close();
    store.dispose();
  });
  test('Catalog has fifteen Istanbul adventures and complete real places', () {
    expect(store.routes.length, 15);
    expect(store.places.length, 229);
    expect(
      store.routes
          .map((r) => r.data)
          .every((r) => (r['branches'] as List).length == 2),
      true,
    );
  });
  test(
    'Hard accessibility, budget, distance and time constraints filter routes',
    () {
      final f = defaultFilters();
      f['noStairs'] = true;
      final result = matchRoutes(store.routes, f);
      expect(result.isNotEmpty, true);
      expect(result.every((r) => r.stairs == 'no'), true);
      f['budget'] = 0;
      expect(
        matchRoutes(store.routes, f).every((r) => r.requiredMax == 0),
        true,
      );
      f['time'] = 60;
      expect(
        matchRoutes(store.routes, f).every((r) => r.duration(f) <= 60),
        true,
      );
      f['time'] = 360;
      f['distance'] = 2000;
      expect(
        matchRoutes(store.routes, f).every((r) => r.meters + 400 <= 2000),
        true,
      );
    },
  );
  test(
    'Unknown access and late schedules do not pass required restrictions',
    () {
      final f = defaultFilters()..['noStairs'] = true;
      expect(
        matchRoutes(store.routes, f).any((r) => r.stairs == 'unknown'),
        false,
      );
      expect(matchRoutes(store.routes, f, late: true), isEmpty);
    },
  );
  test(
    'Arrival is idempotent, mission optional, skip creates no visit',
    () async {
      final id = await store.start('r0');
      await store.arrive(id);
      await store.arrive(id);
      expect(store.visits.length, 1);
      expect(await store.advance(id), false);
      expect(store.session(id)['index'], 1);
      expect(await store.advance(id, skip: true), true);
      expect(store.visits.length, 1);
      expect(store.session(id)['stops'][1]['result'], 'skipped');
    },
  );
  test('Reveal changes visibility without creating visits', () async {
    final id = await store.start('r0');
    await store.reveal(id);
    expect(store.visits, isEmpty);
    expect(
      (store.session(id)['stops'] as List).every((s) => s['visible']),
      true,
    );
    expect(store.session(id)['stops'][1]['result'], 'waiting');
  });
  test('Branch commits one path and replacement preserves original', () async {
    final id = await store.start('r0');
    await store.arrive(id);
    await store.advance(id);
    await store.arrive(id);
    await store.advance(id);
    await store.branch(id, 1);
    final t = store.session(id);
    expect(t['stops'].length, 4);
    expect(t['branch'], 1);
    expect(t['stops'][2]['place'], store.route('r0').branches[1]);
    await store.branch(id, 0);
    expect(store.session(id)['branch'], 1);
    await store.replace(id, 'p05', 'Закрыто');
    expect(
      store.session(id)['stops'][2]['original'],
      store.route('r0').branches[1],
    );
    expect(store.visits.any((v) => v['place'] == 'p05'), false);
  });
  test('Paused session survives repository reload and can end early', () async {
    final id = await store.start('r0');
    await store.arrive(id);
    await store.pause(id);
    final loaded = TravelStore();
    await loaded.init(database: store.db);
    expect(loaded.active?['status'], 'paused');
    expect(loaded.active?['id'], id);
    await loaded.resume(id);
    await loaded.end(id);
    expect(loaded.session(id)['status'], 'endedEarly');
    expect(loaded.active, isNull);
    loaded.dispose();
  });
  test('Saved theme restores alongside a persisted session', () async {
    final id = await store.start('r0');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', 'light');
    final loaded = TravelStore();
    await loaded.init(database: store.db);
    expect(loaded.initError, isNull);
    expect(loaded.ready, true);
    expect(loaded.settings['theme'], 'light');
    expect(loaded.active?['id'], id);
    loaded.dispose();
  });
  test('Save error does not commit changes or duplicate visit', () async {
    final id = await store.start('r0');
    await store.change((s) => s['demo']['saveError'] = true, allowError: true);
    await expectLater(store.arrive(id), throwsStateError);
    expect(store.visits, isEmpty);
    expect(store.session(id)['stops'][0]['result'], 'current');
    await store.change((s) => s['demo']['saveError'] = false, allowError: true);
    await store.arrive(id);
    expect(store.visits.length, 1);
  });
  test(
    'Cannot start second active session; repeat creates separate visits',
    () async {
      final first = await store.start('r0');
      await expectLater(store.start('r1'), throwsStateError);
      await store.arrive(first);
      await store.end(first);
      final second = await store.start('r0');
      await store.arrive(second);
      expect(store.visits.length, 2);
      expect(store.visits.map((v) => v['place']).toSet().length, 1);
      expect(store.visits.map((v) => v['id']).toSet().length, 2);
    },
  );
  test(
    'Full walkthrough with mission, replacement, branch and restart',
    () async {
      final id = await store.start('r0');
      await store.arrive(id);
      await store.mission(id, 'done');
      await store.advance(id);
      await store.replace(id, 'p05', 'Закрыто');
      await store.arrive(id);
      await store.advance(id);
      await store.branch(id, 0);
      await store.arrive(id);
      await store.advance(id);
      await store.arrive(id);
      await store.advance(id);
      expect(store.session(id)['status'], 'completed');
      expect(store.visitedCount(store.session(id)), 4);
      final loaded = TravelStore();
      await loaded.init(database: store.db);
      expect(loaded.visits.length, 4);
      expect(loaded.session(id)['branch'], 0);
      loaded.dispose();
    },
  );
}
