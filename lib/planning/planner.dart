import 'dart:math';

String planTime(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

class TripBrief {
  final String vibe, zone, hotel, arrivalAt, pace, cityId;
  final DateTime date;
  final int days, arrival, departure;
  final bool tickets;
  final List<String> interests;
  TripBrief({
    required this.date,
    this.days = 4,
    this.cityId = 'istanbul',
    this.vibe = 'classic',
    this.zone = 'old',
    this.hotel = '',
    this.arrivalAt = 'hotel',
    this.arrival = 14 * 60,
    this.departure = 18 * 60,
    this.pace = 'balanced',
    this.tickets = false,
    this.interests = const ['История', 'Еда'],
  });
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'cityId': cityId,
    'days': days,
    'vibe': vibe,
    'zone': zone,
    'hotel': hotel,
    'arrivalAt': arrivalAt,
    'arrival': arrival,
    'departure': departure,
    'pace': pace,
    'tickets': tickets,
    'interests': interests,
  };
  factory TripBrief.fromJson(Map<String, dynamic> m) => TripBrief(
    date: DateTime.parse(m['date']),
    cityId: m['cityId'] ?? 'istanbul',
    days: m['days'],
    vibe: m['vibe'],
    zone: m['zone'],
    hotel: m['hotel'],
    arrivalAt: m['arrivalAt'],
    arrival: m['arrival'],
    departure: m['departure'],
    pace: m['pace'],
    tickets: m['tickets'],
    interests: List<String>.from(m['interests']),
  );
}

class PlanPoi {
  final Map<String, dynamic> data;
  PlanPoi(this.data);
  String get id => data['id'];
  String get zone => data['zone'];
  String get name => data['name'];
  String get area => data['area'];
  String get kind => data['kind'];
  int get minutes => data['minutes'];
  int get opens => data['open'];
  int get closes => data['close'];
  bool get paid => data['paid'];
  double get lat => (data['lat'] as num).toDouble();
  double get lon => (data['lon'] as num).toDouble();
  bool openOn(DateTime date) =>
      !(data['closedWeekdays'] as List).contains(date.weekday);
}

class PlanningCatalog {
  final Map<String, dynamic> data;
  late final Map<String, PlanPoi> pois = {
    for (final m in data['pois'])
      m['id']: PlanPoi(Map<String, dynamic>.from(m)),
  };
  PlanningCatalog(this.data);
  String get cityId => data['cityId'] ?? 'istanbul';
  List<Map<String, dynamic>> get zones => [
    for (final z in data['zones']) Map<String, dynamic>.from(z),
  ];
  Map<String, dynamic> zone(String id) =>
      zones.firstWhere((z) => z['id'] == id);
  List<Map<String, dynamic>> get themes => [
    for (final t in data['themes']) Map<String, dynamic>.from(t),
  ];
  List<String> local(String zone) => List<String>.from(data['local'][zone]);
}

class ScheduledStop {
  final PlanPoi poi;
  final int start, end, travel, walkMeters;
  final String transport;
  final bool done;
  ScheduledStop({
    required this.poi,
    required this.start,
    required this.end,
    required this.travel,
    required this.walkMeters,
    required this.transport,
    this.done = false,
  });
  Map<String, dynamic> toJson() => {
    'poi': poi.data,
    'start': start,
    'end': end,
    'travel': travel,
    'walkMeters': walkMeters,
    'transport': transport,
    'done': done,
  };
  factory ScheduledStop.fromJson(Map<String, dynamic> m) => ScheduledStop(
    poi: PlanPoi(Map<String, dynamic>.from(m['poi'])),
    start: m['start'],
    end: m['end'],
    travel: m['travel'],
    walkMeters: m['walkMeters'],
    transport: m['transport'],
    done: m['done'] == true,
  );
}

