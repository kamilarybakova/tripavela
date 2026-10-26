import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'navigation_model.dart';
import 'navigation_services.dart';

class WalkNavigationController extends ChangeNotifier {
  final NavigationLocationSource location;
  final FootRoutingService routing;
  final NavigationCache cache;
  final NavigationExamples examples;
  String destinationId;
  LatLng destination;
  NavigationFix? fix;
  FootRoute? path;
  RouteProgress? progress;
  final List<LatLng> trail = [];
  LocationIssue? locationIssue;
  RouteIssue? routeIssue;
  bool locating = false,
      routingNow = false,
      tracking = false,
      isDemo = false,
      cached = false,
      onlineApproved = false,
      demoPlaying = false;
  bool _disposed = false, _available = true, _trackingWanted = false;
  int _routeEpoch = 0, _gpsEpoch = 0;
  DateTime? _lastRouteRequest;
  StreamSubscription<NavigationFix>? _subscription;
  Timer? _initialFixTimer, _freshnessTimer, _demoTimer;

  WalkNavigationController({
    required this.destinationId,
    required this.destination,
    required this.location,
    required this.routing,
    required this.cache,
    required this.examples,
  });
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool get stale =>
      fix != null &&
      !isDemo &&
      DateTime.now().difference(fix!.timestamp) > const Duration(seconds: 45);
  double? get remainingMeters =>
      path != null &&
          progress != null &&
          progress!.offRouteMeters < 60 &&
          !stale &&
          (fix?.accuracy ?? 1000) <= 100
      ? progress!.remainingMeters
      : null;
  int? get remainingMinutes => remainingMeters == null || path == null
      ? null
      : (remainingMeters! *
                (path!.meters > 0 ? path!.seconds / path!.meters : .8) /
                60)
            .ceil();
  bool get nearDestination =>
      fix != null &&
      !stale &&
      fix!.accuracy <= 50 &&
      metersBetween(fix!.point, destination) <= 25;

  Future<void> restore() async {
    final id = destinationId, epoch = _routeEpoch;
    FootRoute? saved;
    try {
      saved = await cache.load(id, destination);
    } catch (_) {
      return;
    }
    if (_disposed || epoch != _routeEpoch || path != null || isDemo) return;
    if (saved != null) {
      path = saved;
      cached = true;
      progress = fix == null ? null : progressOnRoute(fix!.point, saved);
      _notify();
    }
  }

  void changeDestination(String id, LatLng point) {
    if (id == destinationId && point == destination) return;
    final wasDemo = isDemo;
    _routeEpoch++;
    _lastRouteRequest = null;
    _stopDemoAnimation();
    destinationId = id;
    destination = point;
    path = null;
    progress = null;
    cached = false;
    routingNow = false;
    routeIssue = null;
    _notify();
    if (wasDemo) {
      unawaited(showDemo());
    } else {
      unawaited(restore());
      if (onlineApproved && fix != null && _available) unawaited(buildRoute());
    }
  }

