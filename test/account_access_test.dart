import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripavela/data/account_api.dart';
import 'package:tripavela/data/store.dart';
import 'package:tripavela/domain/models.dart';
import 'package:tripavela/main.dart';
import 'package:tripavela/planning/planner.dart';

class TestAccounts extends AccountApi {
  final _remote = <String, Map<String, dynamic>>{};
  bool offline = false;

  @override
  Future<Map<String, dynamic>> loadTravelData(String token) async {
    if (offline) throw const AccountApiError('Offline');
    return copyMap(
      _remote[token] ??
          {
            'preferences': {},
            'favorites': [],
            'history': [],
            'visits': [],
            'plans': [],
            'tripDraft': null,
            'active': null,
            'activeRevision': 0,
          },
    );
  }

  @override
  Future<Map<String, dynamic>> saveTravelChanges(
    String token,
    Map<String, dynamic> changes,
  ) async {
    final remote = await loadTravelData(token);
    final preferences = remote['preferences'] as Map;
    final favorites = (remote['favorites'] as List).toSet();
    final history = {
      for (final trip in remote['history'] as List) trip['id']: trip,
    };
    if (changes['preferences'] case final Map patch) {
      preferences.addAll(Map<String, dynamic>.from(patch));
    }
    (changes['favorites'] as Map? ?? {}).forEach((id, saved) {
      if (saved == true) {
        favorites.add(id);
      } else {
        favorites.remove(id);
      }
    });
    (changes['history'] as Map? ?? {}).forEach((id, trip) {
      if (trip == null) {
        history.remove(id);
      } else {
        history[id] = trip;
      }
    });
    List<dynamic> merge(String key) {
      final records = {
        for (final item in remote[key] as List) item['id']: item,
      };
      (changes[key] as Map? ?? {}).forEach((id, value) {
        if (value == null) {
          records.remove(id);
        } else {
          records[id] = value;
        }
      });
      return records.values.toList();
    }

    if (changes['active'] case final Map patch) {
      remote['active'] = patch['walk'];
      remote['activeRevision'] += 1;
    }
    final ids = {
      ...history.keys,
      if (remote['active'] case final Map walk) walk['id'],
    };
    _remote[token] = {
      ...remote,
      'favorites': favorites.toList(),
      'history': history.values.toList(),
      'visits': [
        for (final visit in merge('visits').cast<Map>())
          {
            ...visit,
            'trip': ids.contains(visit['trip']) ? visit['trip'] : null,
          },
      ],
      'plans': merge('plans'),
      if (changes.containsKey('tripDraft')) 'tripDraft': changes['tripDraft'],
    };
    return loadTravelData(token);
  }

  @override
  Future<AccountSession?> restore() async => null;

  @override
  Future<AccountSession> authenticate(
    String email,
    String password, {
    String? name,
  }) async => (
    profile: (id: email, email: email, name: name ?? 'Путешественник'),
    token: email,
    expires: DateTime.now().add(const Duration(days: 1)),
  );

  @override
  Future<void> remember(AccountSession session) async {}

  @override
  Future<void> forget() async {}

  @override
  Future<void> revoke(String token) async {}
}

class InitializedAccountStore extends TravelStore {
  InitializedAccountStore({TestAccounts? api})
    : super(accounts: api ?? TestAccounts());

  @override
  Future<void> init({Database? database}) async {
    if (!ready) await super.init(database: database);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'guest sees public catalog and local data belongs to each account',
    () async {
      SharedPreferences.setMockInitialValues({});
      final db = await databaseFactoryMemory.openDatabase('account-scope');
      final store = InitializedAccountStore();
      addTearDown(db.close);
      addTearDown(store.dispose);
      await store.init(database: db);
      expect(store.routes, isNotEmpty);
      await expectLater(store.favorite('r0'), throwsStateError);
      expect(store.favorites, isEmpty);

      await store.authenticate(
        'first@example.test',
        'test-password',
        name: 'Первый',
      );
      await store.favorite('r0');
      final trip = await store.start('r0');
      expect(store.active?['id'], trip);
      await store.signOut();
      expect(store.active, isNull);
      expect(store.favorites, isEmpty);

      await store.authenticate('second@example.test', 'test-password');
      expect(store.active, isNull);
      expect(store.favorites, isEmpty);
      await store.signOut();
      await store.authenticate('first@example.test', 'test-password');
      expect(store.favorites, ['r0']);
      expect(store.active?['id'], trip);
    },
  );

  test('legacy trips are imported once into the chosen account', () async {
    SharedPreferences.setMockInitialValues({});
    final db = await databaseFactoryMemory.openDatabase('legacy-import');
    final legacy = TravelStore();
    final account = InitializedAccountStore();
    addTearDown(db.close);
    addTearDown(legacy.dispose);
    addTearDown(account.dispose);
    await legacy.init(database: db);
    final trip = await legacy.start('r0');
    await legacy.arrive(trip);
    await account.init(database: db);
    expect(account.visits, isEmpty);
    await account.authenticate('owner@example.test', 'test-password');
    expect(account.canImportLegacy, isTrue);
    await account.importLegacyData();
    expect(account.visits.single['trip'], trip);
    await account.signOut();
    await account.authenticate('other@example.test', 'test-password');
    expect(account.canImportLegacy, isFalse);
    expect(account.visits, isEmpty);
  });

