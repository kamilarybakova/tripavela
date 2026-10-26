import 'package:tripavela/navigation/navigation_environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/data/store.dart';
import 'package:tripavela/main.dart';

class JourneyStore extends TravelStore {
  @override
  Future<void> init({Database? database}) async {
    if (ready) return;
    await super.init(database: database);
  }
}

void main() {
  testWidgets(
    'First launch through mission, replacement, branch, finish and atlas',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = JourneyStore();
      await tester.runAsync(() async {
        await store.init(
          database: await databaseFactoryMemory.openDatabase('journey'),
        );
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWith((ref) => store),
            navigationEnvironmentProvider.overrideWithValue(
              const NavigationEnvironment(networkTiles: false),
            ),
          ],
          child: const TravelApp(),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String text) async {
        final finder = find.text(text).last;
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        ScaffoldMessenger.maybeOf(
          tester.element(finder),
        )?.removeCurrentSnackBar();
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tap('Пропустить');
      await tap('Стамбул');
      await tap('Есть свободный вечер?');
      await tap('Замедлиться');
      await tap('Дальше');
      await tap('Дальше');
      await tap('Показать маршруты');
      await tap('Рынок, трамвай и море');
      await tap('Выбрать прогулку');
      await tap('Начать прогулку');
      final id = store.active!['id'] as String;
      expect(find.text(store.places['p03']!.name), findsNothing);
      await tap('Я на месте');
      expect(store.visits.length, 1);
      await tap('Добавить заметку');
      await tester.enterText(
        find.byType(TextField),
        'Запомнился свет во дворе',
      );
      await tap('Сохранить');
      expect(store.visits.first['note'], 'Запомнился свет во дворе');
      await tap('Открыть идею');
      await tap('Сделано');
      if (find.text('Вернуться к истории').evaluate().isNotEmpty) {
        await tap('Вернуться к истории');
      }
      await tap('Продолжить');
      await tap('Место закрыто или не подходит');
      await tap('Показать альтернативы');
      await tap('Другое небольшое открытие');
      await tap('Выбрать замену');
      expect(store.session(id)['stops'][1]['original'], isNotNull);
      await tap('Я на месте');
      await tap('Выбрать, куда дальше');
      await tap('Фасад и афиша');
      await tap('Выбрать направление');
      expect(store.session(id)['branch'], 0);
      await tap('Я на месте');
      await tap('Продолжить');
      await tap('Пропустить остановку');
      await tap('Пропустить');
      expect(store.session(id)['status'], 'completed');
      expect(store.visitedCount(store.session(id)), 3);
      expect(store.skippedCount(store.session(id)), 1);
      await tap('Открыть атлас');
      expect(find.text('Мой атлас'), findsOneWidget);
      expect(store.visits.length, 3);
      await tester.pumpWidget(const SizedBox());
      await store.db!.close();
    },
  );
}
