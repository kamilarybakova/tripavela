import 'dart:convert';

const travelSyncVersion = 'travelSyncVersion';
const currentTravelSyncVersion = 2;
const activeRevision = 'activeRevision';
const pendingTravelChanges = 'pendingTravelChanges';

const _preferenceKeys = {
  'pace',
  'distance',
  'interests',
  'missions',
  'diet',
  'noMissions',
  'noStairs',
  'stroller',
  'rest',
  'indoors',
};

bool _finished(Map trip) => const {
  'completed',
  'endedEarly',
  'cancelledBeforeVisit',
}.contains(trip['status']);

Map<String, dynamic> _history(Map<String, dynamic> state) => {
  for (final trip in (state['sessions'] as List).cast<Map>())
    if (_finished(trip))
      trip['id'] as String: {
        ...trip,
        'cityId': trip['cityId'] ?? trip['snapshot']['cityId'] ?? 'istanbul',
      },
};

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

Map<String, dynamic>? _activeWalk(Map<String, dynamic> state) {
  for (final trip in (state['sessions'] as List).cast<Map>()) {
    if (trip['status'] == 'active' || trip['status'] == 'paused') {
      return {
        ...Map<String, dynamic>.from(trip),
        'cityId': trip['cityId'] ?? trip['snapshot']['cityId'] ?? 'istanbul',
      };
    }
  }
  return null;
}

Map<String, dynamic> _byId(Object? records) => {
  for (final record in (records as List? ?? const []).cast<Map>())
    record['id'] as String: record,
};

Map<String, dynamic> _recordChanges(
  Map<String, dynamic> pending,
  Map<String, dynamic> before,
  Map<String, dynamic> after,
) => {
  ...pending,
  for (final id in before.keys)
    if (!after.containsKey(id)) id: null,
  for (final MapEntry(key: id, value: value) in after.entries)
    if (jsonEncode(before[id]) != jsonEncode(value)) id: value,
};

Map<String, dynamic> queueTravelChanges(
  Map<String, dynamic> before,
  Map<String, dynamic> after,
) {
  final pending = _map(before[pendingTravelChanges]);
  final preferences = _map(pending['preferences']);
  final favorites = _map(pending['favorites']);
  final oldPrefs = _map(before['preferences']);
  final newPrefs = _map(after['preferences']);
  for (final key in _preferenceKeys) {
    if (jsonEncode(oldPrefs[key]) != jsonEncode(newPrefs[key])) {
      preferences[key] = newPrefs[key];
    }
  }
  final oldFavorites = (before['favorites'] as List).cast<String>().toSet();
  final newFavorites = (after['favorites'] as List).cast<String>().toSet();
  for (final id in oldFavorites.difference(newFavorites)) {
    favorites[id] = false;
  }
  for (final id in newFavorites.difference(oldFavorites)) {
    favorites[id] = true;
  }
  final history = _recordChanges(
    _map(pending['history']),
    _history(before),
    _history(after),
  );
  final visits = _recordChanges(
    _map(pending['visits']),
    _byId(before['visits']),
    _byId(after['visits']),
  );
  final plans = _recordChanges(
    _map(pending['plans']),
    _byId(before['travelPlans']),
    _byId(after['travelPlans']),
  );
  final oldActive = _activeWalk(before);
  final newActive = _activeWalk(after);
  final activeChanged = jsonEncode(oldActive) != jsonEncode(newActive);
  final active = activeChanged
      ? {
          'revision':
              _map(pending['active'])['revision'] ??
              before[activeRevision] ??
              0,
          'sessionId': (newActive ?? oldActive)!['id'],
          'walk': newActive,
        }
      : pending['active'];
  final draftChanged =
      jsonEncode(before['tripDraft']) != jsonEncode(after['tripDraft']);
  return {
    if (preferences.isNotEmpty) 'preferences': preferences,
    if (favorites.isNotEmpty) 'favorites': favorites,
    if (history.isNotEmpty) 'history': history,
    if (visits.isNotEmpty) 'visits': visits,
    if (plans.isNotEmpty) 'plans': plans,
    'active': ?active,
    if (draftChanged || pending.containsKey('tripDraft'))
      'tripDraft': draftChanged ? after['tripDraft'] : pending['tripDraft'],
  };
}

Map<String, dynamic> prepareTravelSync(
  Map<String, dynamic> local,
  Map<String, dynamic> defaults,
) {
  if (local[travelSyncVersion] == currentTravelSyncVersion) return local;
  final baseline = local[travelSyncVersion] == 1
      ? {
          ...local,
          'sessions': (local['sessions'] as List)
              .cast<Map>()
              .where(_finished)
              .toList(),
          'visits': [],
          'travelPlans': [],
          'tripDraft': null,
        }
      : {...defaults, pendingTravelChanges: local[pendingTravelChanges]};
  return {
    ...local,
    travelSyncVersion: currentTravelSyncVersion,
    pendingTravelChanges: queueTravelChanges(baseline, local),
  };
}

Map<String, dynamic> applyTravelData(
  Map<String, dynamic> local,
  Map<String, dynamic> remote,
) {
  final sessions = [
    ...(remote['history'] as List).cast<Map<String, dynamic>>(),
    if (remote['active'] case final Map<String, dynamic> active) active,
  ];
  return {
    ...local,
    'preferences': {
      ..._map(local['preferences']),
      for (final entry in _map(remote['preferences']).entries)
        if (_preferenceKeys.contains(entry.key)) entry.key: entry.value,
    },
    'favorites': List<String>.from(remote['favorites'] as List),
    'sessions': sessions,
    'visits': List<Map<String, dynamic>>.from(remote['visits'] as List),
    'travelPlans': List<Map<String, dynamic>>.from(remote['plans'] as List),
    'tripDraft': remote['tripDraft'],
    activeRevision: remote[activeRevision] as int,
    travelSyncVersion: currentTravelSyncVersion,
    pendingTravelChanges: <String, dynamic>{},
  };
}
