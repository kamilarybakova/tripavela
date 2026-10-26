import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'database.dart';
import '../l10n/copy.dart';
import '../planning/planner.dart';

final storeProvider = ChangeNotifierProvider<TravelStore>(
  (ref) => TravelStore(),
);
final _record = stringMapStoreFactory.store('app').record('state');
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
  'demo': <String, dynamic>{},
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
  final Map<String, Map<String, dynamic>> cities = {};
  final Map<String, PlanningCatalog> planningCatalogs = {};
  String get cityId => state['cityId'] as String? ?? 'istanbul';
  Map<String, dynamic> get cityData =>
      cities[cityId] ?? cities['istanbul'] ?? {};
  Map<String, dynamic> cityFor(String id) => cities[id] ?? cities['istanbul']!;
  String cityForPlace(String id) => places[id]?.data['cityId'] ?? 'istanbul';
  String cityNameForPlace(String id) => cityFor(cityForPlace(id))['name'];
  PlanningCatalog planningFor(String id) => planningCatalogs[id]!;
  Future<void> selectCity(String id) => change((s) {
    if (!cities.containsKey(id)) throw ArgumentError('Неизвестный город');
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
  List<WalkRoute> get routes => allRoutes
      .where(
        (r) =>
            (r.data['cityId'] ?? 'istanbul') == cityId &&
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
  Map<String, dynamic> get demo => Map<String, dynamic>.from(state['demo']);
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
      final saved = await _record.get(db!);
      if (saved != null) {
        try {
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
            throw const FormatException();
          }
          state = {...initialState(), ...copyMap(saved)};
        } catch (_) {
          recovered = true;
          await stringMapStoreFactory
              .store('recovery')
              .record(DateTime.now().toIso8601String())
              .put(db!, saved);
          state = {
            ...initialState(),
            'visits': saved['visits'] is List ? saved['visits'] : [],
          };
        }
      }
      if (!cities.containsKey(cityId)) state['cityId'] = 'istanbul';
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
      if (photosUpdated) await _record.put(db!, state);
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

  Future<void> change(
    void Function(Map<String, dynamic>) action, {
    bool allowError = false,
    String? event,
  }) async {
    if (busy) throw StateError(copy.errorBusy);
    busy = true;
    notifyListeners();
    try {
      if (demo['saveError'] == true && !allowError) {
        throw StateError(copy.errorSaving);
      }
      final next = copyMap(state);
      action(next);
      if (event != null) {
        (next['events'] as List).add({
          'name': event,
          'at': DateTime.now().toUtc().toIso8601String(),
        });
        if ((next['events'] as List).length > 200) {
          (next['events'] as List).removeAt(0);
        }
      }
      await db!.transaction((txn) async {
        await _record.put(txn, next);
      });
      state = next;
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
        if (place != t['snapshot']['alternative'] ||
            demo['noAlternatives'] == true) {
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
    t['status'] = 'paused';
    t['pausedAt'] = DateTime.now().toUtc().toIso8601String();
  }, event: 'trip_paused');
  @override
  Future<void> resume(String id) => mutateTrip(id, (t, s) {
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
    await deletePhotoFile(path);
  }

  @override
  Future<void> setting(String key, dynamic value) async {
    await change((s) => s['settings'][key] = value, allowError: true);
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
    }, allowError: true);
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
        await deletePhotoFile(path);
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
