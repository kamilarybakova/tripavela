import 'package:flutter/material.dart';
import '../l10n/copy.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../data/database.dart';
import '../data/store.dart';
import '../domain/models.dart';
import 'components.dart';
import 'package:latlong2/latlong.dart';
import '../navigation/navigation_environment.dart';
import '../navigation/walk_navigation_map.dart';
part 'trip_screens.dart';
part 'atlas_screens.dart';

String dateLabel(String value) => DateFormat(
  'd MMMM yyyy',
  'ru',
).format(DateTime.parse(value).toUtc().add(Duration(hours: 3)));
String money(int amount) => '${(amount / 100).round()} ₺';
final demoLabel = copy.message000;
final moods = [
  copy.message001,
  copy.message002,
  copy.message003,
  copy.message004,
  copy.message005,
  copy.message006,
];
final interests = [
  copy.message007,
  copy.message008,
  copy.message009,
  copy.message010,
  copy.message011,
  copy.message012,
  copy.message013,
  copy.message014,
];
final diets = [
  copy.message015,
  copy.message016,
  copy.message017,
  copy.message018,
];

final tabScrollControllers = <String, ScrollController>{};

class TabShell extends ConsumerWidget {
  final Widget child;
  final StatefulNavigationShell navigationShell;
  const TabShell({
    super.key,
    required this.child,
    required this.navigationShell,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final path = GoRouterState.of(context).uri.path;
    final index = ['/home', '/routes', '/atlas', '/profile'].indexOf(path);
    final active = store.active;
    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Material(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      active['status'] == 'paused'
                          ? Icons.pause_circle_outline
                          : Icons.directions_walk,
                    ),
                    title: Text(
                      active['status'] == 'paused'
                          ? copy.message019
                          : copy.message020(
                              ((active['index'] as int) + 1).toString(),
                              (active['branch'] == null
                                      ? 4
                                      : (active['stops'] as List).length)
                                  .toString(),
                            ),
                    ),
                    trailing: TextButton(
                      onPressed: () => context.push(
                        '/${active['status'] == 'paused' ? 's18' : 's12'}?id=${active['id']}',
                      ),
                      child: Text(
                        active['status'] == 'paused'
                            ? copy.message021
                            : copy.message022,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: .5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF76553F).withValues(alpha: .1),
                    blurRadius: 24,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: NavigationBar(
                  selectedIndex: index < 0 ? 0 : index,
                  onDestinationSelected: (i) {
                    final paths = ['home', 'routes', 'atlas', 'profile'];
                    if (i == index) {
                      final controller = tabScrollControllers[paths[i]];
                      if (controller != null && controller.hasClients) {
                        controller.animateTo(
                          0,
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      }
                    } else {
                      navigationShell.goBranch(i);
                    }
                  },
                  destinations: [
                    NavigationDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore),
                      label: copy.message023,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.route_outlined),
                      selectedIcon: Icon(Icons.route),
                      label: copy.message024,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.auto_stories_outlined),
                      selectedIcon: Icon(Icons.auto_stories),
                      label: copy.message025,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: copy.message026,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TravelScreen extends ConsumerStatefulWidget {
  final String code;
  final String? id, extra;
  const TravelScreen({super.key, required this.code, this.id, this.extra});
  @override
  ConsumerState<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends ConsumerState<TravelScreen> {
  String money(int amount) {
    final r = store.allRoutes.where((r) => r.id == widget.id).firstOrNull;
    return store.formatMoney(amount, forCity: r?.data['cityId']);
  }

  late final TravelStore store;
  late Map<String, dynamic> form;
  String? formCity;
  String query = '',
      themeFilter = copy.message027,
      sort = copy.message028,
      historyFilter = copy.message027;
  String replacementReason = copy.message029;
  int page = 0, selection = -1;
  bool scheme = false, revealAll = false, saving = false;
  String noteDraft = '';
  String? missionNote;
  final scrollController = ScrollController();
  late final PageController pager;
  Map<String, dynamic> get trip => store.session(widget.id!);
  WalkRoute get route => store.route(widget.id!);
  @override
  void initState() {
    super.initState();
    store = ref.read(storeProvider);
    if (widget.code == 's17' && widget.extra != null) {
      final parts = widget.extra!.split('|');
      replacementReason = parts.first;
      noteDraft = parts.skip(1).join('|');
    }
    pager = PageController(
      initialPage: widget.code == 'gallery'
          ? (int.tryParse(widget.extra ?? '0') ?? 0)
          : 0,
    );
    if (['home', 'routes', 'atlas', 'profile'].contains(widget.code)) {
      tabScrollControllers[widget.code] = scrollController;
    }
    form = copyMap(
      widget.code == 's26'
          ? Map<String, dynamic>.from(store.state['preferences'])
          : store.draft,
    );
  }

  void updateUi(VoidCallback action) {
    if (mounted) setState(action);
  }

  @override
  void dispose() {
    pager.dispose();
    if (tabScrollControllers[widget.code] == scrollController) {
      tabScrollControllers.remove(widget.code);
    }
    scrollController.dispose();
    super.dispose();
  }

  void open(String code, {String? id, String? extra}) => context.push(
    '/$code${id != null ? '?id=$id' : ''}${extra != null ? '${id != null ? '&' : '?'}extra=$extra' : ''}',
  );
  Future<bool> act(Future<void> Function() action, {String? success}) async {
    if (saving || store.busy) return false;
    setState(() => saving = true);
    try {
      await action();
      if (mounted && success != null) message(success);
      return true;
    } catch (e) {
      if (mounted) message(e.toString().replaceFirst('Bad state: ', ''));
      return false;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Future<bool> confirm(String title, String body, {String? yes}) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(copy.message030),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(yes ?? copy.messageConfirm),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> sheet(String title, List<Widget> children) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(c).height * .85,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(c).textTheme.titleLarge),
                SizedBox(height: 18),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget title(String text) => Padding(
    padding: EdgeInsets.only(top: 10, bottom: 12),
    child: EditorialText(text),
  );
  Widget bodyText(String text) => Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
  );
  Widget button(String text, VoidCallback? onTap, {IconData? icon}) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: saving || store.busy ? null : onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (saving) ...[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
          ],
          Flexible(child: Text(text, textAlign: TextAlign.center)),
          if (icon != null) ...[SizedBox(width: 10), Icon(icon, size: 20)],
        ],
      ),
    ),
  );
  Widget choice(String key, dynamic value, String text) => ChoiceChip(
    label: Text(text),
    selected: form[key] == value,
    onSelected: (_) => setState(() => form[key] = value),
  );
  Widget choices(String key, List<dynamic> values, List<String> labels) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < values.length; i++) choice(key, values[i], labels[i]),
    ],
  );
  Widget multi(String key, List<String> labels, {int? limit}) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final label in labels)
        FilterChip(
          label: Text(label),
          selected: (form[key] as List? ?? []).contains(label),
          onSelected: (selected) {
            final values = List<String>.from(form[key] ?? []);
            if (selected && limit != null && values.length >= limit) {
              message(copy.message031);
              return;
            }
            setState(() {
              selected ? values.add(label) : values.remove(label);
              form[key] = values;
            });
          },
        ),
    ],
  );
  Widget toggle(String key, String label, {String? subtitle}) =>
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: subtitle == null ? null : Text(subtitle),
        value: form[key] == true,
        onChanged: (v) => setState(() => form[key] = v),
      );
  Widget card(
    WalkRoute r, {
    String? reason,
    VoidCallback? onTap,
    bool nearby = false,
  }) => WalkCard(
    route: r,
    favorite: store.favorites.contains(r.id),
    onTap: onTap ?? () => open('s10', id: r.id),
    onFavorite: () => act(
      () => store.favorite(r.id),
      success: store.favorites.contains(r.id)
          ? copy.message032
          : copy.message033,
    ),
    reason: reason,
    nearby: nearby,
  );
  Widget backButton() => IconButton(
    tooltip: copy.message034,
    onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
    icon: Icon(Icons.arrow_back_rounded),
  );
  @override
  Widget build(BuildContext context) {
    ref.watch(storeProvider);
    if (formCity != null && formCity != store.cityId) {
      form = store.draft;
      query = '';
      themeFilter = copy.message027;
    }
    formCity = store.cityId;
    return switch (widget.code) {
      's01' => boot(),
      's02' => onboarding(),
      's03' => city(),
      'home' => home(),
      'routes' => catalog(),
      'atlas' => atlas(),
      'profile' => profile(),
      's05' || 's06' || 's07' => wizard(),
      's08' => results(),
      's10' => details(),
      's11' => prepare(),
      's12' => activeTrip(),
      's13' => stops(),
      's14' => story(),
      's15' => mission(),
      's16' => branch(),
      's17' => replacement(),
      's18' => pausePage(),
      's19' => summary(),
      's21' => discovery(),
      's22' => history(),
      's23' => pastTrip(),
      's24' => favoritesPage(),
      's26' => preferences(),
      's27' => settingsPage(),
      's28' => about(),
      'note' => notePage(),
      'gallery' => gallery(),
      'demo' => demoPage(),
      _ => PageFrame(
        title: copy.message035,
        child: button(copy.message036, () => context.go('/home')),
      ),
    };
  }

  Widget boot() => PageFrame(
    scroll: false,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/images/app-icon.png',
              width: 96,
              height: 96,
              semanticLabel: 'Tripavela',
            ),
          ),
          title('Tripavela'),
          if (store.initError != null) ...[
            bodyText(store.initError!),
            button(copy.message037, () => store.init()),
          ] else
            CircularProgressIndicator(),
        ],
      ),
    ),
  );
  Widget onboarding() {
    final headings = [copy.message038, copy.message039, copy.message040];
    final descriptions = [copy.message041, copy.message042, copy.message043];
    return PageFrame(
      scroll: false,
      footer: button(page == 2 ? copy.message044 : copy.message045, () async {
        if (page < 2) {
          pager.nextPage(
            duration: Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          await finishOnboarding();
        }
      }),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: finishOnboarding,
              child: Text(copy.message046),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: pager,
              itemCount: 3,
              onPageChanged: (p) => setState(() => page = p),
              itemBuilder: (c, i) => SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    Stack(
                      children: [
                        Photo(
                          'assets/images/${['city', 'coffee', 'park'][i]}.jpg',
                          height: MediaQuery.sizeOf(context).height * .31,
                          radius: 32,
                        ),
                        Positioned(
                          bottom: 18,
                          left: 18,
                          child: Tag(
                            [
                              copy.message047,
                              copy.message048,
                              copy.message049,
                            ][i],
                            gold: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      headings[i],
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    SizedBox(height: 16),
                    Text(
                      descriptions[i],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => AnimatedContainer(
                  duration: Duration(milliseconds: 180),
                  height: 6,
                  width: page == i ? 28 : 6,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: page == i ? Palette.forest : Palette.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> finishOnboarding() async {
    if (await act(
          () => store.change(
            (s) => s['onboarded'] = true,
            event: 'onboarding_completed',
          ),
        ) &&
        mounted) {
      if (widget.extra == 'repeat') {
        context.pop();
      } else {
        context.go('/s03');
      }
    }
  }

  Widget city() {
    final list = store.cities.values
        .where(
          (c) => '${c['name']} ${c['country']} ${c['id']}'
              .toLowerCase()
              .contains(query.toLowerCase()),
        )
        .toList();
    return PageFrame(
      title: 'Куда отправимся?',
      leading: store.state['city'] == true
          ? backButton()
          : const SizedBox.shrink(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Пять городов, 75 прогулок и поездки на 2–7 дней.'),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Найти город',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 20),
          for (final c in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  if (await act(() => store.selectCity(c['id'])) && mounted) {
                    context.go('/home');
                  }
                },
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Photo(c['image'], height: 160),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c['name'],
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (store.cityId == c['id'])
                            const Icon(Icons.check_circle_outline),
                        ],
                      ),
                      Text('${c['country']} · 15 маршрутов'),
                      const SizedBox(height: 8),
                      const Tag('Планы по дням · офлайн'),
                    ],
                  ),
                ),
              ),
            ),
          if (list.isEmpty) const Text('Попробуйте другое название города.'),
        ],
      ),
    );
  }

  Widget home() {
    final active = store.active;
    return PageFrame(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => open('s03'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.message060,
                        style: TextStyle(fontSize: 12, letterSpacing: 1.5),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              store.cityData['name'],
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Мои поездки',
                onPressed: () => context.push('/trips'),
                icon: Icon(Icons.calendar_month_outlined),
              ),
            ],
          ),
          SizedBox(height: 24),
          if (store.recovered) ...[
            Panel(child: Text(copy.recoveryNotice)),
            SizedBox(height: 16),
          ],
          if (active != null) ...[
            Panel(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    active['status'] == 'paused'
                        ? copy.message062
                        : copy.message063,
                  ),
                  Text(
                    store.route(active['routeId']).name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    copy.message064((store.visitedCount(active)).toString()),
                  ),
                  SizedBox(height: 12),
                  button(
                    copy.message065,
                    () => open(
                      active['status'] == 'paused' ? 's18' : 's12',
                      id: active['id'],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
          JournalHero(
            image: store.cityData['image'],
            title: 'Ваш город.\nВаши несколько дней.',
            subtitle:
                'Отель, ваш вайб и готовый план по дням — с прогулками, едой и покупками.',
            action: button(
              'Спланировать поездку',
              () => context.push('/plan-trip'),
              icon: Icons.arrow_forward_rounded,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => context.go('/routes'),
              child: const Text('Посмотреть 15 прогулок'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: beginWizard,
              child: Panel(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Есть свободный вечер?',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Подберём одну прогулку под настроение',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final q in [
                  copy.message071,
                  copy.message072,
                  copy.message073,
                  copy.message074,
                ])
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(q),
                      onPressed: () async {
                        final f = defaultFilters();
                        if (q == copy.message071) f['time'] = 120;
                        if (q == copy.message072) {
                          f['interests'] = [copy.message007];
                        }
                        if (q == copy.message073) f['mood'] = copy.message002;
                        if (q == copy.message074) {
                          f['company'] = copy.message075;
                        }
                        if (await act(() => store.setDraft(f)) && mounted) {
                          open('s05');
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          Section(copy.message076),
          ...store.routes.take(3).map((r) => card(r)),
          Section(copy.message077),
          LayoutBuilder(
            builder: (c, b) {
              final one = MediaQuery.textScalerOf(c).scale(16) > 22;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final item in [
                    copy.message078,
                    copy.message008,
                    copy.message079,
                    copy.message080,
                    copy.message081,
                    copy.message082,
                  ])
                    SizedBox(
                      width: one ? b.maxWidth : (b.maxWidth - 12) / 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          final f = defaultFilters();
                          f['interests'] = [
                            item == copy.message078
                                ? copy.message007
                                : item == copy.message079
                                ? copy.message011
                                : item == copy.message080
                                ? copy.message009
                                : item,
                          ];
                          if (await act(() => store.setDraft(f)) && mounted) {
                            open('s05');
                          }
                        },
                        child: Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                item == copy.message078
                                    ? Icons.restaurant_outlined
                                    : item == copy.message079
                                    ? Icons.spa_outlined
                                    : Icons.explore_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(height: 12),
                              Text(item),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Section(copy.message083),
          InfoLine(Icons.tune, copy.message084),
          InfoLine(Icons.explore_outlined, copy.message085),
          InfoLine(Icons.auto_stories_outlined, copy.message086),
          SizedBox(height: 24),
          Text(demoLabel, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> beginWizard() async {
    if (store.state['hasDraft'] == true) {
      await sheet(copy.message087, [
        Text(copy.message088),
        SizedBox(height: 16),
        button(copy.message021, () {
          context.pop();
          open('s05');
        }),
        TextButton(
          onPressed: () async {
            context.pop();
            if (await act(
                  () => store.setDraft(
                    Map<String, dynamic>.from(store.state['preferences']),
                  ),
                ) &&
                mounted) {
              open('s05');
            }
          },
          child: Text(copy.message089),
        ),
      ]);
    } else {
      if (await act(
            () => store.setDraft(
              Map<String, dynamic>.from(store.state['preferences']),
            ),
          ) &&
          mounted) {
        open('s05');
      }
    }
  }

  Widget moodGrid() => LayoutBuilder(
    builder: (c, b) {
      final columns = MediaQuery.textScalerOf(c).scale(16) > 22 ? 1 : 2;
      final width = (b.maxWidth - (columns - 1) * 12) / columns;
      final icons = [
        Icons.auto_awesome_outlined,
        Icons.spa_outlined,
        Icons.local_cafe_outlined,
        Icons.explore_outlined,
        Icons.people_outline,
        Icons.shuffle,
      ];
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < moods.length; i++)
            SizedBox(
              width: width,
              child: Semantics(
                button: true,
                selected: form['mood'] == moods[i],
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => form['mood'] = moods[i]),
                  child: Panel(
                    color: form['mood'] == moods[i]
                        ? Theme.of(c).colorScheme.primaryContainer
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              icons[i],
                              color: Theme.of(c).colorScheme.primary,
                            ),
                            const Spacer(),
                            if (form['mood'] == moods[i])
                              const Icon(Icons.check_circle, size: 20),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(moods[i], style: Theme.of(c).textTheme.titleSmall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget wizard() {
    final step = {'s05': 1, 's06': 2, 's07': 3}[widget.code]!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await act(() => store.setDraft(form)) && mounted) {
          context.pop();
        }
      },
      child: PageFrame(
        title: copy.message090,
        leading: IconButton(
          tooltip: copy.message034,
          onPressed: () async {
            if (await act(() => store.setDraft(form)) && mounted) context.pop();
          },
          icon: Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: copy.message091,
            onPressed: () async {
              if (await act(
                    () => store.change((s) {
                      s['draft'] = form;
                      s['hasDraft'] = true;
                    }),
                  ) &&
                  mounted) {
                context.go('/home');
              }
            },
            icon: Icon(Icons.close),
          ),
        ],
        footer: button(step == 3 ? copy.message092 : copy.message045, () async {
          if (await act(
                () => store.change((s) {
                  s['draft'] = form;
                  s['hasDraft'] = true;
                }),
              ) &&
              mounted) {
            open(
              step == 1
                  ? 's06'
                  : step == 2
                  ? 's07'
                  : 's08',
            );
          }
        }),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.message093((step).toString()),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: step / 3,
              borderRadius: BorderRadius.circular(5),
              minHeight: 5,
            ),
            SizedBox(height: 18),
            if (step == 1) ...[
              title(copy.message094),
              bodyText(copy.message095),
              Section(copy.message096),
              moodGrid(),
              Section(copy.message097),
              multi('interests', interests, limit: 3),
              Section(copy.message098),
              choices(
                'company',
                [
                  copy.message099,
                  copy.message075,
                  copy.message100,
                  copy.message101,
                ],
                [
                  copy.message099,
                  copy.message075,
                  copy.message100,
                  copy.message101,
                ],
              ),
              if (form['company'] == copy.message101) ...[
                Section(copy.message102),
                choices(
                  'age',
                  [copy.message103, copy.message104, copy.message105],
                  [copy.message103, copy.message104, copy.message105],
                ),
              ],
            ] else if (step == 2) ...[
              title(copy.message106),
              choices(
                'time',
                [60, 120, 240, 360],
                [
                  copy.message107,
                  copy.message108,
                  copy.message109,
                  copy.message110,
                ],
              ),
              SizedBox(height: 12),
              bodyText(copy.message111),
              Section(copy.message112),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: Text(copy.message113),
                    onPressed: () => setState(() {
                      form['startHour'] = store.cityNow().hour;
                      form['startMinute'] = store.cityNow().minute;
                      form['startDate'] = DateFormat(
                        'yyyy-MM-dd',
                      ).format(store.cityNow());
                    }),
                  ),
                  ActionChip(
                    label: Text(copy.message114),
                    onPressed: chooseStart,
                  ),
                ],
              ),
              Text(
                copy.message115(
                  (form['startDate']).toString(),
                  ('${form['startHour']}:${(form['startMinute'] ?? 0).toString().padLeft(2, '0')}'),
                ),
              ),
              SizedBox(height: 12),
              Text(copy.message116),
              Section(copy.message117),
              choices('budget', store.budgetCaps, [
                copy.message118,
                copy.budgetEconomy(money(store.budgetCaps[1])),
                copy.budgetModerate(money(store.budgetCaps[2])),
                copy.message121,
              ]),
              SizedBox(height: 14),
              bodyText(copy.message122),
            ] else ...[
              title(copy.message123),
              Panel(child: InfoLine(Icons.directions_walk, copy.message124)),
              Section(copy.message125),
              choices(
                'distance',
                [2000, 4000, 7000, 100000],
                [
                  copy.message126,
                  copy.message127,
                  copy.message128,
                  copy.message129,
                ],
              ),
              Section(copy.message130),
              choices(
                'pace',
                ['calm', 'normal'],
                [copy.message131, copy.message132],
              ),
              Section(copy.message133),
              toggle('noStairs', copy.message134, subtitle: copy.message135),
              toggle('stroller', copy.message136),
              toggle('rest', copy.message137),
              toggle('indoors', copy.message138),
              Section(copy.message139),
              choices('diet', diets, diets),
              SizedBox(height: 10),
              Text(copy.message140),
              Section(copy.message141),
              multi('missions', [
                copy.message142,
                copy.message143,
                copy.message144,
              ]),
              toggle('noMissions', copy.message145),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> chooseStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null && mounted) {
      setState(() {
        form['startHour'] = time.hour;
        form['startMinute'] = time.minute;
        form['startDate'] = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  Widget results() {
    final matches = matchRoutes(
      store.routes,
      store.draft,
      late: store.demo['late'] == true,
    );
    final suggestions = matches.isEmpty
        ? suggestRoutes(
            store.routes,
            store.draft,
            late: store.demo['late'] == true,
          )
        : <RouteSuggestion>[];
    return PageFrame(
      title: copy.message146,
      leading: backButton(),
      actions: [
        IconButton(
          tooltip: copy.message147,
          onPressed: () => open('s05'),
          icon: const Icon(Icons.tune),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            child: Text(
              copy.message149(
                ((store.draft['time'] / 60).round()).toString(),
                (store.draft['budget'] == 1000000
                        ? copy.message148
                        : money(store.draft['budget']))
                    .toString(),
                (store.draft['mood']).toString(),
              ),
            ),
          ),
          SizedBox(height: 22),
          if (matches.isEmpty) ...[
            Section(copy.nearbyResultsTitle),
            bodyText(copy.nearbyResultsBody),
            for (final suggestion in suggestions) ...[
              card(
                suggestion.route,
                reason: copy.nearbyResultBadge,
                nearby: true,
                onTap: () => acceptSuggestion(suggestion),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  suggestion.changes.entries
                      .where((e) => e.key != 'startMinute')
                      .map((e) => suggestionChange(e.key, e.value))
                      .join(' · '),
                ),
              ),
            ],
            TextButton(
              onPressed: () async {
                final f = store.draft;
                f['time'] = 360;
                f['distance'] = 100000;
                if (await act(() => store.setDraft(f)) && mounted) {
                  setState(() {});
                }
              },
              child: Text(copy.message151),
            ),
          ] else ...[
            Text(copy.message152((matches.length).toString())),
            SizedBox(height: 16),
            for (var i = 0; i < matches.length; i++)
              card(
                matches[i],
                reason: i == 0
                    ? copy.message154(
                        (matches[i].mood == store.draft['mood']
                                ? copy.message153
                                : '')
                            .toString(),
                      )
                    : null,
              ),
          ],
        ],
      ),
    );
  }

  String suggestionChange(String key, dynamic value) => switch (key) {
    'time' => copy.changeTime(value.toString()),
    'distance' => copy.changeDistance(
      ((value as int) / 1000).toStringAsFixed(1),
    ),
    'budget' => copy.changeBudget(money(value as int)),
    'startHour' => copy.changeStart('$value:00'),
    'startMinute' => '',
    'startDate' => copy.changeDate(value.toString()),
    'noStairs' => copy.changeStairs,
    'stroller' => copy.changeStroller,
    'indoors' => copy.changeIndoors,
    'rest' => copy.changeRest,
    'company' => copy.changeCompany,
    'diet' => copy.changeDiet,
    _ => '',
  };

  Future<void> acceptSuggestion(
    RouteSuggestion suggestion,
  ) => sheet(copy.acceptSuggestionTitle, [
    Text(suggestion.route.name, style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 12),
    Text(copy.acceptSuggestionBody),
    for (final entry in suggestion.changes.entries.where(
      (e) => e.key != 'startMinute',
    ))
      InfoLine(Icons.tune, suggestionChange(entry.key, entry.value)),
    const SizedBox(height: 16),
    button(copy.acceptSuggestionButton, () async {
      context.pop();
      if (await act(
            () => store.change((s) {
              s['draft'] = suggestion.filters;
              s['demo']['late'] = false;
            }),
          ) &&
          mounted) {
        open('s10', id: suggestion.route.id);
      }
    }),
    TextButton(onPressed: () => context.pop(), child: Text(copy.message030)),
  ]);

  String emptyReason() {
    if (store.demo['late'] == true || (store.draft['startHour'] as int) > 18) {
      return copy.message155;
    }
    if (store.draft['time'] <= 60) {
      return copy.message156;
    }
    return copy.message157;
  }

  Widget catalog() {
    var list = store.routes
        .where(
          (r) =>
              ('${r.name} ${r.description} ${r.theme}').toLowerCase().contains(
                query.toLowerCase(),
              ) &&
              (themeFilter == copy.message027 || r.theme == themeFilter),
        )
        .toList();
    if (form['catalogFilter'] == true) {
      list = list.where((r) => r.matches(form)).toList();
    }
    list.sort((a, b) {
      int cmp = sort == copy.message158
          ? a.minutes.compareTo(b.minutes)
          : sort == copy.message159
          ? (a.requiredMax + a.foodMax).compareTo(b.requiredMax + b.foodMax)
          : sort == copy.message160
          ? a.meters.compareTo(b.meters)
          : 0;
      return cmp == 0 ? a.id.compareTo(b.id) : cmp;
    });
    return PageFrame(
      controller: scrollController,
      title: copy.message024,
      actions: [
        IconButton(
          tooltip: copy.message061,
          onPressed: () => open('s24'),
          icon: Icon(Icons.bookmark_border),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.message161),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: copy.message162,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tag in [
                  copy.message027,
                  ...store.routes.map((r) => r.theme).toSet(),
                ])
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tag),
                      selected: themeFilter == tag,
                      onSelected: (_) => setState(() => themeFilter = tag),
                    ),
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            children: [
              TextButton.icon(
                onPressed: catalogFilters,
                icon: Icon(Icons.tune),
                label: Text(copy.message163),
              ),
              TextButton.icon(
                onPressed: () async {
                  await sheet(copy.message164, [
                    for (final value in [
                      copy.message028,
                      copy.message158,
                      copy.message159,
                      copy.message160,
                    ])
                      ListTile(
                        title: Text(value),
                        trailing: sort == value ? Icon(Icons.check) : null,
                        onTap: () {
                          setState(() => sort = value);
                          context.pop();
                        },
                      ),
                  ]);
                },
                icon: Icon(Icons.sort),
                label: Text(copy.message164),
              ),
            ],
          ),
          Text(copy.message165((list.length).toString())),
          SizedBox(height: 14),
          if (list.isEmpty)
            EmptyView(
              title: copy.message166,
              text: copy.message167,
              button: copy.message168,
              onTap: () => setState(() {
                query = '';
                themeFilter = copy.message027;
                form = defaultFilters();
              }),
            )
          else
            ...list.map((r) => card(r)),
        ],
      ),
    );
  }

  Future<void> catalogFilters() async {
    final temporary = copyMap(form);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(
        builder: (c, update) {
          Widget opts(String key, List<dynamic> values, List<String> labels) =>
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < values.length; i++)
                    ChoiceChip(
                      label: Text(labels[i]),
                      selected: temporary[key] == values[i],
                      onSelected: (_) =>
                          update(() => temporary[key] = values[i]),
                    ),
                ],
              );
          final count = store.routes
              .where(
                (r) =>
                    r.matches(temporary) &&
                    ((temporary['catalogTheme'] ?? copy.message027) ==
                            copy.message027 ||
                        r.theme == temporary['catalogTheme']),
              )
              .length;
          return FractionallySizedBox(
            heightFactor: .9,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    copy.message163,
                    style: Theme.of(c).textTheme.titleLarge,
                  ),
                  Section(copy.message169),
                  opts(
                    'time',
                    [120, 240, 360],
                    [copy.message108, copy.message109, copy.message110],
                  ),
                  Section(copy.message170),
                  opts('budget', store.budgetCaps, [
                    copy.message171,
                    copy.message172,
                    copy.message173,
                    copy.message174,
                  ]),
                  Section(copy.message175),
                  opts(
                    'distance',
                    [2000, 4000, 7000, 100000],
                    [
                      copy.message126,
                      copy.message127,
                      copy.message128,
                      copy.message176,
                    ],
                  ),
                  Section(copy.message177),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final value in [copy.message027, ...interests])
                        ChoiceChip(
                          label: Text(value),
                          selected:
                              (temporary['catalogTheme'] ?? copy.message027) ==
                              value,
                          onSelected: (_) =>
                              update(() => temporary['catalogTheme'] = value),
                        ),
                    ],
                  ),
                  SwitchListTile(
                    title: Text(copy.message134),
                    value: temporary['noStairs'] == true,
                    onChanged: (v) => update(() => temporary['noStairs'] = v),
                  ),
                  SwitchListTile(
                    title: Text(copy.message136),
                    value: temporary['stroller'] == true,
                    onChanged: (v) => update(() => temporary['stroller'] = v),
                  ),
                  button(copy.message178((count).toString()), () {
                    setState(() {
                      form = temporary;
                      form['catalogFilter'] = true;
                      themeFilter = temporary['catalogTheme'] ?? themeFilter;
                    });
                    Navigator.pop(c);
                  }),
                  TextButton(
                    onPressed: () => update(() {
                      temporary.clear();
                      temporary.addAll(defaultFilters());
                      temporary['time'] = 360;
                      temporary['distance'] = 100000;
                      temporary['budget'] = 1000000;
                    }),
                    child: Text(copy.message179),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget details() {
    final r = route;
    return PageFrame(
      title: copy.message180,
      leading: backButton(),
      actions: [
        IconButton(
          tooltip: copy.message061,
          onPressed: () => act(() => store.favorite(r.id)),
          icon: Icon(
            store.favorites.contains(r.id)
                ? Icons.bookmark
                : Icons.bookmark_border,
          ),
        ),
      ],
      footer: button(copy.message182, () => chooseRoute(r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Photo(r.image, height: 230, radius: 24),
          const SizedBox(height: 18),
          Tag(r.theme),
          title(r.name),
          bodyText(r.description),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('${r.minutes}–${r.maxMinutes} мин'),
              Text('${(r.meters / 1000).toStringAsFixed(1)} км'),
              const Text('4 остановки'),
              Text(
                '≈ ${money(r.requiredMin + r.foodMin)}–${money(r.requiredMax + r.foodMax)}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Места открываются по пути.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          DetailsFold(
            'Перед прогулкой',
            children: [
              InfoLine(Icons.schedule, copy.message204(r.lastStart.toString())),
              InfoLine(
                Icons.stairs_outlined,
                r.stairs == 'no'
                    ? copy.message197
                    : r.stairs == 'yes'
                    ? copy.message198
                    : copy.message199,
              ),
              InfoLine(
                Icons.family_restroom,
                r.family ? copy.message206 : copy.message207,
              ),
              bodyText(r.data['practical'] as String),
            ],
          ),
          DetailsFold(
            'Как добраться',
            children: [bodyText(r.data['gettingThere'] as String)],
          ),
          DetailsFold(
            'Расходы и расстояние',
            children: [
              InfoLine(
                Icons.confirmation_number_outlined,
                copy.message211(money(r.requiredMin), money(r.requiredMax)),
              ),
              InfoLine(
                Icons.restaurant_outlined,
                copy.message212(money(r.foodMin), money(r.foodMax)),
              ),
              bodyText(r.data['budgetNote'] as String),
              bodyText(r.data['distanceNote'] as String),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> chooseRoute(WalkRoute r) async {
    final current = store.active;
    if (current != null) {
      await sheet(copy.message216, [
        button(copy.message217, () {
          context.pop();
          open(
            current['status'] == 'paused' ? 's18' : 's12',
            id: current['id'],
          );
        }),
        TextButton(
          onPressed: () async {
            context.pop();
            if (await confirm(
              copy.message218,
              copy.message219,
              yes: copy.message220,
            )) {
              if (await act(() => store.end(current['id'])) && mounted) {
                open('s11', id: r.id);
              }
            }
          },
          child: Text(copy.message221),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(copy.message030),
        ),
      ]);
    } else {
      open('s11', id: r.id);
    }
  }

  Widget prepare() {
    final r = route;
    return PageFrame(
      title: copy.message222,
      leading: backButton(),
      footer: button(copy.message223, () async {
        String? sid;
        if (await act(() async {
              sid = await store.start(r.id, reveal: revealAll);
            }) &&
            mounted) {
          context.pushReplacement('/s12?id=$sid');
        }
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Photo(r.image, height: 180),
          const SizedBox(height: 18),
          title(r.name),
          bodyText(
            '${r.minutes}–${r.maxMinutes} мин · ${(r.meters / 1000).toStringAsFixed(1)} км · 4 остановки',
          ),
          InfoLine(Icons.schedule, copy.message204(r.lastStart.toString())),
          Section(copy.message239),
          RadioGroup<bool>(
            groupValue: revealAll,
            onChanged: (v) => setState(() => revealAll = v!),
            child: Column(
              children: [
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  title: Text(copy.message240),
                ),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  value: true,
                  title: Text(copy.message241),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DetailsFold(
            'Что взять и учесть',
            children: [
              InfoLine(Icons.battery_charging_full, copy.message236),
              InfoLine(Icons.water_drop_outlined, copy.message237),
              InfoLine(Icons.cloud_outlined, copy.message238),
              InfoLine(
                Icons.stairs_outlined,
                r.stairs == 'no'
                    ? copy.message229
                    : r.stairs == 'yes'
                    ? copy.message230
                    : copy.message199,
              ),
              InfoLine(
                Icons.payments_outlined,
                copy.message231(
                  money(r.requiredMin),
                  money(r.requiredMax),
                  money(r.foodMin),
                  money(r.foodMax),
                ),
              ),
              InfoLine(
                Icons.flag_outlined,
                store.draft['noMissions'] == true
                    ? copy.message233
                    : copy.message234,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