class PlannedDay {
  final int index,
      availableFrom,
      availableUntil,
      returnMinutes,
      returnAt,
      returnWalkMeters;
  final DateTime date;
  final String title, subtitle;
  final List<ScheduledStop> stops;
  final List<String> notes;
  final bool started;
  PlannedDay({
    required this.index,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.stops,
    required this.availableFrom,
    required this.availableUntil,
    required this.returnMinutes,
    required this.returnAt,
    required this.returnWalkMeters,
    this.notes = const [],
    this.started = false,
  });
  int get walkMeters =>
      stops.fold(0, (n, s) => n + s.walkMeters) + returnWalkMeters;
  int get visited => stops.where((s) => s.done).length;
  Map<String, dynamic> toJson() => {
    'index': index,
    'date': date.toIso8601String(),
    'title': title,
    'subtitle': subtitle,
    'stops': stops.map((s) => s.toJson()).toList(),
    'availableFrom': availableFrom,
    'availableUntil': availableUntil,
    'returnMinutes': returnMinutes,
    'returnWalkMeters': returnWalkMeters,
    'returnAt': returnAt,
    'notes': notes,
    'started': started,
  };
  factory PlannedDay.fromJson(Map<String, dynamic> m) => PlannedDay(
    index: m['index'],
    date: DateTime.parse(m['date']),
    title: m['title'],
    subtitle: m['subtitle'],
    stops: [
      for (final s in m['stops'])
        ScheduledStop.fromJson(Map<String, dynamic>.from(s)),
    ],
    availableFrom: m['availableFrom'],
    availableUntil: m['availableUntil'],
    returnMinutes: m['returnMinutes'],
    returnWalkMeters: m['returnWalkMeters'],
    returnAt: m['returnAt'],
    notes: List<String>.from(m['notes']),
    started: m['started'] == true,
  );
}

class TravelPlan {
  final String id;
  final TripBrief brief;
  final List<PlannedDay> days;
  TravelPlan({required this.id, required this.brief, required this.days});
  Map<String, dynamic> toJson() => {
    'id': id,
    'brief': brief.toJson(),
    'days': days.map((d) => d.toJson()).toList(),
  };
  factory TravelPlan.fromJson(Map<String, dynamic> m) => TravelPlan(
    id: m['id'],
    brief: TripBrief.fromJson(Map<String, dynamic>.from(m['brief'])),
    days: [
      for (final d in m['days'])
        PlannedDay.fromJson(Map<String, dynamic>.from(d)),
    ],
  );
}

class _Leg {
  final int minutes, meters;
  final String text;
  const _Leg(this.minutes, this.meters, this.text);
}

class TripPlanner {
  final PlanningCatalog catalog;
  TripPlanner(this.catalog);
  double _distance(double a, double b, double c, double d) {
    const rad = pi / 180;
    final h =
        pow(sin((c - a) * rad / 2), 2) +
        cos(a * rad) * cos(c * rad) * pow(sin((d - b) * rad / 2), 2);
    return 6371000 * 2 * asin(sqrt(h.clamp(0, 1)));
  }

  _Leg _leg(
    String fromZone,
    double lat,
    double lon,
    PlanPoi to,
    TripBrief brief,
  ) {
    final meters = (_distance(lat, lon, to.lat, to.lon) * 1.3).round();
    final bridgeNeighbours =
        catalog.cityId == 'istanbul' &&
        {fromZone, to.zone}.containsAll({'old', 'pera'});
    if ((fromZone == to.zone || bridgeNeighbours) && meters < 2400) {
      return _Leg(
        max(5, (meters / (brief.pace == 'calm' ? 55 : 65)).ceil()),
        meters,
        'Пешком',
      );
    }
    if (catalog.cityId != 'istanbul') {
      // Distances between districts require transit; Dubai never assumes a cross-city walk.
      final road = meters / 1000;
      final minutes = (20 + road * (catalog.cityId == 'dubai' ? 2.5 : 3))
          .ceil()
          .clamp(25, 100);
      return _Leg(
        minutes,
        700,
        catalog.cityId == 'dubai'
            ? 'Метро / автобус + пешком · пересадки уточните в картах'
            : 'Городской автобус + пешком · проверьте маршрут',
      );
    }
    if (fromZone != to.zone && (fromZone == 'asia' || to.zone == 'asia')) {
      return const _Leg(
        65,
        900,
        'Паром / метро + пешком · с запасом на ожидание',
      );
    }
    if ({fromZone, to.zone}.contains('balat')) {
      return const _Leg(45, 800, 'Трамвай / автобус + пешком');
    }
    if (fromZone == to.zone) return const _Leg(30, 700, 'Автобус + пешком');
    return const _Leg(40, 800, 'Трамвай / автобус + пешком');
  }

  _Leg _return(PlanPoi from, TripBrief brief) {
    final z = catalog.zone(brief.zone);
    final pseudo = PlanPoi({
      'id': 'hotel',
      'zone': brief.zone,
      'lat': z['lat'],
      'lon': z['lon'],
    });
    return _leg(from.zone, from.lat, from.lon, pseudo, brief);
  }

