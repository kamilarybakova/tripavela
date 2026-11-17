import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'data/remote_places.dart';
import 'data/store.dart';
import 'l10n/app_localizations.dart';
import 'l10n/copy.dart';
import 'ui/account_screen.dart';
import 'ui/remote_places_screen.dart';
import 'ui/screens.dart';
import 'navigation/route_observer.dart';
import 'planning/planning_screens.dart';

const _activeWalkPaths = {
  '/s12',
  '/s13',
  '/s14',
  '/s15',
  '/s16',
  '/s17',
  '/s18',
};
const _sessionPaths = {..._activeWalkPaths, '/s19', '/s23'};
const _personalPaths = {
  '/atlas',
  '/profile',
  '/trips',
  '/plan-trip',
  '/s11',
  '/s21',
  '/s22',
  '/s24',
  '/s26',
  '/s27',
  '/note',
  '/gallery',
  ..._sessionPaths,
};

bool _requiresTripavelaAccount(String path) =>
    _personalPaths.contains(path) ||
    path.startsWith('/trip-plan/') ||
    path.startsWith('/trip-day/');

String _afterLogin(String? value) {
  final uri = value == null ? null : Uri.tryParse(value);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.path == '/account' ||
      !uri.path.startsWith('/') ||
      uri.path.startsWith('//')) {
    return '/home';
  }
  return uri.toString();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // iOS uses Info.plist: portrait on iPhone, all orientations on iPad.
  if (defaultTargetPlatform != TargetPlatform.iOS) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  runApp(const ProviderScope(child: TravelApp()));
}

class TravelApp extends ConsumerStatefulWidget {
  const TravelApp({super.key});
  @override
  ConsumerState<TravelApp> createState() => _TravelAppState();
}

class _TravelAppState extends ConsumerState<TravelApp> {
  late final GoRouter router;
  late final AppLifecycleListener lifecycle;
  @override
  void initState() {
    super.initState();
    final store = ref.read(storeProvider);
    router = GoRouter(
      observers: [navigationRouteObserver],
      initialLocation: '/s01',
      refreshListenable: store,
      redirect: (context, state) {
        final path = state.uri.path;
        if (!store.ready) return path == '/s01' ? null : '/s01';
        final extra = state.uri.queryParameters['extra'];
        final next = store.state['onboarded'] != true
            ? '/s02'
            : store.state['city'] != true
            ? '/s03'
            : '/home';
        if (path == '/s01' ||
            (path == '/s02' && extra != 'repeat') ||
            (path == '/s03' && extra != 'change')) {
          return path == next ? null : next;
        }
        if (path == '/account' && store.canUsePersonal) {
          return _afterLogin(state.uri.queryParameters['return']);
        }
        if (_requiresTripavelaAccount(path) && !store.canUsePersonal) {
          return accountLocation(state.uri);
        }
        final id = state.uri.queryParameters['id'];
        if ((path == '/s10' || path == '/s11') &&
            !store.allRoutes.any((route) => route.id == id)) {
          return '/routes';
        }
        if (_sessionPaths.contains(path)) {
          final walk = store.sessions
              .where((trip) => trip['id'] == id)
              .firstOrNull;
          if (walk == null) return '/home';
          if (_activeWalkPaths.contains(path) && walk['ended'] != null) {
            return Uri(path: '/s19', queryParameters: {'id': id!}).toString();
          }
        }
        if (path == '/s21' &&
            !store.visits.any((visit) => visit['place'] == id)) {
          return '/atlas';
        }
        if (const {'/note', '/gallery'}.contains(path) &&
            !store.visits.any((visit) => visit['id'] == id)) {
          return '/atlas';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/account',
          builder: (context, state) => const AccountScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => TabShell(
            navigationShell: navigationShell,
            child: navigationShell,
          ),
          branches: [
            for (final path in ['home', 'routes', 'atlas', 'profile'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/$path',
                    builder: (context, state) => TravelScreen(code: path),
                  ),
                ],
              ),
          ],
        ),
        GoRoute(
          path: '/places',
          builder: (context, state) =>
              RemotePlacesScreen(catalog: RemotePlaces(store.db!)),
        ),
        GoRoute(
          path: '/trips',
          builder: (context, state) => const PlannedTripsScreen(),
        ),
        GoRoute(
          path: '/plan-trip',
          builder: (context, state) =>
              TripSetupScreen(editId: state.uri.queryParameters['from']),
        ),
        GoRoute(
          path: '/trip-plan/:id',
          builder: (context, state) =>
              TripPlanScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/trip-day/:id/:day',
          builder: (context, state) => TripDayScreen(
            id: state.pathParameters['id']!,
            dayIndex: int.tryParse(state.pathParameters['day']!) ?? -1,
          ),
        ),
        GoRoute(
          path: '/:code',
          builder: (context, state) => TravelScreen(
            code: state.pathParameters['code']!,
            id: state.uri.queryParameters['id'],
            extra: state.uri.queryParameters['extra'],
          ),
        ),
      ],
    );
    lifecycle = AppLifecycleListener(
      onResume: () => unawaited(store.refreshTravelData()),
    );
    store.init();
  }

  @override
  void dispose() {
    lifecycle.dispose();
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final mode = store.settings['theme'];
    return MaterialApp.router(
      title: 'Tripavela',
      debugShowCheckedModeBanner: false,
      theme: travelTheme(),
      darkTheme: travelTheme(true),
      themeMode: mode == 'light'
          ? ThemeMode.light
          : mode == 'dark'
          ? ThemeMode.dark
          : ThemeMode.system,
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        copy = AppLocalizations.of(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                MediaQuery.of(context).disableAnimations ||
                store.settings['reduceMotion'] == true,
          ),
          child: child!,
        );
      },
    );
  }
}
