import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/data/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Chosen branch and replacement change prepared metrics; skip uses prepared edge',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = TravelStore();
      await store.init(
        database: await databaseFactoryMemory.openDatabase('metrics'),
      );
      final r = store.route('r0');
      final id = await store.start('r0');
      await store.arrive(id);
      await store.advance(id);
      await store.advance(id, skip: true);
      await store.branch(id, 1);
      expect(
        store.tripMetrics(store.session(id))['meters'],
        (store.transition(store.session(id), r.places[0], r.branches[1])!['meters'] as int) +
            (store.transition(store.session(id), r.branches[1], r.places[2])!['meters']
                as int),
      );
      final place = store.session(id)['stops'][2]['place'];
      expect(store.currentTransition(store.session(id)), isNotNull);
      await store.replace(id, r.alternative, 'Закрыто');
      expect(
        store.tripMetrics(store.session(id))['meters'],
        (store.transition(store.session(id), r.places[0], r.alternative)!['meters'] as int) +
            (store.transition(store.session(id), r.alternative, r.places[2])!['meters']
                as int),
      );
      await store.arrive(id);
      expect(store.visits.any((v) => v['place'] == place), false);
      expect(
        store.visitedMeters(store.session(id)),
        store.transition(store.session(id), r.places[0], r.alternative)!['meters'],
      );
      await store.db!.close();
      store.dispose();
    },
  );
}
