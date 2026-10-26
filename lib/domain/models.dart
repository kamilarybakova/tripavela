import 'dart:convert';

Map<String, dynamic> copyMap(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

enum TripStatus { active, paused, completed, endedEarly, cancelledBeforeVisit }

enum StopResult { waiting, current, visited, skipped, replaced }

class Place {
  final Map<String, dynamic> data;
  Place(this.data);
  String get id => data['id'];
  String get name => data['name'];
  String get category => data['category'];
  String get address => data['address'];
  String get story => data['story'];
  String get image => data['image'] ?? '';
  String get notice => data['notice'];
  String get tryIt => data['tryIt'];
  String get mission => data['mission'];
  String get missionType => data['missionType'];
  String get missionCategory => data['missionCategory'] ?? missionType;
  int get missionMinutes => data['missionMinutes'] ?? 5;
  bool get missionPurchaseOptional => data['missionPurchaseOptional'] == true;
  String get missionFreeAlternative => data['missionFreeAlternative'] ?? '';

  String get hours => data['hours'] ?? '';
  String get access => data['access'] ?? '';
  String get cost => data['cost'] ?? '';
  String get booking => data['booking'] ?? '';
  int get visitMinutes => data['visitMinutes'] ?? 20;
  List<String> get sources => List<String>.from(data['sources'] ?? []);
}

class WalkRoute {
  final Map<String, dynamic> data;
  WalkRoute(this.data);
  String get id => data['id'];
  String get name => data['name'];
  String get description => data['description'];
  String get theme => data['theme'];
  String get mood => data['mood'];
  String get image => data['image'];
  int get minutes => data['minutes'];
  int get maxMinutes => data['maxMinutes'] ?? minutes + 25;
  int get meters => data['meters'];
  int get requiredMin => data['requiredMin'];
  int get requiredMax => data['requiredMax'];
  int get foodMin => data['foodMin'];
  int get foodMax => data['foodMax'];
  String get stairs => data['stairs'];
  int get lastStart => data['lastStart'];
  int get earliestStart => data['earliestStart'] ?? 0;
  List<String> get places => List<String>.from(data['places']);
  List<String> get branches => List<String>.from(data['branches']);
  String get alternative => data['alternative'];
  bool get family => data['family'];
  bool get indoor => data['indoor'];
  int duration(Map<String, dynamic> filters) =>
      maxMinutes + (filters['pace'] == 'calm' ? 25 : 0);
  bool matches(Map<String, dynamic> f, {bool late = false}) {
    if (duration(f) > (f['time'] ?? 360)) return false;
    if (meters + 400 > (f['distance'] ?? 100000)) return false;
    if (requiredMax + (f['budget'] == 0 ? 0 : foodMax) >
        (f['budget'] ?? 1000000)) {
      return false;
    }
    if ((f['noStairs'] == true || f['stroller'] == true) && stairs != 'no') {
      return false;
    }
    if (f['rest'] == true && data['rest'] != true) return false;
    if (f['indoors'] == true && !indoor) return false;
    if (f['company'] == 'С детьми' && !family) return false;
    final hour = late ? 22 : (f['startHour'] ?? 10) as int;
    if (hour < earliestStart || hour > lastStart) return false;
    final date = DateTime.tryParse(f['startDate'] as String? ?? '');
    if (date != null &&
        (data['closedWeekdays'] as List? ?? []).contains(date.weekday)) {
      return false;
    }
    final diet = f['diet'] ?? 'Без предпочтений';
    if (diet != 'Без предпочтений' && !(data['diets'] as List).contains(diet)) {
      return false;
    }
    return true;
  }

  int score(Map<String, dynamic> f) =>
      (f['mood'] == mood ? 5 : 0) +
      ((f['interests'] as List? ?? []).contains(theme) ? 3 : 0) +
      (f['company'] == 'Вдвоём' && theme == 'Совместный досуг' ? 2 : 0);
}

class RouteSuggestion {
  final WalkRoute route;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> changes;
  RouteSuggestion(this.route, this.filters, this.changes);
}

/// Exact matching stays strict. These proposals require explicit acceptance.
List<RouteSuggestion> suggestRoutes(
  List<WalkRoute> routes,
  Map<String, dynamic> requested, {
  bool late = false,
}) {
  final ranked = <(int, RouteSuggestion)>[];
  for (final route in routes) {
    final f = copyMap(requested);
    var penalty = 0;
    void change(String key, dynamic value, int weight) {
      if (f[key] == value) return;
      f[key] = value;
      penalty += weight;
    }

    int optionAtLeast(int needed, List<int> options) =>
        options.firstWhere((value) => value >= needed, orElse: () => needed);

    if (route.duration(f) > (f['time'] as int)) {
      change('time', optionAtLeast(route.duration(f), [60, 120, 240, 360]), 20);
    }
    if (route.meters + 400 > (f['distance'] as int)) {
      change(
        'distance',
        optionAtLeast(route.meters + 400, [2000, 4000, 7000, 100000]),
        15,
      );
    }
    final cost = route.requiredMax + (f['budget'] == 0 ? 0 : route.foodMax);
    if (cost > (f['budget'] as int)) {
      change('budget', optionAtLeast(cost, [0, 40000, 80000, 1000000]), 25);
    }
    if (route.stairs != 'no') {
      if (f['noStairs'] == true) change('noStairs', false, 1000);
      if (f['stroller'] == true) change('stroller', false, 1000);
    }
    if (f['indoors'] == true && !route.indoor) change('indoors', false, 1000);
    if (f['rest'] == true && route.data['rest'] != true) {
      change('rest', false, 1000);
    }
    if (f['company'] == 'С детьми' && !route.family) {
      change('company', 'Один / одна', 1000);
    }
    final diet = f['diet'];
    if (diet != 'Без предпочтений' &&
        !(route.data['diets'] as List).contains(diet)) {
      change('diet', 'Без предпочтений', 1000);
    }
    final hour = late ? 22 : f['startHour'] as int;
    var date =
        DateTime.tryParse(f['startDate'] as String? ?? '') ?? DateTime.now();
    if (hour > route.lastStart) {
      date = date.add(const Duration(days: 1));
      change(
        'startHour',
        route.earliestStart > 10 ? route.earliestStart : 10,
        10,
      );
      change('startMinute', 0, 0);
    } else if (hour < route.earliestStart) {
      change('startHour', route.earliestStart, 10);
      change('startMinute', 0, 0);
    }
    final closed = route.data['closedWeekdays'] as List? ?? [];
    if (closed.length >= 7) continue;
    while (closed.contains(date.weekday)) {
      date = date.add(const Duration(days: 1));
    }
    final dateText =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    change('startDate', dateText, 10);
    final changes = <String, dynamic>{
      for (final key in f.keys)
        if (f[key] != requested[key] &&
            !['interests', 'missions'].contains(key))
          key: f[key],
    };
    if (route.matches(f)) {
      ranked.add((penalty, RouteSuggestion(route, f, changes)));
    }
  }
  ranked.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    if (c != 0) return c;
    final score = b.$2.route
        .score(requested)
        .compareTo(a.$2.route.score(requested));
    return score == 0 ? a.$2.route.id.compareTo(b.$2.route.id) : score;
  });
  if (ranked.isEmpty) return [];
  final minimumConstraintChanges = ranked.first.$1 ~/ 1000;
  return ranked
      .where((e) => e.$1 ~/ 1000 == minimumConstraintChanges)
      .take(3)
      .map((e) => e.$2)
      .toList();
}

Map<String, dynamic> defaultFilters() => {
  'mood': 'Почувствовать город',
  'interests': <String>[],
  'company': 'Один / одна',
  'age': '6–11 лет',
  'time': 240,
  'budget': 80000,
  'distance': 7000,
  'pace': 'normal',
  'noStairs': false,
  'stroller': false,
  'rest': false,
  'indoors': false,
  'diet': 'Без предпочтений',
  'missions': ['Наблюдать', 'Пробовать', 'Общаться'],
  'noMissions': false,
  'startHour': 10,
  'startDate': '2026-10-22',
};

List<WalkRoute> matchRoutes(
  List<WalkRoute> routes,
  Map<String, dynamic> f, {
  bool late = false,
}) {
  final result = routes.where((r) => r.matches(f, late: late)).toList();
  result.sort((a, b) {
    final score = b.score(f).compareTo(a.score(f));
    return score == 0 ? a.id.compareTo(b.id) : score;
  });
  return result;
}
