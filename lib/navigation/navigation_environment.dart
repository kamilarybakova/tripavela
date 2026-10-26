import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:sembast/sembast.dart';
import 'navigation_controller.dart';
import 'navigation_services.dart';

typedef NavigationControllerFactory =
    WalkNavigationController Function(
      String tripId,
      String destinationId,
      LatLng destination,
      Database db,
    );

class NavigationEnvironment {
  final bool networkTiles;
  final NavigationControllerFactory? factory;
  const NavigationEnvironment({this.networkTiles = true, this.factory});
  WalkNavigationController create(
    String tripId,
    String destinationId,
    LatLng destination,
    Database db,
  ) =>
      factory?.call(tripId, destinationId, destination, db) ??
      WalkNavigationController(
        destinationId: destinationId,
        destination: destination,
        location: DeviceLocationSource(),
        routing: OsrmFootRoutingService(),
        cache: SembastNavigationCache(db, tripId),
        examples: AssetNavigationExamples(),
      );
}

final navigationEnvironmentProvider = Provider<NavigationEnvironment>(
  (ref) => const NavigationEnvironment(),
);
