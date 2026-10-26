import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

enum LocationIssue { denied, deniedForever, servicesOff, timeout, unavailable }

enum RouteIssue { network, noRoute, tooFar, poorAccuracy, notReady }

class LocationFailure implements Exception {
  final LocationIssue issue;
  const LocationFailure(this.issue);
}

class RoutingFailure implements Exception {
  final RouteIssue issue;
  const RoutingFailure(this.issue);
}

class NavigationFix {
  final LatLng point;
  final double accuracy;
  final DateTime timestamp;
  final double? heading;
  const NavigationFix(
    this.point, {
    required this.accuracy,
    required this.timestamp,
    this.heading,
  });
}

bool validPoint(LatLng p) =>
    p.latitude.isFinite &&
    p.longitude.isFinite &&
    p.latitude.abs() <= 90 &&
    p.longitude.abs() <= 180;
double metersBetween(LatLng a, LatLng b) =>
    const Distance().as(LengthUnit.Meter, a, b);

class FootRoute {
  final List<LatLng> points;
  final double meters, seconds;
  final DateTime createdAt;
  final bool includesFerry;
  FootRoute({
    required List<LatLng> points,
    required this.meters,
    required this.seconds,
    required this.createdAt,
    this.includesFerry = false,
  }) : points = List.unmodifiable(points) {
    if (points.length < 2 ||
        points.any((p) => !validPoint(p)) ||
        !meters.isFinite ||
        meters < 0 ||
        !seconds.isFinite ||
        seconds < 0) {
      throw const FormatException('Invalid foot route');
    }
  }
  Map<String, dynamic> toJson() => {
    'points': points.map((p) => [p.longitude, p.latitude]).toList(),
    'meters': meters,
    'seconds': seconds,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'includesFerry': includesFerry,
  };
  factory FootRoute.fromJson(Map<String, dynamic> json) => FootRoute(
    points: (json['points'] as List)
        .map((p) => LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()))
        .toList(),
    meters: (json['meters'] as num).toDouble(),
    seconds: (json['seconds'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt']),
    includesFerry: json['includesFerry'] == true,
  );
  factory FootRoute.fromOsrm(Map<String, dynamic> json) {
    if (json['code'] != 'Ok' || (json['routes'] as List? ?? []).isEmpty) {
      throw const RoutingFailure(RouteIssue.noRoute);
    }
    final route = json['routes'][0];
    final geometry = route['geometry'];
    if (geometry['type'] != 'LineString') {
      throw const FormatException('Invalid route geometry');
    }
    return FootRoute(
      points: (geometry['coordinates'] as List)
          .map(
            (p) => LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()),
          )
          .toList(),
      meters: (route['distance'] as num).toDouble(),
      seconds: (route['duration'] as num).toDouble(),
      createdAt: DateTime.now().toUtc(),
      includesFerry: (route['legs'] as List? ?? []).any(
        (leg) => (leg['steps'] as List? ?? []).any(
          (step) => step['mode'] == 'ferry',
        ),
      ),
    );
  }
}

class RouteProgress {
  final double remainingMeters, offRouteMeters;
  final LatLng snappedPoint;
  const RouteProgress(
    this.remainingMeters,
    this.offRouteMeters,
    this.snappedPoint,
  );
}

/// Project onto the nearest walking segment; never replace a missing route with a straight line.
RouteProgress progressOnRoute(LatLng position, FootRoute route) {
  final scaleX = 111320 * math.cos(position.latitude * math.pi / 180);
  const scaleY = 111320.0;
  double best = double.infinity, afterBest = 0, passed = 0, total = 0;
  var snapped = route.points.first;
  final lengths = <double>[];
  for (var i = 1; i < route.points.length; i++) {
    final d = metersBetween(route.points[i - 1], route.points[i]);
    lengths.add(d);
    total += d;
  }
  for (var i = 0; i < lengths.length; i++) {
    final a = route.points[i], b = route.points[i + 1];
    final ax = (a.longitude - position.longitude) * scaleX,
        ay = (a.latitude - position.latitude) * scaleY;
    final dx = (b.longitude - a.longitude) * scaleX,
        dy = (b.latitude - a.latitude) * scaleY;
    final denominator = dx * dx + dy * dy;
    final t = denominator == 0
        ? 0.0
        : (-(ax * dx + ay * dy) / denominator).clamp(0.0, 1.0);
    final distance = math.sqrt(
      math.pow(ax + t * dx, 2) + math.pow(ay + t * dy, 2),
    );
    if (distance < best) {
      best = distance;
      afterBest = passed + t * lengths[i];
      snapped = LatLng(
        a.latitude + t * (b.latitude - a.latitude),
        a.longitude + t * (b.longitude - a.longitude),
      );
    }
    passed += lengths[i];
  }
  return RouteProgress((total - afterBest).clamp(0.0, total), best, snapped);
}
