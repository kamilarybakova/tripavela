import 'package:tripavela/navigation/navigation_environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/core/theme.dart';
import 'package:tripavela/data/store.dart';
import 'package:tripavela/l10n/app_localizations.dart';
import 'package:tripavela/ui/components.dart';
import 'package:tripavela/ui/screens.dart';

void main() {
  testWidgets('Near match shows changes and preserves filters until accepted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = TravelStore();
    await tester.runAsync(() async {
      await store.init(
        database: await databaseFactoryMemory.openDatabase('suggestion-ui'),
      );
      final f = store.draft
        ..addAll({'indoors': true, 'startHour': 12, 'startDate': '2026-10-26'});
      await store.setDraft(f);
    });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (c, s) => const TravelScreen(code: 's08'),
        ),
        GoRoute(
          path: '/s10',
          builder: (c, s) =>
              TravelScreen(code: 's10', id: s.uri.queryParameters['id']),
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
          theme: travelTheme(),
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Есть несколько близких вариантов'), findsOneWidget);
    Future<void> openProposal() async {
      final card = find.byType(WalkCard).first;
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();
    }

    await openProposal();
    expect(find.text('Дата старта: 2026-10-27'), findsWidgets);
    expect(store.draft['startDate'], '2026-10-26');
    await tester.tap(find.text('Отмена').last);
    await tester.pumpAndSettle();
    expect(store.draft['startDate'], '2026-10-26');
    await openProposal();
    final apply = find.text('Применить условия и посмотреть');
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(store.draft['startDate'], '2026-10-27');
    expect(store.draft['indoors'], true);
    expect(find.text('О прогулке'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await store.db!.close();
  });
}
