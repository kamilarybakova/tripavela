import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/core/theme.dart';
import 'package:tripavela/data/store.dart';
import 'package:tripavela/ui/screens.dart';

void main() {
  for (final budget in [0, 1000000]) {
    testWidgets(
      'Food idea reveals a free alternative and preserves the visit at budget $budget',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final store = TravelStore();
        late String id;
        await tester.runAsync(() async {
          await store.init(
            database: await databaseFactoryMemory.openDatabase('idea-$budget'),
          );
          await store.setDraft({...store.draft, 'budget': budget});
          id = await store.start('r0');
          await store.arrive(id);
        });
        final router = GoRouter(
          initialLocation: '/idea',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('Готово')),
            ),
            GoRoute(
              path: '/idea',
              builder: (_, _) => TravelScreen(code: 's15', id: id, extra: '0'),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [storeProvider.overrideWith((ref) => store)],
            child: MaterialApp.router(
              theme: travelTheme(),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final free = store.places['p00']!.missionFreeAlternative;
        expect(find.text('Попробуйте туршу'), findsOneWidget);
        expect(find.text(free), budget == 0 ? findsOneWidget : findsNothing);
        if (budget != 0) {
          await tester.tap(find.text('Без покупки'));
          await tester.pumpAndSettle();
          expect(find.text(free), findsOneWidget);
        }
        expect(find.byType(TextFormField), findsNothing);
        expect(store.session(id)['stops'][0]['mission'], 'available');
        expect(store.visits.single['note'], '');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        await store.db!.close();
      },
    );
  }
}
