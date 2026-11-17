import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'account_api.dart';
import 'api_config.dart';
import 'atlas_photos.dart';
import 'database.dart';
import 'public_catalog.dart';
import 'travel_data.dart';
import '../l10n/copy.dart';
import '../planning/planner.dart';

final storeProvider = ChangeNotifierProvider<TravelStore>(
  (ref) => TravelStore(accounts: AccountApi(), loadRemoteCatalog: true),
);
final _appRecords = stringMapStoreFactory.store('app');
final _legacyRecord = _appRecords.record('state');
final _guestRecord = _appRecords.record('guest');
final _legacyImport = _appRecords.record('legacy_import');
const _portableKeys = [
  'sessions',
  'visits',
  'travelPlans',
  'favorites',
  'tripDraft',
];
final _catalogCache = stringMapStoreFactory
    .store('catalog')
    .record('city_catalog:${tripavelaApiBase.origin}');
const _privateKeys = [
  'sessions',
  'visits',
  'travelPlans',
  'favorites',
  'tripDraft',
  'name',
];
Map<String, dynamic> initialState() => {
  'version': 1,
  'onboarded': false,
  'city': false,
  'cityId': 'istanbul',
  'travelPlans': <dynamic>[],
  'tripDraft': null,
  'favorites': <String>[],
  'sessions': <dynamic>[],
  'visits': <dynamic>[],
  'draft': defaultFilters(),
  'preferences': defaultFilters(),
  'settings': {'theme': 'system', 'haptics': true, 'reduceMotion': false},
  'name': copy.message484,
  'events': <dynamic>[],
};

