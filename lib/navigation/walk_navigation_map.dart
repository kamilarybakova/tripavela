import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sembast/sembast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../l10n/copy.dart';
import 'navigation_controller.dart';
import 'navigation_environment.dart';
import 'navigation_model.dart';
import 'route_observer.dart';

// TileLayer adds its User-Agent on native platforms, so headers must be mutable.
NetworkTileProvider createNavigationTileProvider({
  MapCachingProvider? cachingProvider,
}) => NetworkTileProvider(
  headers: <String, String>{
    if (!kIsWeb) 'User-Agent': 'Tripavela/1.0 (Flutter walking prototype)',
  },
  cachingProvider:
      cachingProvider ??
      BuiltInMapCachingProvider.getOrCreateInstance(maxCacheSize: 100000000),
);

class WalkNavigationMap extends StatefulWidget {
  final String tripId, destinationId, destinationName;
  final LatLng destination;
  final List<LatLng> visited;
  final bool enabled, indoors, needsStepFree;
  final Database db;
  final NavigationEnvironment environment;
  const WalkNavigationMap({
    super.key,
    required this.tripId,
    required this.destinationId,
    required this.destinationName,
    required this.destination,
    required this.visited,
    required this.db,
    required this.environment,
    this.enabled = true,
    this.indoors = false,
    this.needsStepFree = false,
  });
  @override
  State<WalkNavigationMap> createState() => _WalkNavigationMapState();
}

