import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'data/store.dart';
import 'l10n/app_localizations.dart';
import 'l10n/copy.dart';
import 'ui/screens.dart';
import 'navigation/route_observer.dart';
import 'planning/planning_screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: TravelApp()));
}

class TravelApp extends ConsumerStatefulWidget {
  const TravelApp({super.key});
  @override
  ConsumerState<TravelApp> createState() => _TravelAppState();
}

class _TravelAppState extends ConsumerState<TravelApp> {
  late final GoRouter router;
  @override
  void initState() {
    super.initState();
    final store = ref.read(storeProvider);
    router = GoRouter(
      observers: [navigationRouteObserver],
      initialLocation: '/s01',
      refreshListenable: store,
      redirect: (context, state) {
        if (!store.ready && state.uri.path != '/s01') return '/s01';
        if (state.uri.path == '/s01' && store.ready) {
          return !store.state['onboarded']
              ? '/s02'
              : !store.state['city']
              ? '/s03'
              : '/home';
        }
        return null;
      },
      routes: [
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
    store.init();
  }

  @override
  void dispose() {
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
