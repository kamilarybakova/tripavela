import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/core/theme.dart';
import 'package:tripavela/data/store.dart';
import 'package:tripavela/navigation/navigation_environment.dart';
import 'package:tripavela/planning/planning_screens.dart';

void main() {
  for (final size in [
    (390.0, 1.0, 'istanbul'),
    (320.0, 1.8, 'istanbul'),
    (390.0, 1.0, 'dubai'),
    (320.0, 1.8, 'dubai'),
  ]) {
    testWidgets(
      'Plan wizard, all days and saved progress at width ${size.$1} / text scale ${size.$2} / ${size.$3}',
      (tester) async {
        tester.view.physicalSize = Size(size.$1, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final store = TravelStore();
        await tester.runAsync(() async {
          await store.init(
            database: await databaseFactoryMemory.openDatabase(
              'planner-ui-${size.$1}-${size.$3}',
            ),
          );
        });
        await tester.runAsync(() => store.selectCity(size.$3));
        final router = GoRouter(
          initialLocation: '/trips',
          routes: [
            GoRoute(
              path: '/trips',
              builder: (_, _) => const PlannedTripsScreen(),
            ),
            GoRoute(
              path: '/plan-trip',
              builder: (_, _) => const TripSetupScreen(),
            ),
            GoRoute(
              path: '/trip-plan/:id',
              builder: (_, s) => TripPlanScreen(id: s.pathParameters['id']!),
            ),
            GoRoute(
              path: '/trip-day/:id/:day',
              builder: (_, s) => TripDayScreen(
                id: s.pathParameters['id']!,
                dayIndex: int.parse(s.pathParameters['day']!),
              ),
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
            child: MaterialApp.router(
              locale: const Locale('ru'),
              supportedLocales: const [Locale('ru')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: travelTheme(),
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(size.$2)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<void> tap(String text) async {
          final f = find.text(text).last;
          await tester.ensureVisible(f);
          await tester.pumpAndSettle();
          await tester.tap(f);
          await tester.pumpAndSettle();
        }

        await tap('Спланировать поездку');
        await tap('Есть и жить как местный');
        await tap('Дальше');
        await tester.enterText(find.byType(TextField), 'Мой отель в Сиркеджи');
        await tap('Дальше');
        await tap(size.$3 == 'istanbul' ? 'Прилёт в IST' : 'Прилёт в DXB');
        await tap('Собрать мой план');
        expect(store.travelPlans.length, 1);
        final plan = store.travelPlans.single;
        expect(plan.brief.vibe, 'food');
        expect(plan.brief.hotel, 'Мой отель в Сиркеджи');
        expect(
          plan.days.first.stops.first.start,
          greaterThanOrEqualTo(17 * 60),
        );
        for (var day = 0; day < 4; day++) {
          router.push('/trip-day/${plan.id}/$day');
          await tester.pumpAndSettle();
          expect(find.text(plan.days[day].title), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (day == 0) {
            await tap('Начать этот день');
            expect(store.travelPlan(plan.id)!.days.first.started, isTrue);
            await tap('Отметить посещение');
            expect(store.travelPlan(plan.id)!.days.first.visited, 1);
          }
          router.pop();
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        await store.db!.close();
      },
    );
  }
}
