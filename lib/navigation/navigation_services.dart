import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:sembast/sembast.dart';
import 'navigation_model.dart';

abstract class NavigationLocationSource {
  Future<void> ensureReady({required bool requestPermission});
  Stream<NavigationFix> watch();
}

class DeviceLocationSource implements NavigationLocationSource {
  @override
  Future<void> ensureReady({required bool requestPermission}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(LocationIssue.servicesOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(LocationIssue.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(LocationIssue.denied);
    }
    if (permission == LocationPermission.unableToDetermine) {
      throw const LocationFailure(LocationIssue.unavailable);
    }
  }

  NavigationFix convert(Position p) => NavigationFix(
    LatLng(p.latitude, p.longitude),
    accuracy: p.accuracy,
    timestamp: p.timestamp,
    heading: p.heading >= 0 ? p.heading : null,
  );
  @override
  Stream<NavigationFix> watch() async* {
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).map(convert);
  }
}

abstract class FootRoutingService {
  Future<FootRoute> route(LatLng origin, LatLng destination);
  void close();
}

class OsrmFootRoutingService implements FootRoutingService {
  final http.Client _client;
  static const host = 'routing.openstreetmap.de';
  DateTime? _nextRequest;
  bool _closed = false;
  OsrmFootRoutingService({http.Client? client})
    : _client = client ?? http.Client();
  @override
  Future<FootRoute> route(LatLng origin, LatLng destination) async {
    if (!validPoint(origin) || !validPoint(destination)) {
      throw const RoutingFailure(RouteIssue.noRoute);
    }
    // FOSSGIS: at most one request per second. Controller uses a much longer interval.
    final now = DateTime.now();
    final slot = _nextRequest != null && _nextRequest!.isAfter(now)
        ? _nextRequest!
        : now;
    _nextRequest = slot.add(const Duration(seconds: 1));
    if (slot.isAfter(now)) {
      await Future<void>.delayed(slot.difference(now));
    }
    if (_closed) throw const RoutingFailure(RouteIssue.network);
    final uri = Uri.https(
      host,
      '/routed-foot/route/v1/foot/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}',
      {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'true',
        'alternatives': 'false',
      },
    );
    try {
      final response = await _client
          .get(
            uri,
            headers: kIsWeb
                ? {}
                : {
                    'User-Agent':
                        'Tripavela/1.0 (Flutter walking prototype)',
                  },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const RoutingFailure(RouteIssue.network);
      }
      final result = FootRoute.fromOsrm(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      if (metersBetween(result.points.first, origin) > 250 ||
          metersBetween(result.points.last, destination) > 250) {
        throw const RoutingFailure(RouteIssue.noRoute);
      }
      return result;
    } on RoutingFailure {
      rethrow;
    } catch (_) {
      throw const RoutingFailure(RouteIssue.network);
    }
  }

  @override
  void close() {
    _closed = true;
    _client.close();
  }
}

abstract class NavigationCache {
  Future<FootRoute?> load(String destinationId, LatLng destination);
  Future<void> save(String destinationId, LatLng destination, FootRoute route);
}

final navigationCacheStore = stringMapStoreFactory.store('navigation');

class SembastNavigationCache implements NavigationCache {
  final Database db;
  final String tripId;
  SembastNavigationCache(this.db, this.tripId);
  @override
  Future<FootRoute?> load(String destinationId, LatLng destination) async {
    try {
      final json = await navigationCacheStore.record(tripId).get(db);
      if (json == null ||
          json['destinationId'] != destinationId ||
          json['lat'] != destination.latitude ||
          json['lon'] != destination.longitude) {
        return null;
      }
      return FootRoute.fromJson(
        Map<String, dynamic>.from(json['route'] as Map),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(
    String destinationId,
    LatLng destination,
    FootRoute route,
  ) => navigationCacheStore
      .record(tripId)
      .put(db, {
        'destinationId': destinationId,
        'lat': destination.latitude,
        'lon': destination.longitude,
        'route': route.toJson(),
      })
      .then((_) {});
}

class MemoryNavigationCache implements NavigationCache {
  String? id;
  LatLng? target;
  FootRoute? value;
  @override
  Future<FootRoute?> load(String destinationId, LatLng destination) async =>
      id == destinationId && target == destination ? value : null;
  @override
  Future<void> save(
    String destinationId,
    LatLng destination,
    FootRoute route,
  ) async {
    id = destinationId;
    target = destination;
    value = route;
  }
}

abstract class NavigationExamples {
  Future<FootRoute?> load(String destinationId);
}

class AssetNavigationExamples implements NavigationExamples {
  @override
  Future<FootRoute?> load(String destinationId) async {
    try {
      final json =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/data/navigation_example.json',
                ),
              )
              as Map<String, dynamic>;
      return json['destinationId'] == destinationId
          ? FootRoute.fromJson(Map<String, dynamic>.from(json['route'] as Map))
          : null;
    } catch (_) {
      return null;
    }
  }
}