  test(
    'offline edits are retried and a second device reads server data',
    () async {
      SharedPreferences.setMockInitialValues({});
      final api = TestAccounts();
      final firstDb = await databaseFactoryMemory.openDatabase('travel-first');
      final secondDb = await databaseFactoryMemory.openDatabase(
        'travel-second',
      );
      final first = InitializedAccountStore(api: api);
      final second = InitializedAccountStore(api: api);
      addTearDown(firstDb.close);
      addTearDown(secondDb.close);
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await first.init(database: firstDb);
      await second.init(database: secondDb);
      const email = 'same@example.test';
      await first.authenticate(email, 'test-password');
      api.offline = true;
      await first.change((state) => state['preferences']['pace'] = 'calm');
      await first.favorite('r0');
      final trip = await first.start('r0');
      await first.arrive(trip);
      await first.end(trip);
      expect(first.hasPendingTravelChanges, isTrue);
      await first.signOut();
      api.offline = false;
      await first.authenticate(email, 'test-password');
      expect(first.hasPendingTravelChanges, isFalse);
      await second.authenticate(email, 'test-password');
      expect(second.state['preferences']['pace'], 'calm');
      expect(second.favorites, ['r0']);
      expect(second.session(trip)['status'], 'endedEarly');
      expect(second.visits.single['place'], second.route('r0').places.first);
      api.offline = true;
      await second.clearData('history');
      expect(second.hasPendingTravelChanges, isTrue);
      await second.signOut();
      api.offline = false;
      await second.authenticate(email, 'test-password');
      expect(second.travelSyncUnavailable, isFalse);
      expect((await api.loadTravelData(email))['history'], isEmpty);
      await first.refreshTravelData();
      expect(first.sessions, isEmpty);
      expect(first.visits.single['trip'], isNull);
    },
  );

  test(
    'atlas, paused walk and planned days follow the signed-in account',
    () async {
      SharedPreferences.setMockInitialValues({});
      final api = TestAccounts();
      final firstDb = await databaseFactoryMemory.openDatabase('details-first');
      final secondDb = await databaseFactoryMemory.openDatabase(
        'details-second',
      );
      final first = InitializedAccountStore(api: api);
      final second = InitializedAccountStore(api: api);
      addTearDown(firstDb.close);
      addTearDown(secondDb.close);
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await first.init(database: firstDb);
      await second.init(database: secondDb);
      const email = 'traveler@example.test';
      await first.authenticate(email, 'test-password');
      final id = await first.start('r0');
      await first.arrive(id);
      await first.advance(id);
      await first.pause(id);
      final visit = first.visits.single['id'] as String;
      await first.note(visit, 'Встретили рассвет');
      final brief = TripBrief(date: DateTime(2026, 11, 18));
      await first.saveTripDraft({...brief.toJson(), 'step': 1});

      await second.authenticate(email, 'test-password');
      expect(second.active?['status'], 'paused');
      expect(second.active?['index'], 1);
      expect(second.visits.single['note'], 'Встретили рассвет');
      expect(second.state['tripDraft']['step'], 1);
      await second.resume(id);
      await second.end(id);
      final plan = TripPlanner(
        second.planningCatalog,
      ).generate(brief, id: 'plan-sync');
      await second.saveTravelPlan(plan);
      await second.startPlannedDay(plan.id, 0);
      await second.markPlannedStop(plan.id, 0, 0, true);

      await first.refreshTravelData();
      expect(first.active, isNull);
      expect(first.session(id)['status'], 'endedEarly');
      expect(first.state['tripDraft'], isNull);
      expect(first.travelPlans.single.days.first.started, isTrue);
      expect(first.travelPlans.single.days.first.stops.first.done, isTrue);
    },
  );

  testWidgets('guest can browse routes and profile redirects to sign-in', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = InitializedAccountStore();
    final db = await databaseFactoryMemory.openDatabase('guest-router');
    addTearDown(db.close);
    await tester.runAsync(() async {
      await store.init(database: db);
      await store.change((state) => state['onboarded'] = true);
      await store.selectCity('istanbul');
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storeProvider.overrideWith((ref) => store)],
        child: const TravelApp(),
      ),
    );
    await tester.pumpAndSettle();
    final router = GoRouter.of(
      tester.element(find.text('Посмотреть прогулки')),
    );
    router.go('/routes');
    await tester.pumpAndSettle();
    expect(find.text('Войти в Tripavela'), findsNothing);
    router.go('/profile');
    await tester.pumpAndSettle();
    expect(find.text('Войти в Tripavela'), findsOneWidget);
    await tester.tap(find.text('Создать аккаунт'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'Зарегистрироваться'),
      findsOneWidget,
    );
    await tester.tap(find.text('Продолжить без аккаунта'));
    await tester.pumpAndSettle();
    expect(find.text('Каталог мест'), findsOneWidget);
    router.go('/profile');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать аккаунт'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Имя'),
      'Тестовый пользователь',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'traveler@example.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Пароль'),
      'test-password-only',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Зарегистрироваться'));
    await tester.pumpAndSettle();
    expect(find.text('Тестовый пользователь'), findsOneWidget);
    final logout = find.text('Выйти из аккаунта');
    await tester.ensureVisible(logout);
    await tester.tap(logout);
    await tester.pumpAndSettle();
    expect(store.account, isNull);
  });
}
