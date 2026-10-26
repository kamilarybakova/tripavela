import 'package:tripavela/navigation/navigation_environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/core/theme.dart';
import 'package:tripavela/data/store.dart';
import 'package:tripavela/ui/screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final scenario in [
    (320.0, 1.0, false),
    (320.0, 1.8, false),
    (430.0, 1.0, false),
    (390.0, 1.0, true),
  ]) {
    final scale = scenario.$2;
    testWidgets(
      'All 28 screens render at 320 logical pixels / text scale $scale / width ${scenario.$1} / dark ${scenario.$3}',
      (tester) async {
        tester.view.physicalSize = Size(scenario.$1, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final store = TravelStore();
        await tester.runAsync(() async {
          await store.init(
            database: await databaseFactoryMemory.openDatabase(
              'ui_${scenario.$1}_${scenario.$2}_${scenario.$3}',
            ),
          );
        });
        String id = '';
        await tester.runAsync(() async {
          id = await store.start('r0');
          await store.arrive(id);
        });
        final screens = [
          's01',
          's02',
          's03',
          'home',
          's05',
          's06',
          's07',
          's08',
          'routes',
          's10',
          's11',
          's12',
          's13',
          's14',
          's15',
          's16',
          's17',
          's18',
          's19',
          'atlas',
          's21',
          's22',
          's23',
          's24',
          'profile',
          's26',
          's27',
          's28',
        ];
        final container = ProviderContainer(
          overrides: [
            storeProvider.overrideWith((ref) => store),
            navigationEnvironmentProvider.overrideWithValue(
              const NavigationEnvironment(networkTiles: false),
            ),
          ],
        );
        for (final code in screens) {
          final routeId = ['s10', 's11'].contains(code)
              ? 'r0'
              : code == 's21'
              ? 'p00'
              : id;
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (c, s) => TravelScreen(code: code, id: routeId),
              ),
            ],
          );
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                theme: travelTheme(scenario.$3),
                locale: const Locale('ru'),
                supportedLocales: const [Locale('ru')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          final error = tester.takeException();
          expect(error, isNull, reason: '$code at scale $scale');
          await tester.pumpWidget(const SizedBox());
          router.dispose();
        }
        await store.db!.close();
        container.dispose();
      },
    );
  }
  testWidgets('Preview omits hidden place names and addresses', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = TravelStore();
    await tester.runAsync(() async {
      await store.init(
        database: await databaseFactoryMemory.openDatabase('privacy'),
      );
    });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (c, s) => TravelScreen(code: 's10', id: 'r0'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWith((ref) => store),
          navigationEnvironmentProvider.overrideWithValue(
            const NavigationEnvironment(networkTiles: false),
          ),
        ],
        child: MaterialApp.router(theme: travelTheme(), routerConfig: router),
      ),
    );
    await tester.pump();
    for (final p in store.places.values) {
      expect(find.text(p.name), findsNothing);
      expect(find.text(p.address), findsNothing);
    }
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await store.db!.close();
  });
}