  TravelPlan generate(TripBrief brief, {required String id}) {
    if (brief.days < 2 ||
        brief.days > 7 ||
        brief.arrival < 0 ||
        brief.arrival >= 1440 ||
        brief.departure < 0 ||
        brief.departure >= 1440 ||
        brief.cityId != catalog.cityId ||
        !catalog.zones.any((z) => z['id'] == brief.zone)) {
      throw ArgumentError('Некорректные условия поездки');
    }
    final used = <String>{};
    final themes = [...catalog.themes];
    final preferenceOrder = switch (brief.vibe) {
      'food' => ['food', 'balat', 'art', 'classic', 'sea'],
      'art' => ['art', 'balat', 'classic', 'food', 'sea'],
      'sea' => ['sea', 'food', 'balat', 'art', 'classic'],
      _ => ['classic', 'art', 'sea', 'food', 'balat'],
    };
    int score(Map<String, dynamic> t) =>
        (t['id'] == 'shopping' && brief.interests.contains('Шопинг')
            ? 140
            : 0) +
        (t['id'] == brief.vibe ? 100 : 0) +
        (preferenceOrder.contains(t['id'])
                ? 5 - preferenceOrder.indexOf(t['id'])
                : 0) *
            4 +
        (t['tags'] as List).where(brief.interests.contains).length * 3;
    if (!brief.interests.contains('Шопинг')) {
      themes.removeWhere((t) => t['id'] == 'shopping');
    }
    themes.sort((a, b) {
      final s = score(b).compareTo(score(a));
      return s != 0 ? s : (a['id'] as String).compareTo(b['id']);
    });
    final days = <PlannedDay>[];
    final usedThemes = <String>{};
    final exploredZones = <String>{};
    for (var i = 0; i < brief.days; i++) {
      final first = i == 0, last = i == brief.days - 1;
      // Add calendar days, avoiding UTC/DST conversions for local visit dates.
      final date = DateTime(
        brief.date.year,
        brief.date.month,
        brief.date.day + i,
      );
      final ready = first
          ? brief.arrival + (brief.arrivalAt == 'hotel' ? 30 : 180)
          : 9 * 60 + 30;
      final start = max(9 * 60, ready);
      final limit = last
          ? max(0, brief.departure - 30)
          : (first ? 21 * 60 : 19 * 60);
      final local = last
          ? List<String>.from(catalog.data['departure'][brief.zone])
          : catalog.local(brief.zone);
      Map<String, dynamic>? theme;
      if (!first && !last) {
        final viable = themes
            .where(
              (t) => (t['pois'] as List).any((id) {
                final p = catalog.pois[id]!;
                return !used.contains(id) &&
                    p.openOn(date) &&
                    (brief.interests.contains('Шопинг') || p.kind != 'Шопинг');
              }),
            )
            .toList();
        final fresh = viable
            .where(
              (t) =>
                  !usedThemes.contains(t['id']) &&
                  (t['pois'] as List).any(
                    (id) => !exploredZones.contains(catalog.pois[id]!.zone),
                  ),
            )
            .toList();
        final unused = viable
            .where((t) => !usedThemes.contains(t['id']))
            .toList();
        theme =
            (fresh.isNotEmpty
                    ? fresh
                    : unused.isNotEmpty
                    ? unused
                    : viable.isNotEmpty
                    ? viable
                    : themes)
                .first;
        usedThemes.add(theme['id']);
      }
      final candidates = theme == null
          ? local
          : List<String>.from(theme['pois']);
      final notes = <String>[];
      if (first) {
        notes.add(
          brief.arrivalAt == 'hotel'
              ? 'После указанного времени оставлено 30 минут на заселение и отдых.'
              : 'Заложено 3 часа от прилёта до готовности гулять: выход из аэропорта, дорога и заселение. Это примерная оценка.',
        );
      }
      if (last) {
        notes.add(
          'Вернёмся в район отеля не позже ${planTime(limit)}. До выезда останется 30 минут; дорога в аэропорт сюда не входит.',
        );
      }
      final stops = <ScheduledStop>[];
      var cursor = start;
      final home = catalog.zone(brief.zone);
      var fromZone = brief.zone;
      var lat = (home['lat'] as num).toDouble(),
          lon = (home['lon'] as num).toDouble();
      final count = first
          ? (brief.pace == 'active' ? 3 : 2)
          : last
          ? (limit - start >= 300
                ? (brief.pace == 'calm'
                      ? 2
                      : brief.pace == 'active'
                      ? 4
                      : 3)
                : 2)
          : (brief.pace == 'calm'
                ? 3
                : brief.pace == 'active'
                ? 5
                : 4);
      final walkLimit = brief.pace == 'calm' ? 4500 : 8500;
      var walk = 0;
      // Interest ordering only within neighbouring candidates, not across the city.
      final ordered = [...candidates];
      if (first) {
        final desiredKind = switch (brief.vibe) {
          'food' => 'Еда',
          'art' => 'Искусство',
          'sea' => 'Море',
          _ => '',
        };
        final matching = ordered.indexWhere(
          (id) => catalog.pois[id]!.kind == desiredKind,
        );
        if (matching > 1) ordered.insert(1, ordered.removeAt(matching));
      }
      if (brief.interests.contains('Шопинг')) {
        final shop = ordered.indexWhere(
          (id) => catalog.pois[id]!.kind == 'Шопинг',
        );
        if (shop > 1) ordered.insert(1, ordered.removeAt(shop));
      }
      if (theme != null && brief.interests.contains('Еда')) {
        final food = ordered.indexWhere(
          (id) => catalog.pois[id]!.kind == 'Еда',
        );
        if (food >= 3) ordered.insert(2, ordered.removeAt(food));
      }
      for (final pid in ordered) {
        if (stops.length >= count) break;
        final poi = catalog.pois[pid]!;
        if (used.contains(pid)) continue;
        if (poi.kind == 'Шопинг' && !brief.interests.contains('Шопинг')) {
          continue;
        }
        if (poi.paid && (!brief.tickets || stops.any((s) => s.poi.paid))) {
          continue;
        }
        if (!poi.openOn(date)) {
          notes.add('${poi.name}: обычный выходной, выбрано другое место.');
          continue;
        }
        final leg = _leg(fromZone, lat, lon, poi, brief);
        final at = max(cursor + leg.minutes, poi.opens);
        // Don't spend a short arrival day waiting hours for a venue to open.
        if (at - (cursor + leg.minutes) > 45) continue;
        final end = at + poi.minutes;
        final back = _return(poi, brief);
        if (end > poi.closes ||
            end + back.minutes > limit ||
            walk + leg.meters + back.meters > walkLimit) {
          continue;
        }
        stops.add(
          ScheduledStop(
            poi: poi,
            start: at,
            end: end,
            travel: leg.minutes,
            walkMeters: leg.meters,
            transport: leg.text,
          ),
        );
        used.add(pid);
        walk += leg.meters;
        cursor = end + (brief.pace == 'calm' ? 25 : 15);
        fromZone = poi.zone;
        lat = poi.lat;
        lon = poi.lon;
        // A proper break is included, rather than scheduling continuous sightseeing.
        if (stops.length == 2 && !first && !last) cursor += 45;
      }
      if (!first && !last) exploredZones.addAll(stops.map((s) => s.poi.zone));
      final back = stops.isEmpty
          ? const _Leg(0, 0, '')
          : _return(stops.last.poi, brief);
      final backAt = stops.isEmpty
          ? min(start, limit)
          : stops.last.end + back.minutes;
      if (last && stops.isNotEmpty && limit - backAt >= 90) {
        notes.add(
          'После ${planTime(backAt)} — свободное время и сборы до выезда в ${planTime(brief.departure)}. Дальних переездов на этот день нет.',
        );
      }
      final areas = stops.map((s) => s.poi.area).toSet().join(' → ');
      days.add(
        PlannedDay(
          index: i,
          date: date,
          title: first
              ? 'Мягкое знакомство с городом'
              : last
              ? 'Последний день без суеты'
              : theme!['title'],
          subtitle: areas.isEmpty ? 'Дорога, заселение и отдых' : areas,
          stops: stops,
          availableFrom: start,
          availableUntil: limit,
          returnMinutes: back.minutes,
          returnWalkMeters: back.meters,
          returnAt: backAt,
          notes: [
            if (stops.isEmpty)
              (first
                  ? 'На прогулку не остаётся комфортного окна. Сегодня — отдых, завтра начнём знакомство с городом.'
                  : 'До выезда лучше оставить время на сборы. Новых остановок не добавляем.'),
            ...notes,
            if (!first && !last && stops.length > 2)
              'Между второй и третьей остановкой оставлено 45 минут на обед и ещё время на паузы.',
          ],
        ),
      );
    }
    return TravelPlan(id: id, brief: brief, days: days);
  }
}