class _WalkNavigationMapState extends State<WalkNavigationMap>
    with WidgetsBindingObserver, RouteAware {
  late final WalkNavigationController engine;
  PageRoute<dynamic>? _route;
  bool _pageVisible = true;
  bool _appVisible = true;
  @override
  void initState() {
    super.initState();
    engine = widget.environment.create(
      widget.tripId,
      widget.destinationId,
      widget.destination,
      widget.db,
    );
    WidgetsBinding.instance.addObserver(this);
    unawaited(engine.restore());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      navigationRouteObserver.unsubscribe(this);
      _route = route;
      navigationRouteObserver.subscribe(this, route);
    }
    _syncAvailability();
  }

  void _syncAvailability() =>
      engine.setAvailable(_pageVisible && _appVisible && widget.enabled);
  @override
  void didUpdateWidget(covariant WalkNavigationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAvailability();
    engine.changeDestination(widget.destinationId, widget.destination);
  }

  @override
  void didPushNext() {
    _pageVisible = false;
    _syncAvailability();
  }

  @override
  void didPopNext() {
    _pageVisible = true;
    _syncAvailability();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appVisible = state == AppLifecycleState.resumed;
    _syncAvailability();
  }

  @override
  void dispose() {
    navigationRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    engine.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!engine.onlineApproved) {
      final approved = await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (c) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                copy.navConsentTitle,
                style: Theme.of(c).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              Text(copy.navConsentBody),
              const SizedBox(height: 12),
              Text(copy.navConsentLocal),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(copy.navConsentAccept),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(copy.message030),
              ),
            ],
          ),
        ),
      );
      if (approved != true || !mounted) return;
      engine.onlineApproved = true;
    }
    if (!engine.tracking || engine.isDemo || engine.fix == null) {
      await engine.startLocation();
    } else {
      await engine.buildRoute(force: true);
    }
  }

  Future<void> _fullscreen() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => FractionallySizedBox(
      heightFactor: .94,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.destinationName,
                      style: Theme.of(c).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: copy.message030,
                    onPressed: () => Navigator.pop(c),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: NavigationMapView(
                engine: engine,
                visited: widget.visited,
                environment: widget.environment,
                enabled: widget.enabled,
                indoors: widget.indoors,
                needsStepFree: widget.needsStepFree,
                fullscreen: true,
                onStart: _start,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => NavigationMapView(
    engine: engine,
    visited: widget.visited,
    environment: widget.environment,
    enabled: widget.enabled,
    indoors: widget.indoors,
    needsStepFree: widget.needsStepFree,
    onStart: _start,
    onExpand: _fullscreen,
  );
}

class NavigationMapView extends StatefulWidget {
  final WalkNavigationController engine;
  final List<LatLng> visited;
  final NavigationEnvironment environment;
  final bool enabled, indoors, needsStepFree, fullscreen;
  final Future<void> Function() onStart;
  final VoidCallback? onExpand;
  const NavigationMapView({
    super.key,
    required this.engine,
    required this.visited,
    required this.environment,
    required this.enabled,
    required this.indoors,
    required this.needsStepFree,
    required this.onStart,
    this.fullscreen = false,
    this.onExpand,
  });
  @override
  State<NavigationMapView> createState() => _NavigationMapViewState();
}

class _NavigationMapViewState extends State<NavigationMapView> {
  final _map = MapController();
  bool _ready = false, _follow = true, _tilesFailed = false;
  int _tileRevision = 0;
  FootRoute? _fittedPath;
  LatLng? _lastCentered;
  LatLng? _lastTarget;
  WalkNavigationController get engine => widget.engine;
  @override
  void initState() {
    super.initState();
    engine.addListener(_update);
    _lastTarget = engine.destination;
  }

  @override
  void dispose() {
    engine.removeListener(_update);
    _map.dispose();
    super.dispose();
  }

  void _update() {
    if (!mounted) return;
    setState(() {});
    if (_ready) {
      if (_lastTarget != engine.destination) {
        _lastTarget = engine.destination;
        _fit();
      } else if (engine.path != null && !identical(_fittedPath, engine.path)) {
        _fit();
      } else if (_follow &&
          engine.fix != null &&
          engine.fix!.point != _lastCentered) {
        _lastCentered = engine.fix!.point;
        _map.move(engine.fix!.point, _map.camera.zoom.clamp(15.0, 18.0));
      }
    }
  }

  void _fit() {
    if (!_ready) return;
    _fittedPath = engine.path;
    final points = engine.path?.points ?? [engine.destination];
    if (points.length < 2) {
      _map.move(engine.destination, 16);
      return;
    }
    _map.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(42),
        maxZoom: 17,
      ),
    );
  }

  Future<void> _link(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  String get _status {
    if (engine.locating) return copy.navLocating;
    if (engine.locationIssue != null) {
      return switch (engine.locationIssue!) {
        LocationIssue.denied => copy.navPermissionDenied,
        LocationIssue.deniedForever => copy.navPermissionForever,
        LocationIssue.servicesOff => copy.navServicesOff,
        LocationIssue.timeout => copy.navLocationTimeout,
        LocationIssue.unavailable => copy.navLocationUnavailable,
      };
    }
    if (engine.routeIssue != null) {
      return switch (engine.routeIssue!) {
        RouteIssue.network => copy.navRouteNetwork,
        RouteIssue.noRoute => copy.navNoRoute,
        RouteIssue.tooFar => copy.navTooFar,
        RouteIssue.poorAccuracy => copy.navPoorAccuracy,
        RouteIssue.notReady => copy.navNeedPosition,
      };
    }
    if (engine.routingNow) return copy.navRouting;
    if (engine.isDemo) return copy.navDemoExplanation;
    if (engine.stale) return copy.navStale;
    if (engine.nearDestination) return copy.navNear;
    if (engine.cached) return copy.navCached;
    if (engine.fix != null) return copy.navFollowing;
    return copy.navIntro;
  }

  String _meters(double value) => value >= 1000
      ? '${(value / 1000).toStringAsFixed(1)} ${copy.navKm}'
      : '${value.round()} ${copy.navMeters}';
  Widget _control(IconData icon, String label, VoidCallback onTap) =>
      IconButton.filled(
        tooltip: label,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: Palette.surface,
          foregroundColor: Palette.ink,
          side: const BorderSide(color: Palette.line),
        ),
        icon: Icon(icon, size: 20),
      );
  Widget _mapCanvas() => ClipRRect(
    borderRadius: BorderRadius.circular(widget.fullscreen ? 0 : 26),
    child: Stack(
      children: [
        ColoredBox(
          color: const Color(0xFFF2ECE1),
          child: CustomPaint(
            painter: _CoordinateGrid(),
            child: const SizedBox.expand(),
          ),
        ),
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: engine.destination,
            initialZoom: 16,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onMapReady: () {
              _ready = true;
              _fit();
            },
            onPositionChanged: (_, gesture) {
              if (gesture && _follow) setState(() => _follow = false);
            },
          ),
          children: [
            if (widget.environment.networkTiles)
              TileLayer(
                key: ValueKey(_tileRevision),
                urlTemplate: const String.fromEnvironment(
                  'TRAVEL_TILE_URL',
                  defaultValue:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                userAgentPackageName: 'com.example.travelRoulette',
                panBuffer: 0,
                keepBuffer: 1,
                tileProvider: createNavigationTileProvider(),
                errorTileCallback: (tile, error, stack) {
                  if (!_tilesFailed) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _tilesFailed = true);
                    });
                  }
                },
              ),
            if (engine.path != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: engine.path!.points,
                    strokeWidth: 6,
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                    color: engine.cached ? Palette.muted : Palette.clay,
                  ),
                ],
              ),
            if (engine.trail.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: List.of(engine.trail),
                    strokeWidth: 4,
                    color: const Color(0xFF4F8EA3),
                  ),
                ],
              ),
            if (engine.fix != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: engine.fix!.point,
                    radius: engine.fix!.accuracy,
                    useRadiusInMeter: true,
                    color: Palette.sea.withValues(alpha: .16),
                    borderColor: Palette.sea.withValues(alpha: .4),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final point in widget.visited)
                  Marker(
                    point: point,
                    width: 20,
                    height: 20,
                    child: Semantics(
                      label: copy.navVisited,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Palette.muted,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                Marker(
                  point: engine.destination,
                  width: 44,
                  height: 44,
                  child: Semantics(
                    label: copy.navDestination,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Palette.clay,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3379543D),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ),
                if (engine.fix != null)
                  Marker(
                    point: engine.fix!.point,
                    width: 28,
                    height: 28,
                    child: Semantics(
                      label: engine.isDemo ? copy.navDemoMarker : copy.navYou,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D88A2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [
                            BoxShadow(color: Color(0x443D88A2), blurRadius: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Palette.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              engine.isDemo
                  ? copy.navDemoBadge
                  : engine.cached
                  ? copy.navCachedBadge
                  : copy.navWalkingBadge,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Palette.ink,
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Column(
            children: [
              if (widget.onExpand != null)
                _control(Icons.open_in_full, copy.navExpand, widget.onExpand!),
              _control(Icons.route_outlined, copy.navFit, () {
                _follow = false;
                _fit();
              }),
              _control(
                _follow ? Icons.my_location : Icons.location_searching,
                copy.navCenter,
                () {
                  setState(() => _follow = true);
                  if (engine.fix != null) {
                    _map.move(engine.fix!.point, 16.5);
                  } else {
                    _fit();
                  }
                },
              ),
            ],
          ),
        ),
        if ((engine.locationIssue != null ||
                engine.routeIssue != null ||
                engine.stale) &&
            !engine.routingNow)
          Positioned(
            top: 60,
            left: 12,
            right: 64,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Palette.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _status,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Palette.ink),
              ),
            ),
          ),
        if (engine.fix == null &&
            !engine.routingNow &&
            !engine.locating &&
            widget.enabled)
          Positioned(
            left: 12,
            right: 62,
            bottom: 12,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: widget.onStart,
                  icon: const Icon(Icons.near_me_outlined, size: 18),
                  label: Text(copy.navStart),
                ),
                _control(
                  Icons.play_circle_outline,
                  copy.navExample,
                  () => engine.showDemo(),
                ),
              ],
            ),
          ),
        if (engine.locating || engine.routingNow)
          const Positioned(
            left: 18,
            bottom: 18,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (engine.remainingMeters != null)
          Positioned(
            left: 12,
            bottom: 12,
            right: 62,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Palette.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  Text(
                    _meters(engine.remainingMeters!),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Palette.ink,
                    ),
                  ),
                  Text(
                    copy.navMinutes(engine.remainingMinutes.toString()),
                    style: const TextStyle(color: Palette.muted),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
  void _showMapInfo() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('О карте', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(copy.navOfflineNote),
          if (engine.fix != null && !engine.isDemo) ...[
            const SizedBox(height: 12),
            Text(copy.navAccuracy(engine.fix!.accuracy.round().toString())),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _link('https://www.openstreetmap.org/fixthemap'),
            icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
            label: Text(copy.navFixMap),
          ),
          if (widget.enabled)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                engine.showDemo();
              },
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: Text(copy.navExample),
            ),
        ],
      ),
    ),
  );

  Widget _details() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        children: [
          TextButton(
            onPressed: () => _link('https://www.openstreetmap.org/copyright'),
            child: const Text(
              '© OpenStreetMap',
              style: TextStyle(fontSize: 11),
            ),
          ),
          TextButton(
            onPressed: () =>
                _link('https://routing.openstreetmap.de/about.html'),
            child: const Text('OSRM · FOSSGIS', style: TextStyle(fontSize: 11)),
          ),
          IconButton(
            tooltip: 'О карте',
            onPressed: _showMapInfo,
            icon: const Icon(Icons.info_outline, size: 17),
          ),
        ],
      ),
      if (widget.indoors)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            copy.navIndoors,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      if (engine.path?.includesFerry == true)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            copy.navFerry,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      if (widget.needsStepFree)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            copy.navAccessibility,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      if (engine.locationIssue != null ||
          engine.routeIssue != null ||
          engine.locating ||
          engine.routingNow ||
          engine.cached ||
          engine.stale ||
          engine.nearDestination)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(_status, style: Theme.of(context).textTheme.bodySmall),
        ),
      if (engine.isDemo)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Пример · точка на карте условная',
            style: TextStyle(fontSize: 12),
          ),
        ),
      if (_tilesFailed)
        TextButton.icon(
          onPressed: () => setState(() {
            _tilesFailed = false;
            _tileRevision++;
          }),
          icon: const Icon(Icons.refresh, size: 17),
          label: Text(copy.navTilesRetry),
        ),
      const SizedBox(height: 12),
      if (widget.enabled &&
          (engine.fix != null || engine.locating || engine.routingNow))
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (engine.fix != null || engine.locating || engine.routingNow)
              FilledButton.icon(
                onPressed: engine.locating || engine.routingNow
                    ? null
                    : widget.onStart,
                icon: const Icon(Icons.near_me_outlined, size: 18),
                label: Text(
                  engine.tracking && !engine.isDemo
                      ? copy.navRefreshRoute
                      : copy.navStart,
                ),
              ),
            IconButton.outlined(
              tooltip: copy.navExample,
              onPressed: engine.routingNow ? null : () => engine.showDemo(),
              icon: const Icon(Icons.play_circle_outline),
            ),
            if (engine.isDemo && engine.path != null)
              IconButton.filledTonal(
                tooltip: engine.demoPlaying
                    ? copy.navPauseExample
                    : copy.navWalkExample,
                onPressed: engine.toggleDemoWalk,
                icon: Icon(
                  engine.demoPlaying ? Icons.pause : Icons.directions_walk,
                ),
              ),
            if (engine.tracking)
              IconButton.outlined(
                tooltip: copy.navStopTracking,
                onPressed: engine.stopLocation,
                icon: const Icon(Icons.gps_off),
              ),
          ],
        ),
      const SizedBox(height: 8),
    ],
  );
  @override
  Widget build(BuildContext context) {
    if (widget.fullscreen) {
      return Column(
        children: [
          Expanded(child: _mapCanvas()),
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .42,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _details(),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 340, child: _mapCanvas()),
        _details(),
      ],
    );
  }
}

class _CoordinateGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE4DCCE)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
