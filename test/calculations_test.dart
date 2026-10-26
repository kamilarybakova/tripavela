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
      final id = await store.start('r0');
      await store.arrive(id);
      await store.advance(id);
      await store.advance(id, skip: true);
      await store.branch(id, 1);
      expect(
        store.tripMetrics(store.session(id))['meters'],
        (store.transition(store.session(id), 'p00', 'p04')!['meters'] as int) +
            (store.transition(store.session(id), 'p04', 'p02')!['meters']
                as int),
      );
      final place = store.session(id)['stops'][2]['place'];
      expect(store.currentTransition(store.session(id)), isNotNull);
      await store.replace(id, 'p05', 'Закрыто');
      expect(
        store.tripMetrics(store.session(id))['meters'],
        (store.transition(store.session(id), 'p00', 'p05')!['meters'] as int) +
            (store.transition(store.session(id), 'p05', 'p02')!['meters']
                as int),
      );
      await store.arrive(id);
      expect(store.visits.any((v) => v['place'] == place), false);
      expect(
        store.visitedMeters(store.session(id)),
        store.transition(store.session(id), 'p00', 'p05')!['meters'],
      );
      await store.db!.close();
      store.dispose();
    },
  );
}