class TravelStore extends ChangeNotifier
    implements
        CatalogRepository,
        SessionRepository,
        AtlasRepository,
        PreferencesRepository,
        FavoritesRepository {
  TravelStore({this._accounts, this.loadRemoteCatalog = false});

  final AccountApi? _accounts;
  final bool loadRemoteCatalog;
  AccountSession? _session;
  Timer? _expiry;
  Timer? _travelRetry;
  bool travelSyncUnavailable = false;
  bool activeWalkSyncConflict = false;
  final _photoReads = <String, Future<List<int>?>>{};
  bool get hasPendingTravelChanges =>
      (state[pendingTravelChanges] as Map?)?.isNotEmpty ?? false;
  bool get canUsePersonal => _accounts == null || _session != null;
  AccountProfile? get account => _session?.profile;
  bool _legacyAvailable = false;
  bool get canImportLegacy =>
      account != null && _legacyAvailable && !_hasPersonalData(state);
  bool _hasPersonalData(Map<String, Object?> data) => _portableKeys.any((key) {
    final value = data[key];
    return value is List ? value.isNotEmpty : value != null;
  });
  RecordRef<String, Map<String, Object?>> get _stateRecord {
    final id = account?.id;
    if (id != null) return _accountRecord(id);
    return _accounts == null ? _legacyRecord : _guestRecord;
  }

  RecordRef<String, Map<String, Object?>> _accountRecord(String id) =>
      _appRecords.record('account:${tripavelaApiBase.origin}:$id');

  final _historicalPlaces = <String>{};
  final _historicalRoutes = <String>{};
  Set<String>? _publishedCities;
  Iterable<Map<String, dynamic>> get availableCities => cities.values.where(
    (city) => _publishedCities?.contains(city['id']) ?? true,
  );

  final Map<String, Map<String, dynamic>> cities = {};
  final Map<String, PlanningCatalog> planningCatalogs = {};
  String get cityId => state['cityId'] as String? ?? 'istanbul';
  Map<String, dynamic> get cityData =>
      cities[cityId] ?? cities['istanbul'] ?? {};
  Map<String, dynamic> cityFor(String id) => cities[id] ?? cities['istanbul']!;
  String cityForPlace(String id) => places[id]?.data['cityId'] ?? 'istanbul';
  String cityNameForPlace(String id) => cityFor(cityForPlace(id))['name'];
  PlanningCatalog planningFor(String id) =>
      planningCatalogs[id] ??
      planningCatalogs[cityId] ??
      planningCatalogs.values.first;
  Future<void> selectCity(String id) => change((s) {
    if (!availableCities.any((city) => city['id'] == id)) {
      throw ArgumentError('Неизвестный город');
    }
    final oldCaps = List<int>.from(cityData['budgetCaps']);
    final level = oldCaps.indexOf(s['preferences']['budget'] as int);
    s['preferences']['budget'] =
        (cities[id]!['budgetCaps'] as List)[level < 0 ? 2 : level];
    s['hasDraft'] = false;
    s['cityId'] = id;
    s['city'] = true;
    s['draft'] = {
      ...defaultFilters(),
      'budget': (cities[id]!['budgetCaps'] as List)[2],
    };
  });
  String formatMoney(int amount, {String? forCity}) =>
      '${(amount / 100).round()} ${cityFor(forCity ?? cityId)['currencySymbol']}';
  List<int> get budgetCaps =>
      List<int>.from(cityData['budgetCaps'] ?? [0, 40000, 80000, 1000000]);
  Database? db;
  Map<String, dynamic> state = initialState();
  List<WalkRoute> allRoutes = [];
  @override
  List<WalkRoute> get routes => routesFor(cityId);
  List<WalkRoute> routesFor(String city) => allRoutes
      .where(
        (r) =>
            (r.data['cityId'] ?? 'istanbul') == city &&
            r.data['archived'] != true,
      )
      .toList();
  @override
  Map<String, Place> places = {};
  PlanningCatalog get planningCatalog => planningFor(cityId);
  List<TravelPlan> get travelPlans => [
    for (final p in state['travelPlans'] as List? ?? [])
      TravelPlan.fromJson(Map<String, dynamic>.from(p)),
  ];
  TravelPlan? travelPlan(String id) =>
      travelPlans.where((p) => p.id == id).firstOrNull;
  Future<void> saveTripDraft(Map<String, dynamic> draft) =>
      change((s) => s['tripDraft'] = draft);
  Future<void> saveTravelPlan(TravelPlan plan) => change((s) {
    (s['travelPlans'] as List).insert(0, plan.toJson());
    s['tripDraft'] = null;
  }, event: 'travel_plan_created');
  Future<void> startPlannedDay(String id, int day) => change((s) {
    final p = (s['travelPlans'] as List).firstWhere((p) => p['id'] == id);
    p['days'][day]['started'] = true;
  });
  Future<void> markPlannedStop(String id, int day, int stop, bool done) =>
      change((s) {
        final p = (s['travelPlans'] as List).firstWhere((p) => p['id'] == id);
        p['days'][day]['stops'][stop]['done'] = done;
      });
  bool ready = false, busy = false, recovered = false;
  String? initError;
  Map<String, dynamic> get draft => Map<String, dynamic>.from(state['draft']);
  @override
  Map<String, dynamic> get settings =>
      Map<String, dynamic>.from(state['settings']);
  @override
  List<Map<String, dynamic>> get sessions =>
      List<Map<String, dynamic>>.from(state['sessions']);
  @override
  List<Map<String, dynamic>> get visits =>
      List<Map<String, dynamic>>.from(state['visits']);
  @override
  Map<String, dynamic>? get active {
    for (final s in sessions) {
      if (s['status'] == 'active' || s['status'] == 'paused') return s;
    }
    return null;
  }

  @override
  WalkRoute route(String id) => allRoutes.firstWhere((r) => r.id == id);
  @override
  Map<String, dynamic> session(String id) =>
      sessions.firstWhere((s) => s['id'] == id);
  @override
  List<String> get favorites => List<String>.from(state['favorites']);
  DateTime cityNow() => DateTime.now().toUtc().add(
    Duration(hours: cityData['utcOffset'] as int? ?? 3),
  );
  Future<void> init({Database? database}) async {
    try {
      _publishedCities = null;
      _historicalPlaces.clear();
      _historicalRoutes.clear();
      allRoutes.clear();
      places.clear();
      cities.clear();
      planningCatalogs.clear();
      final destinations =
          jsonDecode(
                await rootBundle.loadString('assets/data/destinations.json'),
              )
              as Map;
      for (final city in destinations['cities']) {
        final base = city == 'istanbul'
            ? 'assets/data/catalog.json'
            : 'assets/data/cities/$city.json';
        final data = jsonDecode(await rootBundle.loadString(base)) as Map;
        cities[city] = Map<String, dynamic>.from(data['city']);
        allRoutes.addAll(
          (data['routes'] as List).map(
            (e) => WalkRoute({
              ...Map<String, dynamic>.from(e),
              'currencySymbol': cities[city]!['currencySymbol'],
            }),
          ),
        );
        for (final p in data['places']) {
          places[p['id']] = Place({
            ...Map<String, dynamic>.from(p),
            'cityId': city,
          });
        }
        final planningPath = city == 'istanbul'
            ? 'assets/data/planning.json'
            : 'assets/data/cities/$city-planning.json';
        planningCatalogs[city] = PlanningCatalog(
          Map<String, dynamic>.from(
            jsonDecode(await rootBundle.loadString(planningPath)),
          ),
        );
      }
      db = database ?? await openLocalDatabase();
      final session = await _initialSessionAndCatalog();
      _session = session;
      final local = await _readCurrentState();
      _useState(
        session == null ? local : await _syncTravelState(session, local),
      );
      _scheduleTravelRetry();
      if (_accounts != null && await _legacyImport.get(db!) == null) {
        final old = await _legacyRecord.get(db!);
        _legacyAvailable = old != null && _hasPersonalData(old);
      }
      _scheduleExpiry();
      // Refresh only media; saved times, choices and visit marks stay intact.
      var photosUpdated = false;
      for (final plan in state['travelPlans'] as List? ?? []) {
        for (final day in plan['days'] as List) {
          for (final stop in day['stops'] as List) {
            final poi = stop['poi'] as Map;
            final current = planningFor(
              plan['brief']['cityId'] ?? 'istanbul',
            ).pois[poi['id']];
            if (current != null &&
                (poi['image'] != current.data['image'] ||
                    poi['imageCaption'] != current.data['imageCaption'])) {
              poi['image'] = current.data['image'];
              poi['imageCaption'] = current.data['imageCaption'];
              photosUpdated = true;
            }
          }
        }
      }
      for (final session in state['sessions'] as List) {
        final routeNow = allRoutes
            .where((r) => r.id == session['routeId'])
            .firstOrNull;
        if (routeNow != null &&
            session['snapshot']['image'] != routeNow.image) {
          session['snapshot']['image'] = routeNow.image;
          photosUpdated = true;
        }
      }
      if (photosUpdated) await _stateRecord.put(db!, state);
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString('theme');
      if (theme != null) state['settings']['theme'] = theme;
      ready = true;
      initError = null;
      notifyListeners();
    } catch (e, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: stack,
          library: 'local storage',
        ),
      );
      initError = copy.errorOpenData;
      notifyListeners();
    }
  }

  Future<AccountSession?> _initialSessionAndCatalog() async {
    final session = _restoreSession();
    if (loadRemoteCatalog) await _loadCatalog();
    return session;
  }

  Future<AccountSession?> _restoreSession() async {
    try {
      return await _accounts?.restore();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadCatalog() async {
    try {
      final cached = await _catalogCache.get(db!);
      if (cached != null) _applyCatalog(cached);
    } catch (_) {
      // Use the bundled catalog if the cache cannot be read.
    }
    try {
      final fresh = await downloadPublicCatalog();
      _applyCatalog(fresh);
      await _catalogCache.put(db!, fresh);
    } catch (_) {
      // The last usable catalog is already available.
    }
  }

  void _applyCatalog(Map<String, dynamic> payload) {
    final newCities = <String, Map<String, dynamic>>{};
    final newPlaces = <String, Place>{};
    final newRoutes = <String, WalkRoute>{};
    final newPlanning = <String, PlanningCatalog>{};
    for (final entry in (payload['catalogs'] as List).cast<Map>()) {
      final catalog = entry['catalog'] as Map;
      final city = Map<String, dynamic>.from(catalog['city'] as Map);
      final id = city['id'] as String;
      final plan = entry['planning'] as Map?;
      if (plan == null && !planningCatalogs.containsKey(id)) continue;
      if (plan != null) {
        newPlanning[id] = PlanningCatalog(Map<String, dynamic>.from(plan));
      }
      newCities[id] = city;
      final cityPlaces = <String, Place>{};
      for (final data in (catalog['places'] as List).cast<Map>()) {
        final place = Place({...Map<String, dynamic>.from(data), 'cityId': id});
        cityPlaces[place.id] = place;
      }
      newPlaces.addAll(cityPlaces);
      for (final data in (catalog['routes'] as List).cast<Map>()) {
        final route = _walkFromApi(data, city, cityPlaces);
        if (route != null) newRoutes[route.id] = route;
      }
    }
    if (newCities.isEmpty) return;
    _publishedCities = newCities.keys.toSet();
    cities.addAll(newCities);
    places.addAll(newPlaces);
    planningCatalogs.addAll(newPlanning);
    allRoutes = [
      ...newRoutes.values,
      for (final previous in allRoutes)
        if (!newRoutes.containsKey(previous.id))
          WalkRoute({...previous.data, 'archived': true}),
    ];
  }

  WalkRoute? _walkFromApi(
    Map data,
    Map<String, dynamic> city,
    Map<String, Place> cityPlaces,
  ) {
    final route = WalkRoute({
      for (final field in [
        'practical',
        'gettingThere',
        'budgetNote',
        'distanceNote',
      ])
        field: '',
      ...Map<String, dynamic>.from(data),
      'cityId': city['id'],
      'currencySymbol': city['currencySymbol'],
    });
    final alternative = data['alternative'];
    if (route.places.length != 3 ||
        route.branches.length != 2 ||
        alternative is! String) {
      return null;
    }
    final ids = [...route.places, ...route.branches, alternative];
    if (ids.any((id) {
      final place = cityPlaces[id]?.data;
      return place == null || place['lat'] is! num || place['lon'] is! num;
    })) {
      return null;
    }
    final hints = data['branchHints'];
    final deltas = data['branchDelta'];
    if (hints is! List || hints.length != 2) {
      route.data['branchHints'] = [
        for (final id in route.branches)
          {'title': cityPlaces[id]!.name, 'description': ''},
      ];
    }
    if (deltas is! List || deltas.length != 2) {
      route.data['branchDelta'] = [
        for (final _ in route.branches) {'minutes': 0, 'meters': 0},
      ];
    }
    return route;
  }

  Map<String, dynamic> _guestDefaults(Map<String, Object?>? saved) => {
    ...initialState(),
    for (final key in [
      'onboarded',
      'city',
      'cityId',
      'settings',
      'draft',
      'preferences',
    ])
      if (saved?.containsKey(key) ?? false) key: saved![key],
  };

  Future<Map<String, dynamic>> _readCurrentState([
    RecordRef<String, Map<String, Object?>>? record,
  ]) async {
    final saved = await (record ?? _stateRecord).get(db!);
    if (saved == null) {
      if (_accounts == null) return initialState();
      return _guestDefaults(
        await _guestRecord.get(db!) ?? await _legacyRecord.get(db!),
      );
    }
    if (saved['version'] != 1 ||
        saved['sessions'] is! List ||
        saved['visits'] is! List ||
        (saved['sessions'] as List).any(
          (t) =>
              t is! Map ||
              t['stops'] is! List ||
              t['snapshot'] is! Map ||
              t['id'] is! String,
        )) {
      recovered = true;
      await stringMapStoreFactory
          .store('recovery')
          .record(DateTime.now().toIso8601String())
          .put(db!, saved);
      return {
        ...initialState(),
        'visits': saved['visits'] is List ? saved['visits'] : [],
      };
    }
    return {...initialState(), ...copyMap(saved)};
  }

  void _useState(Map<String, dynamic> next) {
    for (final id in _historicalPlaces) {
      places.remove(id);
    }
    allRoutes.removeWhere((route) => _historicalRoutes.contains(route.id));
    _historicalPlaces.clear();
    _historicalRoutes.clear();
    state = next;
    if (!availableCities.any((city) => city['id'] == cityId)) {
      state['cityId'] = availableCities.first['id'];
      final budget = budgetCaps[2];
      state['preferences']['budget'] = budget;
      state['draft']['budget'] = budget;
    }
    void rememberPlace(Map place) {
      final id = place['id'] as String;
      if (!places.containsKey(id)) {
        places[id] = Place(Map<String, dynamic>.from(place));
        _historicalPlaces.add(id);
      }
    }

    for (final trip in sessions) {
      final id = trip['routeId'] as String;
      if (!allRoutes.any((route) => route.id == id)) {
        allRoutes.add(
          WalkRoute({
            ...Map<String, dynamic>.from(trip['snapshot']),
            'archived': true,
          }),
        );
        _historicalRoutes.add(id);
      }
      final snapshots = trip['placeSnapshots'] as Map?;
      for (final place in snapshots?.values ?? const []) {
        if (place is Map) rememberPlace(place);
      }
    }
    for (final visit in visits) {
      final place = visit['placeSnapshot'];
      if (place is Map) rememberPlace(place);
    }
  }

  Future<void> authenticate(
    String email,
    String password, {
    String? name,
  }) async {
    final api = _accounts!;
    if (busy) throw StateError(copy.errorBusy);
    busy = true;
    notifyListeners();
    try {
      final session = await api.authenticate(email, password, name: name);
      final next = await _readCurrentState(_accountRecord(session.profile.id));
      try {
        await api.remember(session);
      } on PlatformException {
        // The verified session is still usable until the app closes.
      } on MissingPluginException {
        // The platform does not provide persistent secure storage.
      }
      _session = session;
      _useState(await _syncTravelState(session, next));
      _scheduleExpiry();
      _scheduleTravelRetry();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    final session = _session;
    if (session == null) return;
    if (busy) throw StateError(copy.errorBusy);
    busy = true;
    notifyListeners();
    try {
      final guest = _guestDefaults(
        await _guestRecord.get(db!) ?? await _legacyRecord.get(db!),
      );
      final api = _accounts!;
      try {
        await api.forget();
      } finally {
        _session = null;
        _expiry?.cancel();
        _travelRetry?.cancel();
        travelSyncUnavailable = false;
        activeWalkSyncConflict = false;
        _useState(guest);
        unawaited(api.revoke(session.token).catchError((Object _) {}));
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    final session = _session;
    if (session == null) return;
    _expiry = Timer(session.expires.difference(DateTime.now()), _expireSession);
  }

  void _expireSession() {
    if (busy) {
      _expiry = Timer(const Duration(seconds: 1), _expireSession);
      return;
    }
    unawaited(signOut().catchError((Object _) {}));
  }

  Future<void> importLegacyData() async {
    if (busy) throw StateError(copy.errorBusy);
    if (!canImportLegacy) return;
    busy = true;
    notifyListeners();
    try {
      final next = await db!.transaction((txn) async {
        if (await _legacyImport.get(txn) != null) return null;
        final legacy = await _legacyRecord.get(txn);
        if (legacy == null) return null;
        final imported = copyMap(state);
        for (final key in _portableKeys) {
          if (legacy.containsKey(key)) imported[key] = legacy[key];
        }
        _recordTravelChanges(imported);
        await _stateRecord.put(txn, imported);
        await _legacyImport.put(txn, {'account': account!.id});
        return imported;
      });
      if (next != null) {
        _useState(await _syncTravelState(_session!, next));
        _scheduleTravelRetry();
      }
      _legacyAvailable = false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> renameProfile(String name) async {
    final session = _session;
    if (session == null) {
      await change((s) => s['name'] = name);
      return;
    }
    try {
      final profile = await _accounts!.updateName(session.token, name);
      if (_session?.token == session.token) {
        _session = (
          profile: profile,
          token: session.token,
          expires: session.expires,
        );
        notifyListeners();
      }
    } on AccountApiError catch (error) {
      if (error.status == 401 && _session?.token == session.token) {
        _expireSession();
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    _travelRetry?.cancel();
    super.dispose();
  }

  bool _recordTravelChanges(Map<String, dynamic> next) {
    final previous = prepareTravelSync(state, initialState());
    final changes = queueTravelChanges(previous, next);
    next[travelSyncVersion] = currentTravelSyncVersion;
    next[activeRevision] = previous[activeRevision] ?? 0;
    next[pendingTravelChanges] = changes;
    return jsonEncode(changes) != jsonEncode(state[pendingTravelChanges] ?? {});
  }

  Future<Map<String, dynamic>> _syncTravelState(
    AccountSession session,
    Map<String, dynamic> local,
  ) async {
    final record = _accountRecord(session.profile.id);
    final prepared = prepareTravelSync(local, initialState());
    if (!identical(prepared, local)) await record.put(db!, prepared);
    final pending = Map<String, dynamic>.from(
      prepared[pendingTravelChanges] as Map? ?? {},
    );
    try {
      final api = _accounts!;
      final photos = AtlasPhotos(db!, api, session);
      final remote = pending.isEmpty
          ? await api.loadTravelData(session.token)
          : await api.saveTravelChanges(
              session.token,
              await photos.prepareVisitChanges(pending),
            );
      final next = applyTravelData(prepared, remote);
      final conflict = remote['activeConflict'] == true;
      await db!.transaction((txn) async {
        if (conflict) {
          final disputedId = (pending['active'] as Map?)?['sessionId'];
          await stringMapStoreFactory
              .store('walk_sync_recovery')
              .record('${record.key}:$disputedId')
              .put(txn, {
                'changes': pending['active'],
                'walk': (prepared['sessions'] as List)
                    .cast<Map>()
                    .where((walk) => walk['id'] == disputedId)
                    .firstOrNull,
              });
        }
        await record.put(txn, next);
      });
      Set<String> photoRefs(Map<String, dynamic> snapshot) => {
        for (final visit in (snapshot['visits'] as List).cast<Map>())
          for (final ref in (visit['photos'] as List).cast<String>())
            if (isAtlasPhotoRef(ref)) ref,
      };
      for (final ref in photoRefs(prepared).difference(photoRefs(next))) {
        try {
          await photos.deleteCached(ref);
        } on Exception {
          // A cache error does not roll back an accepted server change.
        }
      }
      if (pending.containsKey('active')) activeWalkSyncConflict = conflict;
      travelSyncUnavailable = false;
      return next;
    } catch (error) {
      travelSyncUnavailable = true;
      if (ready && error is AccountApiError && error.status == 401) {
        _expireSession();
      }
      return prepared;
    }
  }

  Future<void> refreshTravelData() async {
    final session = _session;
    if (session == null || !ready) return;
    if (busy) {
      _scheduleTravelRetry();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      _useState(await _syncTravelState(session, state));
    } finally {
      busy = false;
      _scheduleTravelRetry();
      notifyListeners();
    }
  }

  void _scheduleTravelRetry() {
    _travelRetry?.cancel();
    if (_session != null && hasPendingTravelChanges) {
      _travelRetry = Timer(const Duration(seconds: 20), refreshTravelData);
    }
  }

  Future<void> change(
    void Function(Map<String, dynamic>) action, {
    String? event,
  }) async {
    if (busy) throw StateError(copy.errorBusy);
    busy = true;
    notifyListeners();
    try {
      final next = copyMap(state);
      action(next);
      if (!canUsePersonal &&
          _privateKeys.any(
            (key) => jsonEncode(next[key]) != jsonEncode(state[key]),
          )) {
        throw StateError('Войдите в аккаунт, чтобы сохранить данные.');
      }
      if (event != null) {
        (next['events'] as List).add({
          'name': event,
          'at': DateTime.now().toUtc().toIso8601String(),
        });
        if ((next['events'] as List).length > 200) {
          (next['events'] as List).removeAt(0);
        }
      }
      final sync = _session;
      final changed = sync != null && _recordTravelChanges(next);
      await db!.transaction((txn) async {
        await _stateRecord.put(txn, next);
      });
      if (changed) {
        _useState(await _syncTravelState(sync, next));
        _scheduleTravelRetry();
      } else {
        state = next;
      }
      if (settings['haptics'] == true && event != null) {
        HapticFeedback.selectionClick();
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> setDraft(Map<String, dynamic> value) =>
      change((s) => s['draft'] = value);
  @override
  Future<void> favorite(String id) => change((s) {
    final list = s['favorites'] as List;
    list.contains(id) ? list.remove(id) : list.add(id);
  }, event: 'favorite_changed');
  @override
  Future<String> start(String id, {bool reveal = false}) async {
    if (active != null) throw StateError(copy.errorActiveTrip);
    final r = route(id);
    final sid = 'trip_${DateTime.now().microsecondsSinceEpoch}';
    final snapshot = copyMap(r.data);
    await change((s) {
      (s['sessions'] as List).add({
        'id': sid,
        'routeId': id,
        'cityId': r.data['cityId'] ?? 'istanbul',
        'snapshot': snapshot,
        'placeSnapshots': {
          for (final placeId in {...r.places, ...r.branches, r.alternative})
            placeId: places[placeId]!.data,
        },
        'filters': copyMap(draft),
        'status': 'active',
        'started': DateTime.now().toUtc().toIso8601String(),
        'pausedAt': null,
        'pauseSeconds': 0,
        'ended': null,
        'index': 0,
        'branch': null,
        'reveal': reveal,
        'rating': 0,
        'feedback': <String, dynamic>{},
        'stops': [
          for (var i = 0; i < 3; i++)
            {
              'place': r.places[i],
              'visible': reveal || i == 0,
              'result': i == 0 ? 'current' : 'waiting',
              'mission': 'available',
              'original': null,
              'reason': null,
            },
        ],
      });
    }, event: 'trip_started');
    if (active?['id'] != sid) {
      throw StateError('На сервере уже есть активная прогулка.');
    }
    return sid;
  }

  Future<void> mutateTrip(
    String id,
    void Function(Map<String, dynamic>, Map<String, dynamic>) action, {
    String? event,
  }) => change((s) {
    final trip = (s['sessions'] as List).cast<Map>().firstWhere(
      (t) => t['id'] == id,
    );
    action(trip.cast<String, dynamic>(), s);
  }, event: event);
  @override
  Future<void> arrive(String id) => mutateTrip(id, (t, s) {
    final stop = t['stops'][t['index']];
    if (stop['result'] == 'visited') return;
    stop['result'] = 'visited';
    final key = '$id:${t['index']}';
    if (!(s['visits'] as List).any((v) => v['id'] == key)) {
      (s['visits'] as List).add({
        'id': key,
        'trip': id,
        'place': stop['place'],
        'placeSnapshot': places[stop['place']]!.data,
        'at': DateTime.now().toUtc().toIso8601String(),
        'note': '',
        'photos': <String>[],
        'hidden': false,
      });
    }
  }, event: 'arrival_confirmed');
  @override
  Future<bool> advance(String id, {bool skip = false, String? reason}) async {
    bool branch = false;
    await mutateTrip(id, (t, s) {
      final i = t['index'] as int;
      final stops = t['stops'] as List;
      if (skip) {
        stops[i]['result'] = 'skipped';
        stops[i]['reason'] = reason;
      }
      if (i == 1 && t['branch'] == null) {
        branch = true;
        return;
      }
      if (i + 1 < stops.length) {
        t['index'] = i + 1;
        stops[i + 1]['visible'] = true;
        stops[i + 1]['result'] = 'current';
      } else {
        _finish(t, early: false);
      }
    }, event: skip ? 'stop_skipped' : 'stop_advanced');
    return branch;
  }

  Future<void> branch(String id, int option) => mutateTrip(id, (t, s) {
    if (t['branch'] != null) return;
    t['branch'] = option;
    final p = t['snapshot']['branches'][option];
    t['stops'].insert(2, {
      'place': p,
      'visible': true,
      'result': 'current',
      'mission': 'available',
      'original': null,
      'reason': null,
    });
    t['index'] = 2;
  }, event: 'branch_chosen');
  Future<void> replace(String id, String place, String reason) =>
      mutateTrip(id, (t, s) {
        if (place != t['snapshot']['alternative']) {
          throw StateError(copy.noReplacement);
        }
        final stop = t['stops'][t['index']];
        if (stop['place'] == place) throw StateError(copy.noReplacement);
        stop['original'] = stop['place'];
        stop['place'] = place;
        stop['reason'] = reason;
        stop['visible'] = true;
        stop['result'] = 'current';
        stop['replacementDelta'] = {
          'minutes': 10,
          'meters': 200,
          'costMin': 0,
          'costMax': 0,
        };
      }, event: 'stop_replaced');
  @override
  Future<void> pause(String id) => mutateTrip(id, (t, s) {
    if (t['status'] != 'active') return;
    t['status'] = 'paused';
    t['pausedAt'] = DateTime.now().toUtc().toIso8601String();
  }, event: 'trip_paused');
  @override
  Future<void> resume(String id) => mutateTrip(id, (t, s) {
    if (t['status'] != 'paused') return;
    if (t['pausedAt'] != null) {
      t['pauseSeconds'] =
          (t['pauseSeconds'] as int) +
          DateTime.now()
              .toUtc()
              .difference(DateTime.parse(t['pausedAt']))
              .inSeconds;
    }
    t['pausedAt'] = null;
    t['status'] = 'active';
  }, event: 'trip_resumed');
  void _finish(Map<String, dynamic> t, {bool early = true}) {
    if (t['ended'] != null) return;
    if (t['status'] == 'paused' && t['pausedAt'] != null) {
      t['pauseSeconds'] += DateTime.now()
          .toUtc()
          .difference(DateTime.parse(t['pausedAt']))
          .inSeconds;
    }
    t['pausedAt'] = null;
    t['ended'] = DateTime.now().toUtc().toIso8601String();
    t['status'] = (t['stops'] as List).any((p) => p['result'] == 'visited')
        ? (early ? 'endedEarly' : 'completed')
        : 'cancelledBeforeVisit';
  }

  @override
  Future<void> end(String id) =>
      mutateTrip(id, (t, s) => _finish(t), event: 'trip_ended');
  Future<void> reveal(String id) => mutateTrip(id, (t, s) {
    t['reveal'] = true;
    for (final stop in t['stops']) {
      stop['visible'] = true;
    }
  }, event: 'route_revealed');
  Future<void> mission(String id, String status) => mutateTrip(id, (t, s) {
    t['stops'][t['index']]['mission'] = status;
  }, event: 'mission_$status');
  @override
  Future<void> note(String visitId, String note) => change((s) {
    (s['visits'] as List).firstWhere((v) => v['id'] == visitId)['note'] = note;
  }, event: 'note_saved');
  @override
  Future<void> photo(String visitId, String path) => change((s) {
    ((s['visits'] as List).firstWhere((v) => v['id'] == visitId)['photos']
            as List)
        .add(path);
  });
  Future<void> removePhoto(String visitId, String path) async {
    await change((s) {
      ((s['visits'] as List).firstWhere((v) => v['id'] == visitId)['photos']
              as List)
          .remove(path);
    });
    await _deleteVisitPhoto(path);
  }

  Future<List<int>?> readVisitPhoto(String path) async {
    if (!isAtlasPhotoRef(path)) return readPhoto(path);
    final session = _session;
    if (session == null) return null;
    final key = '${session.profile.id}:$path';
    final pending = _photoReads[key] ??= AtlasPhotos(
      db!,
      _accounts!,
      session,
    ).read(path).catchError((Object _) => null);
    try {
      final bytes = await pending;
      return _session?.profile.id == session.profile.id ? bytes : null;
    } finally {
      if (identical(_photoReads[key], pending)) _photoReads.remove(key);
    }
  }

  Future<int> localVisitPhotoSize(String path) async {
    if (!isAtlasPhotoRef(path)) return (await readPhoto(path))?.length ?? 0;
    final session = _session;
    if (session == null) return 0;
    return (await AtlasPhotos(
          db!,
          _accounts!,
          session,
        ).readCached(path))?.length ??
        0;
  }

  Future<void> _deleteVisitPhoto(String path) async {
    if (visits.any((visit) => (visit['photos'] as List).contains(path))) return;
    if (!isAtlasPhotoRef(path)) {
      await deletePhotoFile(path);
    } else if (_session case final session?) {
      await AtlasPhotos(db!, _accounts!, session).deleteCached(path);
    }
  }

  @override
  Future<void> setting(String key, dynamic value) async {
    await change((s) => s['settings'][key] = value);
    if (key == 'theme') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', value);
    }
  }

  Future<void> clearData(String type) async {
    final files = [for (final v in visits) ...List<String>.from(v['photos'])];
    await change((s) {
      if (type == 'all') {
        s.clear();
        s.addAll(initialState());
      } else if (type == 'photos') {
        for (final v in s['visits']) {
          v['photos'] = <String>[];
        }
      } else if (type == 'history') {
        final activeIds = (s['sessions'] as List)
            .where((t) => t['status'] == 'active' || t['status'] == 'paused')
            .map((t) => t['id'])
            .toSet();
        (s['sessions'] as List).removeWhere(
          (t) => !activeIds.contains(t['id']),
        );
        for (final v in s['visits']) {
          if (!activeIds.contains(v['trip'])) v['trip'] = null;
        }
      }
    });
    if (type == 'all') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('theme');
      await stringMapStoreFactory.store('navigation').delete(db!);
    } else if (type == 'history') {
      final activeIds = sessions
          .where((s) => s['status'] == 'active' || s['status'] == 'paused')
          .map((s) => s['id'])
          .toSet();
      final cache = stringMapStoreFactory.store('navigation');
      for (final record in await cache.find(db!)) {
        if (!activeIds.contains(record.key)) {
          await cache.record(record.key).delete(db!);
        }
      }
    }
    if (type == 'all' || type == 'photos') {
      for (final path in files) {
        await _deleteVisitPhoto(path);
      }
    }
  }

  Map<String, dynamic>? transition(
    Map<String, dynamic> t,
    String from,
    String to,
  ) {
    final values = t['snapshot']['transitions'] as Map?;
    final value = values?['$from|$to'];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Map<String, dynamic>? currentTransition(Map<String, dynamic> t) {
    final stops = t['stops'] as List;
    final current = t['index'] as int;
    final visited = stops
        .take(current)
        .where((s) => s['result'] == 'visited')
        .toList();
    if (visited.isEmpty) return null;
    return transition(t, visited.last['place'], stops[current]['place']);
  }

  int visitedMeters(Map<String, dynamic> t) {
    final stops = (t['stops'] as List)
        .where((s) => s['result'] == 'visited')
        .toList();
    var total = 0;
    for (var i = 1; i < stops.length; i++) {
      final edge = transition(t, stops[i - 1]['place'], stops[i]['place']);
      if (edge == null) continue;
      total += edge['meters'] as int;
    }
    return total;
  }

  Map<String, int> tripMetrics(Map<String, dynamic> t) {
    final snapshot = t['snapshot'];
    var minutes = snapshot['minutes'] as int;
    final meters = plannedMeters(t);
    if (t['filters']['pace'] == 'calm') minutes += 25;
    final delta = t['branch'] == null
        ? null
        : snapshot['branchDelta'][t['branch']];
    if (delta != null) {
      minutes += delta['minutes'] as int;
    }
    for (final stop in t['stops']) {
      if (stop['replacementDelta'] != null) {
        minutes += stop['replacementDelta']['minutes'] as int;
      }
      if (stop['result'] == 'skipped') {
        minutes -= (snapshot['stopMinutes'] as int? ?? 20);
      }
    }
    return {
      'minutes': minutes.clamp(0, 100000),
      'meters': meters,
      'costMin': snapshot['requiredMin'] as int,
      'costMax': snapshot['requiredMax'] as int,
    };
  }

  int plannedMeters(Map<String, dynamic> t) {
    final stops = List<Map<String, dynamic>>.from(t['stops']);
    int length(List<Map<String, dynamic>> planned) {
      final ids = planned
          .where((s) => s['result'] != 'skipped')
          .map((s) => s['place'] as String)
          .toList();
      var total = 0;
      for (var i = 1; i < ids.length; i++) {
        total += transition(t, ids[i - 1], ids[i])?['meters'] as int? ?? 0;
      }
      return total;
    }

    if (t['branch'] != null) return length(stops);
    final variants = (t['snapshot']['branches'] as List).map((id) {
      final planned = [...stops]..insert(2, {'place': id, 'result': 'waiting'});
      return length(planned);
    }).toList()..sort();
    return variants.first;
  }

  Map<String, int> replacementMetrics(Map<String, dynamic> t) {
    final preview = copyMap(t);
    final stop = preview['stops'][preview['index']];
    stop['place'] = preview['snapshot']['alternative'];
    stop['replacementDelta'] = {'minutes': 10};
    return tripMetrics(preview);
  }

  int elapsedMinutes(Map<String, dynamic> t) {
    final end = DateTime.parse(
      t['ended'] ?? t['pausedAt'] ?? DateTime.now().toUtc().toIso8601String(),
    );
    return ((end.difference(DateTime.parse(t['started'])).inSeconds -
                (t['pauseSeconds'] as int)) /
            60)
        .floor()
        .clamp(0, 100000);
  }

  int visitedCount(Map<String, dynamic> t) =>
      (t['stops'] as List).where((p) => p['result'] == 'visited').length;
  int skippedCount(Map<String, dynamic> t) =>
      (t['stops'] as List).where((p) => p['result'] == 'skipped').length;
}