  Future<void> startLocation({bool requestPermission = true}) async {
    _trackingWanted = true;
    if (!_available || _disposed) return;
    final epoch = ++_gpsEpoch;
    _stopDemoAnimation();
    isDemo = false;
    path = null;
    progress = null;
    cached = false;
    fix = null;
    trail.clear();
    _routeEpoch++;
    routingNow = false;
    routeIssue = null;
    locationIssue = null;
    locating = true;
    await _subscription?.cancel();
    _notify();
    try {
      await location.ensureReady(requestPermission: requestPermission);
      if (_disposed || !_available || epoch != _gpsEpoch) return;
      tracking = true;
      _initialFixTimer?.cancel();
      _initialFixTimer = Timer(const Duration(seconds: 20), () {
        if (fix == null && !_disposed) {
          locating = false;
          locationIssue = LocationIssue.timeout;
          _notify();
        }
      });
      _subscription = location.watch().listen(
        (value) {
          if (!_disposed && _available && epoch == _gpsEpoch) _onFix(value);
        },
        onError: (Object error) {
          if (_disposed || epoch != _gpsEpoch) return;
          locating = false;
          tracking = false;
          locationIssue = error is LocationFailure
              ? error.issue
              : error is TimeoutException
              ? LocationIssue.timeout
              : LocationIssue.unavailable;
          unawaited(_subscription?.cancel());
          _notify();
        },
      );
      _freshnessTimer?.cancel();
      _freshnessTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (stale) _notify();
      });
      unawaited(restore());
      _notify();
    } catch (error) {
      if (_disposed || epoch != _gpsEpoch) return;
      locating = false;
      tracking = false;
      locationIssue = error is LocationFailure
          ? error.issue
          : LocationIssue.unavailable;
      _notify();
    }
  }

  void _onFix(NavigationFix value) {
    if (!validPoint(value.point) ||
        !value.accuracy.isFinite ||
        value.accuracy < 0 ||
        DateTime.now().difference(value.timestamp) >
            const Duration(minutes: 2)) {
      return;
    }
    // Out-of-order platform updates must never move the marker backwards in time.
    if (fix != null && value.timestamp.isBefore(fix!.timestamp)) return;
    fix = value;
    if (value.accuracy <= 100 &&
        (routeIssue == RouteIssue.poorAccuracy ||
            routeIssue == RouteIssue.notReady)) {
      routeIssue = null;
    }
    locating = false;
    locationIssue = null;
    _initialFixTimer?.cancel();
    if (value.accuracy <= 50 &&
        (trail.isEmpty || metersBetween(trail.last, value.point) >= 3)) {
      trail.add(value.point);
      if (trail.length > 600) trail.removeAt(0);
    }
    progress = path == null ? null : progressOnRoute(value.point, path!);
    _notify();
    if (!isDemo &&
        onlineApproved &&
        _available &&
        (path == null || (progress?.offRouteMeters ?? 0) > 50)) {
      unawaited(buildRoute());
    }
  }

  void approveOnlineRouting() {
    onlineApproved = true;
    unawaited(buildRoute(force: true));
  }

  Future<void> buildRoute({bool force = false}) async {
    if (_disposed || !_available || isDemo || !onlineApproved || routingNow) {
      return;
    }
    final current = fix;
    if (current == null || stale) {
      routeIssue = RouteIssue.notReady;
      _notify();
      return;
    }
    if (current.accuracy > 100) {
      routeIssue = RouteIssue.poorAccuracy;
      _notify();
      return;
    }
    if (metersBetween(current.point, destination) > 30000) {
      routeIssue = RouteIssue.tooFar;
      _notify();
      return;
    }
    if (nearDestination) {
      routeIssue = null;
      _notify();
      return;
    }
    final interval = force
        ? const Duration(seconds: 2)
        : const Duration(seconds: 15);
    if (_lastRouteRequest != null &&
        DateTime.now().difference(_lastRouteRequest!) < interval) {
      return;
    }
    _lastRouteRequest = DateTime.now();
    final epoch = ++_routeEpoch, id = destinationId, target = destination;
    routingNow = true;
    routeIssue = null;
    _notify();
    try {
      final result = await routing.route(current.point, target);
      if (_disposed || epoch != _routeEpoch || !_available || isDemo) return;
      path = result;
      cached = false;
      progress = progressOnRoute(fix!.point, result);
      try {
        await cache.save(id, target, result);
      } catch (_) {
        /* Route still works when local storage is full. */
      }
    } catch (error) {
      if (_disposed || epoch != _routeEpoch) return;
      routeIssue = error is RoutingFailure ? error.issue : RouteIssue.network;
    } finally {
      if (!_disposed && epoch == _routeEpoch) {
        routingNow = false;
        _notify();
      }
    }
  }

  Future<void> showDemo() async {
    if (_disposed || !_available || routingNow) return;
    final previousDemoOrigin = isDemo ? fix?.point : null;
    _trackingWanted = false;
    _suspendLocation();
    _stopDemoAnimation();
    final epoch = ++_routeEpoch;
    isDemo = true;
    fix = null;
    path = null;
    progress = null;
    trail.clear();
    cached = false;
    locationIssue = null;
    routeIssue = null;
    routingNow = true;
    _notify();
    try {
      var result = await examples.load(destinationId);
      if (_disposed || epoch != _routeEpoch || !_available) return;
      if (result == null) {
        final origin =
            previousDemoOrigin != null &&
                metersBetween(previousDemoOrigin, destination) > 25 &&
                metersBetween(previousDemoOrigin, destination) < 10000
            ? previousDemoOrigin
            : LatLng(
                destination.latitude + .0009,
                destination.longitude + .0005,
              );
        result = await routing.route(origin, destination);
      }
      if (_disposed || epoch != _routeEpoch || !_available) return;
      path = result;
      _onFix(
        NavigationFix(
          result.points.first,
          accuracy: 6,
          timestamp: DateTime.now(),
        ),
      );
    } catch (error) {
      if (_disposed || epoch != _routeEpoch) return;
      routeIssue = error is RoutingFailure ? error.issue : RouteIssue.network;
    } finally {
      if (!_disposed && epoch == _routeEpoch) {
        routingNow = false;
        _notify();
      }
    }
  }

  void toggleDemoWalk() {
    if (!isDemo || path == null || !_available) return;
    if (demoPlaying) {
      _stopDemoAnimation();
      _notify();
      return;
    }
    demoPlaying = true;
    var walked = path!.points.length > 1 ? _distanceFromStart() : 0.0;
    if (remainingMeters != null && remainingMeters! < 3) {
      walked = 0;
      trail.clear();
    }
    _demoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final route = path;
      if (route == null || !_available) {
        _stopDemoAnimation();
        return;
      }
      walked += 8;
      var accumulated = 0.0;
      var point = route.points.last;
      for (var i = 1; i < route.points.length; i++) {
        final length = metersBetween(route.points[i - 1], route.points[i]);
        if (accumulated + length >= walked && length > 0) {
          final t = (walked - accumulated) / length;
          final a = route.points[i - 1], b = route.points[i];
          point = LatLng(
            a.latitude + (b.latitude - a.latitude) * t,
            a.longitude + (b.longitude - a.longitude) * t,
          );
          break;
        }
        accumulated += length;
      }
      _onFix(NavigationFix(point, accuracy: 6, timestamp: DateTime.now()));
      if (metersBetween(point, route.points.last) < 2) {
        _stopDemoAnimation();
        _notify();
      }
    });
    _notify();
  }

  double _distanceFromStart() {
    if (path == null || progress == null) return 0;
    var total = 0.0;
    for (var i = 1; i < path!.points.length; i++) {
      total += metersBetween(path!.points[i - 1], path!.points[i]);
    }
    return total - progress!.remainingMeters;
  }

  void _stopDemoAnimation() {
    _demoTimer?.cancel();
    _demoTimer = null;
    demoPlaying = false;
  }

  void _suspendLocation() {
    _gpsEpoch++;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _initialFixTimer?.cancel();
    _freshnessTimer?.cancel();
    locating = false;
    tracking = false;
  }

  void setAvailable(bool value) {
    if (_available == value || _disposed) return;
    _available = value;
    if (!value) {
      _routeEpoch++;
      routingNow = false;
      _suspendLocation();
      _stopDemoAnimation();
    } else if (_trackingWanted) {
      unawaited(startLocation(requestPermission: false));
    }
    _notify();
  }

  void stopLocation() {
    _trackingWanted = false;
    _routeEpoch++;
    routingNow = false;
    _suspendLocation();
    _stopDemoAnimation();
    fix = null;
    progress = null;
    cached = path != null;
    locationIssue = null;
    routeIssue = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _routeEpoch++;
    _suspendLocation();
    _stopDemoAnimation();
    routing.close();
    super.dispose();
  }
}
